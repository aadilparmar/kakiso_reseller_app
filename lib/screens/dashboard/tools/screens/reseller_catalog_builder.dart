// reseller_catalog_builder.dart
import 'package:flutter/material.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/categories.dart';

class ResellerCatalogBuilderPage extends StatefulWidget {
  const ResellerCatalogBuilderPage({Key? key}) : super(key: key);

  @override
  State<ResellerCatalogBuilderPage> createState() =>
      _ResellerCatalogBuilderPageState();
}

class _ResellerCatalogBuilderPageState
    extends State<ResellerCatalogBuilderPage> {
  final List<String> selectedProducts = [];
  final List<String> allProducts = List.generate(12, (i) => 'Product ${i + 1}');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reseller catalog builder'),
        backgroundColor: Colors.white,
        foregroundColor: accentColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: allProducts.length,
              itemBuilder: (ctx, i) {
                final p = allProducts[i];
                final selected = selectedProducts.contains(p);
                return CheckboxListTile(
                  value: selected,
                  title: Text(p),
                  subtitle: const Text('Sample description'),
                  onChanged: (v) {
                    setState(() {
                      if (v == true)
                        selectedProducts.add(p);
                      else
                        selectedProducts.remove(p);
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: selectedProducts.isEmpty
                        ? null
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Catalog created for ${selectedProducts.length} products',
                                ),
                              ),
                            );
                          },
                    child: const Text('Create catalog'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
