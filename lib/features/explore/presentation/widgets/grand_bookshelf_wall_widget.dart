import 'dart:math' as math;
import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/explore/domain/entities/category.dart';
import 'package:epub_audio/features/explore/presentation/widgets/book_exploration_inspection_sheet.dart';
import 'package:epub_audio/features/explore/presentation/widgets/realistic_book_spine_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The Grand Library Open-Air Rotunda Exploration Experience.
/// Features a dynamic full-screen 3D library backdrop that smoothly moves with balanced
/// parallax, realistic multi-layered wooden rotunda shelves with brass trim, and interactive minimal books.
class GrandBookshelfWallWidget extends StatefulWidget {
  final List<Book> allBooks;
  final List<Category> categories;
  final ValueChanged<Book> onBookSelected;
  final ValueChanged<Book>? onReadBook;
  final ValueChanged<Book>? onListenBook;
  final ValueChanged<Category>? onCategorySelected;
  final Widget? topHeader;

  const GrandBookshelfWallWidget({
    super.key,
    required this.allBooks,
    required this.categories,
    required this.onBookSelected,
    this.onReadBook,
    this.onListenBook,
    this.onCategorySelected,
    this.topHeader,
  });

  @override
  State<GrandBookshelfWallWidget> createState() =>
      _GrandBookshelfWallWidgetState();
}

class LibraryWingCamera {
  final String wingSector;
  final String wingName;
  final String wingSubtitle;
  final String bgAsset;
  final double pitch; // rotX (tilt up/down)
  final double yaw; // rotY (pan left/right)
  final double roll; // rotZ (subtle tilt angle)
  final double dx; // horizontal 3D translation
  final double dy; // vertical 3D translation
  final double scale; // zoom level
  final Color ambientTint;
  final List<Color> vignetteGradient;
  final IconData wingIcon;
  final String crestLetter;
  final List<Color> shelfTopGradient;
  final List<Color> shelfFrontGradient;
  final Color shelfTrimGold;
  final String beamLabel;
  final Color particleColor;

  const LibraryWingCamera({
    required this.wingSector,
    required this.wingName,
    required this.wingSubtitle,
    required this.bgAsset,
    this.pitch = 0.0,
    this.yaw = 0.0,
    this.roll = 0.0,
    this.dx = 0.0,
    this.dy = 0.0,
    this.scale = 1.15,
    this.ambientTint = Colors.transparent,
    required this.vignetteGradient,
    required this.wingIcon,
    this.crestLetter = 'G',
    required this.shelfTopGradient,
    required this.shelfFrontGradient,
    required this.shelfTrimGold,
    required this.beamLabel,
    required this.particleColor,
  });

