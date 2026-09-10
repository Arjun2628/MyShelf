import 'dart:typed_data';
import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/epub/domain/repositories/epub_repository.dart';

/// Use case for opening and parsing an EPUB file into a domain [Book].
class OpenEpubUseCase {
  final EpubRepository _repository;

  const OpenEpubUseCase(this._repository);

  /// Opens an EPUB book from memory bytes.
  Future<Book> fromBytes(Uint8List bytes, {String? bookId}) {
    return _repository.loadFromBytes(bytes, bookId: bookId);
  }

  /// Opens an EPUB book from a local file path.
  Future<Book> fromPath(String filePath, {String? bookId}) {
    return _repository.loadFromPath(filePath, bookId: bookId);
  }
}
