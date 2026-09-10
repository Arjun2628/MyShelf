import 'dart:typed_data';
import 'package:epub_audio/core/utils/path_utils.dart';
import 'package:epub_audio/features/epub/data/datasources/epub_archive.dart';
import 'package:epub_audio/features/epub/domain/entities/epub_chapter.dart';
import 'package:epub_audio/features/epub/domain/entities/epub_manifest_item.dart';
import 'package:epub_audio/features/epub/domain/entities/epub_metadata.dart';
import 'package:epub_audio/features/epub/domain/entities/epub_spine_item.dart';
import 'package:epub_audio/features/epub/domain/entities/toc_entry.dart';

/// Complete in-memory Book entity representing a parsed EPUB.
class Book {
  final String id;
  final EpubMetadata metadata;
  final Map<String, EpubManifestItem> manifest;
  final List<EpubSpineItem> spine;
  final List<TocEntry> toc;
  final Uint8List? coverImageBytes;
  final EpubArchive archive;
  final bool isPdf;

  const Book({
    required this.id,
    required this.metadata,
    required this.manifest,
    required this.spine,
    required this.toc,
    required this.archive,
    this.coverImageBytes,
    this.isPdf = false,
  });

  /// Total number of linear chapters/spine items.
  int get chapterCount => spine.length;

  /// Retrieves a chapter by its index in the spine.
  EpubChapter getChapter(int index) {
    if (index < 0 || index >= spine.length) {
      throw RangeError.index(index, spine, 'Spine index out of range');
    }

    final spineItem = spine[index];
    final fullPath = spineItem.fullPath;
    final xhtml = archive.readText(fullPath) ?? '';

    // Find a matching title from TOC if possible, otherwise use fallback
    final matchingToc = _findTocForPath(fullPath);
    final title = matchingToc?.title ?? 'Chapter ${index + 1}';

    return EpubChapter(
      id: spineItem.idref,
      title: title,
      fullPath: fullPath,
      spineIndex: index,
      rawXhtml: xhtml,
    );
  }

  /// Finds TOC entry matching the given file path.
  TocEntry? _findTocForPath(String path) {
    final normalized = EpubPathUtils.normalize(path);
    for (final entry in toc) {
      for (final item in entry.flatten()) {
        if (EpubPathUtils.normalize(item.fullPath) == normalized) {
          return item;
        }
      }
    }
    return null;
  }

  /// Resolves and reads raw binary asset (e.g. image, font) from the book archive.
  Uint8List? readAsset(String relativeOrFullPath, {String? baseFilePath}) {
    final resolvedPath = baseFilePath != null
        ? EpubPathUtils.resolve(baseFilePath, relativeOrFullPath)
        : EpubPathUtils.normalize(relativeOrFullPath);

    return archive.readBytes(resolvedPath);
  }

  /// Resolves and reads text asset (e.g. CSS stylesheet) from the book archive.
  String? readTextAsset(String relativeOrFullPath, {String? baseFilePath}) {
    final resolvedPath = baseFilePath != null
        ? EpubPathUtils.resolve(baseFilePath, relativeOrFullPath)
        : EpubPathUtils.normalize(relativeOrFullPath);

    return archive.readText(resolvedPath);
  }

  @override
  String toString() =>
      'Book(title: "${metadata.title}", chapters: ${spine.length}, author: "${metadata.author}")';
}
