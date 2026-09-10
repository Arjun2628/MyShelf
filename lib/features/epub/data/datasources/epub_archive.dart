import 'dart:convert';
import 'dart:typed_data';
import 'package:epub_audio/core/utils/path_utils.dart';

/// In-memory representation of an unpacked EPUB archive.
class EpubArchive {
  final Map<String, Uint8List> _files;

  EpubArchive(Map<String, Uint8List> files) : _files = {} {
    // Store all files keyed by normalized POSIX paths for fast, uniform lookup
    files.forEach((path, bytes) {
      final normalized = EpubPathUtils.normalize(path);
      if (normalized.isNotEmpty) {
        _files[normalized] = bytes;
      }
    });
  }

  /// Checks if a file exists in the archive at the specified path.
  bool hasFile(String path) {
    final normalized = EpubPathUtils.normalize(path);
    return _files.containsKey(normalized);
  }

  /// Reads raw bytes for a file in the archive.
  /// Returns null if the file does not exist.
  Uint8List? readBytes(String path) {
    final normalized = EpubPathUtils.normalize(path);
    return _files[normalized];
  }

  /// Reads a file as a UTF-8 string (or Latin-1 fallback if UTF-8 malformed).
  /// Returns null if the file does not exist.
  String? readText(String path) {
    final bytes = readBytes(path);
    if (bytes == null) return null;
    try {
      return utf8.decode(bytes);
    } catch (_) {
      // Fallback decode with allowance for non-UTF8 legacy encodings
      return utf8.decode(bytes, allowMalformed: true);
    }
  }

  /// Lists all file paths contained in the archive.
  List<String> listFiles() => List.unmodifiable(_files.keys);

  /// Number of files in the archive.
  int get length => _files.length;

  /// True if the archive contains no files.
  bool get isEmpty => _files.isEmpty;
}
