// lib/screens/dashboard/tools/widgets/message_editor.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A richer MessageEditor with:
/// - collapsible templates (tap to apply, long-press for actions)
/// - formatting toolbar (bold, italic, code, bullet, numbered)
/// - emoji picker, insert link, save template callback
/// - undo/redo (simple history stack)
/// - autosave draft to SharedPreferences (debounced)
/// - preview bottom sheet with copy
///
/// Backwards-compatible: existing params still required.
/// Optional:
///  - onDeleteTemplate(index) -> parent may remove saved template if provided.
///  - draftPrefsKey -> custom SharedPreferences key for autosave.
class MessageEditor extends StatefulWidget {
  final TextEditingController messageController;
  final List<String> templates;
  final VoidCallback onInsertLink;
  final VoidCallback onSaveTemplate;
  final ValueChanged<int> onSelectTemplate;

  // optional
  final ValueChanged<int>? onDeleteTemplate;
  final String draftPrefsKey;

  const MessageEditor({
    super.key,
    required this.messageController,
    required this.templates,
    required this.onInsertLink,
    required this.onSaveTemplate,
    required this.onSelectTemplate,
    this.onDeleteTemplate,
    this.draftPrefsKey = 'wa_message_draft',
  });

  @override
  State<MessageEditor> createState() => _MessageEditorState();
}

