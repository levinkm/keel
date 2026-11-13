import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/accounts/domain/repositories/accounts_repository.dart';
import 'package:keel/features/income/domain/entities/income_stream.dart';
import 'package:keel/features/income/domain/repositories/income_repository.dart';
import 'package:keel/features/ledger/domain/entities/journal_entry.dart';
import 'package:keel/features/ledger/domain/repositories/ledger_repository.dart';
import 'package:uuid/uuid.dart';

part 'income_state.dart';
part 'income_cubit.freezed.dart';

class IncomeCubit extends Cubit<IncomeState> {
  final IncomeRepository _incomeRepo;
  final LedgerRepository _ledgerRepo;
  final AccountsRepository _accountsRepo;

  IncomeCubit(this._incomeRepo, this._ledgerRepo, this._accountsRepo)
      : super(const IncomeState.initial());

  static String _todayPeriod() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  static String _offsetPeriod(String period, int offset) {
    final parts = period.split('-');
    var year = int.parse(parts[0]);
    var month = int.parse(parts[1]) + offset;
    while (month < 1) { month += 12; year--; }
    while (month > 12) { month -= 12; year++; }
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  Future<void> load() async {
    emit(const IncomeState.loading());
    await _loadPeriod(_todayPeriod());
  }

  Future<void> selectPeriod(String period) async {
    final current = state;
    if (current is! _Loaded) return;
    await _loadPeriod(period,
        existingStreams: current.streams,
        existingAccounts: current.incomeAccounts,
        selectedStreamId: current.selectedStreamId);
  }

  Future<void> previousPeriod() async {
    final current = state;
    if (current is! _Loaded) return;
    await selectPeriod(_offsetPeriod(current.selectedPeriod, -1));
  }

  Future<void> nextPeriod() async {
    final current = state;
    if (current is! _Loaded) return;
    await selectPeriod(_offsetPeriod(current.selectedPeriod, 1));
  }

  Future<void> selectStream(String? streamId) async {
    final current = state;
    if (current is! _Loaded) return;
    if (streamId == null) {
      emit(current.copyWith(
          selectedStreamId: null, sparkline: [], paymentHistory: []));
      return;
    }
    final stream = current.streams.firstWhere((s) => s.id == streamId);
    final sparkline = await _buildSparkline(stream, current.selectedPeriod);
    final history = await _buildHistory(stream);
    emit(current.copyWith(
      selectedStreamId: streamId,
      sparkline: sparkline,
      paymentHistory: history,
    ));
  }

  void clearValidationError() {
    final current = state;
    if (current is! _Loaded) return;
    emit(current.copyWith(validationError: null));
  }

  Future<void> createStream(IncomeStream stream) async {
    await _incomeRepo.createStream(stream);
    await _reload();
  }

  Future<void> updateStream(IncomeStream stream) async {
    await _incomeRepo.updateStream(stream);
    await _reload();
  }

  Future<void> markReceived({
    required IncomeStream stream,
    required int amountMinor,
    required String note,
  }) async {
    final current = state;
    if (current is! _Loaded) return;

    // ── Period validation ────────────────────────────────────────────────────
    // Only allow marking received in the last 7 days of the period or after.
    // Irregular/one-off streams are exempt.
    if (stream.paymentMode != PaymentMode.milestone &&
        !stream.frequency.isIrregular &&
        stream.type != IncomeType.oneOff) {
      final now = DateTime.now();
      final parts = current.selectedPeriod.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final lastDay = DateTime(year, month + 1, 0); // last day of month
      final windowStart = DateTime(lastDay.year, lastDay.month, lastDay.day - 6);
      if (now.isBefore(windowStart)) {
        const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final daysUntil = windowStart.difference(now).inDays + 1;
        emit(current.copyWith(
          validationError:
              'Cannot mark received yet. Available from ${windowStart.day} '
              '${months[windowStart.month]} ($daysUntil days away).',
        ));
        return;
      }
    }

    final now = DateTime.now();
    final period = _todayPeriod();

    // Entry: Debit asset account (cash in) / Credit opening-equity (income source)
    // If stream has no linked account, fall back to first active asset account
    String debitAccountId = stream.accountId;
    if (debitAccountId.isEmpty) {
      final allAccounts = (await _accountsRepo.getAccounts())
          .fold((_) => <Account>[], (a) => a);
      final firstAsset = allAccounts
          .where((a) => a.type == AccountType.asset && a.isActive)
          .cast<Account?>()
          .firstWhere((_) => true, orElse: () => null);
      if (firstAsset == null) return;
      debitAccountId = firstAsset.id;
    }

    final entry = JournalEntry(
      id: const Uuid().v4(),
      date: now,
      description: note.isEmpty ? 'Income: ${stream.name}' : note,
      period: period,
      isLocked: false,
      createdAt: now,
      lines: [
        JournalLine(
          id: const Uuid().v4(),
          entryId: '',
          accountId: debitAccountId,
          amountMinor: amountMinor,
          currency: stream.currency,
          side: JournalSide.debit,
        ),
        JournalLine(
          id: const Uuid().v4(),
          entryId: '',
          accountId: 'opening-equity',
          amountMinor: amountMinor,
          currency: stream.currency,
          side: JournalSide.credit,
        ),
      ],
    );
    await _ledgerRepo.postEntry(entry);
    await _reload(selectedStreamId: stream.id);
  }

  Future<void> _reload({String? selectedStreamId}) async {
    final current = state;
    final period = current is _Loaded ? current.selectedPeriod : _todayPeriod();
    final sid = selectedStreamId ?? (current is _Loaded ? current.selectedStreamId : null);
    await _loadPeriod(period, selectedStreamId: sid);
  }

  Future<void> _loadPeriod(
    String period, {
    List<IncomeStream>? existingStreams,
    List<Account>? existingAccounts,
    String? selectedStreamId,
  }) async {
    final List<IncomeStream> streams;
    if (existingStreams != null) {
      streams = existingStreams;
    } else {
      final r = await _incomeRepo.getAllStreams();
      streams = r.fold((_) => [], (s) => s);
    }

    final List<Account> allAccounts;
    if (existingAccounts != null) {
      allAccounts = existingAccounts;
    } else {
      final r = await _accountsRepo.getAccounts();
      allAccounts = r.fold((_) => [], (a) => a);
    }
    final incomeAccounts = allAccounts
        .where((a) => a.type == AccountType.income || a.type == AccountType.asset)
        .toList();

    // Compute received per stream from ledger entries this period
    final entriesResult = await _ledgerRepo.getEntriesByPeriod(period);
    final entries = entriesResult.fold((_) => <JournalEntry>[], (e) => e);

    final streamAccountIds = {for (final s in streams) s.accountId: s.id};
    final receivedByStream = <String, int>{};
    for (final entry in entries) {
      for (final line in entry.lines) {
        final streamId = streamAccountIds[line.accountId];
        if (streamId != null && line.side == JournalSide.credit) {
          receivedByStream[streamId] =
              (receivedByStream[streamId] ?? 0) + line.amountMinor;
        }
      }
    }

    // Stats
    final activeStreams = streams.where((s) => s.isActive).toList();
    final expectedMinor = activeStreams.fold(0, (s, st) => s + st.amountMinor);
    final receivedMinor = receivedByStream.values.fold(0, (s, v) => s + v);
    final pendingMinor = (expectedMinor - receivedMinor).clamp(0, expectedMinor);

    // YTD: sum all periods this year
    final year = int.parse(period.split('-')[0]);
    int ytdMinor = 0;
    for (int m = 1; m <= 12; m++) {
      final p = '$year-${m.toString().padLeft(2, '0')}';
      final r = await _ledgerRepo.getEntriesByPeriod(p);
      r.fold((_) => null, (e) {
        for (final entry in e) {
          for (final line in entry.lines) {
            if (streamAccountIds.containsKey(line.accountId) &&
                line.side == JournalSide.credit) {
              ytdMinor += line.amountMinor;
            }
          }
        }
      });
    }

    // Sparkline + history for selected stream
    List<StreamActivity> sparkline = [];
    List<JournalEntry> paymentHistory = [];
    final resolvedStreamId = selectedStreamId ?? (streams.isNotEmpty ? streams.first.id : null);
    if (resolvedStreamId != null) {
      final stream = streams.cast<IncomeStream?>()
          .firstWhere((s) => s?.id == resolvedStreamId, orElse: () => null);
      if (stream != null) {
        sparkline = await _buildSparkline(stream, period);
        paymentHistory = await _buildHistory(stream);
      }
    }

    emit(IncomeState.loaded(
      streams: streams,
      selectedPeriod: period,
      stats: IncomeStats(
        expectedMinor: expectedMinor,
        receivedMinor: receivedMinor,
        pendingMinor: pendingMinor,
        ytdMinor: ytdMinor,
      ),
      receivedByStream: receivedByStream,
      incomeAccounts: incomeAccounts,
      selectedStreamId: resolvedStreamId,
      sparkline: sparkline,
      paymentHistory: paymentHistory,
    ));
  }

  Future<List<StreamActivity>> _buildSparkline(
      IncomeStream stream, String currentPeriod) async {
    final result = <StreamActivity>[];
    for (int i = -5; i <= 0; i++) {
      final p = _offsetPeriod(currentPeriod, i);
      final r = await _ledgerRepo.getEntriesByPeriod(p);
      int received = 0;
      r.fold((_) => null, (entries) {
        for (final entry in entries) {
          for (final line in entry.lines) {
            if (line.accountId == stream.accountId &&
                line.side == JournalSide.credit) {
              received += line.amountMinor;
            }
          }
        }
      });
      result.add(StreamActivity(period: p, receivedMinor: received));
    }
    return result;
  }

  Future<List<JournalEntry>> _buildHistory(IncomeStream stream) async {
    final r = await _ledgerRepo.getEntriesByAccount(stream.accountId);
    return r.fold((_) => [], (e) => e.take(20).toList());
  }
}
