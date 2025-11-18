// price_margin_tool.dart
import 'package:flutter/material.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/tools.dart';

class PriceMarginToolPage extends StatefulWidget {
  const PriceMarginToolPage({super.key});

  @override
  State<PriceMarginToolPage> createState() => _PriceMarginToolPageState();
}

class _PriceMarginToolPageState extends State<PriceMarginToolPage> {
  final TextEditingController _markup = TextEditingController(text: '20');
  final TextEditingController _rounding = TextEditingController(text: '9');

  double _calcPrice(double base) {
    final markup = double.tryParse(_markup.text) ?? 0;
    final rounding = double.tryParse(_rounding.text) ?? 0;
    var p = base * (1 + markup / 100);
    if (rounding > 0) {
      final r = rounding.toInt();
      p = ((p / 10).ceil() * 10 - (10 - r)) as double;
    }
    return p;
  }

  @override
  Widget build(BuildContext context) {
    final sampleBase = 499.0;
    final samplePrice = _calcPrice(sampleBase);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto price margin tool'),
        backgroundColor: Colors.white,
        foregroundColor: accentColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _markup,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Markup %'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _rounding,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Rounding (last digit)',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => setState(() {}),
              style: ElevatedButton.styleFrom(backgroundColor: accentColor),
              child: const Text('Apply'),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: Text('Sample product base ₹$sampleBase'),
                subtitle: Text(
                  'Suggested price: ₹${samplePrice.toStringAsFixed(0)}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
