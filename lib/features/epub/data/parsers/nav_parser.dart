import 'package:epub_audio/core/utils/path_utils.dart';
import 'package:epub_audio/features/epub/domain/entities/toc_entry.dart';
import 'package:xml/xml.dart';

/// Parses EPUB 3 Navigation documents (`nav.xhtml` or `toc.xhtml`).
class NavParser {
  const NavParser();

  List<TocEntry> parse(String navXmlContent, String navFilePath) {
    try {
      final document = XmlDocument.parse(navXmlContent);
      final navElements = document.findAllElements('nav');

      // Find <nav> with epub:type="toc" or type="toc" or first <nav>
      XmlElement? tocNav;
      for (final nav in navElements) {
        final epubType = nav.getAttribute('epub:type') ??
            nav.getAttribute('type') ??
            nav.getAttribute('role');
        if (epubType != null &&
            (epubType.contains('toc') || epubType.contains('doc-toc'))) {
          tocNav = nav;
          break;
        }
      }
      tocNav ??= navElements.firstOrNull;
      if (tocNav == null) return const [];

      final listElement = tocNav.findElements('ol').firstOrNull ??
          tocNav.findElements('ul').firstOrNull;
      if (listElement == null) return const [];

      return _parseListItems(listElement.findElements('li'), navFilePath);
    } catch (_) {
      return const [];
    }
  }

  List<TocEntry> _parseListItems(
    Iterable<XmlElement> listItems,
    String navFilePath,
  ) {
    final entries = <TocEntry>[];
    int idCounter = 0;

    for (final li in listItems) {
      final anchorElement = li.findElements('a').firstOrNull;
      final spanElement = li.findElements('span').firstOrNull;

      final title = anchorElement?.innerText.trim() ??
          spanElement?.innerText.trim() ??
          'Untitled';
      final href = anchorElement?.getAttribute('href') ?? '';

      String targetPath = href;
      String? anchor;
      if (href.contains('#')) {
        final parts = href.split('#');
        targetPath = parts[0];
        anchor = parts.length > 1 ? parts[1] : null;
      }

      final fullPath = targetPath.isNotEmpty
          ? EpubPathUtils.resolve(navFilePath, targetPath)
          : '';

      // Check for nested lists (sub-chapters)
      final subList = li.findElements('ol').firstOrNull ??
          li.findElements('ul').firstOrNull;
      final children = subList != null
          ? _parseListItems(subList.findElements('li'), navFilePath)
          : const <TocEntry>[];

      entries.add(
        TocEntry(
          id: 'nav_${idCounter++}',
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
