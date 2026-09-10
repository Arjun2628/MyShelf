import 'package:epub_audio/features/audio/presentation/screens/audiobook_player_screen.dart';
import 'package:epub_audio/features/epub/data/repositories/epub_repository_impl.dart';
import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/epub/domain/usecases/open_epub_usecase.dart';
import 'package:epub_audio/features/library/data/datasources/hive_storage_service.dart';
import 'package:epub_audio/features/library/data/sample_books_provider.dart';
import 'package:epub_audio/features/reader/domain/entities/bookmark.dart';
import 'package:epub_audio/features/reader/domain/entities/text_highlight.dart';
import 'package:epub_audio/features/reader/presentation/screens/reader_screen.dart';
import 'package:epub_audio/features/session/domain/entities/book_progress.dart';
import 'package:epub_audio/features/session/presentation/controllers/book_session_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Main Library Screen showing available books, reading history, row-by-row shelves,
/// interactive search, and a dedicated Saved & Bookmarks section.
class LibraryScreen extends StatefulWidget {
  final int initialTabIndex;

  const LibraryScreen({super.key, this.initialTabIndex = 0});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final OpenEpubUseCase _openEpubUseCase =
      const OpenEpubUseCase(EpubRepositoryImpl());
  late final SampleBooksProvider _sampleProvider;

  final TextEditingController _searchController = TextEditingController();
  final List<Book> _books = [];
  Map<String, BookProgress> _progressMap = {};
  List<BookProgress> _recentProgressList = [];
  List<TextHighlight> _highlights = [];
  List<Bookmark> _bookmarks = [];

  bool _isLoading = true;
  late int _selectedTabIndex; // 0: Library, 1: Saved
  String _searchQuery = '';
  String _selectedFilterTag = 'All'; // 'All', 'In Progress', 'Malayalam', 'English', 'Imported'
  bool _isGridView = false; // Toggle for explore section
  String _savedFilter = 'All'; // 'All', 'Highlights', 'Bookmarks', 'Notes'

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    _sampleProvider = SampleBooksProvider(_openEpubUseCase);
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final importedBooks =
          await HiveStorageService().loadAllImportedBooks(_openEpubUseCase);
      final mlBook = await _sampleProvider.getMalayalamSampleBook();
      final enBook = await _sampleProvider.getEnglishSampleBook();
      final allProgress = HiveStorageService().getAllProgress();
      final recentProgress = HiveStorageService().getRecentProgressList();
      final allHighlights = HiveStorageService().getAllHighlights();
      final allBookmarks = HiveStorageService().getAllBookmarks();

