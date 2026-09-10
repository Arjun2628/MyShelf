import 'package:epub_audio/features/epub/data/datasources/epub_archive.dart';
import 'package:epub_audio/features/epub/data/parsers/nav_parser.dart';
import 'package:epub_audio/features/epub/data/parsers/ncx_parser.dart';
import 'package:epub_audio/features/epub/data/parsers/opf_parser.dart';
import 'package:epub_audio/features/epub/domain/entities/toc_entry.dart';

/// Unified coordinator for parsing Table of Contents across EPUB 2 and EPUB 3.
class TocParser {
  final NcxParser _ncxParser;
  final NavParser _navParser;

  const TocParser({
    NcxParser ncxParser = const NcxParser(),
    NavParser navParser = const NavParser(),
  })  : _ncxParser = ncxParser,
        _navParser = navParser;

  /// Extracts the list of TOC entries from the archive using OPF package info.
  List<TocEntry> parseToc(EpubArchive archive, OpfPackageData opfData) {
    final tocItem = opfData.tocItem;
    if (tocItem != null && archive.hasFile(tocItem.fullPath)) {
      final content = archive.readText(tocItem.fullPath);
      if (content != null && content.isNotEmpty) {
        if (tocItem.isNav ||
            tocItem.mediaType == 'application/xhtml+xml' ||
            tocItem.mediaType == 'text/html') {
          final entries = _navParser.parse(content, tocItem.fullPath);
          if (entries.isNotEmpty) return entries;
        }

        if (tocItem.isNcx ||
            tocItem.mediaType == 'application/x-dtbncx+xml' ||
            tocItem.fullPath.endsWith('.ncx')) {
          final entries = _ncxParser.parse(content, tocItem.fullPath);
          if (entries.isNotEmpty) return entries;
        }
      }
    }

    // Secondary scan: check if any file in manifest is an NCX or Nav document
    for (final item in opfData.manifest.values) {
      if (item.isNcx && archive.hasFile(item.fullPath)) {
        final content = archive.readText(item.fullPath);
        if (content != null) {
          final entries = _ncxParser.parse(content, item.fullPath);
          if (entries.isNotEmpty) return entries;
        }
      }
    }

    // Fallback: Generate synthetic TOC from spine reading order
    return _generateSpineFallbackToc(opfData);
  }

  List<TocEntry> _generateSpineFallbackToc(OpfPackageData opfData) {
    final entries = <TocEntry>[];
    for (int i = 0; i < opfData.spine.length; i++) {
      final spineItem = opfData.spine[i];
      entries.add(
        TocEntry(
          id: 'spine_$i',
          title: 'Chapter ${i + 1}',
          fullPath: spineItem.fullPath,
        ),
      );
    }
    return entries;
  }
}
