import 'package:epub_audio/features/epub/data/parsers/xhtml_content_parser.dart';
import 'package:epub_audio/features/epub/domain/entities/chapter_content.dart';
import 'package:epub_audio/features/epub/domain/entities/epub_chapter.dart';

/// Use case for parsing raw chapter XHTML into structured normalized [ChapterContent].
class ParseChapterContentUseCase {
  final XhtmlContentParser _parser;

  const ParseChapterContentUseCase({
    XhtmlContentParser parser = const XhtmlContentParser(),
  }) : _parser = parser;

  ChapterContent execute(EpubChapter chapter) {
    return _parser.parseChapter(chapter);
  }
}
