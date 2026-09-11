import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/scan/data/parsers/scan_document_parser.dart';
import 'package:epub_audio/features/scan/data/services/ocr_service.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Progress callback for scan and OCR operations.
typedef ScanProgressCallback = void Function(double progress, String status);

/// Use case for capturing or picking photos, recognizing text via OCR,
/// and creating a domain [Book] for reading and continuous TTS narration.
class ScanBookUseCase {
  final ImagePicker _picker;
  final OcrService _ocrService;
  final ScanDocumentParser _parser;

  ScanBookUseCase({
    ImagePicker? picker,
    OcrService? ocrService,
    ScanDocumentParser? parser,
  })  : _picker = picker ?? ImagePicker(),
        _ocrService = ocrService ?? OcrService(),
        _parser = parser ?? ScanDocumentParser();

  /// Captures a single photo from the camera, runs OCR, and returns a [Book].
  Future<Book?> scanFromCamera({
    String? title,
    OcrLanguage language = OcrLanguage.auto,
    ScanProgressCallback? onProgress,
  }) async {
    onProgress?.call(0.1, 'Opening Camera...');
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 92,
    );

    if (photo == null) {
      return null;
    }

    return _processImageFiles(
      [photo],
      title: title ?? 'Camera Scan ${DateTime.now().toIso8601String().substring(0, 10)}',
      language: language,
      onProgress: onProgress,
    );
  }

  /// Picks a single photo from the device gallery, runs OCR, and returns a [Book].
  Future<Book?> scanFromGallery({
    String? title,
    OcrLanguage language = OcrLanguage.auto,
    ScanProgressCallback? onProgress,
  }) async {
    onProgress?.call(0.1, 'Selecting photo from gallery...');
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );

    if (photo == null) {
      return null;
    }

    return _processImageFiles(
      [photo],
      title: title ?? 'Photo Scan ${DateTime.now().toIso8601String().substring(0, 10)}',
      language: language,
      onProgress: onProgress,
    );
  }

  /// Picks multiple photos from the gallery (e.g. multi-page document),
  /// runs OCR on each, and merges them into a multi-page [Book].
  Future<Book?> scanMultipleFromGallery({
    String? title,
    OcrLanguage language = OcrLanguage.auto,
    ScanProgressCallback? onProgress,
  }) async {
    onProgress?.call(0.1, 'Selecting photos from gallery...');
    final List<XFile> photos = await _picker.pickMultiImage(
      imageQuality: 92,
    );

    if (photos.isEmpty) {
      return null;
    }

    return _processImageFiles(
      photos,
      title: title ?? 'Document Scan (${photos.length} pages)',
      language: language,
      onProgress: onProgress,
    );
  }

  /// Internal helper to OCR a list of images and build a [Book].
  Future<Book> _processImageFiles(
    List<XFile> files, {
    required String title,
    OcrLanguage language = OcrLanguage.auto,
    ScanProgressCallback? onProgress,
  }) async {
    final scannedPages = <ScannedPageData>[];
    Uint8List? coverBytes;

    final total = files.length;
    for (int i = 0; i < total; i++) {
      final file = files[i];
      final pageNum = i + 1;
      final progress = 0.2 + (0.7 * (i / total));

      onProgress?.call(progress, 'Recognizing ${language.displayName} text on page $pageNum of $total...');

      // Read image bytes for first page as cover
      if (i == 0) {
        try {
          coverBytes = await file.readAsBytes();
        } catch (e) {
          debugPrint('[ScanBookUseCase] Failed to read cover bytes: $e');
        }
      }

      String recognizedText = '';
      try {
        recognizedText = await _ocrService.recognizeText(file.path, language: language);
      } catch (e) {
        debugPrint('[ScanBookUseCase] Error recognizing text on ${file.path}: $e');
        recognizedText = '';
      }

      scannedPages.add(ScannedPageData(
        pageNumber: pageNum,
        rawText: recognizedText,
        imagePath: file.path,
      ));
    }

    onProgress?.call(0.95, 'Building book reader pages...');

    final bookId = 'scan_${DateTime.now().millisecondsSinceEpoch}';
    final book = _parser.parse(
      pages: scannedPages,
      bookId: bookId,
      title: title,
      language: language.isoCode,
      coverBytes: coverBytes,
    );

    onProgress?.call(1.0, 'Ready!');
    return book;
  }
}
