import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import 'package:keel/features/contacts/data/datasources/contact_local_datasource.dart';
import 'package:keel/features/contacts/domain/entities/contact.dart';
import 'package:keel/features/contacts/domain/repositories/contact_repository.dart';

class ContactRepositoryImpl implements ContactRepository {
  final ContactLocalDatasource _datasource;
  ContactRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, List<Contact>>> getContacts() async {
    try {
      final rows = await _datasource.getContacts();
      return Right(rows.map(_rowToContact).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Contact>> createContact(Contact contact) async {
    try {
      await _datasource.insertContact(_contactToRow(contact));
      return Right(contact);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Contact>> updateContact(Contact contact) async {
    try {
      await _datasource.updateContact(_contactToRow(contact));
      return Right(contact);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteContact(String id) async {
    try {
      await _datasource.deleteContact(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> tagEntry(
      String contactId, String journalEntryId) async {
    try {
      await _datasource.tagEntry(contactId, journalEntryId);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> untagEntry(String journalEntryId) async {
    try {
      await _datasource.untagEntry(journalEntryId);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> getContactIdForEntry(
      String journalEntryId) async {
    try {
      return Right(await _datasource.getContactIdForEntry(journalEntryId));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getEntryIdsForContact(
      String contactId) async {
    try {
      return Right(await _datasource.getEntryIdsForContact(contactId));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  Map<String, dynamic> _contactToRow(Contact c) => {
        'id': c.id,
        'name': c.name,
        'phone': c.phone,
        'email': c.email,
        'notes': c.notes,
        'relationship': c.relationship.name,
        'created_at': c.createdAt.toIso8601String(),
      };

  Contact _rowToContact(Map<String, dynamic> r) => Contact(
        id: r['id'] as String,
        name: r['name'] as String,
        phone: r['phone'] as String?,
        email: r['email'] as String?,
        notes: r['notes'] as String?,
        relationship: ContactRelationship.values.byName(
            r['relationship'] as String? ?? 'other'),
        createdAt: DateTime.parse(r['created_at'] as String),
      );
}
