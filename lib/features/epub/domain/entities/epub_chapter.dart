import 'package:meta/meta.dart';

/// Represents a loaded chapter from the EPUB spine.
@immutable
class EpubChapter {
  final String id;
  final String title;
  final String fullPath;
  final int spineIndex;
  final String rawXhtml;

  const EpubChapter({
    required this.id,
    required this.title,
    required this.fullPath,
    required this.spineIndex,
    required this.rawXhtml,
  });

  @override
  String toString() =>
      'EpubChapter(index: $spineIndex, title: "$title", fullPath: $fullPath)';
}
