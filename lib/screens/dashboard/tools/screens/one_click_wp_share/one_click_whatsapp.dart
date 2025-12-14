// lib/screens/dashboard/tools/one_click_whatsapp.dart
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/screens/dashboard/tools/screens/one_click_wp_share/widgets/message_editor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:share_plus/share_plus.dart';

const Color kAccent = Color(0xFF0BA39A); // New teal accent
const double kRadius = 18.0;

/// One-click WhatsApp page — now with product picker + full message control.
class OneClickWhatsAppPage extends StatefulWidget {
  const OneClickWhatsAppPage({super.key});

  @override
  State<OneClickWhatsAppPage> createState() => _OneClickWhatsAppPageState();
}

class _OneClickWhatsAppPageState extends State<OneClickWhatsAppPage> {
  // Controllers
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  // Selected product
  ProductModel? selectedProduct;

  // Templates
  static const List<String> _defaultTemplates = [
    'Hi! I am sharing a product with you 👇\n\n{product_block}\n\nIf you like it, I can help you place the order 😊',
    'Hey! Check this product:\n\n{product_block}\n\nLet me know your size / color & I will arrange it for you.',
    '🔥 Hot pick of the day 🔥\n\n{product_block}\n\nLimited stock, ping me quickly if you want it!',
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
      _userTemplates
        ..clear()
        ..addAll(stored);
      setState(() {});
    }
  }

  Future<void> _saveTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _userTemplates);
  }

  // ---------------------------------------------------------------------------
  //  PRODUCT HELPERS
  // ---------------------------------------------------------------------------

  // String? get _currentProductLink {
  //   if (selectedProduct == null) return null;
  //   // Generic WooCommerce product link pattern using ID
  //   return '${ApiService.baseUrl}/?post_type=product&p=${selectedProduct!.id}';
  // }

  String _buildProductBlock(ProductModel p) {
    final buffer = StringBuffer();
    buffer.writeln('🛍️ ${p.name}');
    buffer.writeln('💰 Price: ₹${p.price}');
    if (p.discountPercentage != null && p.discountPercentage! > 0) {
      buffer.writeln(
        '✨ Discount: ${p.discountPercentage}% off (MRP ₹${p.regularPrice})',
      );
    }
    if (p.brandName != null && p.brandName!.trim().isNotEmpty) {
      buffer.writeln('🏷 Brand: ${p.brandName}');
    }
    if (p.hsnCode != null && p.hsnCode!.trim().isNotEmpty) {
      buffer.writeln('📦 HSN: ${p.hsnCode}');
    }
    if (p.gst != null && p.gst!.trim().isNotEmpty) {
      buffer.writeln('🧾 GST: ${p.gst}');
    }
    // show 1–2 attributes quickly
    if (p.attributes.isNotEmpty) {
      final attrs = p.attributes
          .take(2)
          .map((a) {
            if (a.options.isEmpty) return null;
            final first = a.options.first;
            return '${a.name}: $first';
          })
          .whereType<String>()
          .toList();
      if (attrs.isNotEmpty) {
        buffer.writeln('📌 ${attrs.join(' • ')}');
      }
    }
    //   if (_currentProductLink != null) {
    //     buffer.writeln('\n🔗 Link: ${_currentProductLink}');
    //   }
    return buffer.toString().trim();
  }

  void _applyTemplate(int index) {
    if (index < 0 || index >= _allTemplates.length || selectedProduct == null) {
      return;
    }
    final p = selectedProduct!;
    final productBlock = _buildProductBlock(p);
    String template = _allTemplates[index];

    template = template.replaceAll('{product_block}', productBlock);
    // template = template.replaceAll('{link}', _currentProductLink ?? '');

    setState(() {
      selectedTemplateIndex = index;
      messageController.text = template;
      messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: messageController.text.length),
      );
    });
  }

  // ---------------------------------------------------------------------------
  //  PHONE / WHATSAPP HELPERS
  // ---------------------------------------------------------------------------

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
    if (!sanitized.startsWith('+')) {
      sanitized = '$selectedCountry$sanitized';
    } else {
      sanitized = '+${sanitized.replaceFirst(RegExp(r'^\+'), '')}';
    }
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
      // ignore: use_build_context_synchronously
      context,
    ).showSnackBar(SnackBar(content: Text(successMsg ?? 'Copied')));
  }

  String _buildMessage() => messageController.text.trim();

  // ---------------------------------------------------------------------------
  //  RECIPIENTS
  // ---------------------------------------------------------------------------

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadius),
        ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadius),
        ),
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

  // Insert product link at cursor
  // void _insertProductLink() {
  //   if (selectedProduct == null || _currentProductLink == null) {
  //     _showSnack('Select a product before inserting a link');
  //     return;
  //   }
  //   final link = _currentProductLink!;
  //   final text = messageController.text;
  //   final sel = messageController.selection;
  //   if (sel.isValid && sel.start >= 0) {
  //     final newText = text.replaceRange(sel.start, sel.end, link);
  //     messageController.text = newText;
  //     final pos = sel.start + link.length;
  //     messageController.selection = TextSelection.fromPosition(
  //       TextPosition(offset: pos),
  //     );
  //   } else {
  //     messageController.text = text.isEmpty ? link : '$text\n$link';
  //     messageController.selection = TextSelection.fromPosition(
  //       TextPosition(offset: messageController.text.length),
  //     );
  //   }
  // }

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

  // ---------------------------------------------------------------------------
  //  SENDING
  // ---------------------------------------------------------------------------

  Future<void> _sendToAll() async {
    if (selectedProduct == null) {
      _showSnack('Please select a product first');
      return;
    }
    if (!hasRecipient) {
      _showSnack('Please add at least one recipient');
      return;
    }
    final msg = _buildMessage();
    if (msg.isEmpty) {
      _showSnack('Message is empty – please write or apply a template');
      return;
    }

    final sanitized = recipients
        .where((r) => _sanitizeNumber(r).replaceFirst('+', '').length >= 8)
        .map((r) => _sanitizeNumber(r))
        .toList();

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
    if (selectedProduct == null) {
      _showSnack('Please select a product first');
      return;
    }
    if (!hasRecipient) {
      _showSnack('Please add at least one recipient');
      return;
    }
    final msg = _buildMessage();
    if (msg.isEmpty) {
      _showSnack('Message is empty – please write or apply a template');
      return;
    }

    final sanitized = recipients
        .where((r) => _sanitizeNumber(r).replaceFirst('+', '').length >= 8)
        .map((r) => _sanitizeNumber(r))
        .toList();

    final combined = StringBuffer();
    for (var n in sanitized) {
      combined.writeln(n);
    }
    combined.writeln('\n$msg');

    _copyToClipboard(
      combined.toString(),
      successMsg: 'Recipients & message copied',
    );
    final opened = await openPlainTextInWhatsApp(msg);
    _showSnack(
      opened
          ? 'WhatsApp opened — paste into chats'
          : 'Could not open WhatsApp. Message copied to clipboard.',
    );
  }

  /// Share **product image + caption text together** via share sheet (WhatsApp etc.).
  Future<void> _shareImageWithCaption() async {
    if (selectedProduct == null) {
      _showSnack('Please select a product first');
      return;
    }

    final caption = _buildMessage().isNotEmpty
        ? _buildMessage()
        : _buildProductBlock(selectedProduct!);

    if (caption.trim().isEmpty) {
      _showSnack('Message is empty – please write or apply a template');
      return;
    }

    if (selectedProduct!.image.isEmpty) {
      // No image – fallback to text-only share
      final opened = await openPlainTextInWhatsApp(caption);
      _showSnack(
        opened
            ? 'WhatsApp opened with text only (no image available).'
            : 'Could not open WhatsApp – text copied.',
      );
      return;
    }

    try {
      final XFile file = await ApiService.downloadImageAsFile(
        selectedProduct!.image,
      );

      await Share.shareXFiles([file], text: caption);
      // Note: this opens the native share sheet; user selects WhatsApp/chat.
    } catch (e) {
      _showSnack('Could not prepare image share: $e');
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ---------------------------------------------------------------------------
  //  PRODUCT PICKER
  // ---------------------------------------------------------------------------

  Future<void> _openProductPicker() async {
    final ProductModel? picked = await showModalBottomSheet<ProductModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _ProductPickerSheet(),
    );

    if (picked != null) {
      setState(() {
        selectedProduct = picked;
        selectedTemplateIndex = -1;
      });

      // If message is empty, auto-generate a default block for editing
      if (messageController.text.trim().isEmpty) {
        final block = _buildProductBlock(picked);
        final defaultMsg =
            'Hi 👋\n\nI am sharing this product with you:\n\n$block\n\nIf you like it, I can help you place the order.';
        messageController.text = defaultMsg;
        messageController.selection = TextSelection.fromPosition(
          TextPosition(offset: messageController.text.length),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  //  UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final builtMessage = _buildMessage();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Iconsax.message, color: kAccent),
            ),
            const SizedBox(width: 10),
            const Text(
              'WhatsApp Blast',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final availableH = constraints.maxHeight;
          final isCompact = availableH.isFinite && availableH < 260;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Product selection card
                  _SelectedProductCard(
                    product: selectedProduct,
                    onTap: _openProductPicker,
                  ),

                  const SizedBox(height: 14),

                  // 2. Recipients input
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

                  // 3. Recipients list / compact
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
                        maxHeight: math
                            .min(availableH * 0.38, 320.0)
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

                  const SizedBox(height: 14),

                  // 4. Message editor
                  MessageEditor(
                    messageController: messageController,
                    templates: _allTemplates,
                    onSaveTemplate: _saveMessageAsTemplate,
                    onSelectTemplate: (i) => _applyTemplate(i),
                    // link removed from editor as requested
                  ),

                  const SizedBox(height: 12),

                  // 5. Preview + actions
                  _PreviewActions(
                    previewText: builtMessage,
                    isSending: isSending,
                    onSendToAll: _sendToAll,
                    onCopyAllAndOpen: _copyAllAndOpen,
                    onSendSequentially: () async => await _sendToAll(),
                    onShareImage: _shareImageWithCaption,
                    onCopyPreview: builtMessage.isEmpty
                        ? null
                        : () => _copyToClipboard(
                            builtMessage,
                            successMsg: 'Message copied',
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Full recipients sheet for compact mode
  void _showFullRecipientSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          builder: (c, ctrl) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
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

// ============================================================================
//  SMALL UI WIDGETS
// ============================================================================

/// Product selection / summary card.
class _SelectedProductCard extends StatelessWidget {
  final ProductModel? product;
  final VoidCallback onTap;

  const _SelectedProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool hasProduct = product != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0BA39A), Color(0xFF10B981)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: hasProduct && product!.image.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        product!.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Iconsax.image, color: Colors.white),
                      ),
                    )
                  : const Icon(
                      Iconsax.bag_happy,
                      color: Colors.white,
                      size: 26,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: hasProduct
                    ? Column(
                        key: const ValueKey('selected'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Price: ₹${product!.price}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                          ),
                          if (product!.brandName != null &&
                              product!.brandName!.trim().isNotEmpty)
                            Text(
                              product!.brandName!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 11,
                              ),
                            ),
                        ],
                      )
                    : Column(
                        key: const ValueKey('empty'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select product to share',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pick a product and we will auto-fill a WhatsApp message for you.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Icon(
                    hasProduct ? Iconsax.refresh : Iconsax.add_circle,
                    size: 18,
                    color: const Color(0xFF0BA39A),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasProduct ? 'Change' : 'Choose',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF0BA39A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Recipient input row.
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
      elevation: 3,
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
      elevation: 1,
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

/// Preview & actions card.
class _PreviewActions extends StatelessWidget {
  final String previewText;
  final bool isSending;
  final Future<void> Function() onSendToAll;
  final Future<void> Function() onCopyAllAndOpen;
  final Future<void> Function() onSendSequentially;
  final Future<void> Function() onShareImage;
  final VoidCallback? onCopyPreview;

  const _PreviewActions({
    required this.previewText,
    required this.isSending,
    required this.onSendToAll,
    required this.onCopyAllAndOpen,
    required this.onSendSequentially,
    required this.onShareImage,
    required this.onCopyPreview,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasText = previewText.trim().isNotEmpty;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: kAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.visibility_rounded,
                    size: 18,
                    color: kAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Message preview',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasText
                            ? 'This is what will be sent to your customers.'
                            : 'Type a message or apply a template to preview.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasText)
                  TextButton.icon(
                    onPressed: onCopyPreview,
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // WhatsApp-style bubble preview + tiny meta
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F5F4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kAccent.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasText)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: kAccent,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Customer will see:',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${previewText.length} chars',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  if (hasText) const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      hasText
                          ? previewText
                          : 'Message preview will appear here once you type or apply a template.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade900,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Primary actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Row 1: send + copy&open
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
                        label: const Text('Send to all (text)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onCopyAllAndOpen(),
                        icon: const Icon(Icons.copy_all_rounded, size: 18),
                        label: const Text('Copy & open'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Row 2: share image + sequential
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onShareImage(),
                        icon: const Icon(Icons.image_rounded, size: 18),
                        label: const Text('Share image + text'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: kAccent.withValues(alpha: 0.6),
                          ),
                          foregroundColor: kAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => onSendSequentially(),
                        icon: const Icon(Icons.playlist_play_rounded, size: 20),
                        label: const Text('Send sequentially'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Tiny helper text
            Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '“Send to all” opens chats one by one with text. '
                    'Use “Share image + text” to send product photo and caption together via share sheet.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
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

// ============================================================================
//  PRODUCT PICKER SHEET
// ============================================================================

class _ProductPickerSheet extends StatefulWidget {
  // ignore: use_super_parameters
  const _ProductPickerSheet({Key? key}) : super(key: key);

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ProductModel> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _hasMore = true;
      _page = 1;
      _products.clear();
    });

    try {
      final items = _query.isEmpty
          ? await ApiService.fetchProducts(page: _page, perPage: 20)
          : await ApiService.searchProducts(_query);

      setState(() {
        _products = items;
        _isLoading = false;
        _hasMore = _query.isEmpty && items.length == 20;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load products: $e')));
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _query.isNotEmpty) return;

    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _page + 1;
      final items = await ApiService.fetchProducts(page: nextPage, perPage: 20);
      setState(() {
        _page = nextPage;
        _products.addAll(items);
        _hasMore = items.length == 20;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels > pos.maxScrollExtent * 0.7) {
      _loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _query = value.trim();
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(Iconsax.bag_2),
                  const SizedBox(width: 8),
                  const Text(
                    'Pick a product',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Iconsax.search_normal),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _products.isEmpty
                  ? Center(
                      child: Text(
                        'No products found',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _products.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (ctx, idx) {
                        if (idx >= _products.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        final p = _products[idx];
                        return _ProductTile(
                          product: p,
                          onTap: () => Navigator.pop(context, p),
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

class _ProductTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _ProductTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasDiscount =
        product.discountPercentage != null && product.discountPercentage! > 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.grey.shade200,
                  width: 64,
                  height: 64,
                  child: product.image.isNotEmpty
                      ? Image.network(
                          product.image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Iconsax.image),
                        )
                      : const Icon(Iconsax.image),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '₹${product.price}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (hasDiscount)
                          Text(
                            '₹${product.regularPrice}',
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey.shade500,
                              fontSize: 11,
                            ),
                          ),
                        if (hasDiscount) const SizedBox(width: 4),
                        if (hasDiscount)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '-${product.discountPercentage}%',
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (product.brandName != null &&
                        product.brandName!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          product.brandName!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Iconsax.arrow_right_3, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
