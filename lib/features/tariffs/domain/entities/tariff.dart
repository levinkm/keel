import 'dart:convert';

enum TariffOperation { withdrawal, transfer, deposit }

/// A single tier in a tariff schedule.
/// [upToMinor] — upper bound of this tier (inclusive), in minor units.
///               null means "any amount above the previous tier".
/// [feeBp]     — fee as basis points of the transaction amount (0 = none).
/// [feeFixed]  — flat fee in minor units added on top of the % fee.
class TariffTier {
  final int? upToMinor;
  final int feeBp;
  final int feeFixed;

  const TariffTier({
    this.upToMinor,
    required this.feeBp,
    required this.feeFixed,
  });

  Map<String, dynamic> toJson() => {
        'upToMinor': upToMinor,
        'feeBp': feeBp,
        'feeFixed': feeFixed,
      };

  factory TariffTier.fromJson(Map<String, dynamic> j) => TariffTier(
        upToMinor: j['upToMinor'] as int?,
        feeBp: j['feeBp'] as int? ?? 0,
        feeFixed: j['feeFixed'] as int? ?? 0,
      );
}

class Tariff {
  final String id;
  final String provider;   // e.g. "M-Pesa", "KCB"
  final String accountId;  // the account this tariff applies to
  final TariffOperation operation;
  final List<TariffTier> tiers;
  final int taxRateBp;     // tax on the fee itself (e.g. excise duty)
  final String? feeAccountId; // expense account to post fee to (optional)
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;

  const Tariff({
    required this.id,
    required this.provider,
    required this.accountId,
    required this.operation,
    required this.tiers,
    required this.taxRateBp,
    this.feeAccountId,
    required this.effectiveFrom,
    this.effectiveTo,
  });

  static List<TariffTier> tiersFromJson(String raw) {
    final list = jsonDecode(raw) as List;
    return list.map((e) => TariffTier.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String tiersToJson(List<TariffTier> tiers) =>
      jsonEncode(tiers.map((t) => t.toJson()).toList());
}
