// lib/screens/dashboard/tools/utils/wa_utils.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Sanitize number: keep digits & leading plus; if no plus, prepend countryCode (e.g. '+91').
String sanitizeNumber(String raw, String countryCode) {
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
    sanitized = '$countryCode$sanitized';
  } else {
    sanitized = '+${sanitized.replaceFirst(RegExp(r'^\+'), '')}';
  }
  return sanitized;
}

/// Normalize for wa.me (remove '+')
String normalizeForWa(String sanitized) => sanitized.replaceFirst('+', '');

/// Try to open a uri robustly
Future<bool> tryOpenUri(Uri uri) async {
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

/// Open chat for a single number with a message. Returns true if an intent was launched.
Future<bool> openChatForNumber(String sanitizedNumber, String message) async {
  final n = normalizeForWa(sanitizedNumber);
  final encoded = Uri.encodeComponent(message);
  final whatsappUri = Uri.parse('whatsapp://send?phone=$n&text=$encoded');
  final waMeUri = Uri.parse('https://wa.me/$n?text=$encoded');
  bool opened = await tryOpenUri(whatsappUri);
  if (!opened) opened = await tryOpenUri(waMeUri);
  return opened;
}

/// Open WhatsApp with just prefilled text (no phone) — useful for copy & paste flow
Future<bool> openPlainTextInWhatsApp(String message) async {
  final encoded = Uri.encodeComponent(message);
  final appUri = Uri.parse('whatsapp://send?text=$encoded');
  final webUri = Uri.parse('https://web.whatsapp.com/send?text=$encoded');
  bool opened = await tryOpenUri(appUri);
  if (!opened) opened = await tryOpenUri(webUri);
  return opened;
}

/// Insert a link into a TextEditingController at the current selection (or append)
void insertLinkToController(TextEditingController ctrl, String link) {
  final text = ctrl.text;
  final sel = ctrl.selection;
  if (sel.isValid && sel.start >= 0) {
    final newText = text.replaceRange(sel.start, sel.end, link);
    ctrl.text = newText;
    final pos = sel.start + link.length;
    ctrl.selection = TextSelection.fromPosition(TextPosition(offset: pos));
  } else {
    if (text.isEmpty) {
      ctrl.text = link;
    } else {
      ctrl.text = '$text\n$link';
    }
    ctrl.selection = TextSelection.fromPosition(
      TextPosition(offset: ctrl.text.length),
    );
  }
}
