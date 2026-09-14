import 'dart:convert';
import 'dart:io';
import 'package:epub_audio/features/admin/presentation/screens/admin_catalog_screen.dart';
import 'package:epub_audio/features/admin/presentation/widgets/edit_shelf_modal.dart';
import 'package:epub_audio/features/catalog/data/repositories/remote_catalog_repository_impl.dart';
import 'package:epub_audio/features/catalog/domain/entities/remote_catalog_manifest.dart';
import 'package:epub_audio/features/catalog/domain/services/catalog_sync_service.dart';
import 'package:epub_audio/features/explore/data/repositories/explore_repository_impl.dart';
import 'package:epub_audio/features/explore/domain/entities/book_shelf.dart';
import 'package:epub_audio/features/library/data/datasources/hive_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late HiveStorageService storageService;
  late RemoteCatalogRepositoryImpl catalogRepo;
  late CatalogSyncService syncService;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('catalog_sync_test_');
    storageService = HiveStorageService();
    await storageService.init(tempDir.path);
    catalogRepo = RemoteCatalogRepositoryImpl(storageService: storageService);
    syncService = CatalogSyncService(repository: catalogRepo);
  });

  tearDown(() async {
    await storageService.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('RemoteCatalogManifest Domain Entity', () {
    test('RemoteCatalogManifest roundtrip to and from JSON', () {
      final manifest = RemoteCatalogManifest(
        version: '1.2.0',
        lastUpdated: DateTime(2026, 9, 15),
        shelves: const [
          BookShelf(
            id: 'shelf_test_1',
            title: 'Quantum Horizons',
            subtitle: 'Cosmic Journeys',
            displayStyle: ShelfDisplayStyle.storyCards,
            bookIds: ['book_sherlock', 'book_starlight'],
            categoryId: 'cat_scifi',
          ),
        ],
        featuredBookIds: const ['book_sherlock'],
        metadata: const {'curator': 'Scribble Editorial'},
      );

      final json = manifest.toJson();
      final fromJson = RemoteCatalogManifest.fromJson(json);

      expect(fromJson.version, '1.2.0');
      expect(fromJson.shelves.length, 1);
      expect(fromJson.shelves.first.title, 'Quantum Horizons');
      expect(fromJson.shelves.first.displayStyle, ShelfDisplayStyle.storyCards);
      expect(fromJson.featuredBookIds, ['book_sherlock']);
      expect(fromJson.metadata['curator'], 'Scribble Editorial');

      final updated = manifest.copyWith(version: '2.0.0');
      expect(updated.version, '2.0.0');
      expect(updated.shelves.length, 1);
    });
  });

  group('RemoteCatalogRepository & Sync Lifecycle', () {
    test('fetches default catalog manifest when no remote cache exists', () async {
      final manifest = await catalogRepo.fetchRemoteCatalog();
      expect(manifest.shelves, isNotEmpty);
      expect(manifest.featuredBookIds, isNotEmpty);
      expect(manifest.shelves.first.title, 'Malayalam Literary Classics');
    });

    test('publishes custom shelf updates to persistent Hive storage', () async {
      const customShelf = BookShelf(
        id: 'shelf_curated_custom_1',
        title: 'Masterpieces of Philosophy',
        subtitle: 'Mind expanding classics',
        displayStyle: ShelfDisplayStyle.coverCarousel,
        bookIds: ['sample_book_1', 'sample_book_2'],
      );

      final currentManifest = await catalogRepo.fetchRemoteCatalog();
      final updatedManifest = currentManifest.copyWith(
        shelves: [customShelf, ...currentManifest.shelves],
      );

      await catalogRepo.publishCatalogChanges(updatedManifest);

      // Verify manifest reflects published shelf
      final freshManifest = await catalogRepo.fetchRemoteCatalog();
      final found = freshManifest.shelves.any((s) => s.id == 'shelf_curated_custom_1');
      expect(found, isTrue);
    });

    test('creates and restores cloud backup snapshots', () async {
      final backupData = {
        'bookmarks': ['bm_1', 'bm_2'],
        'readingGoalMinutes': 45,
      };

      final backupSuccess = await catalogRepo.backupUserData(
        userId: 'usr_test_cloud',
        data: backupData,
      );
      expect(backupSuccess, isTrue);

      final restored = await catalogRepo.restoreUserData('usr_test_cloud');
      expect(restored, isNotNull);
      expect(restored!['readingGoalMinutes'], 45);
      expect(restored['bookmarks'], ['bm_1', 'bm_2']);
    });
  });

  group('CatalogSyncService Coordinator Operations', () {
    test('syncs catalog and manages shelf modifications', () async {
      final initialManifest = await syncService.syncCatalog();
      final initialCount = initialManifest.shelves.length;

      const newShelf = BookShelf(
        id: 'new_shelf_test',
        title: 'Cyberpunk Chronicles',
        subtitle: 'High tech, low life',
        displayStyle: ShelfDisplayStyle.storyCards,
        bookIds: ['sample_book_1'],
      );

      final updatedManifest = initialManifest.copyWith(
        shelves: [newShelf, ...initialManifest.shelves],
      );

      await syncService.publishChanges(updatedManifest);
      expect(syncService.currentManifest?.shelves.length, initialCount + 1);
      expect(syncService.currentManifest?.shelves.first.id, 'new_shelf_test');

      // Cloud backup via sync service
      final backedUp = await syncService.backupToCloud(
        userId: 'usr_service_test',
        data: {'theme': 'dark'},
      );
      expect(backedUp, isTrue);

      final restored = await syncService.restoreFromCloud('usr_service_test');
      expect(restored?['theme'], 'dark');
    });
  });

  group('ExploreRepositoryImpl Integration with Curated Shelves', () {
    test('dynamically retrieves custom curated shelves from Hive', () async {
      final customShelvesJson = jsonEncode([
        {
          'id': 'custom_shelf_explore_integration',
          'title': 'Curator Top Picks',
          'subtitle': 'Hand-picked wonders',
          'displayStyle': 'largeFeatured',
          'bookIds': ['book_sherlock'],
          'categoryId': 'cat_mystery',
        }
      ]);

      await storageService.setCustomSetting('curated_shelves_custom_v1', customShelvesJson);

      final exploreRepo = ExploreRepositoryImpl(hiveStorageService: storageService);
      final shelves = await exploreRepo.getCuratedShelves();

      expect(shelves, isNotEmpty);
      final hasCustomShelf = shelves.any((s) => s.id == 'custom_shelf_explore_integration');
      expect(hasCustomShelf, isTrue);
    });
  });

  group('Admin Curator Console & EditShelfModal UI Widget Tests', () {
    testWidgets('EditShelfModal renders and allows shelf customization', (tester) async {
      BookShelf? savedShelf;

      const initialShelf = BookShelf(
        id: 'shelf_edit_test',
        title: 'Original Title',
        subtitle: 'Original Subtitle',
        displayStyle: ShelfDisplayStyle.horizontalShelf,
        bookIds: ['sample_book_1'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  EditShelfModal.show(
                    context,
                    shelf: initialShelf,
                    onSave: (shelf) => savedShelf = shelf,
                  );
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Curated Shelf'), findsOneWidget);
      expect(find.text('Original Title'), findsOneWidget);
      expect(find.text('Original Subtitle'), findsOneWidget);

      // Enter new title
      await tester.enterText(find.byType(TextField).first, 'Updated Shelf Name');
      await tester.pumpAndSettle();

      // Scroll until Save button is visible then tap
      final saveButton = find.text('Save & Apply to Explore');
      await tester.scrollUntilVisible(saveButton, 100.0, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(savedShelf, isNotNull);
      expect(savedShelf!.title, 'Updated Shelf Name');
    });

    testWidgets('AdminCatalogScreen renders tabs and switches views', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: AdminCatalogScreen(
              syncService: syncService,
            ),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Catalog & Shelves'), findsOneWidget);
      expect(find.text('Curated Shelves'), findsOneWidget);
      expect(find.text('Catalog Books'), findsOneWidget);
      expect(find.text('Cloud & Sync'), findsOneWidget);

      // Switch to Catalog Books tab
      await tester.tap(find.text('Catalog Books'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Chemmeen (ചെമ്മീൻ)'), findsOneWidget);

      // Switch to Cloud & Sync tab
      await tester.tap(find.text('Cloud & Sync'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Remote Catalog Status'), findsOneWidget);
      expect(find.text('Create Cloud Backup Snapshot'), findsOneWidget);
    });
  });
}
