enum JournalSide { debit, credit }

class JournalLine {
  final String id;
  final String entryId;
  final String accountId;
  final int amountMinor;
  final String currency;
  final JournalSide side;
  final String? memo; // per-line note e.g. 'M-Pesa fee'

  const JournalLine({
    required this.id,
    required this.entryId,
    required this.accountId,
    required this.amountMinor,
    required this.currency,
    required this.side,
    this.memo,
  });
}

class EntryAttachment {
  final String id;
  final String entryId;
  final String filePath;
  final String fileName;
  final String? mimeType;
  final DateTime createdAt;

  const EntryAttachment({
    required this.id,
    required this.entryId,
    required this.filePath,
    required this.fileName,
    this.mimeType,
    required this.createdAt,
  });
}

class JournalEntry {
  final String id;
  final DateTime date;
  final String description;
  final String? reference;
  final String? payee;      // who was paid / who paid
  final String? notes;      // free-form notes
  final String? location;   // where the transaction happened
  final String? contactId;  // linked contact
  final String period;
  final bool isLocked;
  final List<JournalLine> lines;
  final List<EntryAttachment> attachments;
  final DateTime createdAt;
  final List<String> tags; // free-text sub-labels e.g. ['tyres', 'wiring']

  const JournalEntry({
    required this.id,
    required this.date,
    required this.description,
    this.reference,
    this.payee,
    this.notes,
    this.location,
    this.contactId,
    required this.period,
    required this.isLocked,
    required this.lines,
    this.attachments = const [],
    required this.createdAt,
    this.tags = const [],
  });

  bool get isBalanced {
    final debits = lines
        .where((l) => l.side == JournalSide.debit)
        .fold(0, (sum, l) => sum + l.amountMinor);
    final credits = lines
        .where((l) => l.side == JournalSide.credit)
        .fold(0, (sum, l) => sum + l.amountMinor);
    return debits == credits;
  }
}
