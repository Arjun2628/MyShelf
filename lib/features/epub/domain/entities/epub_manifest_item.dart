import 'package:meta/meta.dart';

/// Represents a single resource item declared in the OPF `<manifest>`.
@immutable
class EpubManifestItem {
  final String id;
  final String href;
  final String fullPath;
  final String mediaType;
  final String? properties;

  const EpubManifestItem({
    required this.id,
    required this.href,
    required this.fullPath,
    required this.mediaType,
    this.properties,
  });

  bool get isChapter =>
      mediaType == 'application/xhtml+xml' ||
      mediaType == 'text/html' ||
      mediaType == 'application/xml';

  bool get isImage => mediaType.startsWith('image/');

  bool get isCss => mediaType == 'text/css';

  bool get isNcx => mediaType == 'application/x-dtbncx+xml';

  bool get isNav => properties?.split(RegExp(r'\s+')).contains('nav') ?? false;

  bool get isCoverImage =>
      properties?.split(RegExp(r'\s+')).contains('cover-image') ?? false;

  @override
  String toString() =>
      'EpubManifestItem(id: $id, fullPath: $fullPath, mediaType: $mediaType)';
}
