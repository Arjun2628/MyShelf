import 'package:epub_audio/features/explore/domain/entities/explore_section.dart';
import 'package:epub_audio/features/explore/domain/repositories/explore_repository.dart';

/// Use case to fetch all configured content sections for the Explore screen.
class GetExploreContentUseCase {
  final ExploreRepository repository;

  const GetExploreContentUseCase(this.repository);

  Future<List<ExploreSection>> call() {
    return repository.getExploreSections();
  }
}
