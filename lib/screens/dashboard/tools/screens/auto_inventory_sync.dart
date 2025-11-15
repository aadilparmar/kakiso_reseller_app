// auto_inventory_sync.dart
import 'package:flutter/material.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/categories.dart';

class AutoInventorySyncPage extends StatefulWidget {
  const AutoInventorySyncPage({super.key});

  @override
  State<AutoInventorySyncPage> createState() => _AutoInventorySyncPageState();
}

class _AutoInventorySyncPageState extends State<AutoInventorySyncPage> {
  bool autoSyncEnabled = true;
  String lastSync = 'Not synced yet';

  Future<void> _syncNow() async {
    setState(() => lastSync = 'Syncing...');
    await Future.delayed(const Duration(seconds: 2));
    setState(() => lastSync = DateTime.now().toLocal().toString());
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Inventory synced')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto inventory sync'),
        backgroundColor: Colors.white,
        foregroundColor: accentColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Enable Auto Sync'),
              subtitle: const Text('Sync inventory automatically on schedule'),
              value: autoSyncEnabled,
              onChanged: (v) => setState(() => autoSyncEnabled = v),
            ),
            ListTile(
              title: const Text('Last sync'),
              subtitle: Text(lastSync),
              trailing: ElevatedButton(
                onPressed: _syncNow,
                child: const Text('Sync now'),
                style: ElevatedButton.styleFrom(backgroundColor: accentColor),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Notes',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Auto sync will run every hour by default. You can change schedule in advanced settings.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
