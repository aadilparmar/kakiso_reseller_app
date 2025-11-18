// lib/screens/dashboard/tools/one_click_whatsapp.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'widgets/message_editor.dart';

const Color kAccent = Color(0xFFEB2A7E);
const double kRadius = 14.0;

/// One-click WhatsApp page — responsive & defensive layout (no RenderFlex overflow).
class OneClickWhatsAppPage extends StatefulWidget {
  const OneClickWhatsAppPage({super.key});

  @override
  State<OneClickWhatsAppPage> createState() => _OneClickWhatsAppPageState();
}

class _OneClickWhatsAppPageState extends State<OneClickWhatsAppPage> {
  // Controllers
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  // Templates
  static const List<String> _defaultTemplates = [
    'Hello! I am interested in this product. Can you give more details?',
    'Hey! I want to order this. Please share stock & delivery time.',
    '🔥 New arrival! Check this out: {link}',
  ];
  final List<String> _userTemplates = [];
  List<String> get _allTemplates =>
      List.unmodifiable([..._defaultTemplates, ..._userTemplates]);
  static const String _prefsKey = 'wa_user_templates';
  int selectedTemplateIndex = -1;

  // Recipients
  final List<String> recipients = [];

  // Misc
  bool isSending = false;
  final String sampleProductLink = 'https://kakiso.example.com/product/123';
  final FlutterNativeContactPicker nativePicker = FlutterNativeContactPicker();

