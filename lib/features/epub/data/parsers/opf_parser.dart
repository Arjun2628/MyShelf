import 'package:epub_audio/core/errors/epub_exceptions.dart';
import 'package:epub_audio/core/utils/path_utils.dart';
import 'package:epub_audio/features/epub/domain/entities/epub_manifest_item.dart';
import 'package:epub_audio/features/epub/domain/entities/epub_metadata.dart';
import 'package:epub_audio/features/epub/domain/entities/epub_spine_item.dart';
import 'package:xml/xml.dart';

/// Parsed data package extracted from the OPF file.
class OpfPackageData {
  final EpubMetadata metadata;
  final Map<String, EpubManifestItem> manifest;
  final List<EpubSpineItem> spine;
  final EpubManifestItem? tocItem;
  final EpubManifestItem? coverItem;

  const OpfPackageData({
    required this.metadata,
    required this.manifest,
    required this.spine,
    this.tocItem,
    this.coverItem,
  });
}

/// Parses the OPF package document (Metadata, Manifest, Spine).
class OpfParser {
  const OpfParser();

  /// Parses OPF XML content given the [opfFilePath] inside the archive.
  OpfPackageData parse(String opfXmlContent, String opfFilePath) {
    try {
      final document = XmlDocument.parse(opfXmlContent);
      final packageElement = document.findElements('package').firstOrNull ??
          document.rootElement;

      // 1. Parse Manifest
      final manifestElement =
          packageElement.findElements('manifest').firstOrNull;
      if (manifestElement == null) {
        throw const EpubOpfException('OPF document missing <manifest> element');
      }
      final manifest = _parseManifest(manifestElement, opfFilePath);

      // 2. Parse Metadata
      final metadataElement =
          packageElement.findElements('metadata').firstOrNull;
      final metadata = _parseMetadata(metadataElement, manifest);

      // 3. Parse Spine
      final spineElement = packageElement.findElements('spine').firstOrNull;
      if (spineElement == null) {
        throw const EpubOpfException('OPF document missing <spine> element');
      }
      final spine = _parseSpine(spineElement, manifest);

      // 4. Identify TOC manifest item
      final tocItem = _findTocItem(spineElement, manifest);

      // 5. Identify Cover image manifest item
      final coverItem = _findCoverItem(metadataElement, manifest);

      return OpfPackageData(
        metadata: metadata,
        manifest: manifest,
        spine: spine,
        tocItem: tocItem,
        coverItem: coverItem,
      );
    } on EpubException {
      rethrow;
    } catch (e, stackTrace) {
      throw EpubOpfException('Failed to parse OPF package: $e', stackTrace);
    }
  }

  Map<String, EpubManifestItem> _parseManifest(
    XmlElement manifestElement,
    String opfFilePath,
  ) {
    final manifest = <String, EpubManifestItem>{};

    for (final item in manifestElement.findElements('item')) {
      final id = item.getAttribute('id');
      final href = item.getAttribute('href');
      final mediaType = item.getAttribute('media-type');
      final properties = item.getAttribute('properties');

      if (id != null && href != null && mediaType != null) {
        final fullPath = EpubPathUtils.resolve(opfFilePath, href);
        manifest[id] = EpubManifestItem(
          id: id,
          href: href,
          fullPath: fullPath,
          mediaType: mediaType,
          properties: properties,
        );
      }
    }

    if (manifest.isEmpty) {
      throw const EpubOpfException('<manifest> contains no valid <item> tags');
    }

    return manifest;
  }

