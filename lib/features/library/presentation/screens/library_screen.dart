import 'package:epub_audio/features/audio/presentation/screens/audiobook_player_screen.dart';
import 'package:epub_audio/features/epub/data/repositories/epub_repository_impl.dart';
import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/epub/domain/usecases/open_epub_usecase.dart';
import 'package:epub_audio/features/library/data/datasources/hive_storage_service.dart';
import 'package:epub_audio/features/library/data/sample_books_provider.dart';
import 'package:epub_audio/features/reader/presentation/screens/reader_screen.dart';
import 'package:epub_audio/features/session/presentation/controllers/book_session_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Main Library Screen showing available books, reading progress, and quick Read/Listen actions.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final OpenEpubUseCase _openEpubUseCase =
      const OpenEpubUseCase(EpubRepositoryImpl());
  late final SampleBooksProvider _sampleProvider;

  final List<Book> _books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _sampleProvider = SampleBooksProvider(_openEpubUseCase);
    _loadInitialBooks();
  }

  Future<void> _loadInitialBooks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final importedBooks =
          await HiveStorageService().loadAllImportedBooks(_openEpubUseCase);
      final mlBook = await _sampleProvider.getMalayalamSampleBook();
      final enBook = await _sampleProvider.getEnglishSampleBook();

      if (mounted) {
        setState(() {
          _books.clear();
          _books.addAll([...importedBooks, mlBook, enBook]);
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
        content: Text('Are you sure you want to remove "${book.metadata.title}" from your library?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
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
      });
    }
  }

  void _openReader(Book book) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReaderScreen(book: book),
      ),
    );
    if (mounted) setState(() {});
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
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'EPUB & Audiobook',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload library',
            onPressed: _loadInitialBooks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _books.isEmpty
              ? _buildEmptyState()
              : _buildBookGrid(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _importEpubFile,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Import EPUB'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
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
            Icon(Icons.menu_book_rounded, size: 72, color: Colors.grey.shade400),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookGrid() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Text(
                  'Your Books (${_books.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.58,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final book = _books[index];
                return _buildBookCard(book);
              },
              childCount: _books.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }

  Widget _buildBookCard(Book book) {
    final progress = HiveStorageService().getProgress(book.id);
    final isCustomBook =
        book.id != 'sample_chemmeen' && book.id != 'sample_alice';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                          const BorderRadius.vertical(top: Radius.circular(16)),
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
                        'Ch ${progress.chapterIndex + 1} • P ${progress.paragraphIndex + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Delete button for imported books
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

          // Book Details & Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _openReader(book),
                  child: Text(
                    book.metadata.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
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
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (progress != null && book.chapterCount > 0) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ((progress.chapterIndex + 1) / book.chapterCount)
                          .clamp(0.0, 1.0),
                      minHeight: 3.5,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF2563EB)),
                    ),
                  ),
                ],
                const SizedBox(height: 8),

                // Quick Action Bar: Read & Listen
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _openReader(book),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.menu_book_rounded,
                                  size: 14, color: Color(0xFF334155)),
                              SizedBox(width: 4),
                              Text(
                                'Read',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF334155)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _openAudiobook(book),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.headphones_rounded,
                                  size: 14, color: Color(0xFF2563EB)),
                              const SizedBox(width: 4),
                              Text(
                                progress != null ? 'Resume' : 'Listen',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2563EB)),
                              ),
                            ],
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

  Widget _buildDefaultCover(Book book) {
    final hash = book.metadata.title.hashCode;
    final color1 = HSLColor.fromAHSL(1.0, (hash.abs() % 360).toDouble(), 0.65, 0.45).toColor();
    final color2 = HSLColor.fromAHSL(1.0, ((hash.abs() + 40) % 360).toDouble(), 0.75, 0.35).toColor();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_rounded,
            color: Colors.white.withValues(alpha: 0.6),
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            book.metadata.title,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
