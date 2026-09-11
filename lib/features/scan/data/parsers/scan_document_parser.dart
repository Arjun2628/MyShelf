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
    String? language,
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

    // Auto-detect script language if auto or missing
    final combinedText = pageList.map((p) => p.rawText).join(' ');
    final effectiveLanguage = (language != null && language != 'auto' && language.isNotEmpty)
        ? language
        : detectLanguageFromText(combinedText, defaultLang: 'en');

    final metadata = EpubMetadata(
      title: effectiveTitle,
      creators: const ['Photo Scan'],
      description: 'Document digitized via on-device OCR scan.',
      language: effectiveLanguage,
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

  /// Automatically identifies language from character scripts.
  static String detectLanguageFromText(String text, {String? defaultLang}) {
    if (text.isEmpty) return defaultLang ?? 'en';

    final malCount = RegExp(r'[\u0D00-\u0D7F]').allMatches(text).length;
    if (malCount > 0) return 'ml';

    final hiCount = RegExp(r'[\u0900-\u097F]').allMatches(text).length;
    if (hiCount > 0) return 'hi';

    final tamCount = RegExp(r'[\u0B80-\u0BFF]').allMatches(text).length;
    if (tamCount > 0) return 'ta';

    final telCount = RegExp(r'[\u0C00-\u0C7F]').allMatches(text).length;
    if (telCount > 0) return 'te';

    final kanCount = RegExp(r'[\u0C80-\u0CFF]').allMatches(text).length;
    if (kanCount > 0) return 'kn';

    final benCount = RegExp(r'[\u0980-\u09FF]').allMatches(text).length;
    if (benCount > 0) return 'bn';

    final araCount = RegExp(r'[\u0600-\u06FF]').allMatches(text).length;
    if (araCount > 0) return 'ar';

    final zhCount = RegExp(r'[\u4E00-\u9FFF]').allMatches(text).length;
    if (zhCount > 0) return 'zh';

    final jaCount = RegExp(r'[\u3040-\u309F\u30A0-\u30FF]').allMatches(text).length;
    if (jaCount > 0) return 'ja';

    final koCount = RegExp(r'[\uAC00-\uD7AF]').allMatches(text).length;
    if (koCount > 0) return 'ko';

    return defaultLang ?? 'en';
  }

  /// Converts raw OCR recognized text into clean, structured XHTML
  /// with smart paragraph reconstruction (no artificial heading paragraphs or unwanted paragraph splits).
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

    final paragraphs = _segmentParagraphs(rawText);
    for (final p in paragraphs) {
      buffer.writeln('<p>${_escapeHtml(p)}</p>');
    }

    buffer.writeln('</body>');
    buffer.writeln('</html>');
    return buffer.toString();
  }

  /// Intelligently segments raw OCR output into genuine paragraphs.
  /// Merges accidental line breaks, wraps, and OCR bounding box splits, only splitting when actual paragraph breaks exist.
  List<String> _segmentParagraphs(String rawText) {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) return const [];

    // Normalize all newlines
    var normalized = trimmed.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // Fix OCR hyphenation at line breaks: e.g. "com-\nputer" -> "computer"
    normalized = normalized.replaceAllMapped(
      RegExp(r'(\w+)-\n+(\w+)'),
      (match) => '${match[1]}${match[2]}',
    );

    // Split on multiple newlines
    final rawBlocks = normalized.split(RegExp(r'\n\s*\n+'));

    final paragraphs = <String>[];
    StringBuffer? currentPara;

    // Terminal punctuation check: . ! ? । ॥ : ; " ” ' ’ »
    final terminalPunctuationRegex = RegExp(r'[\.!\?।॥:;"”’»\x27]$');

    for (final rawBlock in rawBlocks) {
      // Join single line-breaks inside a block with spaces
      final cleanBlock = rawBlock
          .replaceAll(RegExp(r'\s*\n\s*'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (cleanBlock.isEmpty) continue;

      if (currentPara == null) {
        currentPara = StringBuffer(cleanBlock);
        continue;
      }

      final currentText = currentPara.toString().trim();
      final endsWithTerminal = terminalPunctuationRegex.hasMatch(currentText);

      // Only create a new paragraph if the previous block finished with terminal punctuation
      // and this block is a distinct sentence/paragraph, otherwise merge OCR wrapped text
      if (endsWithTerminal && cleanBlock.length > 3) {
        paragraphs.add(currentText);
        currentPara = StringBuffer(cleanBlock);
      } else {
        // Merge mid-sentence line break or continuation
        currentPara.write(' ');
        currentPara.write(cleanBlock);
      }
    }

    if (currentPara != null && currentPara.isNotEmpty) {
      final finalPara = currentPara.toString().trim();
      if (finalPara.isNotEmpty) {
        paragraphs.add(finalPara);
      }
    }

    return paragraphs;
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
