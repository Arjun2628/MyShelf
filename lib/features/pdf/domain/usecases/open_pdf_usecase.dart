import 'dart:io';
import 'dart:typed_data';
import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/pdf/data/parsers/pdf_document_parser.dart';
import 'package:path/path.dart' as p;

/// Use case for opening and parsing a PDF file into a domain [Book].
class OpenPdfUseCase {
  final PdfDocumentParser _parser;

  OpenPdfUseCase([PdfDocumentParser? parser])
      : _parser = parser ?? PdfDocumentParser();

  /// Opens a PDF book from memory bytes.
  Future<Book> fromBytes(
    Uint8List bytes, {
    String? bookId,
    String? fallbackTitle,
  }) async {
    final id = bookId ?? 'pdf_${DateTime.now().millisecondsSinceEpoch}';
    return _parser.parse(
      bytes,
      bookId: id,
      fallbackTitle: fallbackTitle,
    );
  }

  /// Opens a PDF book from a local file path.
  Future<Book> fromPath(String filePath, {String? bookId}) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('PDF file not found', filePath);
    }
    final bytes = await file.readAsBytes();
    final filename = p.basename(filePath);
    final id = bookId ?? filename;
    return _parser.parse(
      bytes,
      bookId: id,
      fallbackTitle: filename,
    );
  }
}
