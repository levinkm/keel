import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:keel/features/assets/domain/entities/asset.dart';
import 'package:keel/features/assets/domain/repositories/assets_repository.dart';
import 'package:keel/features/investments/domain/entities/holding.dart';
import 'package:keel/features/investments/domain/repositories/investments_repository.dart';
import 'package:keel/features/ledger/domain/entities/journal_entry.dart';
import 'package:keel/features/ledger/domain/repositories/ledger_repository.dart';
import 'package:uuid/uuid.dart';

part 'investments_state.dart';
part 'investments_cubit.freezed.dart';

class InvestmentsCubit extends Cubit<InvestmentsState> {
  final InvestmentsRepository _repo;
  final AssetsRepository _assetsRepo;
  final LedgerRepository _ledgerRepo;

  InvestmentsCubit(this._repo, this._assetsRepo, this._ledgerRepo)
      : super(const InvestmentsState.initial());

  Future<void> load() async {
    emit(const InvestmentsState.loading());
    await _reload();
  }

  Future<void> selectHolding(String? id) async {
    final current = state;
    if (current is! _Loaded) return;
    emit(current.copyWith(selectedHoldingId: id));
  }

  /// Creates a holding and a linked Asset record of class investments.
  Future<void> createHolding(Holding holding) async {
    final holdingId = const Uuid().v4();
    final withId = holding.copyWith(id: holdingId);

    final result = await _repo.createHolding(withId);
    await result.fold(
      (f) async => _emitError(f.message),
      (id) async {
        // Create linked Asset record
        final asset = Asset(
          id: const Uuid().v4(),
          name: holding.name,
          assetClass: AssetClass.investments,
          acquisitionDate: holding.createdAt,
          costMinor: holding.totalCostBasisMinor,
          currency: holding.currency,
          ownershipShareBp: 10000,
          currentValueMinor: holding.marketValueMinor,
          salvageMinor: 0,
          status: AssetStatus.inUse,
          holdingId: holdingId,
          createdAt: holding.createdAt,
        );
        await _assetsRepo.createAsset(asset);
        await _reload(selectedId: holdingId);
      },
    );
  }

  Future<void> updateHolding(Holding holding) async {
    final result = await _repo.updateHolding(holding);
    result.fold(
      (f) => _emitError(f.message),
      (_) async => await _reload(selectedId: holding.id),
    );
  }

  Future<void> updateCurrentPrice(String holdingId, int priceMinor) async {
    final result = await _repo.updateCurrentPrice(holdingId, priceMinor);
    await result.fold(
      (f) async => _emitError(f.message),
      (_) async {
        // Also update the linked asset's currentValueMinor
        final assetsResult = await _assetsRepo.getAssets();
        assetsResult.fold((_) => null, (assets) async {
          final linked = assets.cast<Asset?>()
              .firstWhere((a) => a?.holdingId == holdingId, orElse: () => null);
          if (linked != null) {
            final current = state;
            final holding = current is _Loaded
                ? current.holdings.cast<Holding?>()
                    .firstWhere((h) => h?.id == holdingId, orElse: () => null)
                : null;
            if (holding != null) {
              final updatedValue = (holding.totalUnits * priceMinor).round();
              await _assetsRepo.updateAsset(
                  linked.copyWith(currentValueMinor: updatedValue));
            }
          }
        });
        await _reload(selectedId: holdingId);
      },
    );
  }

  Future<void> addLot(HoldingLot lot, String investmentAccountId,
      String? sourceAccountId) async {
    final lotId = const Uuid().v4();
    final withId = HoldingLot(
      id: lotId,
      holdingId: lot.holdingId,
      date: lot.date,
      units: lot.units,
      priceMinor: lot.priceMinor,
      feesMinor: lot.feesMinor,
      currency: lot.currency,
    );
    final result = await _repo.addLot(withId);
    await result.fold(
      (f) async => _emitError(f.message),
      (_) async {
        // Post journal entry: DR investment account, CR source account
        if (sourceAccountId != null) {
          final cost = withId.costBasisMinor;
          final period = _period(lot.date);
          final entryId = const Uuid().v4();
          final entry = JournalEntry(
            id: entryId,
            date: lot.date,
            description: 'Investment purchase — ${_holdingName(lot.holdingId)}',
            reference: lotId, // store lot id as reference for reversal lookup
            period: period,
            isLocked: false,
            lines: [
              JournalLine(
                id: const Uuid().v4(),
                entryId: entryId,
                accountId: investmentAccountId,
                amountMinor: cost,
                currency: lot.currency,
                side: JournalSide.debit,
                memo: 'Investment deposit',
              ),
              JournalLine(
                id: const Uuid().v4(),
                entryId: entryId,
                accountId: sourceAccountId,
                amountMinor: cost,
                currency: lot.currency,
                side: JournalSide.credit,
                memo: 'Funded investment',
              ),
            ],
            createdAt: DateTime.now(),
          );
          await _ledgerRepo.postEntry(entry);
        }
        await _syncLinkedAsset(lot.holdingId);
        await _reload(selectedId: lot.holdingId);
      },
    );
  }

