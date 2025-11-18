// lib/screens/dashboard/tools/widgets/recipient_list.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/services.dart';

// If you use utility functions from elsewhere (sanitizeNumber/openChatForNumber),
// import them here. Adjust path as needed.
// import '../../screens/one_click_wp_share/utils.dart';

typedef OnLongPressActions = void Function(int idx, String sanitized);

class RecipientList extends StatelessWidget {
  final List<String> recipients;
  final String selectedCountry;
  final void Function(int) onEdit;
  final void Function(int) onRemove;
  final OnLongPressActions onLongPressActions;
  final VoidCallback onCopyAll;
  final VoidCallback onPickFromContacts;
  final VoidCallback onClear;

  const RecipientList({
    super.key,
    required this.recipients,
    required this.selectedCountry,
    required this.onEdit,
    required this.onRemove,
    required this.onLongPressActions,
    required this.onCopyAll,
    required this.onPickFromContacts,
    required this.onClear,
  });

  static const double _compactThreshold =
      120.0; // if available height < this => compact mode

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final bounded = constraints.maxHeight.isFinite;
            final smallSpace =
                bounded && constraints.maxHeight < _compactThreshold;

            final header = Row(
              children: [
                const Icon(Icons.group_rounded),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recipients',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Pick from contacts',
                  icon: const Icon(Icons.person_add_rounded),
                  onPressed: onPickFromContacts,
                ),
                if (recipients.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${recipients.length} added',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
              ],
            );

            final footer = Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.56,
                  child: OutlinedButton.icon(
                    onPressed: recipients.isEmpty ? null : onCopyAll,
                    icon: const Icon(Icons.copy_all_rounded),
                    label: const Text('Copy recipients'),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.3,
                  child: OutlinedButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.clear_rounded),
                    label: const Text('Clear'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            );

            // Compact mode: show header + a "View list" button that opens bottom sheet (no overflow risk)
            if (smallSpace) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  header,
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          recipients.isEmpty
                              ? 'No recipients yet'
                              : 'Tap to view recipients',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showFullListSheet(context),
                        icon: const Icon(Icons.visibility_rounded),
                        label: const Text('View'),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  footer,
                ],
              );
            }

            // Normal (enough space) mode: header + Expanded ListView + footer
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const SizedBox(height: 10),
                // Let the list expand and scroll inside the available space
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: recipients.isEmpty
                        ? Center(
                            child: Text(
                              'No recipients yet — add numbers or pick from contacts',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: recipients.length,
                            itemBuilder: (ctx, idx) => _recipientTile(ctx, idx),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                footer,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _recipientTile(BuildContext context, int idx) {
    final raw = recipients[idx];
    // NOTE: replace sanitizeNumber/openChatForNumber with your utils import if available.
    final sanitized = raw; // sanitizeNumber(raw, selectedCountry);
    final valid = sanitized.replaceFirst('+', '').length >= 8;

    return Dismissible(
      key: Key(sanitized + idx.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(idx),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete_forever, color: Colors.white),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: valid ? const Color(0xFFEB2A7E) : Colors.red,
          child: Text(
            valid ? '${idx + 1}' : '!',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          sanitized,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          valid ? 'Tap to edit • Long press for actions' : 'Invalid number',
          style: TextStyle(color: valid ? Colors.grey : Colors.red),
        ),
        onTap: () => onEdit(idx),
        onLongPress: () => onLongPressActions(idx, sanitized),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Copy number',
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: sanitized)),
              icon: const Icon(Icons.copy_rounded),
              color: Colors.grey.shade700,
            ),
            IconButton(
              tooltip: 'Open chat',
              onPressed: valid
                  ? () {
                      /* openChatForNumber(sanitized, '') */
                    }
                  : null,
              icon: const Icon(Iconsax.message),
              color: valid ? Colors.green : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  void _showFullListSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        builder: (context, scrollCtrl) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.group_rounded),
                  const SizedBox(width: 8),
                  Text(
                    'Recipients',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${recipients.length} added',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: recipients.isEmpty
                    ? Center(
                        child: Text(
                          'No recipients yet',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollCtrl,
                        itemCount: recipients.length,
                        itemBuilder: (ctx, idx) => _recipientTile(ctx, idx),
                      ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: recipients.isEmpty ? null : onCopyAll,
                      icon: const Icon(Icons.copy_all_rounded),
                      label: const Text('Copy'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.clear_rounded),
                    label: const Text('Clear'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
