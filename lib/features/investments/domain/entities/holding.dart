import 'dart:math';

enum HoldingType {
  bankSavings, moneyMarket, fixedDeposit, treasuryBill,
  sacco, unitTrust, stock, etf, pension
}

enum LotType { purchase, redemption, reinvestment, income }

enum CompoundingFreq { none, daily, monthly, quarterly, annually }

extension CompoundingFreqLabel on CompoundingFreq {
  String get label => switch (this) {
        CompoundingFreq.none => 'Simple (no compounding)',
        CompoundingFreq.daily => 'Daily',
        CompoundingFreq.monthly => 'Monthly',
        CompoundingFreq.quarterly => 'Quarterly',
        CompoundingFreq.annually => 'Annually',
      };
  int get periodsPerYear => switch (this) {
        CompoundingFreq.none => 1,
        CompoundingFreq.daily => 365,
        CompoundingFreq.monthly => 12,
        CompoundingFreq.quarterly => 4,
        CompoundingFreq.annually => 1,
      };
}

extension HoldingTypeLabel on HoldingType {
  String get label => switch (this) {
        HoldingType.bankSavings => 'Bank Savings',
        HoldingType.moneyMarket => 'Money Market',
        HoldingType.fixedDeposit => 'Fixed Deposit',
        HoldingType.treasuryBill => 'Treasury Bill',
        HoldingType.sacco => 'SACCO',
        HoldingType.unitTrust => 'Unit Trust',
        HoldingType.stock => 'Stock',
        HoldingType.etf => 'ETF',
        HoldingType.pension => 'Pension',
      };

  bool get hasUnits => switch (this) {
        HoldingType.stock || HoldingType.etf || HoldingType.unitTrust => true,
        _ => false,
      };
}

extension LotTypeLabel on LotType {
  String get label => switch (this) {
        LotType.purchase => 'Purchase',
        LotType.redemption => 'Redemption',
        LotType.reinvestment => 'Reinvestment',
        LotType.income => 'Income',
      };
}

class HoldingLot {
  final String id;
  final String holdingId;
  final DateTime date;
  final double units;   // negative for redemptions
  final int priceMinor;
  final int feesMinor;
  final String currency;
  final LotType lotType;

  const HoldingLot({
    required this.id,
    required this.holdingId,
    required this.date,
    required this.units,
    required this.priceMinor,
    required this.feesMinor,
    required this.currency,
    this.lotType = LotType.purchase,
  });

  /// Gross amount (units × price). Positive for purchases/income, negative for redemptions.
  int get grossMinor => (units.abs() * priceMinor).round();

  /// Cost basis for purchase/reinvestment lots only.
  int get costBasisMinor {
    if (lotType == LotType.purchase || lotType == LotType.reinvestment) {
      return grossMinor + feesMinor;
    }
    return 0;
  }

  /// Proceeds for redemption lots (after fees).
  int get proceedsMinor {
    if (lotType == LotType.redemption) return grossMinor - feesMinor;
    return 0;
  }

  /// Income amount for income lots.
  int get incomeMinor {
    if (lotType == LotType.income) return grossMinor;
    return 0;
  }
}

class Holding {
  final String id;
  final String name;
  final HoldingType type;
  final String institution;
  final String accountId;
  final String currency;
  final String liquidity;
  final bool isActive;
  final int? currentPriceMinor;
  final String? linkedAssetId;
  final int? annualRateBp;          // e.g. 1200 = 12.00%
  final CompoundingFreq compoundingFreq;
  final DateTime? maturityDate;
  final List<HoldingLot> lots;
  final DateTime createdAt;

  const Holding({
    required this.id,
    required this.name,
    required this.type,
    required this.institution,
    required this.accountId,
    required this.currency,
    required this.liquidity,
    required this.isActive,
    this.currentPriceMinor,
    this.linkedAssetId,
    this.annualRateBp,
    this.compoundingFreq = CompoundingFreq.none,
    this.maturityDate,
    required this.lots,
    required this.createdAt,
  });

  // ── Cost & units (purchases + reinvestments only) ─────────────────────────

  int get totalCostBasisMinor => lots
      .where((l) => l.lotType == LotType.purchase || l.lotType == LotType.reinvestment)
      .fold(0, (s, l) => s + l.costBasisMinor);

  double get totalUnits => lots.fold(0.0, (s, l) {
        if (l.lotType == LotType.purchase || l.lotType == LotType.reinvestment) {
          return s + l.units;
        }
        if (l.lotType == LotType.redemption) return s - l.units.abs();
        return s;
      });

  // ── Market value & unrealised gain ────────────────────────────────────────

  int get marketValueMinor {
    if (currentPriceMinor != null && currentPriceMinor! > 0) {
      return (totalUnits * currentPriceMinor!).round();
    }
    return totalCostBasisMinor;
  }

  int get unrealisedGainMinor => marketValueMinor - totalCostBasisMinor;

  double get unrealisedGainPct {
    if (totalCostBasisMinor == 0) return 0;
    return unrealisedGainMinor / totalCostBasisMinor * 100;
  }

  // ── Realised gain (FIFO) ──────────────────────────────────────────────────

