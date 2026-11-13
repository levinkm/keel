import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/tariffs/domain/entities/tariff.dart';
import 'package:uuid/uuid.dart';

class TariffCsvImportResult {
  final List<Tariff> tariffs;
  final List<String> errors;
  final int rowsRead;

  const TariffCsvImportResult({
    required this.tariffs,
    required this.errors,
    required this.rowsRead,
  });

  bool get hasErrors => errors.isNotEmpty;
}

/// CSV format (header row required):
///
///   provider, account_name, operation, from, to, fee_fixed, fee_pct, tax_pct
///
/// Columns:
///   provider     — string, e.g. "M-Pesa"
///   account_name — must match an existing account name (case-insensitive)
///   operation    — withdrawal | transfer | deposit
///   from         — lower bound of tier in major units (KES), informational only
///   to           — upper bound of tier in major units (KES); blank = catch-all
///   fee_fixed    — flat fee in major units (KES), e.g. 29
///   fee_pct      — percentage fee, e.g. 1.5 means 1.5% (usually 0 for fixed tariffs)
///   tax_pct      — tax on the fee itself, e.g. 16 for 16% excise (optional, default 0)
///
/// Rows with the same provider + account_name + operation are grouped into
/// tiers in the order they appear. The catch-all tier (blank "to") must be last.
///
/// Example (M-Pesa withdrawal):
///   provider,account_name,operation,from,to,fee_fixed,fee_pct,tax_pct
///   M-Pesa,M-Pesa,withdrawal,50,100,11,0,0
///   M-Pesa,M-Pesa,withdrawal,101,500,29,0,0
///   M-Pesa,M-Pesa,withdrawal,501,1000,29,0,0
///   M-Pesa,M-Pesa,withdrawal,1001,,309,0,0
class TariffCsvImporter {
  static const String templateHeader =
      'provider,account_name,operation,from,to,fee_fixed,fee_pct,tax_pct';

