import 'dart:convert';
import 'dart:typed_data';
import 'package:epub_audio/features/epub/data/datasources/epub_archive.dart';
import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/epub/domain/entities/epub_manifest_item.dart';
import 'package:epub_audio/features/epub/domain/entities/epub_metadata.dart';
import 'package:epub_audio/features/epub/domain/entities/epub_spine_item.dart';
import 'package:epub_audio/features/epub/domain/entities/toc_entry.dart';
import 'package:epub_audio/features/text_content/domain/entities/text_document.dart';

/// Parses raw text documents into the unified Clean Architecture [Book] model
/// for distraction-free reading, audio TTS narration, and word-by-word synchronization.
class TextDocumentParser {
  /// Converts a [TextDocument] into an in-memory [Book] entity.
  Book parseDocument(TextDocument document) {
    return parse(
      content: document.content,
      bookId: document.id,
      title: document.title,
      author: document.source == 'file_import' ? 'Imported Text' : 'Custom Text',
    );
  }

  /// Alias for [parseDocument].
  Book parseDocumentToBook(TextDocument document) => parseDocument(document);

  /// Convenience method to parse raw text directly into a [Book].
  Book parseRawTextToBook({
    required String rawText,
    required String id,
    String? title,
    String? language,
  }) {
    return parse(
      content: rawText,
      bookId: id,
      title: title,
      language: language,
    );
  }

  /// Parses raw text content into a unified [Book] entity.
  Book parse({
    required String content,
    required String bookId,
    String? title,
    String? author,
    String? language,
  }) {
    final effectiveTitle = (title != null && title.trim().isNotEmpty)
        ? title.trim()
        : (content.trim().isNotEmpty
            ? content.trim().split('\n').first.replaceAll(RegExp(r'^#+\s*'), '').trim()
            : 'Untitled Document');

    // Split chapters if document contains major dividers (--- or === or # Chapter)
    final rawChapters = _splitIntoChapters(content, defaultTitle: effectiveTitle);

    final archiveFiles = <String, Uint8List>{};
    final manifest = <String, EpubManifestItem>{};
    final spine = <EpubSpineItem>[];
    final tocEntries = <TocEntry>[];

    for (int i = 0; i < rawChapters.length; i++) {
      final ch = rawChapters[i];
      final chFileName = 'chapter_$i.xhtml';
      final chId = 'chapter_$i';

      final xhtmlString = _buildChapterXhtml(
        chapterTitle: ch.title,
        bodyText: ch.content,
      );

      final xhtmlBytes = Uint8List.fromList(utf8.encode(xhtmlString));
      archiveFiles[chFileName] = xhtmlBytes;

      manifest[chId] = EpubManifestItem(
        id: chId,
        href: chFileName,
        mediaType: 'application/xhtml+xml',
        fullPath: chFileName,
      );

      spine.add(EpubSpineItem(
        idref: chId,
        fullPath: chFileName,
        index: i,
      ));

      tocEntries.add(TocEntry(
        id: 'toc_$chId',
        title: ch.title,
        fullPath: chFileName,
      ));
    }

    final archive = EpubArchive(archiveFiles);

    // Auto-detect script language if missing
    final effectiveLanguage = (language != null && language != 'auto' && language.isNotEmpty)
        ? language
        : detectLanguageFromText(content, defaultLang: 'en');

    final metadata = EpubMetadata(
      title: effectiveTitle,
      creators: [author ?? 'Custom Text'],
      description: 'Text document created in-app or imported.',
      language: effectiveLanguage,
    );

    return Book(
      id: bookId,
      metadata: metadata,
      manifest: manifest,
      spine: spine,
      toc: tocEntries,
      archive: archive,
      isText: true,
    );
  }

  /// Splits content into chapters if markdown dividers exist, otherwise returns single chapter.
  List<_RawChapter> _splitIntoChapters(String content, {required String defaultTitle}) {
    if (content.trim().isEmpty) {
      return [_RawChapter(title: defaultTitle, content: 'No text content available.')];
    }

    final dividerRegex = RegExp(r'\n\s*(?:---+|===+)\s*\n');
    if (dividerRegex.hasMatch(content)) {
      final sections = content.split(dividerRegex);
      final chapters = <_RawChapter>[];
      for (int i = 0; i < sections.length; i++) {
        final sec = sections[i].trim();
        if (sec.isEmpty) continue;
        final firstLine = sec.split('\n').first.replaceAll(RegExp(r'^#+\s*'), '').trim();
        final chTitle = firstLine.isNotEmpty && firstLine.length < 40
            ? firstLine
            : 'Section ${i + 1}';
        chapters.add(_RawChapter(title: chTitle, content: sec));
      }
      if (chapters.isNotEmpty) return chapters;
    }

    return [_RawChapter(title: defaultTitle, content: content)];
  }

