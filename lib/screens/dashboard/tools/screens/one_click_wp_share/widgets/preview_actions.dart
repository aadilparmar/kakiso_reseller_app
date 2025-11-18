// lib/screens/dashboard/tools/widgets/preview_actions.dart
import 'package:flutter/material.dart';

class PreviewActions extends StatelessWidget {
  final String previewText;
  final bool isSending;
  final VoidCallback onSendToAll;
  final VoidCallback onCopyAllAndOpen;
  final VoidCallback onSendSequentially;
  final VoidCallback? onCopyPreview;

  const PreviewActions({
    super.key,
    required this.previewText,
    required this.isSending,
    required this.onSendToAll,
    required this.onCopyAllAndOpen,
    required this.onSendSequentially,
    this.onCopyPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.visibility_rounded),
                const SizedBox(width: 8),
                Text(
                  'Preview',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (previewText.isNotEmpty)
                  TextButton.icon(
                    onPressed: onCopyPreview,
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                previewText.isEmpty
                    ? 'Message preview will appear here'
                    : previewText,
                style: TextStyle(color: Colors.grey.shade800),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isSending ? null : onSendToAll,
                    icon: isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: const Text('Send to all'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEB2A7E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: isSending ? null : onCopyAllAndOpen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.copy_all_rounded, color: Colors.black54),
                      SizedBox(width: 6),
                      Text(
                        'Copy & Open',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: isSending ? null : onSendSequentially,
              icon: const Icon(Icons.playlist_play_rounded),
              label: const Text('Send sequentially'),
            ),
          ],
        ),
      ),
    );
  }
}
