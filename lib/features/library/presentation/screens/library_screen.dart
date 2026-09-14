import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:epub_audio/features/audio/presentation/screens/audiobook_player_screen.dart';
import 'package:epub_audio/features/epub/data/repositories/epub_repository_impl.dart';
import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/epub/domain/usecases/open_epub_usecase.dart';
import 'package:epub_audio/features/library/data/datasources/hive_storage_service.dart';
import 'package:epub_audio/features/library/data/sample_books_provider.dart';
import 'package:epub_audio/features/pdf/domain/usecases/open_pdf_usecase.dart';
import 'package:epub_audio/features/reader/domain/entities/bookmark.dart';
import 'package:epub_audio/features/reader/domain/entities/text_highlight.dart';
import 'package:epub_audio/features/reader/presentation/screens/reader_screen.dart';
import 'package:epub_audio/features/scan/data/parsers/scan_document_parser.dart';
import 'package:epub_audio/features/scan/data/services/ocr_service.dart';
import 'package:epub_audio/features/scan/domain/usecases/scan_book_usecase.dart';
import 'package:epub_audio/features/session/domain/entities/book_progress.dart';
import 'package:epub_audio/features/session/presentation/controllers/book_session_controller.dart';
import 'package:epub_audio/features/text_content/data/parsers/text_document_parser.dart';
import 'package:epub_audio/features/text_content/data/services/shared_text_service.dart';
import 'package:epub_audio/features/text_content/domain/entities/text_document.dart';
import 'package:epub_audio/features/text_content/presentation/screens/text_editor_screen.dart';
import 'package:epub_audio/features/text_content/presentation/widgets/quick_paste_modal.dart';
import 'package:epub_audio/main.dart';
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
  final OpenPdfUseCase _openPdfUseCase = OpenPdfUseCase();
  final ScanBookUseCase _scanBookUseCase = ScanBookUseCase();
  final ScanDocumentParser _scanParser = ScanDocumentParser();
  final TextDocumentParser _textParser = TextDocumentParser();
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

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _canvasBg => _isDark ? const Color(0xFF16120E) : const Color(0xFFF3ECE0);
  Color get _cardBg => _isDark ? const Color(0xFF221B14) : const Color(0xFFFFFDF8);
  Color get _cardBorder => _isDark ? const Color(0xFF382F24) : const Color(0xFFDDD2BA);
  Color get _textPrimary => _isDark ? const Color(0xFFF7F1E6) : const Color(0xFF2B2620);
  Color get _textSecondary => _isDark ? const Color(0xFFA99C85) : const Color(0xFF857863);
  Color get _chipBg => _isDark ? const Color(0xFF2C241B) : const Color(0xFFEBE2D0);
  Color get _iconColor => _isDark ? const Color(0xFFDCCFBB) : const Color(0xFF383127);
  Color get _goldAccent => _isDark ? const Color(0xFFE0B45F) : const Color(0xFFC99538);
  Color get _navBarBg => _isDark ? const Color(0xFF1D1711) : const Color(0xFF2B2620);
  Color get _navBarActive => const Color(0xFFF3ECE0);
  Color get _navBarInactive => const Color(0xFFA99C85);

  void _showThemeSelectionModal() {
    final currentMode = appThemeModeNotifier.value;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final modalBg = isDark ? const Color(0xFF221B14) : const Color(0xFFFFFDF8);
        final textColor = isDark ? const Color(0xFFF7F1E6) : const Color(0xFF2B2620);
        final subTextColor = isDark ? const Color(0xFFA99C85) : const Color(0xFF857863);

        return Container(
          decoration: BoxDecoration(
            color: modalBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark ? const Color(0xFF382F24) : const Color(0xFFDDD2BA),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF4A3E31) : const Color(0xFFC7BBA5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Choose App Theme',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
                    letterSpacing: 0.5,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Customize the application look & feel',
                  style: TextStyle(fontSize: 13, color: subTextColor),
                ),
                const SizedBox(height: 18),
                _buildThemeOptionTile(
                  icon: Icons.brightness_auto_rounded,
                  title: 'System Default',
                  subtitle: 'Follow device appearance setting',
                  mode: ThemeMode.system,
                  isSelected: currentMode == ThemeMode.system,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildThemeOptionTile(
                  icon: Icons.light_mode_rounded,
                  title: 'Light Theme',
                  subtitle: 'Crisp, warm parchment linen surfaces',
                  mode: ThemeMode.light,
                  isSelected: currentMode == ThemeMode.light,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildThemeOptionTile(
                  icon: Icons.dark_mode_rounded,
                  title: 'Dark Theme',
                  subtitle: 'Deep ebony night aesthetic with gold accents',
                  mode: ThemeMode.dark,
                  isSelected: currentMode == ThemeMode.dark,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeMode mode,
    required bool isSelected,
    required bool isDark,
  }) {
    final gold = isDark ? const Color(0xFFE0B45F) : const Color(0xFFC99538);
    return _TappableScale(
      onTap: () async {
        Navigator.pop(context);
        appThemeModeNotifier.value = mode;
        await HiveStorageService().setAppThemeMode(mode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? gold.withValues(alpha: isDark ? 0.2 : 0.12)
              : (isDark ? const Color(0xFF2C241B) : const Color(0xFFF3ECE0)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? gold
                : (isDark ? const Color(0xFF382F24) : const Color(0xFFDDD2BA)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? gold
                  : (isDark ? const Color(0xFFDCCFBB) : const Color(0xFF6E624E)),
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14.5,
                      color: isDark ? const Color(0xFFF7F1E6) : const Color(0xFF2B2620),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFFA99C85) : const Color(0xFF857863),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: gold,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  StreamSubscription<String>? _sharedTextSubscription;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    _sampleProvider = SampleBooksProvider(_openEpubUseCase);
    _loadInitialData();
    _initSharedTextListener();
  }

  void _initSharedTextListener() {
    SharedTextService.initialize();
    _sharedTextSubscription = SharedTextService.sharedTextStream.listen((text) {
      if (mounted && text.trim().isNotEmpty) {
        _handleSharedText(text);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initialText = await SharedTextService.getInitialSharedText();
      if (initialText != null && initialText.trim().isNotEmpty && mounted) {
        _handleSharedText(initialText);
      }
    });
  }

  void _handleSharedText(String text) {
    if (text.trim().isEmpty) return;
    final lines = text
        .trim()
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final firstLine = lines.isNotEmpty
        ? lines.first.replaceAll(RegExp(r'^#+\s*'), '')
        : 'Shared Note';
    final title =
        firstLine.length > 40 ? '${firstLine.substring(0, 37)}...' : firstLine;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TextEditorScreen(
          initialTitle: title,
          initialContent: text,
          source: 'shared_text',
        ),
      ),
    ).then((_) => _loadInitialData());
  }

  @override
  void dispose() {
    _sharedTextSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final importedBooks = await HiveStorageService().loadAllImportedBooks(
        _openEpubUseCase,
        _openPdfUseCase,
        _scanParser,
        _textParser,
      );
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

  Future<void> _importBookFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub', 'pdf', 'txt', 'md'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _isLoading = true;
        });

        Book importedBook;
        final isPdf = file.name.toLowerCase().endsWith('.pdf');
        final isTxt = file.name.toLowerCase().endsWith('.txt') ||
            file.name.toLowerCase().endsWith('.md');
        final bytes = file.bytes;

        if (isTxt) {
          final String textContent;
          if (bytes != null) {
            textContent = utf8.decode(bytes, allowMalformed: true);
          } else if (file.path != null) {
            textContent = await File(file.path!).readAsString();
          } else {
            throw Exception('Could not read text file data');
          }

          final cleanTitle = file.name.replaceAll(
            RegExp(r'\.(txt|md)$', caseSensitive: false),
            '',
          );
          final doc = TextDocument(
            id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
            title: cleanTitle,
            content: textContent,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            source: 'file_import',
          );
          await HiveStorageService().saveTextDocument(doc);
          importedBook = _textParser.parseDocument(doc);
        } else if (isPdf) {
          if (bytes != null) {
            importedBook = await _openPdfUseCase.fromBytes(
              bytes,
              bookId: file.name,
              fallbackTitle: file.name,
            );
            await HiveStorageService().saveImportedBook(
              bytes: bytes,
              book: importedBook,
              isPdf: true,
            );
          } else if (file.path != null) {
            importedBook = await _openPdfUseCase.fromPath(
              file.path!,
              bookId: file.name,
            );
            final fileBytes = await File(file.path!).readAsBytes();
            await HiveStorageService().saveImportedBook(
              bytes: fileBytes,
              book: importedBook,
              isPdf: true,
            );
          } else {
            throw Exception('Could not read PDF file data');
          }
        } else {
          if (bytes != null) {
            importedBook = await _openEpubUseCase.fromBytes(
              bytes,
              bookId: file.name,
            );
            await HiveStorageService().saveImportedBook(
              bytes: bytes,
              book: importedBook,
              isPdf: false,
            );
          } else if (file.path != null) {
            importedBook = await _openEpubUseCase.fromPath(
              file.path!,
              bookId: file.name,
            );
            final fileBytes = await File(file.path!).readAsBytes();
            await HiveStorageService().saveImportedBook(
              bytes: fileBytes,
              book: importedBook,
              isPdf: false,
            );
          } else {
            throw Exception('Could not read EPUB file data');
          }
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
            content: Text('Failed to import book: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Opens the Scan & OCR action sheet to capture from camera or pick photos.
  Future<void> _showScanOptionsModal() async {
    OcrLanguage selectedLanguage = OcrLanguage.auto;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scan & Read (Multi-Language OCR)',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Digitize books in Malayalam, Hindi, English & global languages',
                            style: TextStyle(
                              fontSize: 12,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Language Selection Header & Chips
                Row(
                  children: [
                    Icon(Icons.translate_rounded, size: 16, color: _textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Document Language / Script:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${selectedLanguage.flag} ${selectedLanguage.displayName.split('(').first.trim()}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: OcrLanguage.values.map((lang) {
                      final isSelected = selectedLanguage == lang;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ChoiceChip(
                          avatar: Text(lang.flag, style: const TextStyle(fontSize: 13)),
                          label: Text(lang.displayName),
                          selected: isSelected,
                          onSelected: (val) {
                            setModalState(() {
                              selectedLanguage = lang;
                            });
                          },
                          selectedColor: const Color(0xFFF59E0B),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : _textPrimary,
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                          backgroundColor: _isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFFD97706)
                                : _cardBorder,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),

                _buildScanOptionTile(
                  icon: Icons.camera_alt_rounded,
                  title: 'Take Photo with Camera',
                  subtitle: 'Digitize physical page in ${selectedLanguage.displayName}',
                  gradientColors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                  onTap: () {
                    Navigator.pop(ctx);
                    _runScan(
                      scanAction: (onProgress) => _scanBookUseCase.scanFromCamera(
                        language: selectedLanguage,
                        onProgress: onProgress,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildScanOptionTile(
                  icon: Icons.photo_library_rounded,
                  title: 'Choose from Gallery',
                  subtitle: 'Select a photo in ${selectedLanguage.displayName}',
                  gradientColors: [const Color(0xFF10B981), const Color(0xFF059669)],
                  onTap: () {
                    Navigator.pop(ctx);
                    _runScan(
                      scanAction: (onProgress) => _scanBookUseCase.scanFromGallery(
                        language: selectedLanguage,
                        onProgress: onProgress,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildScanOptionTile(
                  icon: Icons.collections_bookmark_rounded,
                  title: 'Batch Photo Scan',
                  subtitle: 'Select multiple photos to create a multi-page book',
                  gradientColors: [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
                  onTap: () {
                    Navigator.pop(ctx);
                    _runScan(
                      scanAction: (onProgress) => _scanBookUseCase.scanMultipleFromGallery(
                        language: selectedLanguage,
                        onProgress: onProgress,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _textSecondary),
          ],
        ),
      ),
    );
  }

  /// Executes OCR scan action and displays synchronized progress dialog.
  Future<void> _runScan({
    required Future<Book?> Function(ScanProgressCallback onProgress) scanAction,
  }) async {
    double progressValue = 0.0;
    String statusMessage = 'Initializing OCR scanner...';
    StateSetter? dialogSetState;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            dialogSetState = setModalState;
            return PopScope(
              canPop: false,
              child: AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                content: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFEF3C7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.document_scanner_rounded,
                          color: Color(0xFFD97706),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Processing Document',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        statusMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progressValue > 0 ? progressValue : null,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    try {
      final Book? scannedBook = await scanAction((prog, status) {
        if (dialogSetState != null) {
          dialogSetState!(() {
            progressValue = prog;
            statusMessage = status;
          });
        }
      });

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context); // Close progress dialog
      }

      if (scannedBook != null) {
        await HiveStorageService().saveScannedBook(scannedBook);
        setState(() {
          _books.removeWhere((b) => b.id == scannedBook.id);
          _books.insert(0, scannedBook);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Scanned "${scannedBook.metadata.title}" ready!'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          _openReader(scannedBook);
        }
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context); // Close progress dialog
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scan failed: $e'),
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

  void _openTextEditor({TextDocument? doc}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TextEditorScreen(existingDocument: doc),
      ),
    );
    if (result == true || mounted) {
      _loadInitialData();
    }
  }

  void _openQuickPaste() async {
    await QuickPasteModal.show(context);
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
      if (_selectedFilterTag == 'EPUB') {
        return !book.isPdf && !book.isScan && !book.isText;
      } else if (_selectedFilterTag == 'PDF') {
        return book.isPdf && !book.isScan;
      } else if (_selectedFilterTag == 'Scans') {
        return book.isScan;
      } else if (_selectedFilterTag == 'Text & Notes') {
        return book.isText;
      } else if (_selectedFilterTag == 'In Progress') {
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

  /// Builds a visual badge distinguishing EPUB, PDF, Scanned, and Custom Text books.
  Widget _buildFormatBadge(Book book, {bool isMini = false}) {
    final isScan = book.isScan;
    final isPdf = book.isPdf;
    final isText = book.isText;
    final bgColors = isText
        ? [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)]
        : (isScan
            ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
            : (isPdf
                ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                : [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]));
    final icon = isText
        ? Icons.edit_note_rounded
        : (isScan
            ? Icons.document_scanner_rounded
            : (isPdf ? Icons.picture_as_pdf_rounded : Icons.auto_stories_rounded));
    final label = isText ? 'TEXT' : (isScan ? 'SCAN' : (isPdf ? 'PDF' : 'EPUB'));
    final shadowColor = isText
        ? Colors.purple
        : (isScan
            ? Colors.amber
            : (isPdf ? Colors.red : Colors.blue));

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMini ? 5 : 6.5,
        vertical: isMini ? 1.5 : 2.5,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isMini ? 9 : 10.5, color: Colors.white),
          SizedBox(width: isMini ? 2.5 : 3.5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMini ? 8.5 : 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
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
      backgroundColor: _canvasBg,
      appBar: AppBar(
        title: Text(
          _selectedTabIndex == 0 ? 'Epub and audiobooks' : 'Saved & Bookmarks',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'serif',
            letterSpacing: 0.8,
            fontSize: 16.5,
            color: _textPrimary,
          ),
        ),
        backgroundColor: _canvasBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_selectedTabIndex == 0)
            _TappableScale(
              onTap: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  _isGridView ? Icons.view_stream_rounded : Icons.grid_view_rounded,
                  color: _iconColor,
                  size: 21,
                ),
              ),
            ),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: appThemeModeNotifier,
            builder: (context, themeMode, _) {
              final IconData themeIcon;
              if (themeMode == ThemeMode.system) {
                themeIcon = Icons.brightness_auto_rounded;
              } else if (themeMode == ThemeMode.dark) {
                themeIcon = Icons.dark_mode_rounded;
              } else {
                themeIcon = Icons.light_mode_rounded;
              }

              return IconButton(
                icon: Icon(themeIcon, color: _iconColor, size: 21),
                tooltip: 'App Theme',
                onPressed: _showThemeSelectionModal,
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: _goldAccent,
              ),
            )
          : Stack(
              children: [
                _selectedTabIndex == 0
                    ? _buildHomeLibrarySection()
                    : _buildSavedSection(),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildActiveAudioPlayerTile(),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        color: _canvasBg,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
        child: Container(
          decoration: BoxDecoration(
            color: _navBarBg,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isDark ? 0.45 : 0.16),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: _isDark ? const Color(0xFF382F24) : const Color(0xFF3D352B),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: _TappableScale(
                  onTap: () => setState(() => _selectedTabIndex = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedTabIndex == 0
                          ? (_isDark ? const Color(0xFF2C241B) : const Color(0xFF3E362C))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_stories_rounded,
                          size: 18,
                          color: _selectedTabIndex == 0 ? _navBarActive : _navBarInactive,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Library',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 12,
                            letterSpacing: 0.8,
                            fontWeight: _selectedTabIndex == 0 ? FontWeight.bold : FontWeight.w500,
                            color: _selectedTabIndex == 0 ? _navBarActive : _navBarInactive,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TappableScale(
                  onTap: () => setState(() => _selectedTabIndex = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedTabIndex == 1
                          ? (_isDark ? const Color(0xFF2C241B) : const Color(0xFF3E362C))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedTabIndex == 1
                              ? Icons.bookmarks_rounded
                              : Icons.bookmarks_outlined,
                          size: 18,
                          color: _selectedTabIndex == 1 ? _navBarActive : _navBarInactive,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          totalSaved > 0 ? 'Saved ($totalSaved)' : 'Saved (0)',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 12,
                            letterSpacing: 0.8,
                            fontWeight: _selectedTabIndex == 1 ? FontWeight.bold : FontWeight.w500,
                            color: _selectedTabIndex == 1 ? _navBarActive : _navBarInactive,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------- ACTIVE AUDIO PLAYER TILE (HOME SCREEN) -----------------

  Widget _buildActiveAudioPlayerTile() {
    return ValueListenableBuilder<BookSessionController?>(
      valueListenable: BookSessionController.activeSessionNotifier,
      builder: (context, session, _) {
        if (session == null) return const SizedBox.shrink();

        return AnimatedBuilder(
          animation: session,
          builder: (context, _) {
            if (session.audioState.isStopped) {
              return const SizedBox.shrink();
            }

            final isPlaying = session.audioState.isPlaying;
            final book = session.book;
            final chapterTitle = session.currentChapterContent?.title ??
                'Chapter ${session.currentChapterIndex + 1}';
            final paraIdx = session.currentParagraphIndex + 1;
            final totalParas = session.currentChapterParagraphs.length;
            final progressFactor =
                totalParas > 0 ? (paraIdx / totalParas).clamp(0.0, 1.0) : 0.0;

            return Container(
              key: const ValueKey('active_audio_tile'),
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isDark
                      ? [const Color(0xFF1E1812), const Color(0xFF2B2218)]
                      : [const Color(0xFF2B2620), const Color(0xFF383127)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _goldAccent.withValues(alpha: 0.2),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: isPlaying
                      ? _goldAccent.withValues(alpha: 0.6)
                      : (_isDark ? const Color(0xFF4A3E31) : const Color(0xFF5A4D3B)),
                  width: 1.2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _openAudiobook(book),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              // Mini Book Cover with drop shadow and border
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(9),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.45),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: _goldAccent.withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 40,
                                    height: 52,
                                    child: book.coverImageBytes != null
                                        ? Image.memory(
                                            book.coverImageBytes!,
                                            fit: BoxFit.cover,
                                          )
                                        : _buildDefaultCover(book, isMini: true),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Title, Chapter, Paragraph status & Equalizer icon
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        if (isPlaying)
                                          Container(
                                            margin: const EdgeInsets.only(right: 6),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _goldAccent.withValues(alpha: 0.25),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.graphic_eq_rounded,
                                                  size: 13,
                                                  color: Color(0xFFE0B45F),
                                                ),
                                              ],
                                            ),
                                          ),
                                        _buildFormatBadge(book, isMini: true),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            book.metadata.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xFFF3ECE0),
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'serif',
                                              fontSize: 13.5,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      totalParas > 0
                                          ? '$chapterTitle • Para $paraIdx of $totalParas'
                                          : chapterTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFFA99C85),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Quick Audio Controls
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.skip_previous_rounded,
                                      size: 22,
                                      color: Color(0xFFDCCFBB),
                                    ),
                                    tooltip: 'Previous Paragraph',
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                    onPressed: session.previousAudioParagraph,
                                  ),
                                  const SizedBox(width: 4),
                                  _TappableScale(
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFE0B45F),
                                            Color(0xFFC99538),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFE0B45F)
                                                .withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          isPlaying
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          size: 22,
                                          color: const Color(0xFF2B2620),
                                        ),
                                        tooltip: isPlaying ? 'Pause' : 'Play',
                                        padding: EdgeInsets.zero,
                                        onPressed: session.toggleAudioPlayPause,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.skip_next_rounded,
                                      size: 22,
                                      color: Color(0xFFDCCFBB),
                                    ),
                                    tooltip: 'Next Paragraph',
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                    onPressed: session.nextAudioParagraph,
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: Color(0xFFA99C85),
                                    ),
                                    tooltip: 'Stop & Dismiss',
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                    onPressed: session.stopAudio,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Chapter Reading Progress Bar along bottom edge
                    if (totalParas > 0)
                      LinearProgressIndicator(
                        value: progressFactor,
                        minHeight: 2.5,
                        backgroundColor: const Color(0xFF1E1812),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _goldAccent,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
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

    // Top In-Progress or Hero Book
    final Book? heroBook = historyBooks.isNotEmpty
        ? historyBooks.first.key
        : (_books.isNotEmpty ? _books.first : null);
    final BookProgress? heroProgress = historyBooks.isNotEmpty
        ? historyBooks.first.value
        : (heroBook != null ? _progressMap[heroBook.id] : null);

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
        // 1. Quick Actions, Search Bar & Filter Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickActionBar(),
                const SizedBox(height: 12),
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
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'serif',
                      color: _textPrimary,
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
                      child: Text(
                        'Reset',
                        style: TextStyle(color: _goldAccent, fontWeight: FontWeight.bold),
                      ),
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
          // 3. Hero In-Progress Card (Matches demo)
          if (heroBook != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: _buildHeroInProgressCard(heroBook, heroProgress),
              ),
            ),

          // 4. Action Trio Bar (Read, Listen, Explore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: _buildActionTrioBar(heroBook),
            ),
          ),

          // 5. Editorial Tagline
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: _buildEditorialTagline(),
            ),
          ),

          if (_isGridView) ...[
            _buildGridSliver(_books),
          ] else ...[
            // 6. Continue Reading / History Shelf
            if (historyBooks.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _buildShelfHeader(
                  title: 'Continue Reading & Listening',
                  subtitle: 'Pick up right where you paused',
                  icon: Icons.history_rounded,
                  iconColor: _goldAccent,
                  count: historyBooks.length,
                ),
              ),
              SliverToBoxAdapter(
                child: _buildHistoryShelf(historyBooks),
              ),
            ],

            // 7. Malayalam Literature Shelf
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

            // 8. English & Global Classics Shelf
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

            // 9. Combined Imported Books & Notes Shelf
            if (importedBooks.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _buildShelfHeader(
                  title: 'Your Documents & Imports',
                  subtitle: 'Custom EPUBs, PDFs, OCR scans & text notes',
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
          ],
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 90)),
      ],
    );
  }

  // ----------------- QUICK ACTION BAR & SEARCH & FILTER WIDGETS -----------------

  // ----------------- HERO IN-PROGRESS CARD & ACTION TRIO -----------------

  Widget _buildHeroInProgressCard(Book book, BookProgress? progress) {
    final chapterCount = book.chapterCount > 0 ? book.chapterCount : 1;
    final currentChap = (progress?.chapterIndex ?? 0) + 1;
    final progressFraction = progress != null
        ? ((progress.chapterIndex + 1) / chapterCount).clamp(0.0, 1.0)
        : 0.3;
    final percent = (progressFraction * 100).toInt();
    final timeStr = progress != null
        ? _formatRelativeTime(progress.lastUpdated)
        : '6h ago';
    final fmtStr = book.isPdf ? 'pdf' : (book.isText ? 'text' : (book.isScan ? 'scan' : 'epub'));

    return _TappableScale(
      onTap: () => _openReader(book, chapterIndex: progress?.chapterIndex ?? 0),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Mini Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 52,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF241E16),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _goldAccent.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: book.coverImageBytes != null
                    ? Image.memory(
                        book.coverImageBytes!,
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Icon(
                          Icons.auto_stories_rounded,
                          color: _goldAccent,
                          size: 24,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // Metadata & Progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    book.metadata.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      letterSpacing: 0.3,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${book.metadata.author} · $fmtStr · $timeStr',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: _textSecondary,
                    ),
                  ),
                  const SizedBox(height: 7),
                  // Thin Progress Bar
                  Container(
                    height: 3.5,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _isDark ? const Color(0xFF382F24) : const Color(0xFFECDFC0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progressFraction,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isDark ? _goldAccent : const Color(0xFF2B2620),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ch. $currentChap / $chapterCount · $percent%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Circular Play Button
            _TappableScale(
              onTap: () => _openAudiobook(book),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isDark ? _goldAccent : const Color(0xFF2B2620),
                  boxShadow: [
                    BoxShadow(
                      color: (_isDark ? _goldAccent : const Color(0xFF2B2620))
                          .withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: 18,
                  color: _isDark ? const Color(0xFF1E1812) : const Color(0xFFF3ECE0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTrioBar(Book? activeBook) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _cardBorder.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTrioActionItem(
            icon: Icons.menu_book_rounded,
            label: 'Read',
            onTap: () {
              if (activeBook != null) {
                _openReader(activeBook);
              }
            },
          ),
          _buildTrioActionItem(
            icon: Icons.headphones_rounded,
            label: 'Listen',
            onTap: () {
              if (activeBook != null) {
                _openAudiobook(activeBook);
              }
            },
          ),
          _buildTrioActionItem(
            icon: Icons.explore_rounded,
            label: 'Explore',
            onTap: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTrioActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return _TappableScale(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 21,
            color: _textPrimary,
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.9,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorialTagline() {
    return Text(
      'Discover universes in words and sound',
      style: TextStyle(
        fontFamily: 'serif',
        fontSize: 15,
        letterSpacing: 0.4,
        fontWeight: FontWeight.w400,
        color: _textPrimary,
      ),
    );
  }

  // ----------------- QUICK ACTION BAR & SEARCH & FILTER WIDGETS -----------------

  Widget _buildQuickActionBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildQuickActionButton(
            label: 'Write text',
            icon: Icons.edit_outlined,
            onTap: _openTextEditor,
          ),
          const SizedBox(width: 8),
          _buildQuickActionButton(
            label: 'Quick paste',
            icon: Icons.content_paste_rounded,
            onTap: _openQuickPaste,
          ),
          const SizedBox(width: 8),
          _buildQuickActionButton(
            label: 'Scan photo',
            icon: Icons.document_scanner_outlined,
            onTap: _showScanOptionsModal,
          ),
          const SizedBox(width: 8),
          _buildQuickActionButton(
            label: 'Import Book',
            icon: Icons.file_upload_outlined,
            onTap: _importBookFile,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return _TappableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isDark ? const Color(0xFF4A3E31) : const Color(0xFF2B2620),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isDark ? 0.2 : 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13.5,
              color: _textPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: _cardBorder),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: _textPrimary, fontSize: 13.5),
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search by book title, author, or language...',
          hintStyle: TextStyle(color: _textSecondary, fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded, color: _textSecondary, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: _textSecondary, size: 18),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCategoryChipsBar() {
    final tags = [
      'All',
      'EPUB',
      'PDF',
      'Text & Notes',
      'Scans',
      'In Progress',
      'Malayalam',
      'English',
      'Imported'
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: tags.map((tag) {
          final isSelected = _selectedFilterTag == tag;
          int count = 0;
          if (tag == 'All') {
            count = _books.length;
          } else if (tag == 'EPUB') {
            count = _books.where((b) => !b.isPdf && !b.isScan && !b.isText).length;
          } else if (tag == 'PDF') {
            count = _books.where((b) => b.isPdf && !b.isScan).length;
          } else if (tag == 'Text & Notes') {
            count = _books.where((b) => b.isText).length;
          } else if (tag == 'Scans') {
            count = _books.where((b) => b.isScan).length;
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

          final activeBg = _isDark ? const Color(0xFFF3ECE0) : const Color(0xFF2B2620);
          final activeFg = _isDark ? const Color(0xFF1E1812) : const Color(0xFFF3ECE0);

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _TappableScale(
              onTap: () {
                setState(() {
                  _selectedFilterTag = tag;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? activeBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? activeBg
                        : (_isDark ? const Color(0xFF4A3E31) : const Color(0xFFC9BC9E)),
                    width: 1,
                  ),
                ),
                child: Text(
                  '$tag ($count)',
                  style: TextStyle(
                    color: isSelected ? activeFg : _textSecondary,
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
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
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: iconColor),
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
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif',
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: _chipBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: _textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: _textSecondary,
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
      height: 195,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
      width: 250,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDark ? 0.25 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Cover Thumbnail + Title & Author
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mini Cover with glowing aura
                _TappableScale(
                  onTap: () => _openReader(book, chapterIndex: progress.chapterIndex),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Container(
                      width: 42,
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFF241E16),
                        boxShadow: [
                          BoxShadow(
                            color: _goldAccent.withValues(alpha: 0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: book.coverImageBytes != null
                          ? Image.memory(
                              book.coverImageBytes!,
                              fit: BoxFit.cover,
                            )
                          : _buildDefaultCover(book, isMini: true),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.metadata.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'serif',
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        book.metadata.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: _textSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          _buildFormatBadge(book, isMini: true),
                          const SizedBox(width: 4),
                          Icon(Icons.access_time_rounded,
                              size: 10, color: _textSecondary),
                          const SizedBox(width: 2),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 10,
                              color: _textSecondary,
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
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                  ),
                ),
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: _goldAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              height: 3.5,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _cardBorder,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progressFraction,
                child: Container(
                  decoration: BoxDecoration(
                    color: _goldAccent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Resume Actions: Read & Audio
            Row(
              children: [
                Expanded(
                  child: _TappableScale(
                    onTap: () => _openReader(
                      book,
                      chapterIndex: progress.chapterIndex,
                      paragraphIndex: progress.paragraphIndex,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _isDark ? const Color(0xFF2C241B) : const Color(0xFF2B2620),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.menu_book_rounded, size: 12, color: Color(0xFFF3ECE0)),
                          SizedBox(width: 4),
                          Text(
                            'Read',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF3ECE0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _TappableScale(
                    onTap: () => _openAudiobook(book),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _goldAccent.withValues(alpha: 0.6),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.headphones_rounded, size: 12, color: _goldAccent),
                          const SizedBox(width: 4),
                          Text(
                            'Audio',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: _goldAccent,
                            ),
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
    );
  }

  Widget _buildHorizontalShelf({
    required List<Book> books,
    required Color tagColor,
    required String shelfTag,
  }) {
    return SizedBox(
      height: 232,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return _buildShelfBookCard(book, tagColor: tagColor, shelfTag: shelfTag);
        },
      ),
    );
  }

  Widget _buildShelfBookCard(
    Book book, {
    required Color tagColor,
    required String shelfTag,
  }) {
    return Container(
      width: 125,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDark ? 0.25 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Thumbnail with glowing border/shadow
            _TappableScale(
              onTap: () => _openReader(book),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 106,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF241E16),
                    boxShadow: [
                      BoxShadow(
                        color: tagColor.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      book.coverImageBytes != null
                          ? Image.memory(
                              book.coverImageBytes!,
                              fit: BoxFit.cover,
                            )
                          : _buildDefaultCover(book, isMini: true),
                      // Top-right format badge
                      Positioned(
                        top: 4,
                        right: 4,
                        child: _buildFormatBadge(book, isMini: true),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            // Title
            _TappableScale(
              onTap: () => _openReader(book),
              child: Text(
                book.metadata.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                  color: _textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 1),
            // Author
            Text(
              book.metadata.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                color: _textSecondary,
              ),
            ),
            const Spacer(),
            // Quick Action Buttons: Read & Listen
            Row(
              children: [
                Expanded(
                  child: _TappableScale(
                    onTap: () => _openReader(book),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 3.5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _chipBg,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: _cardBorder.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        'Read',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _TappableScale(
                    onTap: () => _openAudiobook(book),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 3.5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _isDark
                            ? _goldAccent.withValues(alpha: 0.18)
                            : const Color(0xFFFBF4E4),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: _goldAccent.withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        'Listen',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _goldAccent,
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
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDark ? 0.25 : 0.04),
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
            _TappableScale(
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'serif',
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.metadata.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: _textSecondary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      _buildFormatBadge(book, isMini: true),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: _chipBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${book.chapterCount} Chapters',
                          style: TextStyle(
                              fontSize: 10.5, color: _textSecondary),
                        ),
                      ),
                      if (progress != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: _isDark
                                ? _goldAccent.withValues(alpha: 0.2)
                                : const Color(0xFFFBF4E4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Ch ${progress.chapterIndex + 1}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: _goldAccent,
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
                _TappableScale(
                  child: IconButton(
                    icon: Icon(Icons.headphones_rounded,
                        color: _goldAccent, size: 20),
                    tooltip: 'Listen Audiobook',
                    onPressed: () => _openAudiobook(book),
                  ),
                ),
                if (isCustomBook)
                  _TappableScale(
                    child: IconButton(
                      icon: Icon(Icons.delete_outline_rounded,
                          color: _textSecondary, size: 18),
                      tooltip: 'Delete Book',
                      onPressed: () => _deleteBook(book),
                    ),
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
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDark ? 0.25 : 0.04),
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
                  child: _TappableScale(
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
                // Format Badge & Progress Chip
                Positioned(
                  top: 8,
                  left: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFormatBadge(book, isMini: true),
                      if (progress != null) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Ch ${progress.chapterIndex + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
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
                _TappableScale(
                  onTap: () => _openReader(book),
                  child: Text(
                    book.metadata.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'serif',
                      color: _textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  book.metadata.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 8),

                // Quick Action Bar: Read & Listen
                Row(
                  children: [
                    Expanded(
                      child: _TappableScale(
                        onTap: () => _openReader(book),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _chipBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _cardBorder.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            'Read',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _TappableScale(
                        onTap: () => _openAudiobook(book),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _isDark
                                ? _goldAccent.withValues(alpha: 0.18)
                                : const Color(0xFFFBF4E4),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _goldAccent.withValues(alpha: 0.5),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            progress != null ? 'Resume' : 'Listen',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _goldAccent,
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
    final isScan = book.isScan;
    final isPdf = book.isPdf;
    final hash = book.metadata.title.hashCode;
    final color1 = isScan
        ? const Color(0xFF8B4513)
        : (isPdf
            ? const Color(0xFF5C1D1D)
            : HSLColor.fromAHSL(1.0, (hash.abs() % 360).toDouble(), 0.35, 0.22)
                .toColor());
    final color2 = isScan
        ? const Color(0xFF4A250B)
        : (isPdf
            ? const Color(0xFF380E0E)
            : HSLColor.fromAHSL(
                    1.0, ((hash.abs() + 40) % 360).toDouble(), 0.45, 0.14)
                .toColor());

    final icon = isScan
        ? Icons.document_scanner_rounded
        : (isPdf ? Icons.picture_as_pdf_rounded : Icons.auto_stories_rounded);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.all(isMini ? 6 : 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: _goldAccent.withValues(alpha: 0.9),
            size: isMini ? 18 : 28,
          ),
          if (!isMini) ...[
            const SizedBox(height: 6),
            Text(
              book.metadata.title,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFF3ECE0),
                fontWeight: FontWeight.bold,
                fontFamily: 'serif',
                fontSize: 12,
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
            Icon(Icons.search_off_rounded,
                size: 52, color: _textSecondary),
            const SizedBox(height: 12),
            Text(
              'No Books Found',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                  color: _textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'No books matched "$_searchQuery". Try searching with different keywords.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textSecondary, fontSize: 13),
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
            Icon(Icons.auto_stories_rounded,
                size: 64, color: _goldAccent.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              'No Books in Library',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'serif',
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Import an EPUB or PDF file to start reading and listening.',
              style: TextStyle(color: _textSecondary),
            ),
            const SizedBox(height: 24),
            _TappableScale(
              onTap: _importBookFile,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                decoration: BoxDecoration(
                  color: _isDark ? _goldAccent : const Color(0xFF2B2620),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.file_open_rounded,
                      size: 18,
                      color: _isDark ? const Color(0xFF1E1812) : const Color(0xFFF3ECE0),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Import EPUB / PDF',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontWeight: FontWeight.bold,
                        color: _isDark ? const Color(0xFF1E1812) : const Color(0xFFF3ECE0),
                      ),
                    ),
                  ],
                ),
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
          color: _canvasBg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
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

        Divider(height: 1, color: _cardBorder),

        // Content List
        Expanded(
          child: items.isEmpty
              ? _buildEmptySavedState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
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
    final activeBg = _isDark ? const Color(0xFFF3ECE0) : const Color(0xFF2B2620);
    final activeFg = _isDark ? const Color(0xFF1E1812) : const Color(0xFFF3ECE0);

    return _TappableScale(
      onTap: () {
        setState(() {
          _savedFilter = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? activeBg
                : (_isDark ? const Color(0xFF4A3E31) : const Color(0xFFC9BC9E)),
            width: 1,
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            color: isSelected ? activeFg : _textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
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
              decoration: BoxDecoration(
                color: _isDark
                    ? _goldAccent.withValues(alpha: 0.15)
                    : const Color(0xFFFBF4E4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmarks_outlined,
                size: 44,
                color: _goldAccent,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _savedFilter == 'All'
                  ? 'No Saved Items Yet'
                  : 'No $_savedFilter Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'serif',
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select words while reading to highlight, translate, or bookmark chapters. They will all appear here for quick access.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            _TappableScale(
              onTap: () {
                setState(() {
                  _selectedTabIndex = 0;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _isDark ? _goldAccent : const Color(0xFF2B2620),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_stories_rounded,
                      size: 16,
                      color: _isDark ? const Color(0xFF1E1812) : const Color(0xFFF3ECE0),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Go to Library',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontWeight: FontWeight.bold,
                        color: _isDark ? const Color(0xFF1E1812) : const Color(0xFFF3ECE0),
                      ),
                    ),
                  ],
                ),
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
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDark ? 0.25 : 0.03),
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif',
                        fontSize: 13,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _chipBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Ch ${highlight.chapterIndex + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 18, color: _textSecondary),
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
                  color: highlight.color.withValues(alpha: _isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"${highlight.selectedText}"',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'serif',
                    color: _isDark
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF334155),
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
                    color: _isDark
                        ? const Color(0xFF1E1812)
                        : const Color(0xFFFBF4E4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _cardBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.translate_rounded,
                          size: 16, color: _goldAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          highlight.note!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _textPrimary,
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
                child: _TappableScale(
                  onTap: () {
                    if (book != null) {
                      _openReader(book, chapterIndex: highlight.chapterIndex);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.menu_book_rounded, size: 14, color: _goldAccent),
                        const SizedBox(width: 4),
                        Text(
                          'Read in Chapter',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _goldAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
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
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDark ? 0.25 : 0.03),
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
              left: BorderSide(color: _goldAccent, width: 5.0),
            ),
          ),
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Bookmark Icon, Book Title, Chapter, Delete
              Row(
                children: [
                  Icon(Icons.bookmark_rounded,
                      size: 18, color: _goldAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bookTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif',
                        fontSize: 13,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _isDark
                          ? _goldAccent.withValues(alpha: 0.18)
                          : const Color(0xFFFBF4E4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      bookmark.chapterTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _goldAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 18, color: _textSecondary),
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
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'serif',
                  color: _isDark
                      ? const Color(0xFFDCCFBB)
                      : const Color(0xFF5A4D3B),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 10),

              // Bottom Action: Jump to Bookmark
              Align(
                alignment: Alignment.centerRight,
                child: _TappableScale(
                  onTap: () {
                    if (book != null) {
                      _openReader(book, chapterIndex: bookmark.chapterIndex);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Jump to Bookmark',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _goldAccent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14, color: _goldAccent),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A lightweight interactive micro-animation wrapper providing spring scale feedback on tap
class _TappableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _TappableScale({
    required this.child,
    this.onTap,
  });

  @override
  State<_TappableScale> createState() => _TappableScaleState();
}

class _TappableScaleState extends State<_TappableScale> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _isPressed = true),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

