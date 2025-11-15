// trending_products_dashboard.dart
import 'package:flutter/material.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/categories.dart';

class TrendingProductsDashboardPage extends StatelessWidget {
  const TrendingProductsDashboardPage({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> sample = const [
    {'title': 'Product A', 'sales': 120},
    {'title': 'Product B', 'sales': 90},
    {'title': 'Product C', 'sales': 75},
    {'title': 'Product D', 'sales': 60},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trending products'),
        backgroundColor: Colors.white,
        foregroundColor: accentColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Top trending',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: sample.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, i) {
                  final s = sample[i];
                  return ListTile(
                    leading: CircleAvatar(child: Text('${i + 1}')),
                    title: Text(s['title']),
                    trailing: Text('${s['sales']} sold'),
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
