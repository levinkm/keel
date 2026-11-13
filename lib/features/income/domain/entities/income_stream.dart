enum IncomeType { salary, business, farming, rent, dividends, interest, sideWork, oneOff }

/// Unit for a custom recurrence interval.
enum FrequencyUnit { day, week, month }

/// Payment mode: regular recurring vs milestone/deposit-based.
enum PaymentMode { regular, milestone }

/// Replaces the old IncomeFrequency enum.
/// [interval] = how many [unit]s between payments.
/// e.g. every 2 months → FrequencyUnit.month, interval 2
///      every 2 weeks  → FrequencyUnit.week,  interval 2
///      irregular      → FrequencyUnit.month, interval 0 (special sentinel)
class IncomeFrequency {
  final FrequencyUnit unit;
  final int interval; // 0 = irregular

  const IncomeFrequency({required this.unit, required this.interval});

  // Named constructors for common cases
  const IncomeFrequency.monthly()  : unit = FrequencyUnit.month, interval = 1;
  const IncomeFrequency.weekly()   : unit = FrequencyUnit.week,  interval = 1;
  const IncomeFrequency.irregular(): unit = FrequencyUnit.month, interval = 0;

  bool get isIrregular => interval == 0;

  String get label {
    if (isIrregular) return 'Irregular';
    if (unit == FrequencyUnit.month && interval == 1) return 'Monthly';
    if (unit == FrequencyUnit.week  && interval == 1) return 'Weekly';
    if (unit == FrequencyUnit.day   && interval == 1) return 'Daily';
    final unitLabel = switch (unit) {
      FrequencyUnit.day   => interval == 1 ? 'day'   : 'days',
      FrequencyUnit.week  => interval == 1 ? 'week'  : 'weeks',
      FrequencyUnit.month => interval == 1 ? 'month' : 'months',
    };
    return 'Every $interval $unitLabel';
  }

  @override
  bool operator ==(Object other) =>
      other is IncomeFrequency && other.unit == unit && other.interval == interval;

  @override
  int get hashCode => Object.hash(unit, interval);
}

class IncomeStream {
  final String id;
  final String name;
  final IncomeType type;
  final String accountId;
  final IncomeFrequency frequency;
  final PaymentMode paymentMode;
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
    this.paymentMode = PaymentMode.regular,
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
