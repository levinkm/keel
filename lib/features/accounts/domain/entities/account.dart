enum AccountType { asset, liability, equity, income, expense }
enum Liquidity { instant, days, locked }

class Account {
  final String id;
  final String name;
  final AccountType type;
  final String currency;
  final Liquidity liquidity;
  final bool isActive;
  final DateTime createdAt;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.liquidity,
    required this.isActive,
    required this.createdAt,
  });
}