class _MessageEditorState extends State<MessageEditor>
    with SingleTickerProviderStateMixin {
  bool _templatesOpen = false;
  int _selectedTemplate = -1;
  late final FocusNode _focus;
  static const int _softLimit = 300; // soft char limit for UX warning
  static const List<String> _emojiList = [
    '🙂',
    '🎉',
    '🔥',
    '✅',
    '🚚',
    '💬',
    '👍',
    '🙏',
  ];
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  Timer? _autosaveTimer;
  bool _showSavedDraftBadge = false;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    widget.messageController.addListener(_onTextChanged);
    _loadDraft();
    // seed undo stack with initial text
    _pushUndo(widget.messageController.text, pushIfSame: false);
  }

  @override
  void dispose() {
    widget.messageController.removeListener(_onTextChanged);
    _focus.dispose();
    _autosaveTimer?.cancel();
    super.dispose();
  }

  // ----------------------- Draft persistence -----------------------
  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draft = prefs.getString(widget.draftPrefsKey);
    if (draft != null &&
        draft.isNotEmpty &&
        draft != widget.messageController.text) {
      // keep but do not overwrite user's current content automatically.
      // show small badge that a draft exists
      setState(() => _showSavedDraftBadge = true);
    }
  }

  Future<void> _applyDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draft = prefs.getString(widget.draftPrefsKey);
    if (draft == null) return;
    widget.messageController.text = draft;
    widget.messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: draft.length),
    );
    _showSnack('Draft loaded');
    _pushUndo(draft);
    setState(() => _showSavedDraftBadge = false);
  }

  Future<void> _saveDraftNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(widget.draftPrefsKey, widget.messageController.text);
    _showSnack('Draft saved');
  }

  Future<void> _clearDraftNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(widget.draftPrefsKey);
    setState(() => _showSavedDraftBadge = false);
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    // debounce 1.2s
    _autosaveTimer = Timer(const Duration(milliseconds: 1200), () {
      _saveDraftNow();
    });
  }

  // ----------------------- Undo / Redo -----------------------
  void _pushUndo(String text, {bool pushIfSame = true}) {
    if (!pushIfSame && _undoStack.isNotEmpty && _undoStack.last == text) return;
    _undoStack.add(text);
    if (_undoStack.length > 20) _undoStack.removeAt(0); // cap
    // clear redo on new edit
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.length < 2) return;
    final last = _undoStack.removeLast();
    _redoStack.add(last);
    final prev = _undoStack.last;
    widget.messageController.text = prev;
    widget.messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: prev.length),
    );
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    final next = _redoStack.removeLast();
    _pushUndo(next);
    widget.messageController.text = next;
    widget.messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: next.length),
    );
  }

  // ----------------------- Text changes -----------------------
  void _onTextChanged() {
    // detect if text differs from selected template
    if (_selectedTemplate != -1) {
      final t =
          (_selectedTemplate >= 0 &&
              _selectedTemplate < widget.templates.length)
          ? widget.templates[_selectedTemplate]
          : null;
      if (t == null || widget.messageController.text.trim() != t.trim()) {
        setState(() => _selectedTemplate = -1);
      }
    }
    _pushUndo(widget.messageController.text);
    // schedule autosave
    _scheduleAutosave();
    setState(() {}); // update char counts / progress
  }

  // ----------------------- UI helpers -----------------------
  String _shorten(String s, [int max = 80]) {
    if (s.length <= max) return s;
    return s.substring(0, max - 3) + '...';
  }

  void _tapTemplate(int i) {
    if (i < 0 || i >= widget.templates.length) return;
    final t = widget.templates[i];
    setState(() {
      _selectedTemplate = i;
      widget.messageController.text = t;
      widget.messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: t.length),
      );
      widget.onSelectTemplate(i);
    });
    _focus.requestFocus();
  }

  void _longPressTemplate(int i) {
    if (i < 0 || i >= widget.templates.length) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded),
              title: const Text('Use template'),
              onTap: () {
                Navigator.pop(ctx);
                _tapTemplate(i);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy template'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: widget.templates[i]));
                Navigator.pop(ctx);
                _showSnack('Template copied');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded),
              title: const Text('Delete template'),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteTemplate(i);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteTemplate(int i) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete template?'),
        content: Text(_shorten(widget.templates[i], 300)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // call optional parent callback to delete template from storage
              if (widget.onDeleteTemplate != null) widget.onDeleteTemplate!(i);
              _showSnack('Template delete requested');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ----------------------- Formatting helpers -----------------------
  void _insertAtSelection(String left, [String? right]) {
    final rightPart = right ?? left;
    final text = widget.messageController.text;
    final sel = widget.messageController.selection;
    if (sel.isValid && sel.start >= 0) {
      final newText = text.replaceRange(
        sel.start,
        sel.end,
        '$left${text.substring(sel.start, sel.end)}$rightPart',
      );
      widget.messageController.text = newText;
      final pos =
          sel.start + left.length + (sel.end - sel.start) + rightPart.length;
      widget.messageController.selection = TextSelection.collapsed(offset: pos);
    } else {
      widget.messageController.text = text + left + rightPart;
      widget.messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: widget.messageController.text.length),
      );
    }
    _focus.requestFocus();
  }

  void _wrapSelection(String surround) {
    final text = widget.messageController.text;
    final sel = widget.messageController.selection;
    if (sel.isValid && sel.start >= 0 && sel.start != sel.end) {
      final selected = text.substring(sel.start, sel.end);
      final newText = text.replaceRange(
        sel.start,
        sel.end,
        '$surround$selected$surround',
      );
      widget.messageController.text = newText;
      widget.messageController.selection = TextSelection(
        baseOffset: sel.start,
        extentOffset: sel.start + selected.length + surround.length * 2,
      );
    } else {
      // insert empty surround and place cursor inside
      final inserted = '$surround$surround';
      final newText = text.replaceRange(sel.start, sel.end, inserted);
      widget.messageController.text = newText;
      final cursorPos = (sel.start) + surround.length;
      widget.messageController.selection = TextSelection.collapsed(
        offset: cursorPos,
      );
    }
    _focus.requestFocus();
  }

  void _insertBold() => _wrapSelection('**');
  void _insertItalic() => _wrapSelection('_');
  void _insertCode() => _wrapSelection('`');
  void _insertBullet() {
    final text = widget.messageController.text;
    final sel = widget.messageController.selection;
    // If selection spans multiple lines, insert bullets
    if (sel.isValid && sel.start >= 0 && sel.start != sel.end) {
      final selected = text.substring(sel.start, sel.end);
      final lines = selected.split('\n').map((l) => '- ${l.trim()}').join('\n');
      final newText = text.replaceRange(sel.start, sel.end, lines);
      widget.messageController.text = newText;
      widget.messageController.selection = TextSelection.collapsed(
        offset: sel.start + lines.length,
      );
    } else {
      // insert single bullet
      _insertAtSelection('- ');
    }
    _focus.requestFocus();
  }

  void _insertNumbered() {
    final text = widget.messageController.text;
    final sel = widget.messageController.selection;
    if (sel.isValid && sel.start >= 0 && sel.start != sel.end) {
      final selected = text.substring(sel.start, sel.end);
      final lines = selected.split('\n');
      final numbered = List.generate(
        lines.length,
        (i) => '${i + 1}. ${lines[i].trim()}',
      ).join('\n');
      final newText = text.replaceRange(sel.start, sel.end, numbered);
      widget.messageController.text = newText;
      widget.messageController.selection = TextSelection.collapsed(
        offset: sel.start + numbered.length,
      );
    } else {
      _insertAtSelection('1. ');
    }
    _focus.requestFocus();
  }

  void _insertEmoji(String e) {
    final text = widget.messageController.text;
    final sel = widget.messageController.selection;
    if (sel.isValid && sel.start >= 0) {
      final newText = text.replaceRange(sel.start, sel.end, e);
      widget.messageController.text = newText;
      widget.messageController.selection = TextSelection.collapsed(
        offset: sel.start + e.length,
      );
    } else {
      widget.messageController.text = text + e;
      widget.messageController.selection = TextSelection.collapsed(
        offset: widget.messageController.text.length,
      );
    }
    _focus.requestFocus();
  }

  void _clearMessage() {
    if (widget.messageController.text.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear message?'),
        content: const Text(
          'This will remove the current message. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.messageController.clear();
              _pushUndo('');
              _showSnack('Cleared message');
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _copyPreviewAndClose(BuildContext ctx, String txt) async {
    await Clipboard.setData(ClipboardData(text: txt));
    Navigator.of(ctx).pop();
    _showSnack('Message copied');
  }

  void _showPreview() {
    final txt = widget.messageController.text.trim();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.message_rounded),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Preview',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${txt.length} chars',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  txt.isEmpty ? 'Nothing to preview' : txt,
                  style: TextStyle(color: Colors.grey.shade800),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: txt.isEmpty
                          ? null
                          : () => _copyPreviewAndClose(ctx, txt),
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Close'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------- Small helpers -----------------------
  double get _progress {
    final len = widget.messageController.text.length;
    return (len / _softLimit).clamp(0.0, 1.0);
  }

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ----------------------- Build -----------------------
  @override
  Widget build(BuildContext context) {
    final text = widget.messageController.text;
    final len = text.length;
    final words = text.trim().isEmpty
        ? 0
        : text.trim().split(RegExp(r'\s+')).length;
    final isOverSoftLimit = len > _softLimit;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title row
            Row(
              children: [
                const Icon(Icons.message_rounded),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Message',
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _templatesOpen = !_templatesOpen),
                  child: Row(
                    children: [
                      AnimatedRotation(
                        turns: _templatesOpen ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.expand_more_rounded,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.templates.length} templates',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      if (_showSavedDraftBadge) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Draft',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Templates
            if (_templatesOpen)
              SizedBox(
                height: 64,
                child: widget.templates.isEmpty
                    ? Center(
                        child: Text(
                          'No templates yet',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        itemBuilder: (ctx, i) {
                          final t = widget.templates[i];
                          final selected = i == _selectedTemplate;
                          return GestureDetector(
                            onLongPress: () => _longPressTemplate(i),
                            child: ChoiceChip(
                              selected: selected,
                              label: SizedBox(
                                width: 240,
                                child: Text(
                                  _shorten(t, 80),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              onSelected: (_) => _tapTemplate(i),
                              selectedColor: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.12),
                              backgroundColor: Colors.grey.shade100,
                              labelStyle: TextStyle(
                                color: selected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade800,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemCount: widget.templates.length,
                      ),
              ),

            if (_templatesOpen) const SizedBox(height: 12),

            // Editor box
            Container(
              constraints: const BoxConstraints(minHeight: 64),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: widget.messageController,
                focusNode: _focus,
                keyboardType: TextInputType.multiline,
                maxLines: 8,
                minLines: 2,
                decoration: const InputDecoration(
                  hintText:
                      'Write your message here — you can also tap a template above.',
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Progress + counts
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isOverSoftLimit
                            ? Colors.redAccent
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$len / $_softLimit',
                      style: TextStyle(
                        color: isOverSoftLimit
                            ? Colors.redAccent
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$words words',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Toolbar — wraps responsively
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Tooltip(
                  message: 'Bold',
                  child: OutlinedButton.icon(
                    onPressed: _insertBold,
                    icon: const Icon(Icons.format_bold),
                    label: const Text('Bold'),
                  ),
                ),
                Tooltip(
                  message: 'Italic',
                  child: OutlinedButton.icon(
                    onPressed: _insertItalic,
                    icon: const Icon(Icons.format_italic),
                    label: const Text('Italic'),
                  ),
                ),
                Tooltip(
                  message: 'Code',
                  child: OutlinedButton.icon(
                    onPressed: _insertCode,
                    icon: const Icon(Icons.code_rounded),
                    label: const Text('Code'),
                  ),
                ),
                Tooltip(
                  message: 'Bullet list',
                  child: OutlinedButton.icon(
                    onPressed: _insertBullet,
                    icon: const Icon(Icons.format_list_bulleted_rounded),
                    label: const Text('Bullets'),
                  ),
                ),
                Tooltip(
                  message: 'Numbered list',
                  child: OutlinedButton.icon(
                    onPressed: _insertNumbered,
                    icon: const Icon(Icons.format_list_numbered_rounded),
                    label: const Text('Numbered'),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: widget.onInsertLink,
                  icon: const Icon(Icons.link_rounded),
                  label: const Text('Insert link'),
                ),
                OutlinedButton.icon(
                  onPressed: widget.onSaveTemplate,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save template'),
                ),
                OutlinedButton.icon(
                  onPressed: _clearMessage,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Clear'),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Emoji',
                  icon: const Icon(Icons.emoji_emotions_rounded),
                  itemBuilder: (ctx) => _emojiList
                      .map((e) => PopupMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onSelected: (e) => _insertEmoji(e),
                ),
                // undo/redo small controls
                IconButton(
                  onPressed: _undoStack.length > 1 ? _undo : null,
                  tooltip: 'Undo',
                  icon: const Icon(Icons.undo_rounded),
                ),
                IconButton(
                  onPressed: _redoStack.isNotEmpty ? _redo : null,
                  tooltip: 'Redo',
                  icon: const Icon(Icons.redo_rounded),
                ),
                // autosave actions
                OutlinedButton.icon(
                  onPressed: _saveDraftNow,
                  icon: const Icon(Icons.save_alt_rounded),
                  label: const Text('Save draft'),
                ),
                if (_showSavedDraftBadge)
                  OutlinedButton.icon(
                    onPressed: _applyDraft,
                    icon: const Icon(Icons.history_rounded),
                    label: const Text('Load draft'),
                  ),
                if (_showSavedDraftBadge)
                  IconButton(
                    onPressed: _clearDraftNow,
                    tooltip: 'Discard saved draft',
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: Colors.redAccent,
                  ),
                // preview
                OutlinedButton.icon(
                  onPressed: _showPreview,
                  icon: const Icon(Icons.visibility_rounded),
                  label: const Text('Preview'),
                ),
              ],
            ),

            // small hint row
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Formatting uses simple markdown-like syntax (**, _, `). Tap templates to apply.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
                if (isOverSoftLimit)
                  Text(
                    'Over soft limit',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
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
