import 'dart:typed_data';
import 'package:epub_audio/features/epub/domain/entities/book.dart';

/// Contract for loading and building [Book] domain entities from EPUB sources.
abstract class EpubRepository {
  /// Loads a book from raw byte data.
  Future<Book> loadFromBytes(Uint8List bytes, {String? bookId});

  /// Loads a book from a file path.
  Future<Book> loadFromPath(String filePath, {String? bookId});
}
