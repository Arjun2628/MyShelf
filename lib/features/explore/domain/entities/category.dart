/// Domain entity representing a curated Book category with its associated experience identity.
class Category {
  final String id;
  final String name;
  final String tagline;
  final String iconName;
  final String? coverAsset;
  final List<String> bookIds;
  final List<String> tags;
  final String experienceId;

  const Category({
    required this.id,
    required this.name,
    required this.tagline,
    required this.iconName,
    this.coverAsset,
    this.bookIds = const [],
    this.tags = const [],
    required this.experienceId,
  });

  Category copyWith({
    String? id,
    String? name,
    String? tagline,
    String? iconName,
    String? coverAsset,
    List<String>? bookIds,
    List<String>? tags,
    String? experienceId,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      iconName: iconName ?? this.iconName,
      coverAsset: coverAsset ?? this.coverAsset,
      bookIds: bookIds ?? this.bookIds,
      tags: tags ?? this.tags,
      experienceId: experienceId ?? this.experienceId,
    );
  }
}
