import 'dart:io';
import 'package:epub_audio/features/explore/data/repositories/explore_repository_impl.dart';
import 'package:epub_audio/features/explore/domain/entities/book_shelf.dart';
import 'package:epub_audio/features/explore/domain/entities/category.dart';
import 'package:epub_audio/features/explore/presentation/screens/category_experience_screen.dart';
import 'package:epub_audio/features/explore/presentation/screens/explore_screen.dart';
import 'package:epub_audio/features/explore/presentation/widgets/shelf_renderer.dart';
import 'package:epub_audio/features/library/data/datasources/hive_storage_service.dart';
import 'package:epub_audio/features/navigation/presentation/main_navigation_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ExploreRepositoryImpl mockExploreRepo;

  setUp(() async {
    final tempDir = Directory.systemTemp.createTempSync('explore_ui_test_hive');
    await HiveStorageService().init(tempDir.path);
    mockExploreRepo = ExploreRepositoryImpl();
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  testWidgets('ShelfRenderer renders horizontalCarousel, grid, and verticalList styles', (tester) async {
    final books = await mockExploreRepo.getCategoryBooks('cat_malayalam');
    expect(books.isNotEmpty, isTrue);

    await tester.pumpWidget(
      createTestWidget(
        Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                ShelfRenderer(
                  displayStyle: ShelfDisplayStyle.horizontalCarousel,
                  books: books,
                  title: 'Carousel Shelf',
                ),
                ShelfRenderer(
                  displayStyle: ShelfDisplayStyle.horizontalShelf,
                  books: books,
                  title: 'Wood Shelf',
                ),
                ShelfRenderer(
                  displayStyle: ShelfDisplayStyle.grid,
                  books: books,
                  title: 'Grid Shelf',
                ),
                ShelfRenderer(
                  displayStyle: ShelfDisplayStyle.storyCards,
                  books: books,
                  title: 'Story Shelf',
                ),
                ShelfRenderer(
                  displayStyle: ShelfDisplayStyle.verticalList,
                  books: books,
                  title: 'Vertical Shelf',
                ),
                ShelfRenderer(
                  displayStyle: ShelfDisplayStyle.coverCarousel,
                  books: books,
                  title: 'Cover Shelf',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Carousel Shelf'), findsOneWidget);
    expect(find.text('Wood Shelf'), findsOneWidget);
    expect(find.text('Grid Shelf'), findsOneWidget);
    expect(find.text('Story Shelf'), findsOneWidget);
    expect(find.text('Vertical Shelf'), findsOneWidget);
    expect(find.text('Cover Shelf'), findsOneWidget);
  });

  testWidgets('ShelfRenderer renders largeFeatured style', (tester) async {
    final books = await mockExploreRepo.getCategoryBooks('cat_malayalam');

    await tester.pumpWidget(
      createTestWidget(
        Scaffold(
          body: ShelfRenderer(
            displayStyle: ShelfDisplayStyle.largeFeatured,
            books: books,
            title: 'Featured Today',
          ),
        ),
      ),
    );
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(PageView), findsOneWidget);
  });

  testWidgets('ExploreScreen loads sections, greeting, and category items', (tester) async {
    await tester.pumpWidget(
      createTestWidget(
        ExploreScreen(
          repository: mockExploreRepo,
        ),
      ),
    );

    for (int i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.textContaining('Reader'), findsOneWidget);
    expect(find.text('Featured Today'), findsOneWidget);

    // Drag down to reveal categories
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Browse by Mood & Category'), findsOneWidget);
  });

  testWidgets('CategoryExperienceScreen renders atmospheric category theme and book grid', (tester) async {
    const testCategory = Category(
      id: 'cat_history',
      name: 'History & Lore',
      tagline: 'Ancient chronicles',
      iconName: 'history_edu_rounded',
      experienceId: 'exp_history',
      tags: ['History', 'Ancient'],
    );

    await tester.pumpWidget(
      createTestWidget(
        CategoryExperienceScreen(
          category: testCategory,
          repository: mockExploreRepo,
        ),
      ),
    );

    for (int i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('History & Lore'), findsOneWidget);
    expect(find.text('#History'), findsOneWidget);
    expect(find.text('#Ancient'), findsOneWidget);
    expect(find.textContaining('EXPERIENCE • PARCHMENT'), findsOneWidget);
  });

  testWidgets('MainNavigationShell renders bottom navigation tabs and switches views', (tester) async {
    await tester.pumpWidget(
      createTestWidget(
        MainNavigationShell(
          exploreRepository: mockExploreRepo,
        ),
      ),
    );

    for (int i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Verify bottom navigation tabs exist
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Switch to Profile Tab
    await tester.tap(find.text('Profile'));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Profile & Identity'), findsOneWidget);
    expect(find.text('Arjun (Reader)'), findsOneWidget);
    expect(find.textContaining('Reading Streak'), findsOneWidget);
  });
}
