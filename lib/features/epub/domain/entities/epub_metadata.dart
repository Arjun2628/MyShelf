import 'package:meta/meta.dart';

/// Metadata extracted from the EPUB package document.
@immutable
class EpubMetadata {
  final String title;
  final List<String> creators;
  final String? description;
  final String? publisher;
  final String? language;
  final String? identifier;
  final String? publishDate;
  final String? coverImageHref;

  const EpubMetadata({
    required this.title,
    this.creators = const [],
    this.description,
    this.publisher,
    this.language,
    this.identifier,
    this.publishDate,
    this.coverImageHref,
  });

  String get author => creators.isNotEmpty ? creators.join(', ') : 'Unknown Author';

  @override
  String toString() =>
      'EpubMetadata(title: "$title", author: "$author", lang: "$language")';
}