  /// Computes realised gain using FIFO cost matching.
  int get realisedGainMinor {
    // Build FIFO queue of purchase lots
    final queue = lots
        .where((l) => l.lotType == LotType.purchase || l.lotType == LotType.reinvestment)
        .map((l) => _FifoLot(units: l.units, costPerUnit: l.priceMinor.toDouble()))
        .toList();

    int totalRealised = 0;

    for (final lot in lots.where((l) => l.lotType == LotType.redemption)) {
      double unitsToMatch = lot.units.abs();
      final proceeds = lot.proceedsMinor;
      double costMatched = 0;

      for (final fifo in queue) {
        if (unitsToMatch <= 0) break;
        final consumed = unitsToMatch < fifo.remaining ? unitsToMatch : fifo.remaining;
        costMatched += consumed * fifo.costPerUnit;
        fifo.remaining -= consumed;
        unitsToMatch -= consumed;
      }

      // proceeds - cost = realised gain (negative = loss)
      final costMatchedMinor = costMatched.round();
      totalRealised += proceeds - costMatchedMinor;
    }

    return totalRealised;
  }

  // ── Income ────────────────────────────────────────────────────────────────

  int get totalIncomeMinor =>
      lots.where((l) => l.lotType == LotType.income)
          .fold(0, (s, l) => s + l.incomeMinor);

  int get totalRedeemedMinor =>
      lots.where((l) => l.lotType == LotType.redemption)
          .fold(0, (s, l) => s + l.proceedsMinor);

  // ── Interest projection ───────────────────────────────────────────────────

  bool get hasInterestRate => annualRateBp != null && annualRateBp! > 0;

  /// Annual rate as a decimal (e.g. 0.12 for 12%)
  double get annualRate => (annualRateBp ?? 0) / 10000;

  /// Days since first purchase lot
  int get daysHeld {
    final purchases = lots.where((l) =>
        l.lotType == LotType.purchase || l.lotType == LotType.reinvestment);
    if (purchases.isEmpty) return 0;
    final first = purchases.map((l) => l.date).reduce((a, b) => a.isBefore(b) ? a : b);
    return DateTime.now().difference(first).inDays.clamp(0, 99999);
  }

  /// Days remaining to maturity (null if no maturity date)
  int? get daysToMaturity {
    if (maturityDate == null) return null;
    return maturityDate!.difference(DateTime.now()).inDays;
  }

  /// Total days from first purchase to maturity
  int? get totalTermDays {
    if (maturityDate == null) return null;
    final purchases = lots.where((l) =>
        l.lotType == LotType.purchase || l.lotType == LotType.reinvestment);
    if (purchases.isEmpty) return null;
    final first = purchases.map((l) => l.date).reduce((a, b) => a.isBefore(b) ? a : b);
    return maturityDate!.difference(first).inDays;
  }

  /// Expected interest accrued so far
  int get accruedInterestMinor {
    if (!hasInterestRate || totalCostBasisMinor == 0) return 0;
    return _calcInterest(totalCostBasisMinor, annualRate,
        compoundingFreq, daysHeld);
  }

  /// Expected total interest at maturity
  int? get expectedInterestAtMaturityMinor {
    if (!hasInterestRate || maturityDate == null || totalCostBasisMinor == 0) return null;
    final term = totalTermDays ?? 0;
    if (term <= 0) return null;
    return _calcInterest(totalCostBasisMinor, annualRate, compoundingFreq, term);
  }

  /// Projected value at maturity (principal + interest)
  int? get projectedMaturityValueMinor {
    final interest = expectedInterestAtMaturityMinor;
    if (interest == null) return null;
    return totalCostBasisMinor + interest;
  }

  /// Daily interest accrual
  int get dailyInterestMinor {
    if (!hasInterestRate || totalCostBasisMinor == 0) return 0;
    return (totalCostBasisMinor * annualRate / 365).round();
  }

  /// Annualised return based on actual price movement (for unit-based holdings)
  double? get annualisedReturnPct {
    if (!type.hasUnits || daysHeld == 0 || totalCostBasisMinor == 0) return null;
    final totalReturn = marketValueMinor / totalCostBasisMinor - 1;
    return totalReturn * (365 / daysHeld) * 100;
  }

  static int _calcInterest(
      int principalMinor, double rate, CompoundingFreq freq, int days) {
    if (freq == CompoundingFreq.none) {
      // Simple interest: I = P × r × t
      return (principalMinor * rate * days / 365).round();
    }
    // Compound interest: A = P(1 + r/n)^(n×t) - P
    final n = freq.periodsPerYear;
    final t = days / 365;
    final amount = principalMinor * (pow(1 + rate / n, n * t) - 1);
    return amount.round();
  }

  // ── copyWith ──────────────────────────────────────────────────────────────

  Holding copyWith({
    String? id,
    String? name,
    HoldingType? type,
    String? institution,
    String? accountId,
    String? currency,
    String? liquidity,
    bool? isActive,
    int? currentPriceMinor,
    String? linkedAssetId,
    int? annualRateBp,
    CompoundingFreq? compoundingFreq,
    DateTime? maturityDate,
    List<HoldingLot>? lots,
    DateTime? createdAt,
  }) => Holding(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        institution: institution ?? this.institution,
        accountId: accountId ?? this.accountId,
        currency: currency ?? this.currency,
        liquidity: liquidity ?? this.liquidity,
        isActive: isActive ?? this.isActive,
        currentPriceMinor: currentPriceMinor ?? this.currentPriceMinor,
        linkedAssetId: linkedAssetId ?? this.linkedAssetId,
        annualRateBp: annualRateBp ?? this.annualRateBp,
        compoundingFreq: compoundingFreq ?? this.compoundingFreq,
        maturityDate: maturityDate ?? this.maturityDate,
        lots: lots ?? this.lots,
        createdAt: createdAt ?? this.createdAt,
      );
}

class _FifoLot {
  double remaining;
  final double costPerUnit;
  _FifoLot({required double units, required this.costPerUnit}) : remaining = units;
}
