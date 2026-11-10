class NetWorth {
  final int totalMinor;
  final int liquidMinor;
  final String currency;
  final DateTime asOf;

  const NetWorth({
    required this.totalMinor,
    required this.liquidMinor,
    required this.currency,
    required this.asOf,
  });

  int get illiquidMinor => totalMinor - liquidMinor;
}