  static LibraryWingCamera forCategory(String categoryId) {
    switch (categoryId.toLowerCase()) {
      case 'cat_scifi':
        return const LibraryWingCamera(
          wingSector: 'UPPER ROTUNDA • DOME MEZZANINE',
          wingName: 'CELESTIAL DOME BALCONY',
          wingSubtitle: 'LOOKING DOWN UNDER STARRY GLASS DOME',
          bgAsset: 'assets/rotunda_top_dome_view.jpg',
          pitch: -0.04,
          yaw: 0.02,
          roll: -0.008,
          dx: 0.0,
          dy: 12.0,
          scale: 1.14,
          ambientTint: Color(0x061E354D),
          vignetteGradient: [
            Color(0x700B131C),
            Colors.transparent,
            Color(0x80080E14),
          ],
          wingIcon: Icons.rocket_launch_rounded,
          crestLetter: 'C',
          shelfTopGradient: [
            Color(0xFF382618),
            Color(0xFF563B25),
            Color(0xFF8D6847),
            Color(0xFF563B25),
            Color(0xFF382618),
          ],
          shelfFrontGradient: [
            Color(0xFF2B1C12),
            Color(0xFF170E08),
          ],
          shelfTrimGold: Color(0xFFC7A762),
          beamLabel: 'CELESTIAL DOME MEZZANINE TIER',
          particleColor: Color(0x80C7A762),
        );

      case 'cat_history':
        return const LibraryWingCamera(
          wingSector: 'GROUND FLOOR • EAST STUDY DESK',
          wingName: 'SCHOLAR\'S READING DESK',
          wingSubtitle: 'SEATED AT AMBER LAMP STUDY TABLE',
          bgAsset: 'assets/rotunda_reading_desk_view.jpg',
          pitch: 0.03,
          yaw: -0.02,
          roll: -0.006,
          dx: 10.0,
          dy: -6.0,
          scale: 1.14,
          ambientTint: Color(0x08C79A5B),
          vignetteGradient: [
            Color(0x6520150B),
            Colors.transparent,
            Color(0x80140C05),
          ],
          wingIcon: Icons.history_edu_rounded,
          crestLetter: 'H',
          shelfTopGradient: [
            Color(0xFF422B1B),
            Color(0xFF634129),
            Color(0xFF9E714B),
            Color(0xFF634129),
            Color(0xFF422B1B),
          ],
          shelfFrontGradient: [
            Color(0xFF321F13),
            Color(0xFF190F08),
          ],
          shelfTrimGold: Color(0xFFD4AF37),
          beamLabel: 'ARCHIVAL STUDY DESK TIER',
          particleColor: Color(0x80D4AF37),
        );

      case 'cat_mystery':
        return const LibraryWingCamera(
          wingSector: 'WEST SPIRAL ASCENT • TIER II',
          wingName: 'SPIRAL STAIRCASE ARC',
          wingSubtitle: 'CLIMBING THE ROTUNDA BOOKSHELF WALL',
          bgAsset: 'assets/rotunda_spiral_staircase_view.jpg',
          pitch: -0.02,
          yaw: 0.03,
          roll: 0.010,
          dx: -12.0,
          dy: 6.0,
          scale: 1.14,
          ambientTint: Color(0x061A1424),
          vignetteGradient: [
            Color(0x68120D1A),
            Colors.transparent,
            Color(0x850A0710),
          ],
          wingIcon: Icons.psychology_alt_rounded,
          crestLetter: 'M',
          shelfTopGradient: [
            Color(0xFF352419),
            Color(0xFF503625),
            Color(0xFF825D41),
            Color(0xFF503625),
            Color(0xFF352419),
          ],
          shelfFrontGradient: [
            Color(0xFF281910),
            Color(0xFF140C07),
          ],
          shelfTrimGold: Color(0xFFCBB078),
          beamLabel: 'SPIRAL STAIRCASE ASCENT TIER',
          particleColor: Color(0x80CBB078),
        );

      case 'cat_malayalam':
        return const LibraryWingCamera(
          wingSector: 'GROUND FLOOR • SOUTH DESK QUARTER',
          wingName: 'HERITAGE STUDY NOOK',
          wingSubtitle: 'PERSPECTIVE FROM WARM TEAK READING TABLE',
          bgAsset: 'assets/rotunda_reading_desk_view.jpg',
          pitch: 0.02,
          yaw: -0.03,
          roll: 0.004,
          dx: -6.0,
          dy: -4.0,
          scale: 1.13,
          ambientTint: Color(0x08D9923B),
          vignetteGradient: [
            Color(0x651E1208),
            Colors.transparent,
            Color(0x80100803),
          ],
          wingIcon: Icons.menu_book_rounded,
          crestLetter: 'M',
          shelfTopGradient: [
            Color(0xFF482D1A),
            Color(0xFF6B4327),
            Color(0xFFA56F43),
            Color(0xFF6B4327),
            Color(0xFF482D1A),
          ],
          shelfFrontGradient: [
            Color(0xFF352011),
            Color(0xFF1B0F07),
          ],
          shelfTrimGold: Color(0xFFD9B464),
          beamLabel: 'HERITAGE TEAKWOOD STUDY TIER',
          particleColor: Color(0x80D9B464),
        );

      case 'cat_sleep':
        return const LibraryWingCamera(
          wingSector: 'UPPER ROTUNDA • STARLIGHT MEZZANINE',
          wingName: 'STARLIT DOME SANCTUARY',
          wingSubtitle: 'ELEVATED VIEW OF MOONLIT CUPOLA',
          bgAsset: 'assets/rotunda_top_dome_view.jpg',
          pitch: -0.05,
          yaw: -0.02,
          roll: 0.006,
          dx: -4.0,
          dy: 14.0,
          scale: 1.14,
          ambientTint: Color(0x06142030),
          vignetteGradient: [
            Color(0x70091018),
            Colors.transparent,
            Color(0x8504070C),
          ],
          wingIcon: Icons.bedtime_rounded,
          crestLetter: 'S',
          shelfTopGradient: [
            Color(0xFF332317),
            Color(0xFF4F3624),
            Color(0xFF7E5A3D),
            Color(0xFF4F3624),
            Color(0xFF332317),
          ],
          shelfFrontGradient: [
            Color(0xFF26180F),
            Color(0xFF130B07),
          ],
          shelfTrimGold: Color(0xFFC4A466),
          beamLabel: 'STARLIT DOME TIER',
          particleColor: Color(0x80C4A466),
        );

      case 'cat_fantasy':
        return const LibraryWingCamera(
          wingSector: 'NORTH ROTUNDA • GRAND TIER III',
          wingName: 'HIGH VAULT BALCONY',
          wingSubtitle: 'OVERLOOKING THE ARCHED VAULTS',
          bgAsset: 'assets/rotunda_spiral_staircase_view.jpg',
          pitch: -0.03,
          yaw: -0.03,
          roll: -0.008,
          dx: 8.0,
          dy: 8.0,
          scale: 1.14,
          ambientTint: Color(0x06281838),
          vignetteGradient: [
            Color(0x68180E24),
            Colors.transparent,
            Color(0x85100818),
          ],
          wingIcon: Icons.auto_fix_high_rounded,
          crestLetter: 'F',
          shelfTopGradient: [
            Color(0xFF3D2719),
            Color(0xFF5B3B26),
            Color(0xFF946845),
            Color(0xFF5B3B26),
            Color(0xFF3D2719),
          ],
          shelfFrontGradient: [
            Color(0xFF2E1C12),
            Color(0xFF160D08),
          ],
          shelfTrimGold: Color(0xFFD4AF37),
          beamLabel: 'HIGH VAULT BALCONY TIER',
          particleColor: Color(0x80D4AF37),
        );

      case 'cat_children':
        return const LibraryWingCamera(
          wingSector: 'LOWER ROTUNDA • SUNLIT ALCOVE',
          wingName: 'ALCOVE READING DESK',
          wingSubtitle: 'CLOSE-UP PERSPECTIVE OF WARM LAMPLIT DESK',
          bgAsset: 'assets/rotunda_reading_desk_view.jpg',
          pitch: 0.02,
          yaw: 0.02,
          roll: 0.0,
          dx: 8.0,
          dy: -4.0,
          scale: 1.14,
          ambientTint: Color(0x061C2E1F),
          vignetteGradient: [
            Color(0x65121A13),
            Colors.transparent,
            Color(0x80080D09),
          ],
          wingIcon: Icons.child_care_rounded,
          crestLetter: 'K',
          shelfTopGradient: [
            Color(0xFF3A2618),
            Color(0xFF583A25),
            Color(0xFF8E6442),
            Color(0xFF583A25),
            Color(0xFF3A2618),
          ],
          shelfFrontGradient: [
            Color(0xFF2A1B10),
            Color(0xFF140C07),
          ],
          shelfTrimGold: Color(0xFFC9A86A),
          beamLabel: 'READING ALCOVE DESK TIER',
          particleColor: Color(0x80C9A86A),
        );

      case 'cat_philosophy':
        return const LibraryWingCamera(
          wingSector: 'CENTRAL FLOOR • BALUSTRADE CORE',
          wingName: 'CENTRAL ROTUNDA BALUSTRADE',
          wingSubtitle: 'STANDING AT THE CIRCULAR BALUSTRADE EDGE',
          bgAsset: 'assets/grand_library_bg.jpg',
          pitch: 0.03,
          yaw: 0.01,
          roll: 0.004,
          dx: 0.0,
          dy: -10.0,
          scale: 1.15,
          ambientTint: Color(0x08C79A5B),
          vignetteGradient: [
            Color(0x651E140A),
            Colors.transparent,
            Color(0x800E0803),
          ],
          wingIcon: Icons.lightbulb_rounded,
          crestLetter: 'P',
          shelfTopGradient: [
            Color(0xFF452D1C),
            Color(0xFF67432A),
            Color(0xFFA2724D),
            Color(0xFF67432A),
            Color(0xFF452D1C),
          ],
          shelfFrontGradient: [
            Color(0xFF342013),
            Color(0xFF1B0F08),
          ],
          shelfTrimGold: Color(0xFFD4AF37),
          beamLabel: 'CENTRAL BALUSTRADE TIER',
          particleColor: Color(0x80D4AF37),
        );

      case 'all':
      default:
        return const LibraryWingCamera(
          wingSector: 'ROTUNDA MAIN HALL • CENTRAL PANORAMA',
          wingName: 'GRAND ROTUNDA SANCTUARY',
          wingSubtitle: 'PANORAMIC EYE-LEVEL PERSPECTIVE',
          bgAsset: 'assets/grand_library_bg.jpg',
          pitch: 0.0,
          yaw: 0.0,
          roll: 0.0,
          dx: 0.0,
          dy: 0.0,
          scale: 1.14,
          ambientTint: Colors.transparent,
          vignetteGradient: [
            Color(0x60000000),
            Colors.transparent,
            Color(0x75000000),
          ],
          wingIcon: Icons.all_inclusive_rounded,
          crestLetter: 'G',
          shelfTopGradient: [
            Color(0xFF462E1D),
            Color(0xFF6A462C),
            Color(0xFFA67650),
            Color(0xFF6A462C),
            Color(0xFF462E1D),
          ],
          shelfFrontGradient: [
            Color(0xFF332013),
            Color(0xFF1A0E08),
          ],
          shelfTrimGold: Color(0xFFD4AF37),
          beamLabel: 'ROTUNDA SANCTUARY TIER',
          particleColor: Color(0x80D4AF37),
        );
    }
  }

