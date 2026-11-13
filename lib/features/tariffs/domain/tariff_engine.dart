import 'entities/tariff.dart';

class FeeResult {
  final int feeMinor;
  final int taxMinor;
  int get totalMinor => feeMinor + taxMinor;

  const FeeResult({required this.feeMinor, required this.taxMinor});
  const FeeResult.zero() : feeMinor = 0, taxMinor = 0;
}

class TariffEngine {
  /// Computes the fee for [amountMinor] using [tariff].
  /// Returns [FeeResult.zero] if no matching tier is found.
  static FeeResult compute(Tariff tariff, int amountMinor) {
    if (tariff.tiers.isEmpty || amountMinor <= 0) return const FeeResult.zero();

    TariffTier? matched;
    for (final tier in tariff.tiers) {
      if (tier.upToMinor == null || amountMinor <= tier.upToMinor!) {
        matched = tier;
        break;
      }
    }
    // Fall back to last tier if amount exceeds all explicit upper bounds
    matched ??= tariff.tiers.last;

    final fee = ((amountMinor * matched.feeBp) ~/ 10000) + matched.feeFixed;
    final tax = ((fee * tariff.taxRateBp) ~/ 10000);
    return FeeResult(feeMinor: fee, taxMinor: tax);
  }
}