  Future<void> deleteLot(String lotId, String holdingId,
      String investmentAccountId) async {
    final result = await _repo.deleteLot(lotId);
    await result.fold(
      (f) async => _emitError(f.message),
      (_) async {
        // Reverse the journal entry that used this lot id as reference
        final entriesResult =
            await _ledgerRepo.getEntriesByAccount(investmentAccountId);
        entriesResult.fold((_) => null, (entries) async {
          final entry = entries.cast<JournalEntry?>().firstWhere(
              (e) => e?.reference == lotId, orElse: () => null);
          if (entry != null) {
            await _ledgerRepo.reverseEntry(
                entry.id, 'Lot deleted — investment purchase reversed');
          }
        });
        await _syncLinkedAsset(holdingId);
        await _reload(selectedId: holdingId);
      },
    );
  }

  Future<void> deactivateHolding(String holdingId) async {
    final result = await _repo.deactivateHolding(holdingId);
    result.fold(
      (f) => _emitError(f.message),
      (_) async => await _reload(),
    );
  }

  /// Records a redemption/sale. Posts:
  ///   DR  Bank/destination account   proceeds
  ///   CR  Investment account         cost basis of redeemed units
  ///   DR  Investment Loss / CR Investment Gain  (realised P&L)
  Future<void> recordRedemption({
    required Holding holding,
    required double units,
    required int priceMinor,
    required int feesMinor,
    required DateTime date,
    required String destinationAccountId,
    required String gainLossAccountId, // expense acct for loss, income for gain
  }) async {
    final lotId = const Uuid().v4();
    final lot = HoldingLot(
      id: lotId,
      holdingId: holding.id,
      date: date,
      units: units,
      priceMinor: priceMinor,
      feesMinor: feesMinor,
      currency: holding.currency,
      lotType: LotType.redemption,
    );
    final result = await _repo.addLot(lot);
    await result.fold(
      (f) async => _emitError(f.message),
      (_) async {
        // Reload holding to get updated FIFO cost
        final holdingsResult = await _repo.getHoldings();
        final updated = holdingsResult.fold((_) => null,
            (list) => list.cast<Holding?>().firstWhere(
                (h) => h?.id == holding.id, orElse: () => null));
        if (updated == null) return;

        final proceeds = lot.proceedsMinor;
        // FIFO cost of redeemed units
        final avgCost = updated.totalCostBasisMinor > 0 && updated.totalUnits > 0
            ? (updated.totalCostBasisMinor / (updated.totalUnits + units))
            : 0.0;
        final costOfRedeemed = (avgCost * units).round();
        final realisedGain = proceeds - costOfRedeemed;
        final period = _period(date);
        final entryId = const Uuid().v4();

        final lines = <JournalLine>[
          // DR destination (bank receives proceeds)
          JournalLine(
            id: const Uuid().v4(), entryId: entryId,
            accountId: destinationAccountId,
            amountMinor: proceeds,
            currency: holding.currency,
            side: JournalSide.debit,
            memo: 'Redemption proceeds',
          ),
          // CR investment account (reduces balance by cost basis)
          JournalLine(
            id: const Uuid().v4(), entryId: entryId,
            accountId: holding.accountId,
            amountMinor: costOfRedeemed,
            currency: holding.currency,
            side: JournalSide.credit,
            memo: 'Cost basis of redeemed units',
          ),
        ];

        // Realised gain or loss balancing line
        if (realisedGain > 0) {
          // Gain: CR gain/income account
          lines.add(JournalLine(
            id: const Uuid().v4(), entryId: entryId,
            accountId: gainLossAccountId,
            amountMinor: realisedGain,
            currency: holding.currency,
            side: JournalSide.credit,
            memo: 'Realised investment gain',
          ));
          // Balance: DR investment account for the gain portion
          lines.add(JournalLine(
            id: const Uuid().v4(), entryId: entryId,
            accountId: holding.accountId,
            amountMinor: realisedGain,
            currency: holding.currency,
            side: JournalSide.debit,
            memo: 'Gain on redemption',
          ));
        } else if (realisedGain < 0) {
          final loss = realisedGain.abs();
          // Loss: DR loss/expense account
          lines.add(JournalLine(
            id: const Uuid().v4(), entryId: entryId,
            accountId: gainLossAccountId,
            amountMinor: loss,
            currency: holding.currency,
            side: JournalSide.debit,
            memo: 'Realised investment loss',
          ));
          // Balance: CR investment account for the loss portion
          lines.add(JournalLine(
            id: const Uuid().v4(), entryId: entryId,
            accountId: holding.accountId,
            amountMinor: loss,
            currency: holding.currency,
            side: JournalSide.credit,
            memo: 'Loss on redemption',
          ));
        }

        final entry = JournalEntry(
          id: entryId,
          date: date,
          description: 'Redemption — ${holding.name}',
          reference: lotId,
          period: period,
          isLocked: false,
          lines: lines,
          createdAt: DateTime.now(),
        );
        await _ledgerRepo.postEntry(entry);
        await _syncLinkedAsset(holding.id);
        await _reload(selectedId: holding.id);
      },
    );
  }

