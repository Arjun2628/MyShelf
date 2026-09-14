/// Supported visual arrangements for book shelves in Explore and Categories.
enum ShelfDisplayStyle {
  horizontalCarousel,
  horizontalShelf,
  grid,
  largeFeatured,
  verticalList,
  coverCarousel,
  storyCards,
}

/// Domain entity representing a curated collection of books with a dedicated display style.
class BookShelf {
  final String id;
  final String title;
  final String? subtitle;
  final List<String> bookIds;
  final ShelfDisplayStyle displayStyle;
  final String? categoryId;

  const BookShelf({
    required this.id,
    required this.title,
    this.subtitle,
    required this.bookIds,
    required this.displayStyle,
    this.categoryId,
  });

  BookShelf copyWith({
    String? id,
    String? title,
    String? subtitle,
    List<String>? bookIds,
    ShelfDisplayStyle? displayStyle,
    String? categoryId,
  }) {
    return BookShelf(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      bookIds: bookIds ?? this.bookIds,
      displayStyle: displayStyle ?? this.displayStyle,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}
