enum ContactRelationship {
  family,
  friend,
  colleague,
  client,
  supplier,
  lender,
  borrower,
  other,
}

extension ContactRelationshipLabel on ContactRelationship {
  String get label => switch (this) {
        ContactRelationship.family => 'Family',
        ContactRelationship.friend => 'Friend',
        ContactRelationship.colleague => 'Colleague',
        ContactRelationship.client => 'Client',
        ContactRelationship.supplier => 'Supplier',
        ContactRelationship.lender => 'Lender',
        ContactRelationship.borrower => 'Borrower',
        ContactRelationship.other => 'Other',
      };
}

class Contact {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? notes;
  final ContactRelationship relationship;
  final DateTime createdAt;

  const Contact({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.notes,
    required this.relationship,
    required this.createdAt,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

/// Computed from journal entries tagged to this contact
class ContactSummary {
  final String contactId;
  final int totalPaidOutMinor;   // debits on expense/asset accounts
  final int totalReceivedMinor;  // credits on income/asset accounts (money in)
  final int entryCount;
  final DateTime? lastActivityDate;

  const ContactSummary({
    required this.contactId,
    required this.totalPaidOutMinor,
    required this.totalReceivedMinor,
    required this.entryCount,
    this.lastActivityDate,
  });

  int get netMinor => totalReceivedMinor - totalPaidOutMinor;
  bool get isOwed => netMinor < 0;   // we are owed money (paid more than received)
  bool get owes => netMinor > 0;     // contact owes us nothing, we received more
}
