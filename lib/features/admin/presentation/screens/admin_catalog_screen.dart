import 'package:flutter/material.dart';
import 'package:epub_audio/features/explore/domain/entities/book_shelf.dart';
import 'package:epub_audio/features/catalog/domain/entities/remote_catalog_manifest.dart';
import 'package:epub_audio/features/catalog/domain/services/catalog_sync_service.dart';
import 'package:epub_audio/features/admin/presentation/widgets/edit_shelf_modal.dart';

class AdminCatalogScreen extends StatefulWidget {
  final CatalogSyncService? syncService;

  const AdminCatalogScreen({
    super.key,
    this.syncService,
  });

  @override
  State<AdminCatalogScreen> createState() => _AdminCatalogScreenState();
}

class _AdminCatalogScreenState extends State<AdminCatalogScreen> {
  late CatalogSyncService _syncService;

  List<BookShelf> _curatedShelves = [];
  bool _isLoading = true;
  String _statusMessage = 'Catalog ready';

  @override
  void initState() {
    super.initState();
    _syncService = widget.syncService ?? CatalogSyncService.instance;
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() => _isLoading = true);
    try {
      final manifest = await _syncService.syncCatalog();
      if (mounted) {
        setState(() {
          _curatedShelves = List.from(manifest.shelves);
          _isLoading = false;
          _statusMessage = 'Catalog synced (${_curatedShelves.length} shelves)';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Sync error: $e';
        });
      }
    }
  }

  Future<void> _publishChanges() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Publishing changes...';
    });

    try {
      final manifest = RemoteCatalogManifest(
        version: '1.2.1',
        lastUpdated: DateTime.now(),
        shelves: _curatedShelves,
        featuredBookIds: _curatedShelves.isNotEmpty ? _curatedShelves.first.bookIds : [],
        metadata: {'curator': 'Admin Console', 'action': 'manual_publish'},
      );

      await _syncService.publishChanges(manifest);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Changes published successfully! ✅';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Curated shelves published to Explore!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Publish failed: $e';
        });
      }
    }
  }

  void _openEditShelfModal({BookShelf? shelf, int? index}) {
    EditShelfModal.show(
      context,
      shelf: shelf,
      onSave: (updated) {
        setState(() {
          if (index != null) {
            _curatedShelves[index] = updated;
          } else {
            _curatedShelves.add(updated);
          }
        });
        _publishChanges();
      },
      onDelete: index != null
          ? () {
              setState(() {
                _curatedShelves.removeAt(index);
              });
              _publishChanges();
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvasBg = isDark ? const Color(0xFF0F1117) : const Color(0xFFFAF7F2);
    final cardBg = isDark ? const Color(0xFF1A1D27) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E3446) : const Color(0xFFE5DDD0);
    final titleColor = isDark ? Colors.white : const Color(0xFF1E1812);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const accentColor = Color(0xFF8B5CF6);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: canvasBg,
        appBar: AppBar(
          backgroundColor: canvasBg,
          foregroundColor: titleColor,
          elevation: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  '👑 CURATOR CONSOLE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Catalog & Shelves',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: titleColor),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.cloud_sync_rounded, color: accentColor),
              tooltip: 'Sync Catalog',
              onPressed: _isLoading ? null : _loadCatalog,
            ),
            IconButton(
              icon: const Icon(Icons.publish_rounded, color: Color(0xFF10B981)),
              tooltip: 'Publish Changes',
              onPressed: _isLoading ? null : _publishChanges,
            ),
          ],
          bottom: TabBar(
            indicatorColor: accentColor,
            labelColor: accentColor,
            unselectedLabelColor: subColor,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'Curated Shelves'),
              Tab(text: 'Catalog Books'),
              Tab(text: 'Cloud & Sync'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: accentColor))
            : TabBarView(
                children: [
                  // 1. Curated Shelves Tab
                  _buildShelvesTab(cardBg, borderColor, titleColor, subColor, accentColor),

                  // 2. Catalog Books Tab
                  _buildCatalogBooksTab(cardBg, borderColor, titleColor, subColor, accentColor),

                  // 3. Cloud & Sync Tab
                  _buildCloudSyncTab(cardBg, borderColor, titleColor, subColor, accentColor),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openEditShelfModal(),
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Curated Shelf', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildShelvesTab(
    Color cardBg,
    Color borderColor,
    Color titleColor,
    Color subColor,
    Color accentColor,
  ) {
    if (_curatedShelves.isEmpty) {
      return Center(
        child: Text(
          'No curated shelves configured.\nTap "+ New Curated Shelf" to create one.',
          textAlign: TextAlign.center,
          style: TextStyle(color: subColor, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _curatedShelves.length,
      itemBuilder: (context, index) {
        final shelf = _curatedShelves[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Style icon avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _getStyleEmoji(shelf.displayStyle),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title & Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shelf.title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    if (shelf.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        shelf.subtitle!,
                        style: TextStyle(fontSize: 11.5, color: subColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            shelf.displayStyle.name,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• ${shelf.bookIds.length} books',
                          style: TextStyle(fontSize: 11, color: subColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Edit Action
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Color(0xFFD4A373), size: 18),
                onPressed: () => _openEditShelfModal(shelf: shelf, index: index),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCatalogBooksTab(
    Color cardBg,
    Color borderColor,
    Color titleColor,
    Color subColor,
    Color accentColor,
  ) {
    final catalogBooks = [
      {'id': 'sample_chemmeen', 'title': 'Chemmeen (ചെമ്മീൻ)', 'author': 'Thakazhi Sivasankara Pillai', 'category': 'Kerala Heritage'},
      {'id': 'book_sherlock', 'title': 'The Hound of the Baskervilles', 'author': 'Sir Arthur Conan Doyle', 'category': 'Midnight Mystery'},
      {'id': 'book_starlight', 'title': 'The Starlight Chronicles', 'author': 'Aria Vance', 'category': 'Cosmic Sci-Fi'},
      {'id': 'sample_alice', 'title': 'Alice\'s Adventures in Wonderland', 'author': 'Lewis Carroll', 'category': 'World Classics'},
      {'id': 'book_dracula', 'title': 'Dracula', 'author': 'Bram Stoker', 'category': 'Midnight Mystery'},
      {'id': 'book_indulekha', 'title': 'Indulekha (ഇന്ദുലേഖ)', 'author': 'O. Chandu Menon', 'category': 'Kerala Heritage'},
      {'id': 'book_timemachine', 'title': 'The Time Machine', 'author': 'H.G. Wells', 'category': 'Cosmic Sci-Fi'},
      {'id': 'book_artofwar', 'title': 'The Art of War', 'author': 'Sun Tzu', 'category': 'Ancient Philosophy'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: catalogBooks.length,
      itemBuilder: (context, index) {
        final book = catalogBooks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A373).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Icon(Icons.menu_book_rounded, color: Color(0xFFD4A373), size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book['title']!,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: titleColor),
                    ),
                    Text(
                      book['author']!,
                      style: TextStyle(fontSize: 11.5, color: subColor),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  book['category']!,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: accentColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCloudSyncTab(
    Color cardBg,
    Color borderColor,
    Color titleColor,
    Color subColor,
    Color accentColor,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.cloud_done_rounded, color: Color(0xFF10B981), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Remote Catalog Status',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: titleColor),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Status: $_statusMessage',
                style: TextStyle(fontSize: 12.5, color: subColor),
              ),
              Text(
                'Last Sync: ${_syncService.lastSyncTimestamp ?? "Just now"}',
                style: TextStyle(fontSize: 12, color: subColor),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _loadCatalog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Fetch Remote Manifest', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.backup_rounded, color: Color(0xFFD4A373), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Cloud Snapshot & Backup',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: titleColor),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Create an encrypted cloud snapshot of user bookmarks, highlights, and custom shelves.',
                style: TextStyle(fontSize: 12.5, color: subColor),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final success = await _syncService.backupToCloud(
                    userId: 'usr_arjun_01',
                    data: {
                      'shelvesCount': _curatedShelves.length,
                      'timestamp': DateTime.now().toIso8601String(),
                    },
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Cloud backup snapshot created! ☁️' : 'Backup failed'),
                        backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4A373),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                label: const Text('Create Cloud Backup Snapshot', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getStyleEmoji(ShelfDisplayStyle style) {
    switch (style) {
      case ShelfDisplayStyle.largeFeatured:
        return '🌟';
      case ShelfDisplayStyle.storyCards:
        return '🃏';
      case ShelfDisplayStyle.horizontalCarousel:
        return '🎠';
      case ShelfDisplayStyle.coverCarousel:
        return '📚';
      case ShelfDisplayStyle.horizontalShelf:
        return '➡️';
      case ShelfDisplayStyle.verticalList:
        return '📋';
      case ShelfDisplayStyle.grid:
        return '🔲';
    }
  }
}
