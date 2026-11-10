import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:keel/features/ledger/domain/entities/journal_entry.dart';
import 'package:keel/features/ledger/domain/repositories/ledger_repository.dart';
import 'package:keel/features/ledger/domain/usecases/get_journal_entries_usecase.dart';
import 'package:keel/features/ledger/domain/usecases/post_journal_entry_usecase.dart';

part 'ledger_state.dart';
part 'ledger_cubit.freezed.dart';

class LedgerCubit extends Cubit<LedgerState> {
  final GetJournalEntriesUsecase _getEntries;
  final PostJournalEntryUsecase _postEntry;
  final LedgerRepository _repository;

  String _currentPeriod = _todayPeriod();
  String get currentPeriod => _currentPeriod;

  LedgerCubit(this._getEntries, this._postEntry, this._repository)
      : super(const LedgerState.initial());

  static String _todayPeriod() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  Future<void> loadPeriod([String? period]) async {
    _currentPeriod = period ?? _currentPeriod;
    emit(const LedgerState.loading());
    final result = await _getEntries(_currentPeriod);
    result.fold(
      (f) => emit(LedgerState.error(f.message)),
      (entries) => emit(LedgerState.loaded(entries, _currentPeriod)),
    );
  }

  void selectEntry(JournalEntry? entry) {
    final current = state;
    if (current is! _Loaded) return;
    emit(current.copyWith(selectedEntry: entry));
  }

  Future<void> postEntry(JournalEntry entry) async {
    final result = await _postEntry(entry);
    result.fold(
      (f) => emit(LedgerState.error(f.message)),
      (_) => loadPeriod(),
    );
  }

  Future<void> updateEntryMeta(JournalEntry updated) async {
    final result = await _repository.updateEntryMeta(updated);
    result.fold(
      (f) {
        final current = state;
        if (current is _Loaded) {
          emit(current.copyWith(validationError: f.message));
        }
      },
      (_) async {
        await _reloadKeepingSelection(updated.id);
      },
    );
  }

  Future<void> addTransactionCost({
    required String entryId,
    required String feeAccountId,
    required String paidFromAccountId,
    required int amountMinor,
    required String currency,
    required String memo,
  }) async {
    final result = await _repository.addTransactionCost(
      entryId: entryId,
      feeAccountId: feeAccountId,
      paidFromAccountId: paidFromAccountId,
      amountMinor: amountMinor,
      currency: currency,
      memo: memo,
    );
    result.fold(
      (f) {
        final current = state;
        if (current is _Loaded) emit(current.copyWith(validationError: f.message));
      },
      (_) async => await _reloadKeepingSelection(entryId),
    );
  }

  Future<void> addAttachment({
    required String entryId,
    required String filePath,
    required String fileName,
    String? mimeType,
  }) async {
    final result = await _repository.addAttachment(
      entryId: entryId,
      filePath: filePath,
      fileName: fileName,
      mimeType: mimeType,
    );
    result.fold(
      (f) {
        final current = state;
        if (current is _Loaded) emit(current.copyWith(validationError: f.message));
      },
      (_) async => await _reloadKeepingSelection(entryId),
    );
  }

  Future<void> removeAttachment(String attachmentId, String entryId) async {
    final result = await _repository.removeAttachment(attachmentId);
    result.fold(
      (f) {
        final current = state;
        if (current is _Loaded) emit(current.copyWith(validationError: f.message));
      },
      (_) async => await _reloadKeepingSelection(entryId),
    );
  }

  Future<void> reverseEntry(String entryId, String reason) async {
    final result = await _repository.reverseEntry(entryId, reason);
    result.fold(
      (f) => emit(LedgerState.error(f.message)),
      (_) => loadPeriod(),
    );
  }

  void clearValidationError() {
    final current = state;
    if (current is! _Loaded) return;
    emit(current.copyWith(validationError: null));
  }

  void previousPeriod() {
    final parts = _currentPeriod.split('-');
    var year = int.parse(parts[0]);
    var month = int.parse(parts[1]) - 1;
    if (month == 0) { month = 12; year--; }
    loadPeriod('$year-${month.toString().padLeft(2, '0')}');
  }

  void nextPeriod() {
    final parts = _currentPeriod.split('-');
    var year = int.parse(parts[0]);
    var month = int.parse(parts[1]) + 1;
    if (month == 13) { month = 1; year++; }
    loadPeriod('$year-${month.toString().padLeft(2, '0')}');
  }

  Future<void> _reloadKeepingSelection(String entryId) async {
    final result = await _getEntries(_currentPeriod);
    result.fold(
      (f) => emit(LedgerState.error(f.message)),
      (entries) {
        final updated = entries.cast<JournalEntry?>()
            .firstWhere((e) => e?.id == entryId, orElse: () => null);
        emit(LedgerState.loaded(entries, _currentPeriod,
            selectedEntry: updated));
      },
    );
  }
}
