// lib/models/tool.dart
import 'package:flutter/material.dart';

typedef ToolPageBuilder = Widget Function(BuildContext context);

class Tool {
  final String id;
  final String title;
  final String subtitle;
  final IconData iconData;
  final bool enabled;
  final ToolPageBuilder pageBuilder;

  const Tool({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconData,
    required this.enabled,
    required this.pageBuilder,
  });

  Tool copyWith({
    String? id,
    String? title,
    String? subtitle,
    IconData? iconData,
    bool? enabled,
    ToolPageBuilder? pageBuilder,
  }) {
    return Tool(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      iconData: iconData ?? this.iconData,
      enabled: enabled ?? this.enabled,
      pageBuilder: pageBuilder ?? this.pageBuilder,
    );
  }
}