      if (mounted) {
        setState(() {
          _books.clear();
          _books.addAll([...importedBooks, mlBook, enBook]);
          _progressMap = allProgress;
          _recentProgressList = recentProgress;
          _highlights = allHighlights;
          _bookmarks = allBookmarks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _importEpubFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _isLoading = true;
        });

        Book importedBook;
        final bytes = file.bytes;
        if (bytes != null) {
          importedBook = await _openEpubUseCase.fromBytes(
            bytes,
            bookId: file.name,
          );
          await HiveStorageService().saveImportedEpub(
            bytes: bytes,
            book: importedBook,
          );
        } else if (file.path != null) {
          importedBook = await _openEpubUseCase.fromPath(
            file.path!,
            bookId: file.name,
          );
        } else {
          throw Exception('Could not read file data');
        }

        setState(() {
          _books.removeWhere((b) => b.id == importedBook.id);
          _books.insert(0, importedBook);
          _isLoading = false;
        });

        if (mounted) {
          _openReader(importedBook);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import EPUB: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _deleteBook(Book book) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text(
            'Are you sure you want to remove "${book.metadata.title}" from your library?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await HiveStorageService().deleteBook(book.id);
      setState(() {
        _books.removeWhere((b) => b.id == book.id);
        _progressMap.remove(book.id);
        _recentProgressList.removeWhere((p) => p.bookId == book.id);
      });
    }
  }

  Future<void> _deleteHighlight(TextHighlight highlight) async {
    await HiveStorageService().deleteHighlight(highlight.id);
    _loadInitialData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Highlight deleted'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _deleteBookmark(Bookmark bookmark) async {
    await HiveStorageService().deleteBookmark(bookmark.id);
    _loadInitialData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bookmark deleted'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _openReader(Book book, {int? chapterIndex, int? paragraphIndex}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReaderScreen(
          book: book,
          initialChapterIndex: chapterIndex,
          initialParagraphIndex: paragraphIndex,
        ),
      ),
    );
    if (mounted) {
      _loadInitialData();
    }
  }

  void _openAudiobook(Book book) async {
    final session = BookSessionController(book: book);
    session.playAudio();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudiobookPlayerScreen(session: session),
      ),
    );
    if (mounted) {
      _loadInitialData();
    }
  }

  Book? _findBookById(String bookId) {
    try {
      return _books.firstWhere((b) => b.id == bookId);
    } catch (_) {
      return null;
    }
  }

  List<Book> _getFilteredBooks() {
    return _books.where((book) {
      // 1. Search Query Filter
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase().trim();
        final matchesTitle = book.metadata.title.toLowerCase().contains(query);
        final matchesAuthor =
            book.metadata.author.toLowerCase().contains(query);
        final desc = book.metadata.description ?? '';
        final matchesDesc = desc.toLowerCase().contains(query);
        final lang = book.metadata.language ?? '';
        final matchesLang = lang.toLowerCase().contains(query);

        if (!matchesTitle && !matchesAuthor && !matchesDesc && !matchesLang) {
          return false;
        }
      }

      final lang = (book.metadata.language ?? '').toLowerCase();

      // 2. Category Tag Filter
      if (_selectedFilterTag == 'In Progress') {
        return _progressMap.containsKey(book.id);
      } else if (_selectedFilterTag == 'Malayalam') {
        return lang.contains('ml') ||
            book.id.contains('chemmeen') ||
            book.metadata.title.contains('ചെമ്മീൻ');
      } else if (_selectedFilterTag == 'English') {
        return lang.contains('en') ||
            book.id.contains('alice');
      } else if (_selectedFilterTag == 'Imported') {
        return book.id != 'sample_chemmeen' && book.id != 'sample_alice';
      }

      return true;
    }).toList();
  }

  String _formatRelativeTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSaved = _highlights.length + _bookmarks.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _selectedTabIndex == 0 ? 'EPUB & Audiobooks' : 'Saved & Bookmarks',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_selectedTabIndex == 0) ...[
            IconButton(
              icon: Icon(
                _isGridView ? Icons.view_stream_rounded : Icons.grid_view_rounded,
                color: const Color(0xFF334155),
              ),
              tooltip: _isGridView ? 'Shelf View' : 'Grid View',
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF334155)),
            tooltip: 'Reload Library',
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedTabIndex == 0
              ? _buildHomeLibrarySection()
              : _buildSavedSection(),
      floatingActionButton: _selectedTabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _importEpubFile,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Import EPUB',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTabIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        backgroundColor: Colors.white,
        elevation: 3,
        indicatorColor: const Color(0xFFEFF6FF),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon:
                Icon(Icons.auto_stories_rounded, color: Color(0xFF2563EB)),
            label: 'Library',
          ),
          NavigationDestination(
            icon: totalSaved > 0
                ? Badge(
                    label: Text('$totalSaved'),
                    backgroundColor: const Color(0xFF2563EB),
                    child: const Icon(Icons.bookmarks_outlined),
                  )
                : const Icon(Icons.bookmarks_outlined),
            selectedIcon: totalSaved > 0
                ? Badge(
                    label: Text('$totalSaved'),
                    backgroundColor: const Color(0xFF2563EB),
                    child: const Icon(Icons.bookmarks_rounded,
                        color: Color(0xFF2563EB)),
                  )
                : const Icon(Icons.bookmarks_rounded,
                    color: Color(0xFF2563EB)),
            label: 'Saved ($totalSaved)',
          ),
        ],
      ),
    );
  }

  // ----------------- HOME / ROW-BY-ROW LIBRARY SECTION -----------------

  Widget _buildHomeLibrarySection() {
    if (_books.isEmpty) {
      return _buildEmptyState();
    }

    final filteredBooks = _getFilteredBooks();
    final isSearching =
        _searchQuery.trim().isNotEmpty || _selectedFilterTag != 'All';

    // Reading History Books
    final historyBooks = <MapEntry<Book, BookProgress>>[];
    for (final progress in _recentProgressList) {
      final book = _findBookById(progress.bookId);
      if (book != null) {
        historyBooks.add(MapEntry(book, progress));
      }
    }

    // Curated Shelves
    final importedBooks = _books
        .where((b) => b.id != 'sample_chemmeen' && b.id != 'sample_alice')
        .toList();
    final malayalamBooks = _books
        .where((b) =>
            (b.metadata.language ?? '').toLowerCase().contains('ml') ||
            b.id.contains('chemmeen') ||
            b.metadata.title.contains('ചെമ്മീൻ'))
        .toList();
    final englishBooks = _books
        .where((b) =>
            (b.metadata.language ?? '').toLowerCase().contains('en') ||
            b.id.contains('alice'))
        .toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 1. Search Bar & Filter Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(),
                const SizedBox(height: 12),
                _buildCategoryChipsBar(),
              ],
            ),
          ),
        ),

        // 2. If actively searching or filtering, show direct filtered collection
        if (isSearching) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Search Results (${filteredBooks.length})',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const Spacer(),
                  if (_searchQuery.isNotEmpty || _selectedFilterTag != 'All')
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                          _selectedFilterTag = 'All';
                        });
                      },
                      child: const Text('Reset'),
                    ),
                ],
              ),
            ),
          ),
          if (filteredBooks.isEmpty)
            SliverToBoxAdapter(child: _buildEmptySearchState())
          else
            _isGridView
                ? _buildGridSliver(filteredBooks)
                : _buildListSliver(filteredBooks),
        ] else ...[
          // 3. Row 1: Continue Reading / History Shelf
          if (historyBooks.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildShelfHeader(
                title: 'Continue Reading & Listening',
                subtitle: 'Pick up right where you paused',
                icon: Icons.history_rounded,
                iconColor: const Color(0xFF2563EB),
                count: historyBooks.length,
              ),
            ),
            SliverToBoxAdapter(
              child: _buildHistoryShelf(historyBooks),
            ),
          ],

          // 4. Row 2: Featured & Imported Shelf
          if (importedBooks.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildShelfHeader(
                title: 'Your Imported Books',
                subtitle: 'Custom EPUBs on your device',
                icon: Icons.folder_special_rounded,
                iconColor: const Color(0xFF0284C7),
                count: importedBooks.length,
              ),
            ),
            SliverToBoxAdapter(
              child: _buildHorizontalShelf(
                books: importedBooks,
                tagColor: const Color(0xFF0284C7),
                shelfTag: 'Imported',
              ),
            ),
          ],

          // 5. Row 3: Malayalam Literature Shelf
          if (malayalamBooks.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildShelfHeader(
                title: 'Malayalam Literature & Classics',
                subtitle: 'മലയാള സാഹിത്യം • Audio & Sync',
                icon: Icons.local_fire_department_rounded,
                iconColor: const Color(0xFFEA580C),
                count: malayalamBooks.length,
              ),
            ),
            SliverToBoxAdapter(
              child: _buildHorizontalShelf(
                books: malayalamBooks,
                tagColor: const Color(0xFFEA580C),
                shelfTag: 'Malayalam',
              ),
            ),
          ],

          // 6. Row 4: English & Global Classics Shelf
          if (englishBooks.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildShelfHeader(
                title: 'World Classics & Novels',
                subtitle: 'Timeless literary masterpieces',
                icon: Icons.public_rounded,
                iconColor: const Color(0xFF7C3AED),
                count: englishBooks.length,
              ),
            ),
            SliverToBoxAdapter(
              child: _buildHorizontalShelf(
                books: englishBooks,
                tagColor: const Color(0xFF7C3AED),
                shelfTag: 'Classics',
              ),
            ),
          ],

          // 7. Row 5: Explore All Books (Complete Library)
          SliverToBoxAdapter(
            child: _buildShelfHeader(
              title: 'Explore All Books',
              subtitle: 'Full collection in your library',
              icon: Icons.auto_awesome_mosaic_rounded,
              iconColor: const Color(0xFF0F172A),
              count: _books.length,
            ),
          ),
          _isGridView
              ? _buildGridSliver(_books)
              : _buildListSliver(_books),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  // ----------------- SEARCH & FILTER BAR WIDGETS -----------------

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search by book title, author, or language...',
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Color(0xFF64748B)),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryChipsBar() {
    final tags = ['All', 'In Progress', 'Malayalam', 'English', 'Imported'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: tags.map((tag) {
          final isSelected = _selectedFilterTag == tag;
          int count = 0;
          if (tag == 'All') {
            count = _books.length;
          } else if (tag == 'In Progress') {
            count = _recentProgressList.length;
          } else if (tag == 'Malayalam') {
            count = _books
                .where((b) =>
                    (b.metadata.language ?? '').toLowerCase().contains('ml') ||
                    b.id.contains('chemmeen') ||
                    b.metadata.title.contains('ചെമ്മീൻ'))
                .length;
          } else if (tag == 'English') {
            count = _books
                .where((b) =>
                    (b.metadata.language ?? '').toLowerCase().contains('en') ||
                    b.id.contains('alice'))
                .length;
          } else if (tag == 'Imported') {
            count = _books
                .where((b) =>
                    b.id != 'sample_chemmeen' && b.id != 'sample_alice')
                .length;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text('$tag ($count)'),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  _selectedFilterTag = tag;
                });
              },
              selectedColor: const Color(0xFF2563EB),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF475569),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFE2E8F0),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildShelfHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required int count,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------- ROW-BY-ROW HORIZONTAL SHELVES -----------------

  Widget _buildHistoryShelf(List<MapEntry<Book, BookProgress>> historyItems) {
    return SizedBox(
      height: 215,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: historyItems.length,
        itemBuilder: (context, index) {
          final item = historyItems[index];
          final book = item.key;
          final progress = item.value;
          return _buildHistoryCard(book, progress);
        },
      ),
    );
  }

  Widget _buildHistoryCard(Book book, BookProgress progress) {
    final chapterCount = book.chapterCount > 0 ? book.chapterCount : 1;
    final progressFraction =
        ((progress.chapterIndex + 1) / chapterCount).clamp(0.0, 1.0);
    final percent = (progressFraction * 100).toInt();
    final timeStr = _formatRelativeTime(progress.lastUpdated);

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Cover Thumbnail + Title & Author
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mini Cover
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 48,
                    height: 68,
                    child: book.coverImageBytes != null
                        ? Image.memory(
                            book.coverImageBytes!,
                            fit: BoxFit.cover,
                          )
                        : _buildDefaultCover(book, isMini: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.metadata.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        book.metadata.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 11, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 3),
                          Text(
                            timeStr,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Progress Bar & Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chapter ${progress.chapterIndex + 1} of $chapterCount',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Container(
              height: 4.5,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progressFraction,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Resume Actions: Read & Audio
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openReader(
                      book,
                      chapterIndex: progress.chapterIndex,
                      paragraphIndex: progress.paragraphIndex,
                    ),
                    icon: const Icon(Icons.menu_book_rounded, size: 14),
                    label: const Text('Read', style: TextStyle(fontSize: 11.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openAudiobook(book),
                    icon: const Icon(Icons.headphones_rounded, size: 14),
                    label:
                        const Text('Audio', style: TextStyle(fontSize: 11.5)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalShelf({
    required List<Book> books,
    required Color tagColor,
    required String shelfTag,
  }) {
    return SizedBox(
      height: 275,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return _buildShelfBookCard(book, tagColor: tagColor, tag: shelfTag);
        },
      ),
    );
  }

  Widget _buildShelfBookCard(
    Book book, {
    required Color tagColor,
    required String tag,
  }) {
    final progress = _progressMap[book.id];
    final isCustomBook =
        book.id != 'sample_chemmeen' && book.id != 'sample_alice';

    return Container(
      width: 155,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Thumbnail (Tap to Read)
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => _openReader(book),
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(15)),
                      child: book.coverImageBytes != null
                          ? Image.memory(
                              book.coverImageBytes!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : _buildDefaultCover(book),
                    ),
                  ),
                ),
                // Language / Category Tag
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tagColor.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Delete button for custom imported books
                if (isCustomBook)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _deleteBook(book),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Details & Actions
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.metadata.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  book.metadata.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),

                // Read & Audio Buttons
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _openReader(book),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Read',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: InkWell(
                        onTap: () => _openAudiobook(book),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            progress != null ? 'Resume' : 'Listen',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------- SLIVER GRID & LIST VIEWS -----------------

  Widget _buildGridSliver(List<Book> books) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.62,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final book = books[index];
            return _buildBookCard(book);
          },
          childCount: books.length,
        ),
      ),
    );
  }

  Widget _buildListSliver(List<Book> books) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final book = books[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildBookListTile(book),
            );
          },
          childCount: books.length,
        ),
      ),
    );
  }

  Widget _buildBookListTile(Book book) {
    final progress = _progressMap[book.id];
    final isCustomBook =
        book.id != 'sample_chemmeen' && book.id != 'sample_alice';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Cover
            GestureDetector(
              onTap: () => _openReader(book),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 50,
                  height: 72,
                  child: book.coverImageBytes != null
                      ? Image.memory(book.coverImageBytes!, fit: BoxFit.cover)
                      : _buildDefaultCover(book, isMini: true),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.metadata.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.metadata.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${book.chapterCount} Chapters',
                          style: const TextStyle(
                              fontSize: 10.5, color: Color(0xFF475569)),
                        ),
                      ),
                      if (progress != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Ch ${progress.chapterIndex + 1}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.headphones_rounded,
                      color: Color(0xFF2563EB), size: 20),
                  tooltip: 'Listen Audiobook',
                  onPressed: () => _openAudiobook(book),
                ),
                if (isCustomBook)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Color(0xFF94A3B8), size: 18),
                    tooltip: 'Delete Book',
                    onPressed: () => _deleteBook(book),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookCard(Book book) {
    final progress = _progressMap[book.id];
    final isCustomBook =
        book.id != 'sample_chemmeen' && book.id != 'sample_alice';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image with Badges (Tap to Read)
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => _openReader(book),
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(15)),
                      child: book.coverImageBytes != null
                          ? Image.memory(
                              book.coverImageBytes!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : _buildDefaultCover(book),
                    ),
                  ),
                ),
                // Progress Chip
                if (progress != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Ch ${progress.chapterIndex + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Delete button for custom imported books
                if (isCustomBook)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _deleteBook(book),
                        child: const Padding(
                          padding: EdgeInsets.all(5.0),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Details & Actions
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _openReader(book),
                  child: Text(
                    book.metadata.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  book.metadata.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),

                // Quick Action Bar: Read & Listen
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _openReader(book),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Read',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: InkWell(
                        onTap: () => _openAudiobook(book),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            progress != null ? 'Resume' : 'Listen',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultCover(Book book, {bool isMini = false}) {
    final hash = book.metadata.title.hashCode;
    final color1 = HSLColor.fromAHSL(
            1.0, (hash.abs() % 360).toDouble(), 0.65, 0.45)
        .toColor();
    final color2 = HSLColor.fromAHSL(
            1.0, ((hash.abs() + 40) % 360).toDouble(), 0.75, 0.35)
        .toColor();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.all(isMini ? 6 : 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_rounded,
            color: Colors.white.withValues(alpha: 0.7),
            size: isMini ? 18 : 32,
          ),
          if (!isMini) ...[
            const SizedBox(height: 8),
            Text(
              book.metadata.title,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                height: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Padding(
      padding: const EdgeInsets.all(36.0),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded,
                size: 56, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            const Text(
              'No Books Found',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 6),
            Text(
              'No books matched "$_searchQuery". Try searching with different keywords.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_rounded,
                size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No Books in Library',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Import an EPUB file to start reading and listening.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _importEpubFile,
              icon: const Icon(Icons.file_open_rounded),
              label: const Text('Import EPUB File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------- SAVED & BOOKMARKS SECTION -----------------

  Widget _buildSavedSection() {
    final notesOnly = _highlights
        .where((h) => h.note != null && h.note!.isNotEmpty)
        .toList();

    List<dynamic> items = [];
    if (_savedFilter == 'Highlights') {
      items = _highlights;
    } else if (_savedFilter == 'Bookmarks') {
      items = _bookmarks;
    } else if (_savedFilter == 'Notes') {
      items = notesOnly;
    } else {
      items = [..._highlights, ..._bookmarks];
      items.sort((a, b) {
        final DateTime dateA =
            a is TextHighlight ? a.createdAt : (a as Bookmark).createdAt;
        final DateTime dateB =
            b is TextHighlight ? b.createdAt : (b as Bookmark).createdAt;
        return dateB.compareTo(dateA);
      });
    }

    return Column(
      children: [
        // Filter Pills Bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSavedFilterChip(
                    'All', _highlights.length + _bookmarks.length),
                const SizedBox(width: 8),
                _buildSavedFilterChip('Highlights', _highlights.length),
                const SizedBox(width: 8),
                _buildSavedFilterChip('Bookmarks', _bookmarks.length),
                const SizedBox(width: 8),
                _buildSavedFilterChip('Notes', notesOnly.length),
              ],
            ),
          ),
        ),

        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // Content List
        Expanded(
          child: items.isEmpty
              ? _buildEmptySavedState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    if (item is TextHighlight) {
                      return _buildHighlightCard(item);
                    } else if (item is Bookmark) {
                      return _buildBookmarkCard(item);
                    }
                    return const SizedBox.shrink();
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSavedFilterChip(String label, int count) {
    final isSelected = _savedFilter == label;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (val) {
        setState(() {
          _savedFilter = label;
        });
      },
      selectedColor: const Color(0xFF2563EB),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF475569),
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      ),
      backgroundColor: const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(
        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _buildEmptySavedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmarks_outlined,
                size: 48,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _savedFilter == 'All'
                  ? 'No Saved Items Yet'
                  : 'No $_savedFilter Found',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select words while reading to highlight, translate, or bookmark chapters. They will all appear here for quick access.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedTabIndex = 0;
                });
              },
              icon: const Icon(Icons.menu_book_rounded),
              label: const Text('Go to Library'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightCard(TextHighlight highlight) {
    final book = _findBookById(highlight.bookId);
    final bookTitle = book?.metadata.title ?? 'Book: ${highlight.bookId}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: highlight.color, width: 5.0),
            ),
          ),
          padding: const EdgeInsets.all(14.0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Book Title, Chapter, Highlight Color Indicator, Delete
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: highlight.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bookTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Ch ${highlight.chapterIndex + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: Color(0xFF94A3B8)),
                  tooltip: 'Delete Highlight',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _deleteHighlight(highlight),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Highlighted Quote Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: highlight.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"${highlight.selectedText}"',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF334155),
                  height: 1.4,
                ),
              ),
            ),

            // Attached Note / Translation (if any)
            if (highlight.note != null && highlight.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.translate_rounded,
                        size: 16, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        highlight.note!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Bottom Action: Read in Chapter
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.menu_book_rounded, size: 15),
                label: const Text('Read in Chapter'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  textStyle:
                      const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  if (book != null) {
                    _openReader(book, chapterIndex: highlight.chapterIndex);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildBookmarkCard(Bookmark bookmark) {
    final book = _findBookById(bookmark.bookId);
    final bookTitle = book?.metadata.title ?? 'Book: ${bookmark.bookId}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: Color(0xFF2563EB), width: 5.0),
            ),
          ),
          padding: const EdgeInsets.all(14.0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Bookmark Icon, Book Title, Chapter, Delete
            Row(
              children: [
                const Icon(Icons.bookmark_rounded,
                    size: 18, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bookTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    bookmark.chapterTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: Color(0xFF94A3B8)),
                  tooltip: 'Delete Bookmark',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _deleteBookmark(bookmark),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Snippet Preview
            Text(
              bookmark.snippet,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.4,
              ),
            ),

            const SizedBox(height: 10),

            // Bottom Action: Jump to Bookmark
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                label: const Text('Jump to Bookmark'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  textStyle:
                      const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  if (book != null) {
                    _openReader(book, chapterIndex: bookmark.chapterIndex);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
