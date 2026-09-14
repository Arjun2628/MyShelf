import 'package:epub_audio/features/explore/domain/entities/book_shelf.dart';
import 'package:epub_audio/features/explore/domain/entities/category.dart';
import 'package:epub_audio/features/explore/domain/entities/category_experience_config.dart';
import 'package:epub_audio/features/explore/domain/entities/explore_section.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Explore Domain Entities', () {
    test('CategoryExperienceConfig initializes with valid properties and fallback', () {
      const config = CategoryExperienceConfig(
        id: 'exp_test',
        themeId: 'parchment',
        gradientHexColors: ['0xFF2B2217', '0xFF161009'],
        typographyId: 'classical',
        accentColorHex: '0xFFD4A373',
        atmosphereEffectId: 'ink_dust',
        ambientAudioId: 'historical_ambience',
        transitionType: 'page_unfold',
      );

      expect(config.id, 'exp_test');
      expect(config.themeId, 'parchment');
      expect(config.gradientHexColors.length, 2);
      expect(config.accentColorHex, '0xFFD4A373');
      expect(config.transitionType, 'page_unfold');

      expect(CategoryExperienceConfig.defaultConfig.id, 'default_config');
      expect(CategoryExperienceConfig.defaultConfig.themeId, 'obsidian');
    });

    test('Category entity supports copyWith and maintains experience link', () {
      const category = Category(
        id: 'cat_history',
        name: 'History',
        tagline: 'Ancient chronicles',
        iconName: 'history_edu',
        bookIds: ['book_1', 'book_2'],
        tags: ['History', 'Ancient'],
        experienceId: 'exp_history',
      );

      expect(category.bookIds, ['book_1', 'book_2']);
      expect(category.experienceId, 'exp_history');

      final updated = category.copyWith(name: 'World History', bookIds: ['book_1', 'book_2', 'book_3']);
      expect(updated.name, 'World History');
      expect(updated.bookIds.length, 3);
      expect(updated.experienceId, 'exp_history');
    });

    test('BookShelf supports 7 distinct display styles', () {
      for (final style in ShelfDisplayStyle.values) {
        final shelf = BookShelf(
          id: 'shelf_${style.name}',
          title: 'Shelf Title',
          bookIds: ['book_a'],
          displayStyle: style,
        );
        expect(shelf.displayStyle, style);
      }
      expect(ShelfDisplayStyle.values.length, 7);
    });

    test('ExploreSection supports semantic section types and metadata', () {
      const section = ExploreSection(
        id: 'sec_featured',
        title: 'Featured Today',
        subtitle: 'Editor picks',
        type: ExploreSectionType.featured,
        bookIds: ['b1', 'b2'],
        displayStyle: ShelfDisplayStyle.largeFeatured,
        metadata: {'bannerText': 'Exclusive'},
      );

      expect(section.type, ExploreSectionType.featured);
      expect(section.displayStyle, ShelfDisplayStyle.largeFeatured);
      expect(section.metadata['bannerText'], 'Exclusive');
    });
  });
}