  // Country codes
  final List<Map<String, String>> countryCodes = [
    {'label': 'IN', 'code': '+91'},
    {'label': 'US', 'code': '+1'},
    {'label': 'UK', 'code': '+44'},
    {'label': 'AU', 'code': '+61'},
  ];
  String selectedCountry = '+91';

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList(_prefsKey);
    if (stored != null) {
      _userTemplates.clear();
      _userTemplates.addAll(stored);
      setState(() {});
    }
  }

  Future<void> _saveTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _userTemplates);
  }

  // --------------------- Utilities ---------------------
  String _sanitizeNumber(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final buffer = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      final ch = trimmed[i];
      if (ch == '+' && i == 0) {
        buffer.write(ch);
        continue;
      }
      if (RegExp(r'\d').hasMatch(ch)) buffer.write(ch);
    }
    var sanitized = buffer.toString();
    if (sanitized.isEmpty) return '';
    if (!sanitized.startsWith('+'))
      sanitized = '$selectedCountry$sanitized';
    else
      sanitized = '+${sanitized.replaceFirst(RegExp(r'^\+'), '')}';
    return sanitized;
  }

  String _normalizeForWa(String sanitized) => sanitized.replaceFirst('+', '');

  Future<bool> _tryOpenUri(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      return false;
    }
  }

  Future<bool> openChatForNumber(String sanitizedNumber, String message) async {
    final n = _normalizeForWa(sanitizedNumber);
    final encoded = Uri.encodeComponent(message);
    final whatsappUri = Uri.parse('whatsapp://send?phone=$n&text=$encoded');
    final waMeUri = Uri.parse('https://wa.me/$n?text=$encoded');
    bool opened = await _tryOpenUri(whatsappUri);
    if (!opened) opened = await _tryOpenUri(waMeUri);
    return opened;
  }

  Future<bool> openPlainTextInWhatsApp(String message) async {
    final encoded = Uri.encodeComponent(message);
    final appUri = Uri.parse('whatsapp://send?text=$encoded');
    final webUri = Uri.parse('https://web.whatsapp.com/send?text=$encoded');
    bool opened = await _tryOpenUri(appUri);
    if (!opened) opened = await _tryOpenUri(webUri);
    return opened;
  }

  bool get hasRecipient => recipients
      .where((r) => _sanitizeNumber(r).replaceFirst('+', '').length >= 8)
      .isNotEmpty;

  void _copyToClipboard(String txt, {String? successMsg}) async {
    await Clipboard.setData(ClipboardData(text: txt));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(successMsg ?? 'Copied')));
  }

  String _buildMessage() {
    if (selectedTemplateIndex >= 0 &&
        selectedTemplateIndex < _allTemplates.length) {
      var msg = _allTemplates[selectedTemplateIndex];
      if (msg.contains('{link}'))
        msg = msg.replaceAll('{link}', sampleProductLink);
      return msg;
    }
    return messageController.text.trim();
  }

  // --------------------- Recipients actions ---------------------
  void _addQuickPhone() {
    final raw = phoneController.text.trim();
    final sanitized = _sanitizeNumber(raw);
    if (sanitized.isEmpty || sanitized.replaceFirst('+', '').length < 8) {
      _showSnack('Enter a valid phone number (at least 8 digits)');
      return;
    }
    setState(() {
      recipients.add(sanitized);
      phoneController.clear();
    });
  }

  Future<void> _pickContactAndAdd() async {
    try {
      final contact = await nativePicker.selectPhoneNumber();
      if (contact == null) return;
      final maybePhone =
          contact.selectedPhoneNumber ??
          (contact.phoneNumbers?.isNotEmpty == true
              ? contact.phoneNumbers!.first
              : null);
      if (maybePhone == null || maybePhone.isEmpty) {
        _showSnack('No phone number found for selected contact');
        return;
      }
      final sanitized = _sanitizeNumber(maybePhone);
      if (sanitized.replaceFirst('+', '').length < 8) {
        _showSnack('Selected number is not valid');
        return;
      }
      setState(() => recipients.add(sanitized));
    } catch (e) {
      _showSnack('Failed to pick contact (permission or canceled)');
    }
  }

  void _editRecipientAt(int index) {
    final current = recipients[index];
    String display = current;
    if (display.startsWith('+')) display = display.substring(1);
    final ctrl = TextEditingController(text: display);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit recipient'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: 'e.g. 9876543210 or +919876543210',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newVal = _sanitizeNumber(ctrl.text);
              if (newVal.isEmpty || newVal.replaceFirst('+', '').length < 8) {
                _showSnack('Enter a valid phone number');
                return;
              }
              setState(() => recipients[index] = newVal);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearRecipients() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all recipients?'),
        content: const Text(
          'This will remove all recipients from the list. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => recipients.clear());
      _showSnack('Recipients cleared');
    }
  }

  // Insert link into message at cursor
  void _insertSampleLink() {
    final link = sampleProductLink;
    final text = messageController.text;
    final sel = messageController.selection;
    if (sel.isValid && sel.start >= 0) {
      final newText = text.replaceRange(sel.start, sel.end, link);
      messageController.text = newText;
      final pos = sel.start + link.length;
      messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: pos),
      );
    } else {
      messageController.text = text.isEmpty ? link : '$text\n$link';
      messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: messageController.text.length),
      );
    }
    setState(() => selectedTemplateIndex = -1);
  }

  Future<void> _saveMessageAsTemplate() async {
    final t = messageController.text.trim();
    if (t.isEmpty) {
      _showSnack('Cannot save an empty message');
      return;
    }
    setState(() => _userTemplates.insert(0, t));
    await _saveTemplates();
    _showSnack('Template saved');
    setState(() => messageController.clear());
  }

  // Send to all recipients — opens a chat for each contact (user must send in WhatsApp)
  Future<void> _sendToAll() async {
    if (!hasRecipient) {
      _showSnack('Please add at least one recipient');
      return;
    }
    final sanitized = recipients
        .where((r) => _sanitizeNumber(r).replaceFirst('+', '').length >= 8)
        .map((r) => _sanitizeNumber(r))
        .toList();
    final msg = _buildMessage();
    setState(() => isSending = true);
    bool anyFailed = false;
    for (var n in sanitized) {
      final ok = await openChatForNumber(n, msg);
      if (!ok) {
        anyFailed = true;
        _showSnack('Could not open WhatsApp for $n');
      }
      await Future.delayed(const Duration(milliseconds: 700));
    }
    setState(() => isSending = false);
    _showSnack(
      anyFailed
          ? 'Finished with some failures'
          : 'Opened chats for all recipients',
    );
  }

  Future<void> _copyAllAndOpen() async {
    if (!hasRecipient) {
      _showSnack('Please add at least one recipient');
      return;
    }
    final sanitized = recipients
        .where((r) => _sanitizeNumber(r).replaceFirst('+', '').length >= 8)
        .map((r) => _sanitizeNumber(r))
        .toList();
    final msg = _buildMessage();
    final combined = StringBuffer();
    for (var n in sanitized) combined.writeln(n);
    combined.writeln('\n$msg');
    _copyToClipboard(
      combined.toString(),
      successMsg: 'Recipients & message copied',
    );
    final opened = await openPlainTextInWhatsApp(msg);
    _showSnack(
      opened
          ? 'WhatsApp opened — paste into chats'
          : 'Could not open WhatsApp app. Message copied to clipboard.',
    );
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // --------------------- UI ---------------------
  @override
  Widget build(BuildContext context) {
    final builtMessage = _buildMessage();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'One-click WhatsApp',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: kAccent,
        actions: [
          IconButton(
            tooltip: 'Pick contact',
            onPressed: _pickContactAndAdd,
            icon: const Icon(Icons.person_search_rounded),
            color: kAccent,
          ),
          IconButton(
            tooltip: 'Clear recipients',
            onPressed: recipients.isEmpty ? null : _confirmClearRecipients,
            icon: const Icon(Icons.clear_all_rounded),
            color: recipients.isEmpty ? Colors.grey : kAccent,
          ),
        ],
      ),
      // LayoutBuilder allows us to react to available height (keyboard, small parent, etc.)
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final availableH = constraints.maxHeight;
          final compactThreshold =
              220.0; // if available height < this, switch to compact layout
          final isCompact =
              availableH.isFinite && availableH < compactThreshold;

          // Page content — use SingleChildScrollView so on very small screens everything can scroll
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Recipient input (responsive)
                  _RecipientInput(
                    countryCodes: countryCodes,
                    selectedCountry: selectedCountry,
                    onCountryChanged: (c) =>
                        setState(() => selectedCountry = c),
                    phoneController: phoneController,
                    onAdd: _addQuickPhone,
                    onPickFromContacts: _pickContactAndAdd,
                  ),

                  const SizedBox(height: 12),

                  // Recipients area
                  if (isCompact)
                    _CompactRecipientCard(
                      recipients: recipients,
                      onViewList: () => _showFullRecipientSheet(context),
                      onCopyAll: () {
                        final combined = recipients.join('\n');
                        _copyToClipboard(
                          combined,
                          successMsg: 'Recipients copied',
                        );
                      },
                      onClear: _confirmClearRecipients,
                      count: recipients.length,
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        // limit height so message editor stays reachable
                        maxHeight: math
                            .min(availableH * 0.45, 420.0)
                            .toDouble(),
                      ),
                      child: _ExpandedRecipientCard(
                        recipients: recipients,
                        selectedCountry: selectedCountry,
                        onEdit: _editRecipientAt,
                        onRemove: (i) => setState(() => recipients.removeAt(i)),
                        onLongPressActions: (i, s) =>
                            _showRecipientActions(i, s),
                        onCopyAll: () {
                          final combined = recipients.join('\n');
                          _copyToClipboard(
                            combined,
                            successMsg: 'Recipients copied',
                          );
                        },
                        onPickFromContacts: _pickContactAndAdd,
                        onClear: _confirmClearRecipients,
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Message editor (external widget file)
                  MessageEditor(
                    messageController: messageController,
                    templates: _allTemplates,
                    onInsertLink: _insertSampleLink,
                    onSaveTemplate: _saveMessageAsTemplate,
                    onSelectTemplate: (i) {
                      setState(() {
                        selectedTemplateIndex = i;
                        messageController.text = _buildMessage();
                      });
                    },
                    // optional: onDeleteTemplate callback could be added to MessageEditor if you want
                  ),

                  const SizedBox(height: 12),

                  // Preview + Actions
                  _PreviewActions(
                    previewText: builtMessage,
                    isSending: isSending,
                    onSendToAll: _sendToAll,
                    onCopyAllAndOpen: _copyAllAndOpen,
                    onSendSequentially: () async => await _sendToAll(),
                    onCopyPreview: builtMessage.isEmpty
                        ? null
                        : () => _copyToClipboard(
                            builtMessage,
                            successMsg: 'Message copied',
                          ),
                  ),

                  const SizedBox(height: 18),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Show full list in bottom sheet (used by compact mode)
  void _showFullRecipientSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          builder: (c, ctrl) => Padding(
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
                          controller: ctrl,
                          itemCount: recipients.length,
                          itemBuilder: (ctx, idx) => _recipientTile(ctx, idx),
                        ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: recipients.isEmpty
                            ? null
                            : () => _copyToClipboard(
                                recipients.join('\n'),
                                successMsg: 'Copied',
                              ),
                        icon: const Icon(Icons.copy_all_rounded),
                        label: const Text('Copy'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _confirmClearRecipients,
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
      ),
    );
  }

  Widget _recipientTile(BuildContext context, int idx) {
    final raw = recipients[idx];
    final sanitized = _sanitizeNumber(raw);
    final valid = sanitized.replaceFirst('+', '').length >= 8;
    return Dismissible(
      key: Key(sanitized + idx.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => setState(() => recipients.removeAt(idx)),
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
          backgroundColor: valid ? kAccent : Colors.red,
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
        onTap: () => _editRecipientAt(idx),
        onLongPress: () => _showRecipientActions(idx, sanitized),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Copy number',
              onPressed: () =>
                  _copyToClipboard(sanitized, successMsg: 'Copied number'),
              icon: const Icon(Icons.copy_rounded),
              color: Colors.grey.shade700,
            ),
            IconButton(
              tooltip: 'Open chat',
              onPressed: valid
                  ? () => openChatForNumber(sanitized, _buildMessage())
                  : null,
              icon: const Icon(Iconsax.message),
              color: valid ? Colors.green : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  void _showRecipientActions(int idx, String number) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy number'),
              onTap: () {
                Navigator.pop(ctx);
                _copyToClipboard(number, successMsg: 'Copied number');
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.message),
              title: const Text('Open chat'),
              onTap: () {
                Navigator.pop(ctx);
                openChatForNumber(number, _buildMessage());
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(ctx);
                _editRecipientAt(idx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => recipients.removeAt(idx));
                _showSnack('Recipient removed');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    messageController.dispose();
    super.dispose();
  }
}

// --------------------- Small internal widgets (keeps file tidy) ---------------------

/// Responsive recipient input row.
class _RecipientInput extends StatelessWidget {
  final List<Map<String, String>> countryCodes;
  final String selectedCountry;
  final ValueChanged<String> onCountryChanged;
  final TextEditingController phoneController;
  final VoidCallback onAdd;
  final VoidCallback onPickFromContacts;

  const _RecipientInput({
    required this.countryCodes,
    required this.selectedCountry,
    required this.onCountryChanged,
    required this.phoneController,
    required this.onAdd,
    required this.onPickFromContacts,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final isNarrow = constraints.maxWidth < 420;
            if (isNarrow) {
              return Row(
                children: [
                  DropdownButtonHideUnderline(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: DropdownButton<String>(
                        value: selectedCountry,
                        items: countryCodes
                            .map(
                              (c) => DropdownMenuItem(
                                value: c['code'],
                                child: Text(
                                  c['label']!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            v == null ? null : onCountryChanged(v),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        hintText: 'Enter phone number',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_call),
                    tooltip: 'Add',
                    color: kAccent,
                  ),
                  IconButton(
                    onPressed: onPickFromContacts,
                    icon: const Icon(Icons.person_add_rounded),
                    tooltip: 'From contacts',
                    color: Colors.black54,
                  ),
                ],
              );
            } else {
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCountry,
                        items: countryCodes
                            .map(
                              (c) => DropdownMenuItem(
                                value: c['code'],
                                child: Row(
                                  children: [
                                    Text(
                                      c['label']!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      c['code']!,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            v == null ? null : onCountryChanged(v),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        hintText: 'Enter phone number',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IntrinsicWidth(
                    child: ElevatedButton(
                      onPressed: onAdd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Text(
                          'Add',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onPickFromContacts,
                    icon: const Icon(Icons.person_add_rounded),
                    label: const Text('From contacts'),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}

/// Compact recipient card for tiny screens.
class _CompactRecipientCard extends StatelessWidget {
  final List<String> recipients;
  final VoidCallback onViewList;
  final VoidCallback onCopyAll;
  final VoidCallback onClear;
  final int count;

  const _CompactRecipientCard({
    required this.recipients,
    required this.onViewList,
    required this.onCopyAll,
    required this.onClear,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.group_rounded),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recipients',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (count > 0)
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
                      '$count added',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
              ],
            ),
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
                  onPressed: onViewList,
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: recipients.isEmpty ? null : onCopyAll,
                    icon: const Icon(Icons.copy_all_rounded),
                    label: const Text('Copy recipients'),
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
          ],
        ),
      ),
    );
  }
}

/// Expanded recipient card showing list.
class _ExpandedRecipientCard extends StatelessWidget {
  final List<String> recipients;
  final String selectedCountry;
  final void Function(int) onEdit;
  final void Function(int) onRemove;
  final void Function(int, String) onLongPressActions;
  final VoidCallback onCopyAll;
  final VoidCallback onPickFromContacts;
  final VoidCallback onClear;

  const _ExpandedRecipientCard({
    required this.recipients,
    required this.selectedCountry,
    required this.onEdit,
    required this.onRemove,
    required this.onLongPressActions,
    required this.onCopyAll,
    required this.onPickFromContacts,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.group_rounded),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recipients',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
            ),
            const SizedBox(height: 10),
            Expanded(
              child: recipients.isEmpty
                  ? Center(
                      child: Text(
                        'No recipients yet — add numbers or pick from contacts',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.builder(
                      itemCount: recipients.length,
                      itemBuilder: (ctx, idx) {
                        final raw = recipients[idx];
                        final sanitized = raw;
                        final valid =
                            sanitized.replaceFirst('+', '').length >= 8;
                        return Dismissible(
                          key: Key(sanitized + idx.toString()),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => onRemove(idx),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 18),
                            color: Colors.red.shade400,
                            child: const Icon(
                              Icons.delete_forever,
                              color: Colors.white,
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: valid ? kAccent : Colors.red,
                              child: Text(
                                valid ? '${idx + 1}' : '!',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              sanitized,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              valid
                                  ? 'Tap to edit • Long press for actions'
                                  : 'Invalid number',
                              style: TextStyle(
                                color: valid ? Colors.grey : Colors.red,
                              ),
                            ),
                            onTap: () => onEdit(idx),
                            onLongPress: () =>
                                onLongPressActions(idx, sanitized),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Copy number',
                                  onPressed: () => Clipboard.setData(
                                    ClipboardData(text: sanitized),
                                  ),
                                  icon: const Icon(Icons.copy_rounded),
                                  color: Colors.grey.shade700,
                                ),
                                IconButton(
                                  tooltip: 'Open chat',
                                  onPressed: valid
                                      ? () => _openWhatsAppChat(sanitized)
                                      : null,
                                  icon: const Icon(Iconsax.message),
                                  color: valid ? Colors.green : Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: recipients.isEmpty ? null : onCopyAll,
                    icon: const Icon(Icons.copy_all_rounded),
                    label: const Text('Copy recipients'),
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
          ],
        ),
      ),
    );
  }

  static Future<void> _openWhatsAppChat(String sanitized) async {
    final n = sanitized.replaceFirst('+', '');
    final uri = Uri.parse('whatsapp://send?phone=$n');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        final web = Uri.parse('https://wa.me/$n');
        await launchUrl(web, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}

/// Preview & actions card (keeps code tidy).
class _PreviewActions extends StatelessWidget {
  final String previewText;
  final bool isSending;
  final Future<void> Function() onSendToAll;
  final Future<void> Function() onCopyAllAndOpen;
  final Future<void> Function() onSendSequentially;
  final VoidCallback? onCopyPreview;

  const _PreviewActions({
    required this.previewText,
    required this.isSending,
    required this.onSendToAll,
    required this.onCopyAllAndOpen,
    required this.onSendSequentially,
    required this.onCopyPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
      ),
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
                Expanded(
                  child: Text(
                    'Preview',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
                    onPressed: isSending ? null : () => onSendToAll(),
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
                      backgroundColor: kAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => onCopyAllAndOpen(),
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
              onPressed: () => onSendSequentially(),
              icon: const Icon(Icons.playlist_play_rounded),
              label: const Text('Send sequentially'),
            ),
          ],
        ),
      ),
    );
  }
}
