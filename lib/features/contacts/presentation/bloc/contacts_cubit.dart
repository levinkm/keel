import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/accounts/domain/repositories/accounts_repository.dart';
import 'package:keel/features/contacts/domain/entities/contact.dart';
import 'package:keel/features/contacts/domain/repositories/contact_repository.dart';
import 'package:keel/features/ledger/domain/entities/journal_entry.dart';
import 'package:keel/features/ledger/domain/repositories/ledger_repository.dart';
part 'contacts_state.dart';
part 'contacts_cubit.freezed.dart';

class ContactsCubit extends Cubit<ContactsState> {
  final ContactRepository _repo;
  final LedgerRepository _ledgerRepo;
  final AccountsRepository _accountsRepo;

  ContactsCubit(this._repo, this._ledgerRepo, this._accountsRepo)
      : super(const ContactsState.initial());

  Future<void> load() async {
    emit(const ContactsState.loading());
    await _reload();
  }

  Future<void> selectContact(String? contactId) async {
    final current = state;
    if (current is! _Loaded) return;
    if (contactId == null) {
      emit(current.copyWith(selectedContactId: null, selectedEntries: []));
      return;
    }
    final entries = await _loadEntriesForContact(contactId);
    emit(current.copyWith(
        selectedContactId: contactId, selectedEntries: entries));
  }

  Future<void> createContact(Contact contact) async {
    final result = await _repo.createContact(contact);
    result.fold(
      (f) => _emitError(f.message),
      (_) async => await _reload(selectedContactId: contact.id),
    );
  }

  Future<void> updateContact(Contact contact) async {
    final result = await _repo.updateContact(contact);
    result.fold(
      (f) => _emitError(f.message),
      (_) async => await _reload(selectedContactId: contact.id),
    );
  }

  Future<void> deleteContact(String contactId) async {
    final result = await _repo.deleteContact(contactId);
    result.fold(
      (f) => _emitError(f.message),
      (_) async => await _reload(),
    );
  }

  /// Tag a journal entry to this contact (also updates the entry's contact_id)
  Future<void> tagEntry(String contactId, String journalEntryId) async {
    await _repo.tagEntry(contactId, journalEntryId);
    await _reload(selectedContactId: contactId);
  }

  Future<void> untagEntry(String journalEntryId) async {
    final current = state;
    if (current is! _Loaded) return;
    await _repo.untagEntry(journalEntryId);
    await _reload(selectedContactId: current.selectedContactId);
  }

  void clearValidationError() {
    final current = state;
    if (current is! _Loaded) return;
    emit(current.copyWith(validationError: null));
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _emitError(String message) {
    final current = state;
    if (current is _Loaded) {
      emit(current.copyWith(validationError: message));
    } else {
      emit(ContactsState.error(message));
    }
  }

  Future<List<JournalEntry>> _loadEntriesForContact(String contactId) async {
    final idsResult = await _repo.getEntryIdsForContact(contactId);
    final ids = idsResult.fold((_) => <String>[], (ids) => ids);
    if (ids.isEmpty) return [];

    final entries = <JournalEntry>[];
    for (final id in ids) {
      final result = await _ledgerRepo.getEntryById(id);
      result.fold((_) => null, (e) { if (e != null) entries.add(e); });
    }
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  Future<ContactSummary> _computeSummary(
      String contactId, List<JournalEntry> entries) async {
    final accountsResult = await _accountsRepo.getAccounts();
    final accounts = accountsResult.fold((_) => <Account>[], (a) => a);
    final expenseIds =
        accounts.where((a) => a.type == AccountType.expense).map((a) => a.id).toSet();
    final incomeIds =
        accounts.where((a) => a.type == AccountType.income).map((a) => a.id).toSet();

    int paidOut = 0;
    int received = 0;
    DateTime? lastActivity;

    for (final entry in entries) {
      if (lastActivity == null || entry.date.isAfter(lastActivity)) {
        lastActivity = entry.date;
      }
      for (final line in entry.lines) {
        // Money paid out: debits to expense accounts
        if (line.side == JournalSide.debit &&
            expenseIds.contains(line.accountId)) {
          paidOut += line.amountMinor;
        }
        // Money received: credits to income accounts
        if (line.side == JournalSide.credit &&
            incomeIds.contains(line.accountId)) {
          received += line.amountMinor;
        }
      }
    }

    return ContactSummary(
      contactId: contactId,
      totalPaidOutMinor: paidOut,
      totalReceivedMinor: received,
      entryCount: entries.length,
      lastActivityDate: lastActivity,
    );
  }

  Future<void> _reload({String? selectedContactId}) async {
    final contactsResult = await _repo.getContacts();
    final contacts = contactsResult.fold((_) => <Contact>[], (c) => c);

    final summaries = <String, ContactSummary>{};
    for (final contact in contacts) {
      final entries = await _loadEntriesForContact(contact.id);
      summaries[contact.id] = await _computeSummary(contact.id, entries);
    }

    final current = state;
    final resolvedId = selectedContactId ??
        (current is _Loaded ? current.selectedContactId : null);

    final selectedEntries = resolvedId != null
        ? await _loadEntriesForContact(resolvedId)
        : <JournalEntry>[];

    emit(ContactsState.loaded(
      contacts: contacts,
      summaries: summaries,
      selectedContactId: resolvedId,
      selectedEntries: selectedEntries,
    ));
  }
}
