import 'dart:convert';
import 'dart:typed_data';
import 'package:epub_audio/features/epub/data/datasources/epub_archive.dart';
import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/epub/domain/entities/epub_manifest_item.dart';
import 'package:epub_audio/features/epub/domain/entities/epub_metadata.dart';
import 'package:epub_audio/features/epub/domain/entities/epub_spine_item.dart';
import 'package:epub_audio/features/epub/domain/entities/toc_entry.dart';

/// Representation of a single scanned page extracted via OCR.
class ScannedPageData {
  final int pageNumber;
  final String rawText;
  final String? imagePath;
  final Uint8List? imageBytes;

  const ScannedPageData({
    required this.pageNumber,
    required this.rawText,
    this.imagePath,
    this.imageBytes,
  });
}

/// Parses scanned photo/OCR pages into the unified Clean Architecture [Book] model
/// for reader display, continuous TTS audio narration, and word highlighting.
class ScanDocumentParser {
  /// Builds a [Book] entity from OCR scanned page data.
  Book parse({
    required List<ScannedPageData> pages,
    required String bookId,
    String? title,
    Uint8List? coverBytes,
  }) {
    final effectiveTitle = (title != null && title.trim().isNotEmpty)
        ? title.trim()
        : 'Scanned Document (${pages.length} ${pages.length == 1 ? "page" : "pages"})';

    final archiveFiles = <String, Uint8List>{};
    final manifest = <String, EpubManifestItem>{};
    final spine = <EpubSpineItem>[];
    final tocEntries = <TocEntry>[];

    final sortedPages = List<ScannedPageData>.from(pages)
      ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

    // If no pages provided, create a placeholder single page
    final pageList = sortedPages.isEmpty
        ? [const ScannedPageData(pageNumber: 1, rawText: 'No text was recognized from this scan.')]
        : sortedPages;

    for (int i = 0; i < pageList.length; i++) {
      final page = pageList[i];
      final pageNum = page.pageNumber;
      final pageFileName = 'page_$pageNum.xhtml';
      final pageId = 'page_$pageNum';
      final pageTitle = pageList.length > 1 ? 'Page $pageNum' : effectiveTitle;

      final xhtmlString = _buildPageXhtml(
        pageTitle: pageTitle,
        rawText: page.rawText,
      );

      final xhtmlBytes = Uint8List.fromList(utf8.encode(xhtmlString));
      archiveFiles[pageFileName] = xhtmlBytes;

      manifest[pageId] = EpubManifestItem(
        id: pageId,
        href: pageFileName,
        mediaType: 'application/xhtml+xml',
        fullPath: pageFileName,
      );

      spine.add(EpubSpineItem(
        idref: pageId,
        fullPath: pageFileName,
        index: i,
      ));

      tocEntries.add(TocEntry(
        id: 'toc_$pageId',
        title: pageTitle,
        fullPath: pageFileName,
      ));
    }

    final archive = EpubArchive(archiveFiles);

    final metadata = EpubMetadata(
      title: effectiveTitle,
      creators: const ['Photo Scan'],
      description: 'Document digitized via on-device OCR scan.',
      language: 'en',
    );

    return Book(
      id: bookId,
      metadata: metadata,
      manifest: manifest,
      spine: spine,
      toc: tocEntries,
      archive: archive,
      coverImageBytes: coverBytes,
      isPdf: false,
      isScan: true,
    );
  }

  /// Converts raw OCR recognized text into clean, structured XHTML.
  String _buildPageXhtml({
    required String pageTitle,
    required String rawText,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="utf-8"?>');
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html xmlns="http://www.w3.org/1999/xhtml">');
    buffer.writeln('<head><title>${_escapeHtml(pageTitle)}</title></head>');
    buffer.writeln('<body>');
    buffer.writeln('<h2>${_escapeHtml(pageTitle)}</h2>');

    final trimmed = rawText.trim();
    if (trimmed.isEmpty) {
      buffer.writeln('<p><em>[No recognized text in this photo]</em></p>');
    } else {
      // Split on empty lines or paragraph breaks
      final rawParagraphs = trimmed.split(RegExp(r'\n\s*\n+'));
      for (final p in rawParagraphs) {
        // Normalize intra-paragraph newlines into spaces
        final cleanP = p.replaceAll(RegExp(r'\r\n|\r|\n'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
        if (cleanP.isNotEmpty) {
          buffer.writeln('<p>${_escapeHtml(cleanP)}</p>');
        }
      }
    }

    buffer.writeln('</body>');
    buffer.writeln('</html>');
    return buffer.toString();
  }

  /// Serializes a scanned book into a JSON structure for disk persistence.
  Map<String, dynamic> toJson(Book book) {
    final pages = <Map<String, dynamic>>[];
    for (int i = 0; i < book.spine.length; i++) {
      final spineItem = book.spine[i];
      final xhtml = book.archive.readText(spineItem.fullPath) ?? '';
      // Extract text content from xhtml paragraphs
      final plainText = _extractTextFromXhtml(xhtml);
      pages.add({
        'pageNumber': i + 1,
        'rawText': plainText,
      });
    }

    return {
      'id': book.id,
      'title': book.metadata.title,
      'author': book.metadata.author,
      'description': book.metadata.description,
      'pages': pages,
      'isScan': true,
    };
  }

  /// Deserializes a JSON structure into a [Book] entity.
  Book fromJson(Map<String, dynamic> json, {Uint8List? coverBytes}) {
    final bookId = json['id'] as String? ?? 'scan_${DateTime.now().millisecondsSinceEpoch}';
    final title = json['title'] as String? ?? 'Scanned Document';
    final rawPages = json['pages'] as List<dynamic>? ?? [];

    final pages = <ScannedPageData>[];
    for (final p in rawPages) {
      if (p is Map) {
        pages.add(ScannedPageData(
          pageNumber: (p['pageNumber'] as num?)?.toInt() ?? (pages.length + 1),
          rawText: p['rawText'] as String? ?? '',
        ));
      }
    }

    return parse(
      pages: pages,
      bookId: bookId,
      title: title,
      coverBytes: coverBytes,
    );
  }

  /// Extracts readable text from generated XHTML.
  String _extractTextFromXhtml(String xhtml) {
    return xhtml
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
