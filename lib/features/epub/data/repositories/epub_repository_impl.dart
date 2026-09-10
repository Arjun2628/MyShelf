import 'dart:typed_data';
import 'package:epub_audio/core/errors/epub_exceptions.dart';
import 'package:epub_audio/features/epub/data/datasources/epub_archive.dart';
import 'package:epub_audio/features/epub/data/datasources/epub_archive_loader.dart';
import 'package:epub_audio/features/epub/data/parsers/container_parser.dart';
import 'package:epub_audio/features/epub/data/parsers/opf_parser.dart';
import 'package:epub_audio/features/epub/data/parsers/toc_parser.dart';
import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/epub/domain/repositories/epub_repository.dart';

/// Concrete implementation of [EpubRepository] orchestrating loader and parsers.
class EpubRepositoryImpl implements EpubRepository {
  final EpubArchiveLoader _archiveLoader;
  final ContainerParser _containerParser;
  final OpfParser _opfParser;
  final TocParser _tocParser;

  const EpubRepositoryImpl({
    EpubArchiveLoader archiveLoader = const EpubArchiveLoader(),
    ContainerParser containerParser = const ContainerParser(),
    OpfParser opfParser = const OpfParser(),
    TocParser tocParser = const TocParser(),
  })  : _archiveLoader = archiveLoader,
        _containerParser = containerParser,
        _opfParser = opfParser,
        _tocParser = tocParser;

  @override
  Future<Book> loadFromBytes(Uint8List bytes, {String? bookId}) async {
    final archive = await _archiveLoader.loadFromBytes(bytes);
    return _buildBookFromArchive(archive, bookId);
  }

  @override
  Future<Book> loadFromPath(String filePath, {String? bookId}) async {
    final archive = await _archiveLoader.loadFromPath(filePath);
    return _buildBookFromArchive(archive, bookId ?? filePath);
  }

  Book _buildBookFromArchive(EpubArchive archive, String? explicitId) {
    // 1. Parse container.xml to locate OPF path
    final opfPath = _containerParser.parseOpfPath(archive);
    if (!archive.hasFile(opfPath)) {
      throw EpubOpfException('OPF file not found in archive at path: $opfPath');
    }

    // 2. Read and parse OPF document
    final opfContent = archive.readText(opfPath);
    if (opfContent == null || opfContent.trim().isEmpty) {
      throw EpubOpfException('OPF file is empty at path: $opfPath');
    }
    final opfData = _opfParser.parse(opfContent, opfPath);

    // 3. Parse Table of Contents
    final toc = _tocParser.parseToc(archive, opfData);

    // 4. Resolve cover image bytes if present
    Uint8List? coverBytes;
    if (opfData.coverItem != null) {
      coverBytes = archive.readBytes(opfData.coverItem!.fullPath);
    }

    final bookId = explicitId ??
        opfData.metadata.identifier ??
        'book_${opfData.metadata.title.hashCode}';

    return Book(
      id: bookId,
      metadata: opfData.metadata,
      manifest: opfData.manifest,
      spine: opfData.spine,
      toc: toc,
      archive: archive,
      coverImageBytes: coverBytes,
    );
  }
}