  static const String templateExample = '''provider,account_name,operation,from,to,fee_fixed,fee_pct,tax_pct
M-Pesa,M-Pesa,withdrawal,50,100,11,0,0
M-Pesa,M-Pesa,withdrawal,101,500,29,0,0
M-Pesa,M-Pesa,withdrawal,501,1000,29,0,0
M-Pesa,M-Pesa,withdrawal,1001,1500,29,0,0
M-Pesa,M-Pesa,withdrawal,1501,2500,29,0,0
M-Pesa,M-Pesa,withdrawal,2501,3500,52,0,0
M-Pesa,M-Pesa,withdrawal,3501,5000,69,0,0
M-Pesa,M-Pesa,withdrawal,5001,7500,87,0,0
M-Pesa,M-Pesa,withdrawal,7501,10000,115,0,0
M-Pesa,M-Pesa,withdrawal,10001,15000,167,0,0
M-Pesa,M-Pesa,withdrawal,15001,20000,185,0,0
M-Pesa,M-Pesa,withdrawal,20001,35000,197,0,0
M-Pesa,M-Pesa,withdrawal,35001,50000,278,0,0
M-Pesa,M-Pesa,withdrawal,50001,,309,0,0
M-Pesa,M-Pesa,transfer,1,100,0,0,0
M-Pesa,M-Pesa,transfer,101,500,7,0,0
M-Pesa,M-Pesa,transfer,501,1000,13,0,0
M-Pesa,M-Pesa,transfer,1001,1500,23,0,0
M-Pesa,M-Pesa,transfer,1501,2500,33,0,0
M-Pesa,M-Pesa,transfer,2501,3500,53,0,0
M-Pesa,M-Pesa,transfer,3501,5000,57,0,0
M-Pesa,M-Pesa,transfer,5001,7500,78,0,0
M-Pesa,M-Pesa,transfer,7501,10000,90,0,0
M-Pesa,M-Pesa,transfer,10001,15000,100,0,0
M-Pesa,M-Pesa,transfer,15001,20000,105,0,0
M-Pesa,M-Pesa,transfer,20001,35000,108,0,0
M-Pesa,M-Pesa,transfer,35001,50000,108,0,0
M-Pesa,M-Pesa,transfer,50001,,108,0,0
Airtel Money,Airtel Money,withdrawal,50,100,11,0,0
Airtel Money,Airtel Money,withdrawal,101,500,29,0,0
Airtel Money,Airtel Money,withdrawal,501,1000,29,0,0
Airtel Money,Airtel Money,withdrawal,1001,2500,29,0,0
Airtel Money,Airtel Money,withdrawal,2501,5000,52,0,0
Airtel Money,Airtel Money,withdrawal,5001,10000,87,0,0
Airtel Money,Airtel Money,withdrawal,10001,20000,167,0,0
Airtel Money,Airtel Money,withdrawal,20001,50000,197,0,0
Airtel Money,Airtel Money,withdrawal,50001,,309,0,0
Airtel Money,Airtel Money,transfer,1,100,0,0,0
Airtel Money,Airtel Money,transfer,101,500,7,0,0
Airtel Money,Airtel Money,transfer,501,1000,13,0,0
Airtel Money,Airtel Money,transfer,1001,2500,33,0,0
Airtel Money,Airtel Money,transfer,2501,5000,57,0,0
Airtel Money,Airtel Money,transfer,5001,10000,90,0,0
Airtel Money,Airtel Money,transfer,10001,20000,105,0,0
Airtel Money,Airtel Money,transfer,20001,,108,0,0
T-Kash,T-Kash,withdrawal,50,500,29,0,0
T-Kash,T-Kash,withdrawal,501,2500,29,0,0
T-Kash,T-Kash,withdrawal,2501,5000,52,0,0
T-Kash,T-Kash,withdrawal,5001,10000,87,0,0
T-Kash,T-Kash,withdrawal,10001,,167,0,0
T-Kash,T-Kash,transfer,1,500,7,0,0
T-Kash,T-Kash,transfer,501,2500,33,0,0
T-Kash,T-Kash,transfer,2501,10000,90,0,0
T-Kash,T-Kash,transfer,10001,,105,0,0
KCB Bank,KCB Bank,transfer,1,1000,0,0,20
KCB Bank,KCB Bank,transfer,1001,,30,0,20
KCB Bank,KCB Bank,withdrawal,1,2500,35,0,20
KCB Bank,KCB Bank,withdrawal,2501,5000,50,0,20
KCB Bank,KCB Bank,withdrawal,5001,10000,75,0,20
KCB Bank,KCB Bank,withdrawal,10001,20000,100,0,20
KCB Bank,KCB Bank,withdrawal,20001,50000,150,0,20
KCB Bank,KCB Bank,withdrawal,50001,,200,0,20
KCB Bank,KCB Bank,deposit,1,,0,0,0
Co-op Bank,Co-op Bank,transfer,1,1000,0,0,20
Co-op Bank,Co-op Bank,transfer,1001,,20,0,20
Co-op Bank,Co-op Bank,withdrawal,100,5000,50,0,20
Co-op Bank,Co-op Bank,withdrawal,5001,10000,70,0,20
Co-op Bank,Co-op Bank,withdrawal,10001,20000,80,0,20
Co-op Bank,Co-op Bank,withdrawal,20001,30000,100,0,20
Co-op Bank,Co-op Bank,withdrawal,30001,40000,120,0,20
Co-op Bank,Co-op Bank,withdrawal,40001,50000,140,0,20
Co-op Bank,Co-op Bank,withdrawal,50001,,250,0,20
Co-op Bank,Co-op Bank,deposit,1,,0,0,0
Equity Bank,Equity Bank,transfer,1,1000,0,0,20
Equity Bank,Equity Bank,transfer,1001,,25,0,20
Equity Bank,Equity Bank,withdrawal,1,2500,35,0,20
Equity Bank,Equity Bank,withdrawal,2501,5000,50,0,20
Equity Bank,Equity Bank,withdrawal,5001,10000,75,0,20
Equity Bank,Equity Bank,withdrawal,10001,20000,100,0,20
Equity Bank,Equity Bank,withdrawal,20001,50000,150,0,20
Equity Bank,Equity Bank,withdrawal,50001,,200,0,20
Equity Bank,Equity Bank,deposit,1,,0,0,0
National Bank,National Bank,transfer,1,1000,0,0,20
National Bank,National Bank,transfer,1001,,30,0,20
National Bank,National Bank,withdrawal,1,5000,50,0,20
National Bank,National Bank,withdrawal,5001,10000,75,0,20
National Bank,National Bank,withdrawal,10001,20000,100,0,20
National Bank,National Bank,withdrawal,20001,,200,0,20
National Bank,National Bank,deposit,1,,0,0,0
Absa Bank,Absa Bank,transfer,1,1000,0,0,20
Absa Bank,Absa Bank,transfer,1001,,35,0,20
Absa Bank,Absa Bank,withdrawal,1,2500,40,0,20
Absa Bank,Absa Bank,withdrawal,2501,5000,60,0,20
Absa Bank,Absa Bank,withdrawal,5001,10000,85,0,20
Absa Bank,Absa Bank,withdrawal,10001,20000,110,0,20
Absa Bank,Absa Bank,withdrawal,20001,50000,160,0,20
Absa Bank,Absa Bank,withdrawal,50001,,210,0,20
Absa Bank,Absa Bank,deposit,1,,0,0,0
Standard Chartered,Standard Chartered,transfer,1,1000,0,0,20
Standard Chartered,Standard Chartered,transfer,1001,,35,0,20
Standard Chartered,Standard Chartered,withdrawal,1,5000,50,0,20
Standard Chartered,Standard Chartered,withdrawal,5001,10000,80,0,20
Standard Chartered,Standard Chartered,withdrawal,10001,20000,120,0,20
Standard Chartered,Standard Chartered,withdrawal,20001,,200,0,20
Standard Chartered,Standard Chartered,deposit,1,,0,0,0
I&M Bank,I&M Bank,transfer,1,1000,0,0,20
I&M Bank,I&M Bank,transfer,1001,,30,0,20
I&M Bank,I&M Bank,withdrawal,1,5000,50,0,20
I&M Bank,I&M Bank,withdrawal,5001,10000,80,0,20
I&M Bank,I&M Bank,withdrawal,10001,20000,110,0,20
I&M Bank,I&M Bank,withdrawal,20001,,180,0,20
I&M Bank,I&M Bank,deposit,1,,0,0,0
Diamond Trust Bank,Diamond Trust Bank,transfer,1,1000,0,0,20
Diamond Trust Bank,Diamond Trust Bank,transfer,1001,,30,0,20
Diamond Trust Bank,Diamond Trust Bank,withdrawal,1,5000,50,0,20
Diamond Trust Bank,Diamond Trust Bank,withdrawal,5001,10000,80,0,20
Diamond Trust Bank,Diamond Trust Bank,withdrawal,10001,20000,110,0,20
Diamond Trust Bank,Diamond Trust Bank,withdrawal,20001,,180,0,20
Diamond Trust Bank,Diamond Trust Bank,deposit,1,,0,0,0
Family Bank,Family Bank,transfer,1,1000,0,0,20
Family Bank,Family Bank,transfer,1001,,25,0,20
Family Bank,Family Bank,withdrawal,1,5000,45,0,20
Family Bank,Family Bank,withdrawal,5001,10000,70,0,20
Family Bank,Family Bank,withdrawal,10001,20000,95,0,20
Family Bank,Family Bank,withdrawal,20001,,170,0,20
Family Bank,Family Bank,deposit,1,,0,0,0
Stanbic Bank,Stanbic Bank,transfer,1,1000,0,0,20
Stanbic Bank,Stanbic Bank,transfer,1001,,35,0,20
Stanbic Bank,Stanbic Bank,withdrawal,1,5000,55,0,20
Stanbic Bank,Stanbic Bank,withdrawal,5001,10000,85,0,20
Stanbic Bank,Stanbic Bank,withdrawal,10001,20000,115,0,20
Stanbic Bank,Stanbic Bank,withdrawal,20001,,190,0,20
Stanbic Bank,Stanbic Bank,deposit,1,,0,0,0
CITI Bank,CITI Bank,transfer,1,1000,0,0,20
CITI Bank,CITI Bank,transfer,1001,,40,0,20
CITI Bank,CITI Bank,withdrawal,1,5000,60,0,20
CITI Bank,CITI Bank,withdrawal,5001,10000,90,0,20
CITI Bank,CITI Bank,withdrawal,10001,20000,130,0,20
CITI Bank,CITI Bank,withdrawal,20001,,220,0,20
CITI Bank,CITI Bank,deposit,1,,0,0,0
Gulf African Bank,Gulf African Bank,transfer,1,1000,0,0,20
Gulf African Bank,Gulf African Bank,transfer,1001,,25,0,20
Gulf African Bank,Gulf African Bank,withdrawal,1,5000,45,0,20
Gulf African Bank,Gulf African Bank,withdrawal,5001,10000,70,0,20
Gulf African Bank,Gulf African Bank,withdrawal,10001,20000,95,0,20
Gulf African Bank,Gulf African Bank,withdrawal,20001,,170,0,20
Gulf African Bank,Gulf African Bank,deposit,1,,0,0,0
Prime Bank,Prime Bank,transfer,1,1000,0,0,20
Prime Bank,Prime Bank,transfer,1001,,30,0,20
Prime Bank,Prime Bank,withdrawal,1,5000,50,0,20
Prime Bank,Prime Bank,withdrawal,5001,10000,80,0,20
Prime Bank,Prime Bank,withdrawal,10001,20000,110,0,20
Prime Bank,Prime Bank,withdrawal,20001,,180,0,20
Prime Bank,Prime Bank,deposit,1,,0,0,0
Sidian Bank,Sidian Bank,transfer,1,1000,0,0,20
Sidian Bank,Sidian Bank,transfer,1001,,25,0,20
Sidian Bank,Sidian Bank,withdrawal,1,5000,45,0,20
Sidian Bank,Sidian Bank,withdrawal,5001,10000,70,0,20
Sidian Bank,Sidian Bank,withdrawal,10001,20000,95,0,20
Sidian Bank,Sidian Bank,withdrawal,20001,,170,0,20
Sidian Bank,Sidian Bank,deposit,1,,0,0,0
Postbank,Postbank,transfer,1,1000,0,0,20
Postbank,Postbank,transfer,1001,,20,0,20
Postbank,Postbank,withdrawal,1,5000,40,0,20
Postbank,Postbank,withdrawal,5001,10000,65,0,20
Postbank,Postbank,withdrawal,10001,20000,90,0,20
Postbank,Postbank,withdrawal,20001,,160,0,20
Postbank,Postbank,deposit,1,,0,0,0''';