  /// Builds semantic XHTML structure from markdown/plain text content.
  String _buildChapterXhtml({
    required String chapterTitle,
    required String bodyText,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="utf-8"?>');
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html xmlns="http://www.w3.org/1999/xhtml">');
    buffer.writeln('<head>');
    buffer.writeln('  <title>${_escapeXml(chapterTitle)}</title>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');

    final rawParagraphs = bodyText
        .split(RegExp(r'\r?\n\s*\r?\n|\r?\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (rawParagraphs.isEmpty) {
      buffer.writeln('  <p>No text content.</p>');
    } else {
      for (int i = 0; i < rawParagraphs.length; i++) {
        final rawPara = rawParagraphs[i];

        // 1. Heading detection (# H1, ## H2, ### H3)
        if (rawPara.startsWith('### ')) {
          final hText = rawPara.substring(4).trim();
          buffer.writeln('  <h3 id="p_$i">${_formatInline(hText)}</h3>');
        } else if (rawPara.startsWith('## ')) {
          final hText = rawPara.substring(3).trim();
          buffer.writeln('  <h2 id="p_$i">${_formatInline(hText)}</h2>');
        } else if (rawPara.startsWith('# ')) {
          final hText = rawPara.substring(2).trim();
          buffer.writeln('  <h1 id="p_$i">${_formatInline(hText)}</h1>');
        } else if (rawPara.startsWith('> ')) {
          final quoteText = rawPara.substring(2).trim();
          buffer.writeln('  <blockquote id="p_$i">${_formatInline(quoteText)}</blockquote>');
        } else {
          buffer.writeln('  <p id="p_$i">${_formatInline(rawPara)}</p>');
        }
      }
    }

    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }

  String _formatInline(String text) {
    String escaped = _escapeXml(text);
    // Replace **bold** with <strong>bold</strong>
    escaped = escaped.replaceAllMapped(
      RegExp(r'\*\*(.+?)\*\*'),
      (match) => '<strong>${match.group(1)}</strong>',
    );
    // Replace *italic* with <em>italic</em>
    escaped = escaped.replaceAllMapped(
      RegExp(r'\*(.+?)\*'),
      (match) => '<em>${match.group(1)}</em>',
    );
    return escaped;
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// Detects script language from text Unicode characters.
  static String detectLanguageFromText(String text, {String? defaultLang = 'en'}) {
    if (text.isEmpty) return defaultLang ?? 'en';
    int mlCount = 0;
    int hiCount = 0;
    int taCount = 0;
    int teCount = 0;
    int knCount = 0;
    int arCount = 0;
    int cjkCount = 0;

    for (final rune in text.runes) {
      if (rune >= 0x0D00 && rune <= 0x0D7F) {
        mlCount++;
      } else if (rune >= 0x0900 && rune <= 0x097F) {
        hiCount++;
      } else if (rune >= 0x0B80 && rune <= 0x0BFF) {
        taCount++;
      } else if (rune >= 0x0C00 && rune <= 0x0C7F) {
        teCount++;
      } else if (rune >= 0x0C80 && rune <= 0x0CFF) {
        knCount++;
      } else if (rune >= 0x0600 && rune <= 0x06FF) {
        arCount++;
      } else if ((rune >= 0x4E00 && rune <= 0x9FFF) || (rune >= 0x3040 && rune <= 0x30FF)) {
        cjkCount++;
      }
    }

    if (mlCount > 5) return 'ml';
    if (hiCount > 5) return 'hi';
    if (taCount > 5) return 'ta';
    if (teCount > 5) return 'te';
    if (knCount > 5) return 'kn';
    if (arCount > 5) return 'ar';
    if (cjkCount > 5) return 'zh';

    return defaultLang ?? 'en';
  }
}

class _RawChapter {
  final String title;
  final String content;

  const _RawChapter({required this.title, required this.content});
}
