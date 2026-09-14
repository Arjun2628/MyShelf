import 'package:epub_audio/features/explore/domain/entities/book_shelf.dart';

/// Represents a downloadable remote catalog manifest containing curated books,
/// shelves, and experience metadata.
class RemoteCatalogManifest {
  final String version;
  final DateTime lastUpdated;
  final List<BookShelf> shelves;
  final List<String> featuredBookIds;
  final Map<String, dynamic> metadata;

  const RemoteCatalogManifest({
    required this.version,
    required this.lastUpdated,
    required this.shelves,
    required this.featuredBookIds,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'lastUpdated': lastUpdated.toIso8601String(),
      'shelves': shelves
          .map((s) => {
                'id': s.id,
                'title': s.title,
                'subtitle': s.subtitle,
                'bookIds': s.bookIds,
                'displayStyle': s.displayStyle.name,
                'categoryId': s.categoryId,
              })
          .toList(),
      'featuredBookIds': featuredBookIds,
      'metadata': metadata,
    };
  }

  factory RemoteCatalogManifest.fromJson(Map<String, dynamic> json) {
    final rawShelves = json['shelves'] as List<dynamic>? ?? [];
    final parsedShelves = rawShelves.map((item) {
      final map = item as Map<String, dynamic>;
      final styleName = map['displayStyle'] as String?;
      final style = ShelfDisplayStyle.values.firstWhere(
        (s) => s.name == styleName,
        orElse: () => ShelfDisplayStyle.horizontalShelf,
      );

      return BookShelf(
        id: map['id'] as String? ?? 'shelf_remote',
        title: map['title'] as String? ?? 'Curated Shelf',
        subtitle: map['subtitle'] as String?,
        bookIds: (map['bookIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        displayStyle: style,
        categoryId: map['categoryId'] as String?,
      );
    }).toList();

    return RemoteCatalogManifest(
      version: json['version'] as String? ?? '1.0.0',
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'] as String) ?? DateTime.now()
          : DateTime.now(),
      shelves: parsedShelves,
      featuredBookIds: (json['featuredBookIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  RemoteCatalogManifest copyWith({
    String? version,
    DateTime? lastUpdated,
    List<BookShelf>? shelves,
    List<String>? featuredBookIds,
    Map<String, dynamic>? metadata,
  }) {
    return RemoteCatalogManifest(
      version: version ?? this.version,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      shelves: shelves ?? this.shelves,
      featuredBookIds: featuredBookIds ?? this.featuredBookIds,
      metadata: metadata ?? this.metadata,
    );
  }
}