  static TariffCsvImportResult parse(String csvContent, List<Account> accounts) {
    final errors = <String>[];
    final lines = csvContent
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return TariffCsvImportResult(tariffs: [], errors: ['File is empty.'], rowsRead: 0);
    }

    final header = _splitCsv(lines.first).map((h) => h.toLowerCase().trim()).toList();
    const required = ['provider', 'account_name', 'operation', 'to', 'fee_fixed'];
    for (final col in required) {
      if (!header.contains(col)) {
        errors.add('Missing required column: "$col".');
      }
    }
    if (errors.isNotEmpty) {
      return TariffCsvImportResult(tariffs: [], errors: errors, rowsRead: 0);
    }

    int col(String name) => header.indexOf(name);

    final accountMap = {
      for (final a in accounts) a.name.toLowerCase().trim(): a,
    };

    // Group rows by provider|account_name|operation (preserving insertion order)
    final groups = <String, List<_TierData>>{};
    int rowsRead = 0;

    for (int i = 1; i < lines.length; i++) {
      final cells = _splitCsv(lines[i]);
      if (cells.length < 5) {
        errors.add('Row ${i + 1}: not enough columns, skipped.');
        continue;
      }

      String cell(String name) {
        final idx = col(name);
        return idx >= 0 && idx < cells.length ? cells[idx].trim() : '';
      }

      final provider = cell('provider');
      final accountName = cell('account_name');
      final operationRaw = cell('operation').toLowerCase();

      if (provider.isEmpty) {
        errors.add('Row ${i + 1}: provider is empty, skipped.');
        continue;
      }
      if (accountName.isEmpty) {
        errors.add('Row ${i + 1}: account_name is empty, skipped.');
        continue;
      }
      if (!['withdrawal', 'transfer', 'deposit'].contains(operationRaw)) {
        errors.add('Row ${i + 1}: unknown operation "$operationRaw" (use withdrawal/transfer/deposit), skipped.');
        continue;
      }

      final toRaw = cell('to');
      final feeFixedRaw = cell('fee_fixed');
      final feePctRaw = col('fee_pct') >= 0 ? cell('fee_pct') : '0';
      final taxPctRaw = col('tax_pct') >= 0 ? cell('tax_pct') : '0';

      final feeFixed = double.tryParse(feeFixedRaw);
      if (feeFixed == null) {
        errors.add('Row ${i + 1}: invalid fee_fixed "$feeFixedRaw", skipped.');
        continue;
      }

      final feePct = double.tryParse(feePctRaw) ?? 0;
      final taxPct = double.tryParse(taxPctRaw) ?? 0;

      int? toMinor;
      if (toRaw.isNotEmpty) {
        final toVal = double.tryParse(toRaw);
        if (toVal == null) {
          errors.add('Row ${i + 1}: invalid "to" value "$toRaw", skipped.');
          continue;
        }
        toMinor = (toVal * 100).round();
      }

      final key = '$provider|${accountName.toLowerCase()}|$operationRaw';
      groups.putIfAbsent(key, () => []).add(_TierData(
        provider: provider,
        accountName: accountName,
        operation: operationRaw,
        toMinor: toMinor,
        feeBp: (feePct * 100).round(),
        feeFixed: (feeFixed * 100).round(),
        taxPct: taxPct,
      ));
      rowsRead++;
    }

