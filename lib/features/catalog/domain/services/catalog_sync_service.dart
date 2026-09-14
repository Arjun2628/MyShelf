import 'package:flutter/foundation.dart';
import '../entities/remote_catalog_manifest.dart';
import '../repositories/remote_catalog_repository.dart';
import '../../data/repositories/remote_catalog_repository_impl.dart';

class CatalogSyncService extends ChangeNotifier {
  static CatalogSyncService? _instance;
  static CatalogSyncService get instance => _instance ??= CatalogSyncService();

  final RemoteCatalogRepository _repository;
  RemoteCatalogManifest? _currentManifest;
  bool _isSyncing = false;
  String? _lastSyncTimestamp;
  String? _errorMessage;

  CatalogSyncService({RemoteCatalogRepository? repository})
      : _repository = repository ?? RemoteCatalogRepositoryImpl() {
    _repository.syncStatusChanges.listen((syncing) {
      _isSyncing = syncing;
      notifyListeners();
    });
  }

  RemoteCatalogManifest? get currentManifest => _currentManifest;
  bool get isSyncing => _isSyncing;
  String? get lastSyncTimestamp => _lastSyncTimestamp;
  String? get errorMessage => _errorMessage;

  Future<RemoteCatalogManifest> syncCatalog() async {
    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final manifest = await _repository.fetchRemoteCatalog();
      _currentManifest = manifest;
      _lastSyncTimestamp = DateTime.now().toLocal().toString().split('.').first;
      _isSyncing = false;
      notifyListeners();
      return manifest;
    } catch (e) {
      _errorMessage = e.toString();
      _isSyncing = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> publishChanges(RemoteCatalogManifest manifest) async {
    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.publishCatalogChanges(manifest);
      _currentManifest = manifest;
      _lastSyncTimestamp = DateTime.now().toLocal().toString().split('.').first;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<bool> backupToCloud({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    _isSyncing = true;
    notifyListeners();
    try {
      final success = await _repository.backupUserData(userId: userId, data: data);
      return success;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> restoreFromCloud(String userId) async {
    _isSyncing = true;
    notifyListeners();
    try {
      return await _repository.restoreUserData(userId);
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
