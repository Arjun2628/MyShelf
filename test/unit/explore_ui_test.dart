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

  testWidgets('ExploreScreen renders Grand Bookshelf Wall and toggles to Editorial Feed mode', (tester) async {
    await tester.pumpWidget(
      createTestWidget(
        ExploreScreen(
          repository: mockExploreRepo,
          initialViewMode: ExploreViewMode.discoveryStage,
        ),
      ),
    );

    for (int i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // 1. Verify Header & Mode Switcher tabs
    expect(find.textContaining('Reader'), findsOneWidget);
    expect(find.text('Grand Bookshelf'), findsOneWidget);
    expect(find.text('Editorial Feed'), findsOneWidget);

    // 2. Verify The Grand Library elements
    expect(find.text('THE GRAND LIBRARY'), findsOneWidget);
    expect(find.text('YOUR NEXT STORY AWAITS'), findsOneWidget);
    expect(find.text('All Shelves'), findsOneWidget);
    expect(find.text('SERENDIPITY DISCOVERY'), findsOneWidget);

    // Test Serendipity Discovery Banner Tap
    await tester.tap(find.text('SERENDIPITY DISCOVERY'));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Read Book'), findsOneWidget);

    // Close inspection sheet
    await tester.tap(find.byIcon(Icons.close_rounded));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // 3. Toggle Mode to Editorial Feed
    await tester.tap(find.text('Editorial Feed'));
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Verify classic editorial catalog elements render
    expect(find.text('Featured Today'), findsOneWidget);

    // Scroll down to check categories
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

  testWidgets('GrandBookshelfWallWidget pivots 3D camera and updates wing compass badge on category change', (tester) async {
    await tester.pumpWidget(
      createTestWidget(
        ExploreScreen(
          repository: mockExploreRepo,
          initialViewMode: ExploreViewMode.discoveryStage,
        ),
      ),
    );

    for (int i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Initially at Grand Rotunda Sanctuary
    expect(find.text('GRAND ROTUNDA SANCTUARY'), findsOneWidget);
    expect(find.text('ROTUNDA MAIN HALL • CENTRAL PANORAMA'), findsOneWidget);

    // Tap History & Lore category
    await tester.tap(find.text('History & Lore'));
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Verify camera wing badge updated to Scholar's Reading Desk
    expect(find.text('SCHOLAR\'S READING DESK'), findsOneWidget);
    expect(find.text('GROUND FLOOR • EAST STUDY DESK'), findsOneWidget);

    // Tap Mystery & Crime category
    await tester.tap(find.text('Mystery & Crime'));
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Verify camera wing badge updated to Spiral Staircase Arc
    expect(find.text('SPIRAL STAIRCASE ARC'), findsOneWidget);
    expect(find.text('WEST SPIRAL ASCENT • TIER II'), findsOneWidget);

    // Scroll to and tap Sci-Fi & Time Travel category
    await tester.ensureVisible(find.text('Sci-Fi & Time Travel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sci-Fi & Time Travel'));
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Verify camera wing badge updated to Celestial Dome Balcony
    expect(find.text('CELESTIAL DOME BALCONY'), findsOneWidget);
    expect(find.text('UPPER ROTUNDA • DOME MEZZANINE'), findsOneWidget);
  });

  testWidgets('GrandBookshelfWallWidget renders 3D Tour button and opens Interactive3DRotundaScreen', (tester) async {
    await tester.pumpWidget(
      createTestWidget(
        ExploreScreen(
          repository: mockExploreRepo,
          initialViewMode: ExploreViewMode.discoveryStage,
        ),
      ),
    );

    for (int i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Verify 3D Tour button exists in header
    expect(find.text('3D TOUR'), findsOneWidget);
    expect(find.byIcon(Icons.view_in_ar_rounded), findsWidgets);

    // Tap 3D Tour button
    await tester.tap(find.text('3D TOUR'));
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Verify 3D Rotunda Screen elements
    expect(find.text('3D GRAND ROTUNDA'), findsOneWidget);
    expect(find.text('INTERACTIVE 360° BLENDER MODEL'), findsOneWidget);
    expect(find.text('Interior 360°'), findsOneWidget);
    expect(find.text('Study Desk'), findsOneWidget);
    expect(find.text('Dome Vault'), findsOneWidget);
    expect(find.text('Balcony'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    // Test switching preset chips
    await tester.tap(find.text('Study Desk'));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Test toggling Auto-Rotate
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

    // Close 3D Rotunda screen
    await tester.tap(find.byIcon(Icons.close_rounded));
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('THE GRAND LIBRARY'), findsOneWidget);
  });
}

