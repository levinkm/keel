enum AssetClass { cashAndBank, investments, vehicle, machinery, land, building, receivable, other }
enum DepreciationMethod { straightLine, reducingBalance }
enum ValuationPolicy { costModel, fairValue }
enum AssetStatus { inUse, sold, writtenOff }

class AssetAttachment {
  final String id;
  final String assetId;
  final String filePath;
  final String fileName;
  final String? mimeType;
  final DateTime createdAt;

  const AssetAttachment({
    required this.id,
    required this.assetId,
    required this.filePath,
    required this.fileName,
    this.mimeType,
    required this.createdAt,
  });
}

class Asset {
  final String id;
  final String name;
  final AssetClass assetClass;
  final DateTime acquisitionDate;
  final int costMinor;
  final String currency;
  final int ownershipShareBp; // 10000 = 100%
  final int? currentValueMinor;
  final DateTime? valuationDate;
  final String? valuationSource;
  final DepreciationMethod? depreciationMethod;
  final int? annualRateBp;
  final int salvageMinor;
  final String? linkedLoanId;
  final DateTime? insuranceExpiry;
  final AssetStatus status;
  final String? location;
  final String? notes;
  final String? holdingId;       // linked Holding (investments asset class)
  final DateTime createdAt;

  const Asset({
    required this.id,
    required this.name,
    required this.assetClass,
    required this.acquisitionDate,
    required this.costMinor,
    required this.currency,
    required this.ownershipShareBp,
    this.currentValueMinor,
    this.valuationDate,
    this.valuationSource,
    this.depreciationMethod,
    this.annualRateBp,
    required this.salvageMinor,
    this.linkedLoanId,
    this.insuranceExpiry,
    required this.status,
    this.location,
    this.notes,
    this.holdingId,
    required this.createdAt,
  });

  int get bookValue => currentValueMinor ?? costMinor;

  Asset copyWith({
    String? id,
    String? name,
    AssetClass? assetClass,
    DateTime? acquisitionDate,
    int? costMinor,
    String? currency,
    int? ownershipShareBp,
    int? currentValueMinor,
    DateTime? valuationDate,
    String? valuationSource,
    DepreciationMethod? depreciationMethod,
    int? annualRateBp,
    int? salvageMinor,
    String? linkedLoanId,
    DateTime? insuranceExpiry,
    AssetStatus? status,
    String? location,
    String? notes,
    String? holdingId,
    DateTime? createdAt,
  }) => Asset(
        id: id ?? this.id,
        name: name ?? this.name,
        assetClass: assetClass ?? this.assetClass,
        acquisitionDate: acquisitionDate ?? this.acquisitionDate,
        costMinor: costMinor ?? this.costMinor,
        currency: currency ?? this.currency,
        ownershipShareBp: ownershipShareBp ?? this.ownershipShareBp,
        currentValueMinor: currentValueMinor ?? this.currentValueMinor,
        valuationDate: valuationDate ?? this.valuationDate,
        valuationSource: valuationSource ?? this.valuationSource,
        depreciationMethod: depreciationMethod ?? this.depreciationMethod,
        annualRateBp: annualRateBp ?? this.annualRateBp,
        salvageMinor: salvageMinor ?? this.salvageMinor,
        linkedLoanId: linkedLoanId ?? this.linkedLoanId,
        insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
        status: status ?? this.status,
        location: location ?? this.location,
        notes: notes ?? this.notes,
        holdingId: holdingId ?? this.holdingId,
        createdAt: createdAt ?? this.createdAt,
      );
}
