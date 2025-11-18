// auto_video_generator.dart
import 'package:flutter/material.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/tools.dart';

class AutoVideoGeneratorPage extends StatefulWidget {
  const AutoVideoGeneratorPage({super.key});

  @override
  State<AutoVideoGeneratorPage> createState() => _AutoVideoGeneratorPageState();
}

class _AutoVideoGeneratorPageState extends State<AutoVideoGeneratorPage> {
  final List<String> images = [];
  final TextEditingController _title = TextEditingController();

  void _addPlaceholderImage() {
    setState(() {
      images.add('assets/placeholders/product_placeholder.png');
    });
  }

  void _generateVideo() {
    // Placeholder: show simulation
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Video generation'),
        content: const Text('This will stitch selected images into a video.'),
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
        title: const Text('Auto video generator'),
        backgroundColor: Colors.white,
        foregroundColor: accentColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Video title'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _addPlaceholderImage,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Add image'),
                  style: ElevatedButton.styleFrom(backgroundColor: accentColor),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _generateVideo,
                  child: const Text('Generate video'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: images.isEmpty
                  ? const Center(child: Text('No images added yet'))
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: images.length,
                      itemBuilder: (_, i) =>
                          Image.asset(images[i], fit: BoxFit.cover),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
