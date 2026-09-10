import 'package:meta/meta.dart';

/// Represents an item in the book's Table of Contents (TOC).
@immutable
class TocEntry {
  final String id;
  final String title;
  final String fullPath;
  final String? anchor;
  final List<TocEntry> children;

  const TocEntry({
    required this.id,
    required this.title,
    required this.fullPath,
    this.anchor,
    this.children = const [],
  });

  /// Flatten all TOC entries recursively in depth-first order.
  List<TocEntry> flatten() {
    final result = <TocEntry>[this];
    for (final child in children) {
      result.addAll(child.flatten());
    }
    return result;
  }

  @override
  String toString() =>
      'TocEntry(title: "$title", fullPath: $fullPath, anchor: $anchor, children: ${children.length})';
}
