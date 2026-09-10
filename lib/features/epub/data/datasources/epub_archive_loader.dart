import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:epub_audio/core/errors/epub_exceptions.dart';
import 'package:epub_audio/features/epub/data/datasources/epub_archive.dart';

/// Loads and extracts EPUB ZIP archives from file system or memory bytes.
class EpubArchiveLoader {
  const EpubArchiveLoader();

  /// Extracts an [EpubArchive] from raw byte data.
  Future<EpubArchive> loadFromBytes(Uint8List bytes) async {
    if (bytes.isEmpty) {
      throw const EpubInvalidArchiveException('Cannot load EPUB: byte array is empty');
    }

    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final fileMap = <String, Uint8List>{};

      for (final file in archive.files) {
        if (file.isFile) {
          final content = file.content;
          if (content is Uint8List) {
            fileMap[file.name] = content;
          } else if (content is List<int>) {
            fileMap[file.name] = Uint8List.fromList(content);
          }
        }
      }

      return EpubArchive(fileMap);
    } catch (e, stackTrace) {
      if (e is EpubException) rethrow;
      throw EpubInvalidArchiveException(
        'Failed to decode EPUB ZIP archive: ${e.toString()}',
        stackTrace,
      );
    }
  }

  /// Extracts an [EpubArchive] from a file path.
  Future<EpubArchive> loadFromPath(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw EpubFileNotFoundException('EPUB file not found at path: $filePath');
    }

    try {
      final bytes = await file.readAsBytes();
      return await loadFromBytes(bytes);
    } on EpubException {
      rethrow;
    } catch (e, stackTrace) {
      throw EpubFileNotFoundException(
        'Failed to read EPUB file at path: $filePath ($e)',
        stackTrace,
      );
    }
  }

  /// Extracts an [EpubArchive] from a [File] instance.
  Future<EpubArchive> loadFromFile(File file) async {
    return loadFromPath(file.path);
  }
}
