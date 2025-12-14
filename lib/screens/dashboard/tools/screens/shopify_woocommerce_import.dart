// shopify_woocommerce_import.dart
import 'package:flutter/material.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/tools.dart';

class ShopifyWooImportPage extends StatefulWidget {
  const ShopifyWooImportPage({super.key});

  @override
  State<ShopifyWooImportPage> createState() => _ShopifyWooImportPageState();
}

class _ShopifyWooImportPageState extends State<ShopifyWooImportPage> {
  final TextEditingController _storeUrl = TextEditingController();
  String status = 'Idle';

  Future<void> _importFromStore() async {
    if (_storeUrl.text.trim().isEmpty) return;
    setState(() => status = 'Importing...');
    await Future.delayed(const Duration(seconds: 2));
    setState(() => status = 'Imported 42 products');
    ScaffoldMessenger.of(
      // ignore: use_build_context_synchronously
      context,
    ).showSnackBar(const SnackBar(content: Text('Import complete')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopify / WooCommerce import'),
        backgroundColor: Colors.white,
        foregroundColor: accentColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _storeUrl,
              decoration: const InputDecoration(
                labelText: 'Store URL or API endpoint',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _importFromStore,
              style: ElevatedButton.styleFrom(backgroundColor: accentColor),
              child: const Text('Start import'),
            ),
            const SizedBox(height: 12),
            Text('Status: $status'),
          ],
        ),
      ),
    );
  }
}
