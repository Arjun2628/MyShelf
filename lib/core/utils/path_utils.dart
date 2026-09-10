import 'package:path/path.dart' as p;

/// Utility functions for path normalization and resolution within EPUB archives.
class EpubPathUtils {
  const EpubPathUtils._();

  /// Normalizes path by replacing backslashes with forward slashes,
  /// removing redundant './' or '../', and stripping leading slashes.
  static String normalize(String path) {
    if (path.isEmpty) return '';
    // Unescape URI encoding if present (e.g. %20 -> space)
    String decoded = path;
    try {
      decoded = Uri.decodeFull(path);
    } catch (_) {
      decoded = path;
    }
    // Convert backslashes to forward slashes
    var normalized = decoded.replaceAll('\\', '/');
    // Normalize path components
    normalized = p.posix.normalize(normalized);
    // Strip leading slash or dot slash
    while (normalized.startsWith('/') || normalized.startsWith('./')) {
      if (normalized.startsWith('/')) {
        normalized = normalized.substring(1);
      } else if (normalized.startsWith('./')) {
        normalized = normalized.substring(2);
      }
    }
    return normalized;
  }

  /// Resolves a relative resource path against a base file path inside the EPUB.
  /// Example:
  ///   basePath: "OEBPS/content.opf"
  ///   relativePath: "toc.ncx"
  ///   result: "OEBPS/toc.ncx"
  ///
  ///   basePath: "OEBPS/text/ch1.xhtml"
  ///   relativePath: "../images/cover.jpg"
  ///   result: "OEBPS/images/cover.jpg"
  static String resolve(String basePath, String relativePath) {
    final cleanRelative = normalize(relativePath);
    if (cleanRelative.isEmpty) return '';

    // If the base path has a directory component, join with it
    final baseDir = p.posix.dirname(normalize(basePath));
    if (baseDir == '.' || baseDir.isEmpty) {
      return cleanRelative;
    }

    final joined = p.posix.join(baseDir, cleanRelative);
    return normalize(joined);
  }

  /// Returns the directory containing the given path in POSIX format.
  static String getDirectory(String path) {
    final dir = p.posix.dirname(normalize(path));
    return (dir == '.' || dir.isEmpty) ? '' : dir;
  }
}
