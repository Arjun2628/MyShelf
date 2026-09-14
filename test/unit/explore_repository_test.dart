import 'package:epub_audio/features/explore/data/repositories/explore_repository_impl.dart';
import 'package:epub_audio/features/explore/domain/entities/explore_section.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExploreRepositoryImpl', () {
    late ExploreRepositoryImpl repository;

    setUp(() {
      repository = ExploreRepositoryImpl();
    });

    test('getExploreSections returns configured sections with distinct types', () async {
      final sections = await repository.getExploreSections();

      expect(sections.isNotEmpty, isTrue);
      expect(sections.any((s) => s.type == ExploreSectionType.greeting), isTrue);
      expect(sections.any((s) => s.type == ExploreSectionType.featured), isTrue);
      expect(sections.any((s) => s.type == ExploreSectionType.categories), isTrue);
    });

    test('getCategories returns rich categories with experience IDs and tags', () async {
      final categories = await repository.getCategories();

      expect(categories.length, greaterThanOrEqualTo(5));
      final history = categories.firstWhere((c) => c.id == 'cat_history');
      expect(history.name, 'History & Lore');
      expect(history.experienceId, 'exp_history');
      expect(history.bookIds.isNotEmpty, isTrue);
    });

    test('getCategoryExperienceConfig resolves valid theme and atmosphere configs', () async {
      final config = await repository.getCategoryExperienceConfig('exp_history');

      expect(config.id, 'exp_history');
      expect(config.themeId, 'parchment');
      expect(config.accentColorHex, '0xFFD4A373');
      expect(config.atmosphereEffectId, 'ink_dust');
    });

    test('getCategoryBooks resolves valid Book entities for a given category', () async {
      final books = await repository.getCategoryBooks('cat_malayalam');

      expect(books.isNotEmpty, isTrue);
      expect(books.first.metadata.title.isNotEmpty, isTrue);
      expect(books.first.chapterCount, greaterThan(0));
    });

    test('getCuratedShelves returns curated shelves with valid display styles', () async {
      final shelves = await repository.getCuratedShelves();

      expect(shelves.isNotEmpty, isTrue);
      for (final shelf in shelves) {
        expect(shelf.bookIds.isNotEmpty, isTrue);
      }
    });

    test('getBookById returns the exact Book entity without duplicating models', () async {
      final book = await repository.getBookById('book_sherlock');

      expect(book, isNotNull);
      expect(book!.metadata.title, contains('Sherlock Holmes'));
      expect(book.metadata.author, 'Arthur Conan Doyle');
      expect(book.spine.isNotEmpty, isTrue);
    });
  });
}
