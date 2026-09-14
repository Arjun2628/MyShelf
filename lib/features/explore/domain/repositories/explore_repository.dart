import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/explore/domain/entities/book_shelf.dart';
import 'package:epub_audio/features/explore/domain/entities/category.dart';
import 'package:epub_audio/features/explore/domain/entities/category_experience_config.dart';
import 'package:epub_audio/features/explore/domain/entities/explore_section.dart';

/// Contract for discovering and resolving explore sections, curated shelves, categories,
/// and resolving book entities without owning a duplicate Book model.
abstract class ExploreRepository {
  /// Fetches the configured sections to render on the main Explore screen.
  Future<List<ExploreSection>> getExploreSections();

  /// Fetches all available discovery categories.
  Future<List<Category>> getCategories();

  /// Fetches a specific category by its ID.
  Future<Category?> getCategoryById(String categoryId);

  /// Fetches the visual & atmospheric experience configuration for a category.
  Future<CategoryExperienceConfig> getCategoryExperienceConfig(String experienceId);

  /// Fetches the list of books belonging to a specific category.
  Future<List<Book>> getCategoryBooks(String categoryId);

  /// Resolves multiple existing Book entities by their unique IDs.
  Future<List<Book>> getBooksByIds(List<String> bookIds);

  /// Resolves a single existing Book entity by its ID.
  Future<Book?> getBookById(String bookId);

  /// Fetches standalone curated shelves for Explore or discovery views.
  Future<List<BookShelf>> getCuratedShelves();
}
