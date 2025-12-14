// whatsapp_store_builder.dart
import 'package:flutter/material.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/tools.dart';

class WhatsappStoreBuilderPage extends StatefulWidget {
  const WhatsappStoreBuilderPage({super.key});

  @override
  State<WhatsappStoreBuilderPage> createState() =>
      _WhatsappStoreBuilderPageState();
}

class _WhatsappStoreBuilderPageState extends State<WhatsappStoreBuilderPage> {
  final List<Map<String, String>> products = [];
  final TextEditingController _name = TextEditingController();
  final TextEditingController _price = TextEditingController();

  void _addProduct() {
    if (_name.text.trim().isEmpty) return;
    setState(() {
      products.add({'name': _name.text.trim(), 'price': _price.text.trim()});
      _name.clear();
      _price.clear();
    });
  }

  void _previewCatalog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('WhatsApp Catalog preview'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: products
                .map(
                  (p) => ListTile(
                    title: Text(p['name']!),
                    subtitle: Text('₹${p['price']}'),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp store builder'),
        backgroundColor: Colors.white,
        foregroundColor: accentColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Product name',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _price,
                    decoration: const InputDecoration(labelText: 'Price'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _addProduct,
                  style: ElevatedButton.styleFrom(backgroundColor: accentColor),
                  child: const Text('Add product'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _previewCatalog,
                  child: const Text('Preview'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: products.isEmpty
                  ? const Center(child: Text('No products added'))
                  : ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (ctx, i) {
                        final p = products[i];
                        return ListTile(
                          title: Text(p['name']!),
                          subtitle: Text('₹${p['price']}'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
