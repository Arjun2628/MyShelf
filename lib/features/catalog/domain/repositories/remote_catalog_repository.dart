import '../entities/remote_catalog_manifest.dart';

abstract class RemoteCatalogRepository {
  /// Fetches the latest published remote catalog manifest.
  Future<RemoteCatalogManifest> fetchRemoteCatalog();

  /// Publishes new or modified catalog manifest (Admin only).
  Future<void> publishCatalogChanges(RemoteCatalogManifest manifest);

  /// Backs up user progress and preferences to cloud storage.
  Future<bool> backupUserData({
    required String userId,
    required Map<String, dynamic> data,
  });

  /// Restores user backup data from cloud storage.
  Future<Map<String, dynamic>?> restoreUserData(String userId);

  /// Returns whether a cloud sync is currently in progress.
  bool get isSyncing;

  /// Stream of sync status updates.
  Stream<bool> get syncStatusChanges;
}