  EpubMetadata _parseMetadata(
    XmlElement? metadataElement,
    Map<String, EpubManifestItem> manifest,
  ) {
    if (metadataElement == null) {
      return const EpubMetadata(title: 'Untitled');
    }

    String title = 'Untitled';
    final creators = <String>[];
    String? description;
    String? publisher;
    String? language;
    String? identifier;
    String? publishDate;

    for (final child in metadataElement.children.whereType<XmlElement>()) {
      final localName = child.name.local.toLowerCase();
      final text = child.innerText.trim();

      switch (localName) {
        case 'title':
          if (text.isNotEmpty) title = text;
          break;
        case 'creator':
        case 'author':
          if (text.isNotEmpty) creators.add(text);
          break;
        case 'description':
          if (text.isNotEmpty) description = text;
          break;
        case 'publisher':
          if (text.isNotEmpty) publisher = text;
          break;
        case 'language':
          if (text.isNotEmpty) language = text;
          break;
        case 'identifier':
          if (text.isNotEmpty && identifier == null) identifier = text;
          break;
        case 'date':
          if (text.isNotEmpty && publishDate == null) publishDate = text;
          break;
      }
    }

    // Attempt to locate cover image href from manifest or meta tag
    String? coverHref;
    final coverMeta = metadataElement.findElements('meta').firstWhere(
          (m) => m.getAttribute('name')?.toLowerCase() == 'cover',
          orElse: () => XmlElement(XmlName('')),
        );
    final coverId = coverMeta.getAttribute('content');
    if (coverId != null && manifest.containsKey(coverId)) {
      coverHref = manifest[coverId]?.fullPath;
    }

    return EpubMetadata(
      title: title,
      creators: creators,
      description: description,
      publisher: publisher,
      language: language,
      identifier: identifier,
      publishDate: publishDate,
      coverImageHref: coverHref,
    );
  }

  List<EpubSpineItem> _parseSpine(
    XmlElement spineElement,
    Map<String, EpubManifestItem> manifest,
  ) {
    final spine = <EpubSpineItem>[];
    int index = 0;

    for (final itemref in spineElement.findElements('itemref')) {
      final idref = itemref.getAttribute('idref');
      final linearAttr = itemref.getAttribute('linear')?.toLowerCase();
      final isLinear = linearAttr != 'no';

      if (idref != null) {
        final manifestItem = manifest[idref];
        if (manifestItem != null) {
          spine.add(
            EpubSpineItem(
              idref: idref,
              fullPath: manifestItem.fullPath,
              index: index++,
              isLinear: isLinear,
            ),
          );
        }
      }
    }

    if (spine.isEmpty) {
      throw const EpubOpfException('<spine> has no resolvable <itemref> items');
    }

    return spine;
  }

  EpubManifestItem? _findTocItem(
    XmlElement spineElement,
    Map<String, EpubManifestItem> manifest,
  ) {
    // 1. Check EPUB 3 nav property in manifest
    for (final item in manifest.values) {
      if (item.isNav) return item;
    }

    // 2. Check EPUB 2 toc attribute on <spine toc="ncx-id">
    final tocId = spineElement.getAttribute('toc');
    if (tocId != null && manifest.containsKey(tocId)) {
      return manifest[tocId];
    }

    // 3. Check for any NCX item in manifest
    for (final item in manifest.values) {
      if (item.isNcx) return item;
    }

    return null;
  }

  EpubManifestItem? _findCoverItem(
    XmlElement? metadataElement,
    Map<String, EpubManifestItem> manifest,
  ) {
    // 1. Check EPUB 3 cover-image property in manifest
    for (final item in manifest.values) {
      if (item.isCoverImage) return item;
    }

    // 2. Check EPUB 2 <meta name="cover" content="..."> in metadata
    if (metadataElement != null) {
      for (final meta in metadataElement.findElements('meta')) {
        if (meta.getAttribute('name')?.toLowerCase() == 'cover') {
          final content = meta.getAttribute('content');
          if (content != null && manifest.containsKey(content)) {
            return manifest[content];
          }
        }
      }
    }

    // 3. Heuristic fallback: check id/href containing 'cover'
    for (final item in manifest.values) {
      if (item.isImage &&
          (item.id.toLowerCase().contains('cover') ||
              item.href.toLowerCase().contains('cover'))) {
        return item;
      }
    }

    return null;
  }
}
