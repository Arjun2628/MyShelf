import 'package:epub_audio/core/errors/epub_exceptions.dart';
import 'package:epub_audio/core/utils/path_utils.dart';
import 'package:epub_audio/features/epub/data/datasources/epub_archive.dart';
import 'package:xml/xml.dart';

/// Parses `META-INF/container.xml` to discover the primary OPF package path.
class ContainerParser {
  static const String containerPath = 'META-INF/container.xml';
  static const String opfMediaType = 'application/oebps-package+xml';

  const ContainerParser();

  /// Extracts the relative path of the primary OPF package file from [archive].
  String parseOpfPath(EpubArchive archive) {
    if (!archive.hasFile(containerPath)) {
      throw const EpubContainerNotFoundException();
    }

    final xmlContent = archive.readText(containerPath);
    if (xmlContent == null || xmlContent.trim().isEmpty) {
      throw const EpubInvalidContainerException(
        'META-INF/container.xml is empty',
      );
    }

    return parseOpfPathFromXml(xmlContent);
  }

  /// Extracts the OPF path directly from XML string content.
  String parseOpfPathFromXml(String xmlContent) {
    try {
      final document = XmlDocument.parse(xmlContent);
      final container = document.findElements('container').firstOrNull ??
          document.rootElement;

      final rootfilesContainer = container.findElements('rootfiles').firstOrNull;
      if (rootfilesContainer == null) {
        throw const EpubInvalidContainerException(
          'Missing <rootfiles> tag in container.xml',
        );
      }

      final rootfiles = rootfilesContainer.findElements('rootfile').toList();
      if (rootfiles.isEmpty) {
        throw const EpubInvalidContainerException(
          'No <rootfile> elements found in container.xml',
        );
      }

      // First try to find a rootfile with standard OPF media-type
      XmlElement? primaryRootfile = rootfiles.firstWhere(
        (rf) => rf.getAttribute('media-type') == opfMediaType,
        orElse: () => rootfiles.first,
      );

      final fullPath = primaryRootfile.getAttribute('full-path');
      if (fullPath == null || fullPath.trim().isEmpty) {
        throw const EpubInvalidContainerException(
          'Found <rootfile> with empty full-path attribute in container.xml',
        );
      }

      return EpubPathUtils.normalize(fullPath.trim());
    } on EpubException {
      rethrow;
    } catch (e, stackTrace) {
      throw EpubInvalidContainerException(
        'Failed to parse META-INF/container.xml: $e',
        stackTrace,
      );
    }
  }
}
