// lib/services/invoice_service.dart
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:kakiso_reseller_app/models/order.dart';

class InvoiceService {
  static Future<void> generateAndPrintInvoice(Order order) async {
    final pdf = pw.Document();

    // We use standard standard fonts to ensure speed and compatibility
    // but we will use "Rs." text to avoid the 'box with cross' issue.
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        // Remove margin here and handle it inside to allow full-width header
        margin: const pw.EdgeInsets.all(0),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (context) => [
          _buildHeader(order),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 20,
            ),
            child: pw.Column(
              children: [
                _buildProfessionalTable(order),
                pw.SizedBox(height: 20),
                _buildTotalSection(order),
                pw.SizedBox(height: 50),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_${order.id}.pdf',
    );
  }

  // ----------------------------------------------------------
  // 1. FULL WIDTH COLORED HEADER
  // ----------------------------------------------------------
  static pw.Widget _buildHeader(Order order) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 30, horizontal: 40),
      color: PdfColors.deepPurple700, // Corporate Color
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Left: Invoice Details
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'TAX INVOICE',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Invoice #: INV-${order.id}',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey200,
                ),
              ),
              pw.Text(
                'Date: ${DateFormat('dd MMM yyyy').format(order.createdAt)}',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey200,
                ),
              ),
            ],
          ),

          // Right: Company Branding
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'KaKiSo',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                'GSTIN: 24ABCDE1234F1Z5',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey200,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                ),
                child: pw.Text(
                  'PAID',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.deepPurple900,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // 2. STRIPED PROFESSIONAL TABLE
  // ----------------------------------------------------------
  static pw.Widget _buildProfessionalTable(Order order) {
    const tableHeaders = [
      'Item Description',
      'HSN',
      'Qty',
      'Rate',
      'GST',
      'Tax',
      'Amount',
    ];

    // 1. Map Items
    final data = order.items.map((item) {
      final double gstRate = double.tryParse(item.gstRate) ?? 18.0;
      final double totalLinePrice = item.unitPrice * item.quantity;

      // Math: Taxable = Total / (1 + GST%)
      final double taxableValue = totalLinePrice / (1 + (gstRate / 100));
      final double taxAmount = totalLinePrice - taxableValue;
      final double unitTaxable = taxableValue / item.quantity;

      return [
        item.name,
        item.hsnCode,
        '${item.quantity}',
        _formatCurrency(unitTaxable), // Rate (Taxable)
        '${item.gstRate}%',
        _formatCurrency(taxAmount),
        _formatCurrency(totalLinePrice),
      ];
    }).toList();

    // 2. Add Shipping & Fees
    const double shippingFee = 100.0;
    const double combinedFee = 27.0;

    final double shippingTaxable = shippingFee / 1.18;
    final double shippingTax = shippingFee - shippingTaxable;

    final double feeTaxable = combinedFee / 1.18;
    final double feeTax = combinedFee - feeTaxable;

    data.add([
      'Shipping Charges',
      '996812',
      '1',
      _formatCurrency(shippingTaxable),
      '18%',
      _formatCurrency(shippingTax),
      _formatCurrency(shippingFee),
    ]);
    data.add([
      'Platform Fees',
      '999799',
      '1',
      _formatCurrency(feeTaxable),
      '18%',
      _formatCurrency(feeTax),
      _formatCurrency(combinedFee),
    ]);

    return pw.Table.fromTextArray(
      headers: tableHeaders,
      data: data,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.grey800,
        fontSize: 10,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      // Zebra/Striped effect for rows
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey100)),
      ),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
      cellAlignments: {
        0: pw.Alignment.centerLeft, // Item
        1: pw.Alignment.center, // HSN
        2: pw.Alignment.center, // Qty
        3: pw.Alignment.centerRight, // Rate
        4: pw.Alignment.center, // GST
        5: pw.Alignment.centerRight, // Tax
        6: pw.Alignment.centerRight, // Amount
      },
    );
  }

  // ----------------------------------------------------------
  // 3. TOTALS SECTION
  // ----------------------------------------------------------
  static pw.Widget _buildTotalSection(Order order) {
    // Recalculate Totals
    double totalTaxable = 0;
    double totalTax = 0;

    for (var item in order.items) {
      final double gstRate = double.tryParse(item.gstRate) ?? 18.0;
      final double total = item.unitPrice * item.quantity;
      final double taxable = total / (1 + (gstRate / 100));
      totalTaxable += taxable;
      totalTax += (total - taxable);
    }

    // Add Services (100 + 27 = 127)
    double servicesTotal = 127.0;
    double servicesTaxable = servicesTotal / 1.18;
    double servicesTax = servicesTotal - servicesTaxable;

    totalTaxable += servicesTaxable;
    totalTax += servicesTax;

    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 240,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _summaryRow('Total Taxable Value', totalTaxable),
            pw.SizedBox(height: 6),
            _summaryRow('Total GST', totalTax),
            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Invoice Total',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                // Grand total color
                pw.Text(
                  _formatCurrency(order.amount),
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                    color: PdfColors.deepPurple700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _summaryRow(String label, double value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.Text(
          _formatCurrency(value),
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // 4. FOOTER
  // ----------------------------------------------------------
  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 10),
        pw.Text(
          'Thank you for your business!',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.deepPurple700,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'This is a computer-generated invoice and requires no signature.',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // 5. HELPER: CURRENCY FIX
  // ----------------------------------------------------------
  static String _formatCurrency(double amount) {
    // 隼 FIX: Manually using "Rs." text instead of symbol
    // because fonts often fail to render the symbol (邃ｹ).
    return 'Rs. ${amount.toStringAsFixed(2)}';
  }
}