  /// Records interest/dividend income. Posts:
  ///   isReinvested=false: DR bank account / CR income account
  ///   isReinvested=true:  DR investment account / CR income account + adds reinvestment lot
  Future<void> recordIncome({
    required Holding holding,
    required int amountMinor,
    required DateTime date,
    required String incomeAccountId,
    required String bankOrInvestmentAccountId,
    required bool isReinvested,
    double reinvestedUnits = 0,
    int reinvestedPriceMinor = 0,
  }) async {
    // Add income lot for tracking
    final incomeLot = HoldingLot(
      id: const Uuid().v4(),
      holdingId: holding.id,
      date: date,
      units: isReinvested ? reinvestedUnits : 0,
      priceMinor: isReinvested ? reinvestedPriceMinor : amountMinor,
      feesMinor: 0,
      currency: holding.currency,
      lotType: isReinvested ? LotType.reinvestment : LotType.income,
    );
    await _repo.addLot(incomeLot);

    final period = _period(date);
    final entryId = const Uuid().v4();
    final entry = JournalEntry(
      id: entryId,
      date: date,
      description: '${isReinvested ? 'Reinvested income' : 'Investment income'} — ${holding.name}',
      period: period,
      isLocked: false,
      lines: [
        JournalLine(
          id: const Uuid().v4(), entryId: entryId,
          accountId: bankOrInvestmentAccountId,
          amountMinor: amountMinor,
          currency: holding.currency,
          side: JournalSide.debit,
          memo: isReinvested ? 'Reinvested into fund' : 'Income received',
        ),
        JournalLine(
          id: const Uuid().v4(), entryId: entryId,
          accountId: incomeAccountId,
          amountMinor: amountMinor,
          currency: holding.currency,
          side: JournalSide.credit,
          memo: 'Investment income',
        ),
      ],
      createdAt: DateTime.now(),
    );
    await _ledgerRepo.postEntry(entry);
    await _syncLinkedAsset(holding.id);
    await _reload(selectedId: holding.id);
  }

  void clearValidationError() {
    final current = state;
    if (current is! _Loaded) return;
    emit(current.copyWith(validationError: null));
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  /// Syncs the linked Asset's cost/value after lot changes.
  Future<void> _syncLinkedAsset(String holdingId) async {
    final holdingsResult = await _repo.getHoldings();
    final holding = holdingsResult.fold((_) => null,
        (list) => list.cast<Holding?>()
            .firstWhere((h) => h?.id == holdingId, orElse: () => null));
    if (holding == null) return;

    final assetsResult = await _assetsRepo.getAssets();
    assetsResult.fold((_) => null, (assets) async {
      final linked = assets.cast<Asset?>()
          .firstWhere((a) => a?.holdingId == holdingId, orElse: () => null);
      if (linked != null) {
        await _assetsRepo.updateAsset(linked.copyWith(
          costMinor: holding.totalCostBasisMinor,
          currentValueMinor: holding.marketValueMinor,
        ));
      }
    });
  }

  void _emitError(String message) {
    final current = state;
    if (current is _Loaded) {
      emit(current.copyWith(validationError: message));
    } else {
      emit(InvestmentsState.error(message));
    }
  }

  String _period(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  String _holdingName(String holdingId) {
    final current = state;
    if (current is! _Loaded) return holdingId;
    return current.holdings
        .cast<Holding?>()
        .firstWhere((h) => h?.id == holdingId, orElse: () => null)
        ?.name ?? holdingId;
  }

  Future<void> _reload({String? selectedId}) async {
    final result = await _repo.getHoldings();
    final holdings = result.fold((_) => <Holding>[], (h) => h);

    int totalInvested = 0;
    int totalMarket = 0;
    int totalRealised = 0;
    int totalIncome = 0;
    for (final h in holdings) {
      totalInvested += h.totalCostBasisMinor;
      totalMarket += h.marketValueMinor;
      totalRealised += h.realisedGainMinor;
      totalIncome += h.totalIncomeMinor;
    }

    final current = state;
    final resolvedId = selectedId ??
        (current is _Loaded ? current.selectedHoldingId : null) ??
        (holdings.isNotEmpty ? holdings.first.id : null);

    emit(InvestmentsState.loaded(
      holdings: holdings,
      selectedHoldingId: resolvedId,
      totalInvestedMinor: totalInvested,
      totalMarketValueMinor: totalMarket,
      totalGainMinor: totalMarket - totalInvested,
      totalRealisedGainMinor: totalRealised,
      totalIncomeMinor: totalIncome,
    ));
  }
}
