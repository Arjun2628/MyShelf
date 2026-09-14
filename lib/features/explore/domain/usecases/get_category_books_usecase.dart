import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/explore/domain/repositories/explore_repository.dart';

/// Use case to fetch all books associated with a specific category.
class GetCategoryBooksUseCase {
  final ExploreRepository repository;

  const GetCategoryBooksUseCase(this.repository);

  Future<List<Book>> call(String categoryId) {
    return repository.getCategoryBooks(categoryId);
  }
}