  static LibraryWingCamera lerp(
      LibraryWingCamera a, LibraryWingCamera b, double t) {
    return LibraryWingCamera(
      wingSector: t < 0.5 ? a.wingSector : b.wingSector,
      wingName: t < 0.5 ? a.wingName : b.wingName,
      wingSubtitle: t < 0.5 ? a.wingSubtitle : b.wingSubtitle,
      bgAsset: t < 0.5 ? a.bgAsset : b.bgAsset,
      pitch: a.pitch + (b.pitch - a.pitch) * t,
      yaw: a.yaw + (b.yaw - a.yaw) * t,
      roll: a.roll + (b.roll - a.roll) * t,
      dx: a.dx + (b.dx - a.dx) * t,
      dy: a.dy + (b.dy - a.dy) * t,
      scale: a.scale + (b.scale - a.scale) * t,
      ambientTint: Color.lerp(a.ambientTint, b.ambientTint, t) ?? b.ambientTint,
      vignetteGradient: [
        Color.lerp(a.vignetteGradient[0], b.vignetteGradient[0], t) ??
            b.vignetteGradient[0],
        Color.lerp(a.vignetteGradient[1], b.vignetteGradient[1], t) ??
            b.vignetteGradient[1],
        Color.lerp(a.vignetteGradient[2], b.vignetteGradient[2], t) ??
            b.vignetteGradient[2],
      ],
      wingIcon: t < 0.5 ? a.wingIcon : b.wingIcon,
      crestLetter: t < 0.5 ? a.crestLetter : b.crestLetter,
      shelfTopGradient: [
        Color.lerp(a.shelfTopGradient[0], b.shelfTopGradient[0], t) ??
            b.shelfTopGradient[0],
        Color.lerp(a.shelfTopGradient[1], b.shelfTopGradient[1], t) ??
            b.shelfTopGradient[1],
        Color.lerp(a.shelfTopGradient[2], b.shelfTopGradient[2], t) ??
            b.shelfTopGradient[2],
        Color.lerp(a.shelfTopGradient[3], b.shelfTopGradient[3], t) ??
            b.shelfTopGradient[3],
        Color.lerp(a.shelfTopGradient[4], b.shelfTopGradient[4], t) ??
            b.shelfTopGradient[4],
      ],
      shelfFrontGradient: [
        Color.lerp(a.shelfFrontGradient[0], b.shelfFrontGradient[0], t) ??
            b.shelfFrontGradient[0],
        Color.lerp(a.shelfFrontGradient[1], b.shelfFrontGradient[1], t) ??
            b.shelfFrontGradient[1],
      ],
      shelfTrimGold:
          Color.lerp(a.shelfTrimGold, b.shelfTrimGold, t) ?? b.shelfTrimGold,
      beamLabel: t < 0.5 ? a.beamLabel : b.beamLabel,
      particleColor:
          Color.lerp(a.particleColor, b.particleColor, t) ?? b.particleColor,
    );
  }
}

