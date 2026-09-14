import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../library/data/datasources/hive_storage_service.dart';
import '../../domain/entities/remote_catalog_manifest.dart';
import '../../domain/repositories/remote_catalog_repository.dart';
import '../../../explore/domain/entities/book_shelf.dart';

class RemoteCatalogRepositoryImpl implements RemoteCatalogRepository {
  final HiveStorageService _storageService;
  final StreamController<bool> _syncStatusController = StreamController<bool>.broadcast();

  static const String _cachedManifestKey = 'catalog_remote_manifest_v1';
  static const String _cloudBackupPrefix = 'cloud_backup_user_';

  bool _isSyncing = false;
  final int simulatedDelayMs;

  RemoteCatalogRepositoryImpl({
    HiveStorageService? storageService,
    this.simulatedDelayMs = 150,
  }) : _storageService = storageService ?? HiveStorageService();

  @override
  bool get isSyncing => _isSyncing;

  @override
  Stream<bool> get syncStatusChanges => _syncStatusController.stream;

  void _setSyncing(bool val) {
    _isSyncing = val;
    _syncStatusController.add(_isSyncing);
  }

  RemoteCatalogManifest _buildDefaultManifest() {
    return RemoteCatalogManifest(
      version: '1.2.0',
      lastUpdated: DateTime(2026, 9, 15),
      shelves: const [
        BookShelf(
          id: 'shelf_malayalam_masterpieces',
          title: 'Malayalam Literary Classics',
          subtitle: 'Timeless tales from God\'s Own Country',
          bookIds: ['sample_chemmeen', 'book_kayar', 'book_khasak'],
          displayStyle: ShelfDisplayStyle.horizontalCarousel,
          categoryId: 'cat_malayalam',
        ),
        BookShelf(
          id: 'shelf_trending_curators',
          title: 'Curator\'s Spotlight',
          subtitle: 'Handpicked stories with distinct multi-voice narration',
          bookIds: ['book_sherlock', 'sample_chemmeen', 'book_starlight', 'book_alice', 'book_dracula'],
          displayStyle: ShelfDisplayStyle.storyCards,
        ),
        BookShelf(
          id: 'shelf_scifi_dystopia',
          title: 'Sci-Fi & Cosmic Odysseys',
          subtitle: 'High-concept cosmic journeys & futuristic realms',
          bookIds: ['book_starlight', 'book_cyberpunk', 'book_mars'],
          displayStyle: ShelfDisplayStyle.largeFeatured,
          categoryId: 'cat_scifi',
        ),
        BookShelf(
          id: 'shelf_detective_noir',
          title: 'Mystery, Crime & Whodunit',
          subtitle: 'Gripping suspense and deductive thrillers',
          bookIds: ['book_sherlock', 'book_baskerville', 'book_orient_express'],
          displayStyle: ShelfDisplayStyle.coverCarousel,
          categoryId: 'cat_mystery',
        ),
        BookShelf(
          id: 'shelf_bedtime_sleep',
          title: 'Sleep Tales & Ambient Journeys',
          subtitle: 'Gentle pacing and soothing soundscapes for deep rest',
          bookIds: ['book_whispering_pines', 'book_night_sky', 'book_rainy_café'],
          displayStyle: ShelfDisplayStyle.horizontalShelf,
          categoryId: 'cat_sleep',
        ),
        BookShelf(
          id: 'shelf_epic_fantasy',
          title: 'Mythology & High Fantasy',
          subtitle: 'Swords, sorcery, and ancient enchanted realms',
          bookIds: ['book_dragon_realm', 'book_enchanted_forest', 'book_runes'],
          displayStyle: ShelfDisplayStyle.grid,
          categoryId: 'cat_fantasy',
        ),
      ],
      featuredBookIds: ['book_sherlock', 'sample_chemmeen', 'book_starlight'],
      metadata: {'curator': 'Scribble Editorial Board', 'region': 'Global / Malayalam'},
    );
  }

  @override
  Future<RemoteCatalogManifest> fetchRemoteCatalog() async {
    _setSyncing(true);
    try {
      if (simulatedDelayMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: simulatedDelayMs));
      }

      final cached = _storageService.getCustomSetting<String>(_cachedManifestKey);
      if (cached != null && cached.isNotEmpty) {
        final Map<String, dynamic> json = jsonDecode(cached);
        final manifest = RemoteCatalogManifest.fromJson(json);
        _setSyncing(false);
        return manifest;
      }

      final defaultManifest = _buildDefaultManifest();
      await _storageService.setCustomSetting(_cachedManifestKey, jsonEncode(defaultManifest.toJson()));
      _setSyncing(false);
      return defaultManifest;
    } catch (e) {
      debugPrint('[RemoteCatalog] Error fetching catalog: $e');
      _setSyncing(false);
      return _buildDefaultManifest();
    }
  }

  @override
  Future<void> publishCatalogChanges(RemoteCatalogManifest manifest) async {
    _setSyncing(true);
    try {
      if (simulatedDelayMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: simulatedDelayMs));
      }
      final updated = manifest.copyWith(
        lastUpdated: DateTime.now(),
      );
      final jsonStr = jsonEncode(updated.toJson());
      await _storageService.setCustomSetting(_cachedManifestKey, jsonStr);

      // Also persist to curated shelves in Hive
      await _storageService.setCustomSetting(
        'curated_shelves_custom_v1',
        jsonEncode(updated.shelves.map((s) => {
          'id': s.id,
          'title': s.title,
          'subtitle': s.subtitle,
          'bookIds': s.bookIds,
          'displayStyle': s.displayStyle.name,
          'categoryId': s.categoryId,
        }).toList()),
      );
    } finally {
      _setSyncing(false);
    }
  }

  @override
  Future<bool> backupUserData({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    _setSyncing(true);
    try {
      if (simulatedDelayMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: simulatedDelayMs));
      }
      final key = '$_cloudBackupPrefix$userId';
      final payload = {
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
        'data': data,
      };
      await _storageService.setCustomSetting(key, jsonEncode(payload));
      return true;
    } catch (_) {
      return false;
    } finally {
      _setSyncing(false);
    }
  }

  @override
  Future<Map<String, dynamic>?> restoreUserData(String userId) async {
    _setSyncing(true);
    try {
      if (simulatedDelayMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: simulatedDelayMs));
      }
      final key = '$_cloudBackupPrefix$userId';
      final raw = _storageService.getCustomSetting<String>(key);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> payload = jsonDecode(raw);
        return payload['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      _setSyncing(false);
    }
  }

  void dispose() {
    _syncStatusController.close();
  }
}
