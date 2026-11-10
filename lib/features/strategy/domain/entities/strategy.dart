class StrategyBucket {
  final String id;
  final String strategyId;
  final String name;         // e.g. 'Needs', 'Wants', 'Savings'
  final int targetPct;       // 0-100, percentage of income
  final List<String> accountIds;          // linked expense/asset accounts
  final Map<String, int> accountWeights;  // accountId -> weight (0-100, must sum to 100)

  const StrategyBucket({
    required this.id,
    required this.strategyId,
    required this.name,
    required this.targetPct,
    required this.accountIds,
    this.accountWeights = const {},
  });

  /// Returns weights map, filling missing entries with an equal split.
  Map<String, int> resolvedWeights() {
    if (accountIds.isEmpty) return {};
    if (accountIds.length == 1) return {accountIds.first: 100};
    final result = <String, int>{};
    int assigned = 0;
    for (int i = 0; i < accountIds.length; i++) {
      final id = accountIds[i];
      if (i == accountIds.length - 1) {
        result[id] = 100 - assigned; // last gets remainder to avoid rounding drift
      } else {
        final w = accountWeights[id] ?? (100 ~/ accountIds.length);
        result[id] = w;
        assigned += w;
      }
    }
    return result;
  }

  StrategyBucket copyWith({
    String? name,
    int? targetPct,
    List<String>? accountIds,
    Map<String, int>? accountWeights,
  }) =>
      StrategyBucket(
        id: id,
        strategyId: strategyId,
        name: name ?? this.name,
        targetPct: targetPct ?? this.targetPct,
        accountIds: accountIds ?? this.accountIds,
        accountWeights: accountWeights ?? this.accountWeights,
      );
}

class Strategy {
  final String id;
  final String name;
  final String tagline;
  final String description;
  final bool isBuiltin;
  final List<StrategyBucket> buckets;
  final DateTime createdAt;

  const Strategy({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.isBuiltin,
    required this.buckets,
    required this.createdAt,
  });

  int get totalPct => buckets.fold(0, (s, b) => s + b.targetPct);
  bool get isBalanced => totalPct == 100;
}

// ── Built-in strategy definitions ────────────────────────────────────────────

abstract final class BuiltinStrategies {
  static List<Strategy> all = [
    _make('commitments_first', 'Commitments first',
        'Fixed amounts first, then weights', [
      ('Commitments', 50),
      ('Flexible', 30),
      ('Savings', 20),
    ]),
    _make('50_30_20', '50/30/20', 'Needs · Wants · Savings', [
      ('Needs', 50),
      ('Wants', 30),
      ('Savings', 20),
    ]),
    _make('70_20_10', '70/20/10', 'Living · Savings · Debt', [
      ('Living', 70),
      ('Savings', 20),
      ('Debt', 10),
    ]),
    _make('pay_yourself_first', 'Pay yourself first',
        'Save first, spend the rest', [
      ('Savings', 20),
      ('Everything else', 80),
    ]),
    _make('zero_based', 'Zero-based', 'Every shilling gets a job', [
      ('Needs', 50),
      ('Wants', 30),
      ('Savings', 20),
    ]),
    _make('envelope', 'Envelope', 'Monthly amounts with rollover', [
      ('Needs', 50),
      ('Wants', 30),
      ('Savings', 20),
    ]),
    _make('kakeibo', 'Kakeibo', 'Mindful spending', [
      ('Survival', 50),
      ('Optional', 20),
      ('Culture', 15),
      ('Extra', 15),
    ]),
    _make('custom', 'Custom', 'Build your own', [
      ('Bucket 1', 100),
    ]),
  ];

  static Strategy _make(
      String id, String name, String tagline, List<(String, int)> buckets) {
    return Strategy(
      id: id,
      name: name,
      tagline: tagline,
      description: '',
      isBuiltin: true,
      buckets: buckets
          .map((b) => StrategyBucket(
                id: '${id}_${b.$1.toLowerCase().replaceAll(' ', '_')}',
                strategyId: id,
                name: b.$1,
                targetPct: b.$2,
                accountIds: const [],
              ))
          .toList(),
      createdAt: DateTime(2024),
    );
  }

  static Strategy? findById(String id) {
    return all.cast<Strategy?>().firstWhere((s) => s?.id == id, orElse: () => null);
  }
}
