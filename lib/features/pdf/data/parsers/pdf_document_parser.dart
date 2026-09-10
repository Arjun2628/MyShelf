import 'dart:convert';
import 'package:epub_audio/features/epub/data/datasources/epub_archive.dart';
import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/epub/domain/entities/epub_manifest_item.dart';
import 'package:epub_audio/features/epub/domain/entities/epub_metadata.dart';
import 'package:epub_audio/features/epub/domain/entities/epub_spine_item.dart';
import 'package:epub_audio/features/epub/domain/entities/toc_entry.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Parses PDF documents into the unified Clean Architecture [Book] model
/// for reflowable reading, typography adjustments, and synchronized TTS narration.
class PdfDocumentParser {
  /// Parses PDF bytes and constructs a [Book] entity.
  Book parse(
    Uint8List bytes, {
    required String bookId,
    String? fallbackTitle,
  }) {
    PdfDocument? document;
    try {
      document = PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;

      // 1. Extract Document Metadata
      final docInfo = document.documentInformation;
      var title = (docInfo.title.isNotEmpty ? docInfo.title : fallbackTitle) ?? 'Untitled PDF';
      title = title.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '').trim();
      if (title.isEmpty) {
        title = fallbackTitle ?? 'PDF Document';
      }

      final author = docInfo.author.isNotEmpty ? docInfo.author : 'Unknown Author';
      final subject = docInfo.subject.isNotEmpty ? docInfo.subject : null;

      // 2. Extract Text Page-by-Page and Build Reflowable XHTML
      final archiveFiles = <String, Uint8List>{};
      final manifest = <String, EpubManifestItem>{};
      final spine = <EpubSpineItem>[];
      final tocEntries = <TocEntry>[];

      final extractor = PdfTextExtractor(document);

      for (int i = 0; i < pageCount; i++) {
        final pageNum = i + 1;
        final pageFileName = 'page_$pageNum.xhtml';
        final pageId = 'page_$pageNum';
        final pageTitle = 'Page $pageNum';

        // Extract raw text for this single page
        String pageText = '';
        try {
          pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);
        } catch (e) {
          debugPrint('[PdfDocumentParser] Error extracting text on page $pageNum: $e');
        }

        final xhtmlString = _buildPageXhtml(
          pageTitle: pageTitle,
          rawText: pageText,
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

      // 3. Process Bookmarks / Outlines if available to enrich TOC
      final enrichedToc = _buildTocWithBookmarks(
        document.bookmarks,
        fallbackToc: tocEntries,
      );

      final archive = EpubArchive(archiveFiles);

      final metadata = EpubMetadata(
        title: title,
        creators: [author],
        description: subject,
        language: 'en',
      );

      return Book(
        id: bookId,
        metadata: metadata,
        manifest: manifest,
        spine: spine,
        toc: enrichedToc,
        archive: archive,
        coverImageBytes: null,
        isPdf: true,
      );
    } finally {
      document?.dispose();
    }
  }

  /// Converts raw page text into structured XHTML with headings and paragraphs.
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
      buffer.writeln('<p><em>[No extractable text on this page]</em></p>');
    } else {
      // Split into paragraphs by double newlines or indentation
      final rawParagraphs = trimmed.split(RegExp(r'\n\s*\n+'));
      for (final p in rawParagraphs) {
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

  /// Recursively extracts bookmarks from the PDF if present.
  List<TocEntry> _buildTocWithBookmarks(
    PdfBookmarkBase? bookmarks, {
    required List<TocEntry> fallbackToc,
  }) {
    if (bookmarks == null || bookmarks.count == 0) {
      return fallbackToc;
    }

    try {
      final customToc = <TocEntry>[];
      for (int i = 0; i < bookmarks.count; i++) {
        final bm = bookmarks[i];
        final int targetPage = i + 1;

        customToc.add(TocEntry(
          id: 'bm_$i',
          title: bm.title.isNotEmpty ? bm.title : 'Section ${i + 1}',
          fullPath: 'page_$targetPage.xhtml',
        ));
      }
      return customToc.isNotEmpty ? customToc : fallbackToc;
    } catch (_) {
      return fallbackToc;
    }
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