    final tariffs = <Tariff>[];

    for (final entry in groups.entries) {
      final rows = entry.value;
      final first = rows.first;

      final account = accountMap[first.accountName.toLowerCase().trim()];
      if (account == null) {
        errors.add('Account "${first.accountName}" not found — "${first.provider}" skipped. '
            'Make sure the account exists in Keel before importing.');
        continue;
      }

      final operation = TariffOperation.values.byName(first.operation);
      final taxPct = first.taxPct;

      final tiers = rows.map((r) => TariffTier(
            upToMinor: r.toMinor,
            feeBp: r.feeBp,
            feeFixed: r.feeFixed,
          )).toList();

      tariffs.add(Tariff(
        id: const Uuid().v4(),
        provider: first.provider,
        accountId: account.id,
        operation: operation,
        tiers: tiers,
        taxRateBp: (taxPct * 100).round(),
        effectiveFrom: DateTime.now(),
      ));
    }

    return TariffCsvImportResult(
      tariffs: tariffs,
      errors: errors,
      rowsRead: rowsRead,
    );
  }

  static List<String> _splitCsv(String line) {
    final result = <String>[];
    final buf = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        result.add(buf.toString());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    result.add(buf.toString());
    return result;
  }
}

class _TierData {
  final String provider;
  final String accountName;
  final String operation;
  final int? toMinor;
  final int feeBp;
  final int feeFixed;
  final double taxPct;

  const _TierData({
    required this.provider,
    required this.accountName,
    required this.operation,
    required this.toMinor,
    required this.feeBp,
    required this.feeFixed,
    required this.taxPct,
  });
}
