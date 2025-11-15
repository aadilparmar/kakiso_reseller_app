// one_click_whatsapp.dart
import 'package:flutter/material.dart';
import 'package:kakiso_reseller_app/screens/dashboard/categories/categories.dart';
import 'package:url_launcher/url_launcher.dart';

class OneClickWhatsAppPage extends StatefulWidget {
  const OneClickWhatsAppPage({Key? key}) : super(key: key);

  @override
  State<OneClickWhatsAppPage> createState() => _OneClickWhatsAppPageState();
}

class _OneClickWhatsAppPageState extends State<OneClickWhatsAppPage> {
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _message = TextEditingController(
    text: 'Check this product: https://example.com/product/123',
  );

  Future<void> _openWhatsApp() async {
    final phone = _phone.text.trim();
    final text = Uri.encodeComponent(_message.text);
    final url = 'https://wa.me/$phone?text=$text';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cannot open WhatsApp')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('One-click WhatsApp'),
        backgroundColor: Colors.white,
        foregroundColor: accentColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _phone,
              decoration: const InputDecoration(
                labelText: 'Phone (with country code, e.g. 91888...)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _message,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Message to send'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openWhatsApp,
              icon: const Icon(Icons.send),
              label: const Text('Open in WhatsApp'),
              style: ElevatedButton.styleFrom(backgroundColor: accentColor),
            ),
          ],
        ),
      ),
    );
  }
}
