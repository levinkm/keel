import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import '../entities/contact.dart';

abstract class ContactRepository {
  Future<Either<Failure, List<Contact>>> getContacts();
  Future<Either<Failure, Contact>> createContact(Contact contact);
  Future<Either<Failure, Contact>> updateContact(Contact contact);
  Future<Either<Failure, void>> deleteContact(String id);

  // Tag a journal entry to a contact
  Future<Either<Failure, void>> tagEntry(String contactId, String journalEntryId);
  Future<Either<Failure, void>> untagEntry(String journalEntryId);
  Future<Either<Failure, String?>> getContactIdForEntry(String journalEntryId);
  Future<Either<Failure, List<String>>> getEntryIdsForContact(String contactId);
}
