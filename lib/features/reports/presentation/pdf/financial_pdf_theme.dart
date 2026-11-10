import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfThemeFonts {
  final pw.Font regular;
  final pw.Font bold;
  final pw.Font italic;

  const PdfThemeFonts({
    required this.regular,
    required this.bold,
    required this.italic,
  });

  static Future<PdfThemeFonts> load() async {
    try {
      final r = await PdfGoogleFonts.interRegular();
      final b = await PdfGoogleFonts.interBold();
      final i = await PdfGoogleFonts.interItalic();
      return PdfThemeFonts(regular: r, bold: b, italic: i);
    } catch (_) {
      // Offline or network restricted fallback
      return PdfThemeFonts(
        regular: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
        italic: pw.Font.helveticaOblique(),
      );
    }
  }
}

class FinancialPdfTheme {
  // ── Palette ────────────────────────────────────────────────────────────────
  static const primaryNavy = PdfColor.fromInt(0xFF0F172A);
  static const royalBlue = PdfColor.fromInt(0xFF2563EB);
  static const royalBlueLight = PdfColor.fromInt(0xFFEFF6FF);
  static const successGreen = PdfColor.fromInt(0xFF059669);
  static const successGreenLight = PdfColor.fromInt(0xFFECFDF5);
  static const errorRed = PdfColor.fromInt(0xFFDC2626);
  static const errorRedLight = PdfColor.fromInt(0xFFFEF2F2);
  static const warningAmber = PdfColor.fromInt(0xFFD97706);
  static const warningAmberLight = PdfColor.fromInt(0xFFFFFBEB);
  static const slateDark = PdfColor.fromInt(0xFF334155);
  static const slateMedium = PdfColor.fromInt(0xFF64748B);
  static const slateLight = PdfColor.fromInt(0xFF94A3B8);
  static const cardBackground = PdfColor.fromInt(0xFFF8FAFC);
  static const tableStripe = PdfColor.fromInt(0xFFF1F5F9);
  static const borderColor = PdfColor.fromInt(0xFFE2E8F0);
  static const white = PdfColors.white;

  // ── Currency & String Formatters (Strictly ASCII safe) ─────────────────────

  static String formatKes(int minor, {bool showDecimals = false}) {
    final isNeg = minor < 0;
    final abs = minor.abs();
    final major = abs ~/ 100;
    final cents = abs % 100;

    final majorStr = _addCommas(major);
    final sign = isNeg ? '-' : '';

    if (showDecimals) {
      return '${sign}KES $majorStr.${cents.toString().padLeft(2, '0')}';
    }
    return '${sign}KES $majorStr';
  }

  static String formatKesSigned(int minor, {bool showDecimals = false}) {
    if (minor > 0) {
      return '+${formatKes(minor, showDecimals: showDecimals)}';
    }
    return formatKes(minor, showDecimals: showDecimals);
  }

  static String formatCompact(int minor) {
    final isNeg = minor < 0;
    final abs = minor.abs() / 100.0;
    final sign = isNeg ? '-' : '';

    if (abs >= 1000000) {
      return '${sign}KES ${(abs / 1000000).toStringAsFixed(2)}M';
    }
    if (abs >= 1000) {
      return '${sign}KES ${(abs / 1000).toStringAsFixed(1)}K';
    }
    return '${sign}KES ${abs.toStringAsFixed(0)}';
  }

  static String formatPct(double ratio, {bool showSign = true}) {
    final pct = ratio * 100;
    final sign = showSign && pct > 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}%';
  }

  static String formatDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month]} ${d.year}';
  }

  static String formatPeriod(String period) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final parts = period.split('-');
    if (parts.length == 2) {
      final m = int.tryParse(parts[1]) ?? 1;
      return '${months[m]} ${parts[0]}';
    }
    return period;
  }

  static String _addCommas(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    final len = str.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  // ── Header & Footer ────────────────────────────────────────────────────────

  static pw.Widget buildHeader({
    required PdfThemeFonts fonts,
    required String title,
    String? subtitle,
    Uint8List? logoBytes,
    Uint8List? wordmarkBytes,
    DateTime? date,
  }) {
    final now = date ?? DateTime.now();
    final dateStr = formatDate(now);
    final logoImage = logoBytes != null ? pw.MemoryImage(logoBytes) : null;
    final wordmarkImage =
        wordmarkBytes != null ? pw.MemoryImage(wordmarkBytes) : null;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Top Masthead: Brand on Left, Date & Metadata on Right
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Left: Logo & Wordmark
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logoImage != null)
                  pw.Container(
                    width: 20,
                    height: 20,
                    margin: const pw.EdgeInsets.only(right: 6),
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  ),
                if (wordmarkImage != null)
                  pw.Image(wordmarkImage, width: 44, height: 16, fit: pw.BoxFit.contain)
                else
                  pw.Text('KEEL',
                      style: pw.TextStyle(
                        font: fonts.bold,
                        fontSize: 13,
                        color: royalBlue,
                        letterSpacing: 1.2,
                      )),
                pw.Container(
                  margin: const pw.EdgeInsets.symmetric(horizontal: 8),
                  height: 12,
                  width: 0.8,
                  color: borderColor,
                ),
                pw.Text('FINANCIAL INTELLIGENCE',
                    style: pw.TextStyle(
                      font: fonts.bold,
                      fontSize: 7.5,
                      color: slateMedium,
                      letterSpacing: 0.8,
                    )),
              ],
            ),
            // Right: Date & Currency
            pw.Text(
              'As of $dateStr · Currency: KES',
              style: pw.TextStyle(
                font: fonts.regular,
                fontSize: 8,
                color: slateMedium,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Divider(color: borderColor, thickness: 0.6),
        pw.SizedBox(height: 6),

        // Page Headline & Context - Full Width, Left Aligned & Presentable
        pw.Text(
          title,
          style: pw.TextStyle(
            font: fonts.bold,
            fontSize: 12,
            color: primaryNavy,
            letterSpacing: 0.4,
          ),
        ),
        if (subtitle != null && subtitle.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            subtitle,
            style: pw.TextStyle(
              font: fonts.regular,
              fontSize: 7.8,
              color: slateMedium,
            ),
          ),
        ],
        pw.SizedBox(height: 8),
      ],
    );
  }

  static pw.Widget buildFooter({
    required pw.Context context,
    required PdfThemeFonts fonts,
  }) {
    return pw.Column(
      children: [
        pw.Divider(color: borderColor, thickness: 0.5),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Confidential · Prepared with Keel Personal Ledger & Financial Intelligence',
              style: pw.TextStyle(
                font: fonts.italic,
                fontSize: 7.5,
                color: slateMedium,
              ),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(
                font: fonts.regular,
                fontSize: 7.5,
                color: slateDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Section Title (Clean Typographic Rule, Zero Blue Pills) ───────────────

  static pw.Widget buildSectionTitle({
    required PdfThemeFonts fonts,
    required String title,
    String? subtitle,
    PdfColor? accentColor,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10, bottom: 5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                title.toUpperCase(),
                style: pw.TextStyle(
                  font: fonts.bold,
                  fontSize: 8.5,
                  color: primaryNavy,
                  letterSpacing: 0.5,
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    subtitle,
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      font: fonts.regular,
                      fontSize: 7.5,
                      color: slateMedium,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ],
          ),
          pw.SizedBox(height: 3),
          pw.Divider(color: borderColor, thickness: 0.45),
        ],
      ),
    );
  }
}
