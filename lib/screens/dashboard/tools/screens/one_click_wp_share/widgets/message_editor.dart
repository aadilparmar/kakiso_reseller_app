// lib/screens/dashboard/tools/widgets/message_editor.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MessageEditor extends StatefulWidget {
  final TextEditingController messageController;
  final List<String> templates;

  final VoidCallback onSaveTemplate;
  final ValueChanged<int> onSelectTemplate;

  // optional
  final ValueChanged<int>? onDeleteTemplate;
  final String draftPrefsKey;

  const MessageEditor({
    super.key,
    required this.messageController,
    required this.templates,
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

  static const int _softLimit = 300;

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
    _pushUndo(widget.messageController.text, pushIfSame: false);
  }

  @override
  void dispose() {
    widget.messageController.removeListener(_onTextChanged);
    _focus.dispose();
    _autosaveTimer?.cancel();
    super.dispose();
  }

  // ----------------------- Draft handling -----------------------
  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draft = prefs.getString(widget.draftPrefsKey);
    if (draft != null &&
        draft.isNotEmpty &&
        draft != widget.messageController.text) {
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

    _pushUndo(draft);
    setState(() => _showSavedDraftBadge = false);

    _showSnack('Draft loaded');
  }

  Future<void> _saveDraftNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(widget.draftPrefsKey, widget.messageController.text);
    _showSnack('Draft saved');
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 1200), _saveDraftNow);
  }

  // ----------------------- Undo / Redo -----------------------
  void _pushUndo(String text, {bool pushIfSame = true}) {
    if (!pushIfSame && _undoStack.isNotEmpty && _undoStack.last == text) {
      return;
    }
    _undoStack.add(text);
    if (_undoStack.length > 20) _undoStack.removeAt(0);
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
    _scheduleAutosave();
    setState(() {});
  }

  // ----------------------- Template actions -----------------------
  void _tapTemplate(int i) {
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
                if (widget.onDeleteTemplate != null) {
                  widget.onDeleteTemplate!(i);
                }
                _showSnack('Template deleted');
              },
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------- Formatting -----------------------
  void _wrapSelection(String surround) {
    final text = widget.messageController.text;
    final sel = widget.messageController.selection;

    if (sel.isValid && sel.start != sel.end) {
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
      final inserted = '$surround$surround';
      final newText = text.replaceRange(sel.start, sel.end, inserted);

      widget.messageController.text = newText;
      widget.messageController.selection = TextSelection.collapsed(
        offset: sel.start + surround.length,
      );
    }
  }

  void _insertBold() => _wrapSelection('**');
  void _insertItalic() => _wrapSelection('_');
  void _insertCode() => _wrapSelection('`');

  void _insertEmoji(String e) {
    final text = widget.messageController.text;
    final sel = widget.messageController.selection;

    final newText = text.replaceRange(sel.start, sel.end, e);
    widget.messageController.text = newText;
    widget.messageController.selection = TextSelection.collapsed(
      offset: sel.start + e.length,
    );
  }

  void _clearMessage() {
    if (widget.messageController.text.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear message?'),
        content: const Text('This action cannot be undone.'),
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
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ----------------------- Preview -----------------------
  void _showPreview() {
    final txt = widget.messageController.text.trim();

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
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
              Text(
                'Preview',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
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
              OutlinedButton.icon(
                onPressed: txt.isEmpty
                    ? null
                    : () {
                        Clipboard.setData(ClipboardData(text: txt));
                        Navigator.pop(ctx);
                        _showSnack('Copied');
                      },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------- Helpers -----------------------
  double get _progress =>
      (widget.messageController.text.length / _softLimit).clamp(0.0, 1.0);

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ----------------------- Build UI -----------------------
  @override
  Widget build(BuildContext context) {
    final text = widget.messageController.text;
    final len = text.length;

    final isOverSoftLimit = len > _softLimit;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
      child: Padding(
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
                      if (_showSavedDraftBadge)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Container(
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
                        ),
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
                                  t.length > 80
                                      ? '${t.substring(0, 77)}...'
                                      : t,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              onSelected: (_) => _tapTemplate(i),
                              selectedColor: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.12),
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemCount: widget.templates.length,
                      ),
              ),

            const SizedBox(height: 12),

            // Editor
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: widget.messageController,
                focusNode: _focus,
                maxLines: 8,
                minLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Write your message here...',
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Progress
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOverSoftLimit
                          ? Colors.red
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$len / $_softLimit',
                  style: TextStyle(
                    color: isOverSoftLimit ? Colors.red : Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Toolbar
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _insertBold,
                  icon: const Icon(Icons.format_bold),
                  label: const Text('Bold'),
                ),
                OutlinedButton.icon(
                  onPressed: _insertItalic,
                  icon: const Icon(Icons.format_italic),
                  label: const Text('Italic'),
                ),
                OutlinedButton.icon(
                  onPressed: _insertCode,
                  icon: const Icon(Icons.code),
                  label: const Text('Code'),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Emoji',
                  icon: const Icon(Icons.emoji_emotions_rounded),
                  itemBuilder: (ctx) => _emojiList
                      .map((e) => PopupMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onSelected: (e) => _insertEmoji(e),
                ),
                OutlinedButton.icon(
                  onPressed: widget.onSaveTemplate,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Template'),
                ),
                OutlinedButton.icon(
                  onPressed: _clearMessage,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Clear'),
                ),
                IconButton(
                  onPressed: _undoStack.length > 1 ? _undo : null,
                  icon: const Icon(Icons.undo),
                ),
                IconButton(
                  onPressed: _redoStack.isNotEmpty ? _redo : null,
                  icon: const Icon(Icons.redo),
                ),
                OutlinedButton.icon(
                  onPressed: _saveDraftNow,
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Save Draft'),
                ),
                if (_showSavedDraftBadge)
                  OutlinedButton.icon(
                    onPressed: _applyDraft,
                    icon: const Icon(Icons.history),
                    label: const Text('Load Draft'),
                  ),
                OutlinedButton.icon(
                  onPressed: _showPreview,
                  icon: const Icon(Icons.visibility),
                  label: const Text('Preview'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
