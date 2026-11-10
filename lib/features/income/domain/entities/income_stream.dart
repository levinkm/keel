enum IncomeType { salary, business, farming, rent, dividends, interest, sideWork, oneOff }
enum IncomeFrequency { monthly, weekly, irregular, scheduled }

class IncomeStream {
  final String id;
  final String name;
  final IncomeType type;
  final String accountId;
  final IncomeFrequency frequency;
  final int amountMinor;
  final int? reliableAmountMinor;
  final String currency;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  const IncomeStream({
    required this.id,
    required this.name,
    required this.type,
    required this.accountId,
    required this.frequency,
    required this.amountMinor,
    this.reliableAmountMinor,
    required this.currency,
    required this.isActive,
    this.startDate,
    this.endDate,
    required this.createdAt,
  });

  int get effectiveReliableAmount => reliableAmountMinor ?? amountMinor;
}
