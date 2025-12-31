// lib/services/invoice_service.dart
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:kakiso_reseller_app/models/order.dart';

class InvoiceService {
  // --- MINIMALIST DESIGN THEME ---
  static const PdfColor _primaryColor = PdfColors.deepPurple700;
  static const PdfColor _textColor = PdfColors.black;
  static const PdfColor _subTextColor = PdfColors.grey700;
  static const PdfColor _tableHeaderColor = PdfColors.grey100;

  static Future<void> generateAndPrintInvoice(Order order) async {
    final pdf = pw.Document();

    // Standard Helvetica is clean and professional
    final fontRegular = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        // Standard professional margins (no full-bleed header to keep it clean)
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        build: (context) => [
          _buildTopHeader(order),
          pw.SizedBox(height: 30),
          _buildCleanAddressSection(order),
          pw.SizedBox(height: 30),
          _buildWideTable(order),
          pw.SizedBox(height: 10),
          _buildTotalSection(order),
          pw.Spacer(),
          _buildFooter(),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_${order.id}.pdf',
    );
  }

  // ---------------------------------------------------------------------------
  // 1. HEADER (Logo + Invoice Details)
  // ---------------------------------------------------------------------------
  static pw.Widget _buildTopHeader(Order order) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // LEFT: Company Name (Large)
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'KaKiSo',
              style: pw.TextStyle(
                fontSize: 32,
                fontWeight: pw.FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Reselling Simplified',
              style: const pw.TextStyle(fontSize: 10, color: _subTextColor),
            ),
          ],
        ),

        // RIGHT: Big "INVOICE" text + Date
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey300, // Subtle background text style
              ),
            ),
            pw.SizedBox(height: 10),
            _buildMetaLine('Invoice #', 'INV-${order.id}'),
            _buildMetaLine(
              'Date',
              DateFormat('dd MMM yyyy').format(order.createdAt),
            ),
            _buildMetaLine('GSTIN', '24ABCDE1234F1Z5'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildMetaLine(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            '$label: ',
            style: const pw.TextStyle(fontSize: 10, color: _subTextColor),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. CLEAN ADDRESS SECTION (No Boxes, Just Text)
  // ---------------------------------------------------------------------------
  static pw.Widget _buildCleanAddressSection(Order order) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Left: Invoice For (Customer)
        // pw.Expanded(
        //   child: pw.Column(
        //     crossAxisAlignment: pw.CrossAxisAlignment.start,
        //     children: [
        //       pw.Text(
        //         'INVOICE FOR',
        //         style: pw.TextStyle(
        //           fontSize: 9,
        //           fontWeight: pw.FontWeight.bold,
        //           color: _subTextColor,
        //           letterSpacing: 1,
        //         ),
        //       ),
        //       pw.SizedBox(height: 8),
        //       pw.Text(
        //         order.customerAddress, // Directly using the full address string
        //         style: const pw.TextStyle(
        //           fontSize: 11,
        //           lineSpacing: 4, // Nice breathing room between lines
        //           color: _textColor,
        //         ),
        //       ),
        //       pw.SizedBox(height: 4),
        //       // Show Name if available distinct from address, or rely on address string
        //       if (order.userName.isNotEmpty)
        //         pw.Text(
        //           order.userName,
        //           style: pw.TextStyle(
        //             fontSize: 11,
        //             fontWeight: pw.FontWeight.bold,
        //           ),
        //         ),
        //     ],
        //   ),
        // ),

        // Right: Payable To (Company) - Kept simple
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'PAID TO',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _subTextColor,
                  letterSpacing: 1,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'KaKiSo Pvt Ltd.',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              // pw.Text(
              //   '123, Business Park, Main Road,\nAhmedabad, Gujarat - 380001',
              //   style: const pw.TextStyle(
              //     fontSize: 10,
              //     color: _subTextColor,
              //     lineSpacing: 2,
              //   ),
              // ),
              pw.SizedBox(height: 4),
              pw.Text(
                'support@kakiso.app',
                style: const pw.TextStyle(fontSize: 10, color: _subTextColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 3. WIDE TABLE (Fixed Column Widths)
  // ---------------------------------------------------------------------------
  static pw.Widget _buildWideTable(Order order) {
    const tableHeaders = ['Description', 'HSN', 'Qty', 'Price', 'GST', 'Total'];

    final List<List<dynamic>> data = [];

    // 1. Items
    for (var item in order.items) {
      final double gstRate = double.tryParse(item.gstRate) ?? 18.0;
      final double totalLinePrice = item.unitPrice * item.quantity;
      final double taxableValue = totalLinePrice / (1 + (gstRate / 100));
      // Unit Price (Taxable)
      final double unitTaxable = taxableValue / item.quantity;

      data.add([
        item.name,
        item.hsnCode,
        '${item.quantity}',
        _formatMoney(unitTaxable),
        '${item.gstRate}%',
        _formatMoney(totalLinePrice), // Keeping it simple: Total Line Amount
      ]);
    }

    // 2. Fees
    const double shippingFee = 100.0;
    const double combinedFee = 27.0;

    data.add([
      'Shipping Charges',
      '996812',
      '1',
      _formatMoney(shippingFee / 1.18),
      '18%',
      _formatMoney(shippingFee),
    ]);

    data.add([
      'Platform Fees',
      '999799',
      '1',
      _formatMoney(combinedFee / 1.18),
      '18%',
      _formatMoney(combinedFee),
    ]);

    return pw.TableHelper.fromTextArray(
      headers: tableHeaders,
      data: data,
      border: null, // Very clean look, no borders
      headerStyle: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: _textColor,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: _tableHeaderColor, // Light grey header background
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      cellStyle: const pw.TextStyle(fontSize: 10, color: _textColor),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 12),

      // 🔹 IMPORTANT: Column Widths to prevent wrapping
      // Proportions: Description (4), HSN (1.5), Qty (0.8), Price (2), GST (1), Total (2.5)
      columnWidths: {
        0: const pw.FlexColumnWidth(4), // Description gets most space
        1: const pw.FlexColumnWidth(1.5), // HSN
        2: const pw.FlexColumnWidth(0.8), // Qty (Needs very little)
        3: const pw.FlexColumnWidth(2), // Price
        4: const pw.FlexColumnWidth(1), // GST
        5: const pw.FlexColumnWidth(2.5), // Total (Needs ample space)
      },

      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.center,
        5: pw.Alignment.centerRight,
      },
      // Simple border at the bottom of rows
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. TOTALS SECTION
  // ---------------------------------------------------------------------------
  static pw.Widget _buildTotalSection(Order order) {
    double totalTaxable = 0;
    double totalTax = 0;

    for (var item in order.items) {
      final double gstRate = double.tryParse(item.gstRate) ?? 18.0;
      final double total = item.unitPrice * item.quantity;
      final double taxable = total / (1 + (gstRate / 100));
      totalTaxable += taxable;
      totalTax += (total - taxable);
    }

    double servicesTotal = 127.0;
    double servicesTaxable = servicesTotal / 1.18;
    double servicesTax = servicesTotal - servicesTaxable;
    totalTaxable += servicesTaxable;
    totalTax += servicesTax;

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Container(
            width: 250,
            child: pw.Column(
              children: [
                _buildSummaryRow('Subtotal (Taxable)', totalTaxable),
                pw.SizedBox(height: 6),
                _buildSummaryRow('Total GST', totalTax),
                pw.SizedBox(height: 12),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 10),

                // Final Total
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Amount',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                        color: _textColor,
                      ),
                    ),
                    pw.Text(
                      _formatMoney(order.amount),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 18,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryRow(String label, double value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: _subTextColor),
        ),
        pw.Text(
          _formatMoney(value),
          style: const pw.TextStyle(fontSize: 10, color: _textColor),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. FOOTER
  // ---------------------------------------------------------------------------
  static pw.Widget _buildFooter() {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'Thank you for your business!',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: _primaryColor,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'For any queries, contact support@kakiso.app',
          style: const pw.TextStyle(fontSize: 9, color: _subTextColor),
        ),
      ],
    );
  }

  static String _formatMoney(double amount) {
    // Standard format to avoid large symbol issues
    return 'Rs. ${amount.toStringAsFixed(2)}';
  }
}
