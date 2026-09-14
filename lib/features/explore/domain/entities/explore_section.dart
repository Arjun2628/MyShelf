import 'package:epub_audio/features/explore/domain/entities/book_shelf.dart';

/// Semantic classification of sections appearing on the Explore screen.
enum ExploreSectionType {
  greeting,
  featured,
  continueReading,
  continueListening,
  categories,
  popular,
  newReleases,
  recommended,
  curated,
}

/// Domain entity representing a configurable visual block on the Explore screen.
class ExploreSection {
  final String id;
  final String title;
  final String? subtitle;
  final ExploreSectionType type;
  final List<String> bookIds;
  final String? categoryId;
  final ShelfDisplayStyle displayStyle;
  final Map<String, dynamic> metadata;
  final String? actionLabel;

  const ExploreSection({
    required this.id,
    required this.title,
    this.subtitle,
    required this.type,
    this.bookIds = const [],
    this.categoryId,
    this.displayStyle = ShelfDisplayStyle.horizontalShelf,
    this.metadata = const {},
    this.actionLabel,
  });

  ExploreSection copyWith({
    String? id,
    String? title,
    String? subtitle,
    ExploreSectionType? type,
    List<String>? bookIds,
    String? categoryId,
    ShelfDisplayStyle? displayStyle,
    Map<String, dynamic>? metadata,
    String? actionLabel,
  }) {
    return ExploreSection(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      type: type ?? this.type,
      bookIds: bookIds ?? this.bookIds,
      categoryId: categoryId ?? this.categoryId,
      displayStyle: displayStyle ?? this.displayStyle,
      metadata: metadata ?? this.metadata,
      actionLabel: actionLabel ?? this.actionLabel,
    );
  }
}