class _GrandBookshelfWallWidgetState extends State<GrandBookshelfWallWidget>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = 'all';
  String? _selectedBookId;
  String? _highlightedBookId;
  Book? _serendipityBook;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Parallax tracking controllers
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _tier1Controller = ScrollController();
  final ScrollController _tier2Controller = ScrollController();

  double _verticalScrollOffset = 0.0;
  double _horizontalScrollOffset = 0.0;

  // Category Camera 3D transitions
  late AnimationController _cameraAnimController;
  late Animation<double> _cameraCurve;
  LibraryWingCamera _prevCamera = LibraryWingCamera.forCategory('all');
  LibraryWingCamera _targetCamera = LibraryWingCamera.forCategory('all');

  @override
  void initState() {
    super.initState();
    _pickInitialSerendipityBook();

    _cameraAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _cameraCurve = CurvedAnimation(
      parent: _cameraAnimController,
      curve: Curves.easeInOutCubic,
    );

    _verticalScrollController.addListener(() {
      if (mounted) {
        setState(() {
          _verticalScrollOffset = _verticalScrollController.offset;
        });
      }
    });

    _tier1Controller.addListener(_updateHorizontalOffset);
  }

  void _updateHorizontalOffset() {
    if (!mounted) return;
    if (_tier1Controller.hasClients) {
      setState(() {
        _horizontalScrollOffset = _tier1Controller.offset;
      });
    }
  }

  void _selectCategory(String id) {
    if (_selectedCategory == id) return;
    HapticFeedback.selectionClick();

    setState(() {
      _prevCamera = LibraryWingCamera.lerp(
        _prevCamera,
        _targetCamera,
        _cameraCurve.value,
      );
      _selectedCategory = id;
      _targetCamera = LibraryWingCamera.forCategory(id);
    });

    _cameraAnimController.forward(from: 0.0);

    final cat = widget.categories
        .where((c) => c.id.toLowerCase() == id.toLowerCase())
        .firstOrNull;
    if (cat != null) {
      widget.onCategorySelected?.call(cat);
    }
  }

  void _pickInitialSerendipityBook() {
    if (widget.allBooks.isNotEmpty) {
      _serendipityBook = widget.allBooks.first;
    }
  }

  @override
  void dispose() {
    _cameraAnimController.dispose();
    _searchController.dispose();
    _verticalScrollController.dispose();
    _tier1Controller.dispose();
    _tier2Controller.dispose();
    super.dispose();
  }

  List<Book> get _filteredBooks {
    var list = widget.allBooks;
    if (_selectedCategory != 'all') {
      final category = widget.categories
          .where((c) => c.id.toLowerCase() == _selectedCategory.toLowerCase())
          .firstOrNull;
      if (category != null && category.bookIds.isNotEmpty) {
        list = list.where((b) => category.bookIds.contains(b.id)).toList();
      }
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((b) =>
              b.metadata.title.toLowerCase().contains(q) ||
              b.metadata.author.toLowerCase().contains(q) ||
              (b.metadata.description?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    return list;
  }

  void _onBookTapped(Book book) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedBookId = book.id;
      _highlightedBookId = book.id;
      _serendipityBook = book;
    });

    widget.onBookSelected(book);

    BookExplorationInspectionSheet.show(
      context,
      book: book,
      onRead: () => widget.onReadBook?.call(book),
      onListen: () => widget.onListenBook?.call(book),
    );
  }

  void _triggerLuckyPick() {
    final books = _filteredBooks.isNotEmpty ? _filteredBooks : widget.allBooks;
    if (books.isEmpty) return;

    HapticFeedback.heavyImpact();
    final random = math.Random();
    final luckyBook = books[random.nextInt(books.length)];

    setState(() {
      _selectedBookId = luckyBook.id;
      _highlightedBookId = luckyBook.id;
      _serendipityBook = luckyBook;
    });

    BookExplorationInspectionSheet.show(
      context,
      book: luckyBook,
      onRead: () => widget.onReadBook?.call(luckyBook),
      onListen: () => widget.onListenBook?.call(luckyBook),
    );
  }

  @override
  Widget build(BuildContext context) {
    final books = _filteredBooks;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _cameraAnimController,
        _verticalScrollController,
        _tier1Controller,
      ]),
      builder: (context, child) {
        final t = _cameraCurve.value;
        final currentCamera = LibraryWingCamera.lerp(
          _prevCamera,
          _targetCamera,
          t,
        );

        // Balanced, stabilized background parallax (smooth translation, no jarring angle flips)
        final bgY = currentCamera.dy - (_verticalScrollOffset * 0.04).clamp(-20.0, 20.0);
        final bgX = currentCamera.dx - (_horizontalScrollOffset * 0.02).clamp(-15.0, 15.0);
        final rotY = currentCamera.yaw;
        final rotX = currentCamera.pitch;
        final rotZ = currentCamera.roll;
        final baseScale = currentCamera.scale;

        final isTransitioning =
            _prevCamera.bgAsset != _targetCamera.bgAsset && t < 1.0;

        return Stack(
          children: [
            // 1. FULL-SCREEN 3D Grand Library Background Layer
            if (isTransitioning) ...[
              // Target Arriving Library View
              Positioned.fill(
                child: Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..translateByDouble(bgX, bgY, 0.0, 1.0)
                      ..rotateY(rotY)
                      ..rotateX(rotX)
                      ..rotateZ(rotZ)
                      ..scaleByDouble(
                        baseScale * (0.95 + t * 0.05),
                        baseScale * (0.95 + t * 0.05),
                        1.0,
                        1.0,
                      ),
                    child: Image.asset(
                      _targetCamera.bgAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFF19130D),
                      ),
                    ),
                  ),
                ),
              ),

              // Previous Departing Library View
              Positioned.fill(
                child: Opacity(
                  opacity: (1.0 - t).clamp(0.0, 1.0),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..translateByDouble(bgX, bgY, 0.0, 1.0)
                      ..rotateY(rotY)
                      ..rotateX(rotX)
                      ..rotateZ(rotZ)
                      ..scaleByDouble(
                        baseScale * (1.0 + t * 0.15),
                        baseScale * (1.0 + t * 0.15),
                        1.0,
                        1.0,
                      ),
                    child: Image.asset(
                      _prevCamera.bgAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFF19130D),
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Settled Current Library Perspective
              Positioned.fill(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..translateByDouble(bgX, bgY, 0.0, 1.0)
                    ..rotateY(rotY)
                    ..rotateX(rotX)
                    ..rotateZ(rotZ)
                    ..scaleByDouble(baseScale, baseScale, 1.0, 1.0),
                  child: Image.asset(
                    currentCamera.bgAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF19130D),
                    ),
                  ),
                ),
              ),
            ],

            // 2. Subtle Atmospheric Wing Tint
            Positioned.fill(
              child: Container(
                color: currentCamera.ambientTint,
              ),
            ),

            // 3. Very Soft Ambient Vignette (Keeps rotunda fully visible & luminous)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: currentCamera.vignetteGradient,
                    stops: const [0.0, 0.40, 1.0],
                  ),
                ),
              ),
            ),

            // 4. Open Floating Rotunda Shelves Content
            Positioned.fill(
              child: SingleChildScrollView(
                controller: _verticalScrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Injected Top Greeting & Mode Bar (if provided)
                    if (widget.topHeader != null) widget.topHeader!,

                    const SizedBox(height: 8),

                    // Header Section with Title & Animated Library Wing Compass
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'THE GRAND LIBRARY',
                                  style: TextStyle(
                                    fontFamily: 'serif',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                    color: Color(0xFFF9F5EC),
                                    shadows: [
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 8,
                                        offset: Offset(0, 1.5),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'YOUR NEXT STORY AWAITS',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.6,
                                    color: Color(0xFFD4AF37),
                                    shadows: [
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 5,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Dynamic Library Wing Compass Pill
                          _buildWingCompassBadge(currentCamera),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Translucent Glassmorphic Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 0.8,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search books, authors, or genres...',
                            hintStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 17,
                              color: Color(0xFFD4AF37),
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 15),
                                    color: const Color(0xFFD4AF37),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category Filter Capsules
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: [
                          _buildCategoryPill(
                            id: 'all',
                            label: 'All Shelves',
                            icon: Icons.all_inclusive_rounded,
                            isSelected: _selectedCategory == 'all',
                          ),
                          ...widget.categories.map((cat) => _buildCategoryPill(
                                id: cat.id,
                                label: cat.name,
                                icon: _getCategoryIcon(cat.id),
                                isSelected: _selectedCategory.toLowerCase() ==
                                    cat.id.toLowerCase(),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 5. Open-Air Floating Rotunda Bookshelves
                    _buildOpenRotundaTier(
                      tierNumber: 1,
                      tierLabel: currentCamera.wingName,
                      sectorLabel: currentCamera.wingSector,
                      camera: currentCamera,
                      books: books.isNotEmpty ? books : widget.allBooks,
                      isReversed: false,
                      controller: _tier1Controller,
                    ),
                    const SizedBox(height: 24),

                    _buildOpenRotundaTier(
                      tierNumber: 2,
                      tierLabel: 'CURATED ARCHIVES',
                      sectorLabel: currentCamera.wingSubtitle,
                      camera: currentCamera,
                      books: books.isNotEmpty ? books : widget.allBooks,
                      isReversed: true,
                      controller: _tier2Controller,
                    ),
                  ],
                ),
              ),
            ),

            // 6. Floating Bottom Serendipity Discovery Banner
            Positioned(
              left: 18,
              right: 18,
              bottom: 14,
              child: _buildSerendipityBanner(context),
            ),
          ],
        );
      },
    );
  }

  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId.toLowerCase()) {
      case 'cat_scifi':
        return Icons.rocket_launch_rounded;
      case 'cat_history':
        return Icons.history_edu_rounded;
      case 'cat_mystery':
        return Icons.psychology_alt_rounded;
      case 'cat_malayalam':
        return Icons.menu_book_rounded;
      case 'cat_sleep':
        return Icons.bedtime_rounded;
      case 'cat_fantasy':
        return Icons.auto_fix_high_rounded;
      case 'cat_children':
        return Icons.child_care_rounded;
      case 'cat_philosophy':
        return Icons.lightbulb_rounded;
      default:
        return Icons.auto_stories_rounded;
    }
  }

  Widget _buildWingCompassBadge(LibraryWingCamera camera) {
    const goldAccent = Color(0xFFD4AF37);

    return Container(
      constraints: const BoxConstraints(maxWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: goldAccent.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            camera.wingIcon,
            size: 12,
            color: goldAccent,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  camera.wingSector,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 7.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: goldAccent,
                  ),
                ),
                Text(
                  camera.wingName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 8.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: Color(0xFFF9F5EC),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill({
    required String id,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    const goldAccent = Color(0xFFD4AF37);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _selectCategory(id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6.5),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFE5B869), Color(0xFFB58E23)],
                  )
                : null,
            color: isSelected ? null : Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? goldAccent
                  : Colors.white.withValues(alpha: 0.2),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 12,
                color: isSelected
                    ? const Color(0xFF191107)
                    : const Color(0xFFE5B869),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFF191107)
                      : const Color(0xFFF9F5EC),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Open-Air Rotunda Shelf Tier with Authentic Layered Woodcraft
  Widget _buildOpenRotundaTier({
    required int tierNumber,
    required String tierLabel,
    String? sectorLabel,
    required LibraryWingCamera camera,
    required List<Book> books,
    required bool isReversed,
    required ScrollController controller,
  }) {
    final goldAccent = camera.shelfTrimGold;
    final displayBooks = isReversed ? books.reversed.toList() : books;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Tier Header with Antique Cast-Brass Plaque & Volume Counter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Antique Engraved Cast-Brass Genre Plaque
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFDE68A),
                        goldAccent,
                        const Color(0xFFB48A3C),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: const Color(0xFF8C6621),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 3.5,
                        height: 3.5,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF5A4016),
                        ),
                      ),
                      Icon(
                        camera.wingIcon,
                        size: 12,
                        color: const Color(0xFF1E1408),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '$tierLabel • TIER 0$tierNumber',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 9.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Color(0xFF1E1408),
                          ),
                        ),
                      ),
                      Container(
                        width: 3.5,
                        height: 3.5,
                        margin: const EdgeInsets.only(left: 5),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF5A4016),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Brass Volume Counter
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3.0),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: goldAccent.withValues(alpha: 0.5),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '${displayBooks.length} VOLUMES',
                  style: TextStyle(
                    fontSize: 8.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: goldAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 2. Open Books Row
        SizedBox(
          height: 168,
          child: ListView.builder(
            controller: controller,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: displayBooks.length,
            itemBuilder: (context, index) {
              final book = displayBooks[index];
              final isSelected = _selectedBookId == book.id;
              final isHighlighted = _highlightedBookId == book.id;

              final tilt = (index % 5 == 1)
                  ? 5.0
                  : (index % 5 == 3 ? -4.5 : 0.0);
              final isStack = index % 7 == 3;
              final spineWidth = isStack
                  ? 50.0
                  : (30.0 + (index % 4) * 3.0);

              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: RealisticBookSpineWidget(
                  book: book,
                  index: isReversed ? index + 10 : index,
                  isSelected: isSelected,
                  isHighlighted: isHighlighted,
                  tiltAngle: tilt,
                  width: spineWidth,
                  height: 148,
                  isHorizontalStack: isStack,
                  stackCount: 3,
                  onTap: () => _onBookTapped(book),
                ),
              );
            },
          ),
        ),

        // 3. Multi-Layered Ancient Hardwood Shelf Architecture
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Layer 1: Seasoned Oak/Walnut Deck Board with Amber Lamp Sheen
              Container(
                height: 7,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: camera.shelfTopGradient,
                    stops: const [0.0, 0.22, 0.5, 0.78, 1.0],
                  ),
                  border: Border(
                    top: BorderSide(
                      color: goldAccent.withValues(alpha: 0.8),
                      width: 1.0,
                    ),
                  ),
                ),
              ),

              // Layer 2: Intermediate Joinery Shadow Groove (Recessed Core Hardwood)
              Container(
                height: 2.0,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF160D07),
                      Color(0xFF28180E),
                      Color(0xFF160D07),
                    ],
                  ),
                ),
              ),

              // Layer 3: Heavy Sculpted Ancient Timber Fascia Beam
              Container(
                height: 16,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: camera.shelfFrontGradient,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Bronze Endcap
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: goldAccent.withValues(alpha: 0.5),
                        border: Border.all(
                          color: const Color(0xFF4A3418),
                          width: 0.5,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.circle,
                          size: 3.0,
                          color: Color(0xFF1E1408),
                        ),
                      ),
                    ),

                    // Center Inscription (Expanded to prevent overflow)
                    Expanded(
                      child: Center(
                        child: Text(
                          '• ${camera.beamLabel} 0$tierNumber •',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 8.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: goldAccent.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),

                    // Right Bronze Endcap
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: goldAccent.withValues(alpha: 0.5),
                        border: Border.all(
                          color: const Color(0xFF4A3418),
                          width: 0.5,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.circle,
                          size: 3.0,
                          color: Color(0xFF1E1408),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Layer 4: Under-Shelf Support Corbels
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildVictorianCorbel(goldAccent),
                    _buildVictorianCorbel(goldAccent),
                    _buildVictorianCorbel(goldAccent),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Hand-Forged Victorian Under-Shelf Support Corbel
  Widget _buildVictorianCorbel(Color goldAccent) {
    return Container(
      width: 12,
      height: 9,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            goldAccent.withValues(alpha: 0.6),
            const Color(0xFF140D07),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
    );
  }

  /// Floating Serendipity Discovery Bottom Banner
  Widget _buildSerendipityBanner(BuildContext context) {
    const goldAccent = Color(0xFFD4AF37);
    final book = _serendipityBook ??
        (_filteredBooks.isNotEmpty
            ? _filteredBooks.first
            : widget.allBooks.firstOrNull);

    final title = book?.metadata.title ?? 'Explore Grand Archives';

    return GestureDetector(
      onTap: _triggerLuckyPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: goldAccent,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFE5B869), Color(0xFFB58E23)],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: Color(0xFF191107),
                ),
              ),
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SERENDIPITY DISCOVERY',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: goldAccent,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFF9F5EC),
                    ),
                  ),
                ],
              ),
            ),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Inspect',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: goldAccent,
                  ),
                ),
                SizedBox(width: 2),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: goldAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
