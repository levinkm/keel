part of 'contacts_cubit.dart';

@freezed
abstract class ContactsState with _$ContactsState {
  const factory ContactsState.initial() = _Initial;
  const factory ContactsState.loading() = _Loading;
  const factory ContactsState.loaded({
    required List<Contact> contacts,
    required Map<String, ContactSummary> summaries,
    String? selectedContactId,
    required List<JournalEntry> selectedEntries,
    String? validationError,
  }) = _Loaded;
  const factory ContactsState.error(String message) = _Error;
}
