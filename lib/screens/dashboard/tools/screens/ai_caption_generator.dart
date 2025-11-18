// ai_caption_generator.dart
import 'package:flutter/material.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/tools.dart';

class AICaptionGeneratorPage extends StatefulWidget {
  const AICaptionGeneratorPage({super.key});

  @override
  State<AICaptionGeneratorPage> createState() => _AICaptionGeneratorPageState();
}

class _AICaptionGeneratorPageState extends State<AICaptionGeneratorPage> {
  final TextEditingController _prompt = TextEditingController();
  String result = '';

  Future<void> _generate() async {
    setState(() => result = 'Generating...');
    await Future.delayed(const Duration(seconds: 1));
    setState(
      () => result =
          '🔥 New arrival! Grab this limited edition product at a special price. Tap to buy!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI caption generator'),
        backgroundColor: Colors.white,
        foregroundColor: accentColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _prompt,
              decoration: const InputDecoration(
                labelText: 'Describe the product (or paste product name)',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _generate,
              style: ElevatedButton.styleFrom(backgroundColor: accentColor),
              child: const Text('Generate'),
            ),
            const SizedBox(height: 12),
            if (result.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(result),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
