import 'package:epub_audio/core/utils/path_utils.dart';
import 'package:epub_audio/features/epub/domain/entities/toc_entry.dart';
import 'package:xml/xml.dart';

/// Parses EPUB 2 NCX Navigation XML files (`toc.ncx`).
class NcxParser {
  const NcxParser();

  List<TocEntry> parse(String ncxXmlContent, String ncxFilePath) {
    try {
      final document = XmlDocument.parse(ncxXmlContent);
      final navMap = document.findAllElements('navMap').firstOrNull;
      if (navMap == null) return const [];

      return _parseNavPoints(navMap.findElements('navPoint'), ncxFilePath);
    } catch (_) {
      return const [];
    }
  }

  List<TocEntry> _parseNavPoints(
    Iterable<XmlElement> navPoints,
    String ncxFilePath,
  ) {
    final entries = <TocEntry>[];

    for (final navPoint in navPoints) {
      final id = navPoint.getAttribute('id') ?? '';
      final labelElement = navPoint.findElements('navLabel').firstOrNull;
      final textElement = labelElement?.findElements('text').firstOrNull;
      final title = textElement?.innerText.trim() ?? 'Untitled';

      final contentElement = navPoint.findElements('content').firstOrNull;
      final src = contentElement?.getAttribute('src') ?? '';

      // Split href and anchor (#anchor)
      String targetPath = src;
      String? anchor;
      if (src.contains('#')) {
        final parts = src.split('#');
        targetPath = parts[0];
        anchor = parts.length > 1 ? parts[1] : null;
      }

      final fullPath = EpubPathUtils.resolve(ncxFilePath, targetPath);

      // Parse nested child navPoints recursively
      final children = _parseNavPoints(
        navPoint.findElements('navPoint'),
        ncxFilePath,
      );

      entries.add(
        TocEntry(
          id: id,
          title: title,
          fullPath: fullPath,
          anchor: anchor,
          children: children,
        ),
      );
    }

    return entries;
  }
}
