// broadcast_marketing_tools.dart
import 'package:flutter/material.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/categories.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/tools.dart';

class BroadcastMarketingToolsPage extends StatefulWidget {
  const BroadcastMarketingToolsPage({super.key});

  @override
  State<BroadcastMarketingToolsPage> createState() =>
      _BroadcastMarketingToolsPageState();
}

class _BroadcastMarketingToolsPageState
    extends State<BroadcastMarketingToolsPage> {
  final TextEditingController _message = TextEditingController();
  final List<String> _audiences = [
    'All customers',
    'Recent buyers',
    'Top resellers',
  ];
  String selectedAudience = 'All customers';

  void _sendBroadcast() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Broadcast queued')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Broadcast marketing tools'),
        backgroundColor: Colors.white,
        foregroundColor: accentColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedAudience,
              items: _audiences
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => selectedAudience = v ?? selectedAudience),
              decoration: const InputDecoration(labelText: 'Audience'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _message,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _sendBroadcast,
              child: const Text('Send broadcast'),
              style: ElevatedButton.styleFrom(backgroundColor: accentColor),
            ),
          ],
        ),
      ),
    );
  }
}
