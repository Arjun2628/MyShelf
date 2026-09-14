import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/opening_experience/domain/entities/book_opening_config.dart';

/// Contract for resolving book opening experiences based on book overrides and category presets.
abstract class BookOpeningRepository {
  /// Resolves the opening experience configuration for a book, optionally informed by its category.
  Future<BookOpeningConfig> resolveOpeningConfig({
    required Book book,
    String? categoryId,
  });
}
