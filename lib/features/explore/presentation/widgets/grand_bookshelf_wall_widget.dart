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

  static LibraryWingCamera forCategory(String categoryId, {bool isDark = true}) {
    switch (categoryId.toLowerCase()) {
      case 'cat_scifi':
        return LibraryWingCamera(
          wingSector: 'UPPER ROTUNDA • DOME MEZZANINE',
          wingName: 'CELESTIAL DOME BALCONY',
          wingSubtitle: 'LOOKING DOWN UNDER STARRY GLASS DOME',
          bgAsset: isDark
              ? 'assets/rotunda_top_dome_view.jpg'
              : 'assets/rotunda_top_dome_view_light.jpg',
          pitch: -0.04,
          yaw: 0.02,
          roll: -0.008,
          dx: 0.0,
          dy: 12.0,
          scale: 1.14,
          ambientTint: isDark
              ? const Color(0x061E354D)
              : const Color(0x04C0D4E8),
          vignetteGradient: isDark
              ? const [
                  Color(0x700B131C),
                  Colors.transparent,
                  Color(0x80080E14),
                ]
              : const [
                  Color(0x350B131C),
                  Colors.transparent,
                  Color(0x45080E14),
                ],
          wingIcon: Icons.rocket_launch_rounded,
          crestLetter: 'C',
          shelfTopGradient: isDark
              ? const [
                  Color(0xFF382618),
                  Color(0xFF563B25),
                  Color(0xFF8D6847),
                  Color(0xFF563B25),
                  Color(0xFF382618),
                ]
              : const [
                  Color(0xFF5C3C24),
                  Color(0xFF865B38),
                  Color(0xFFC7986B),
                  Color(0xFF865B38),
                  Color(0xFF5C3C24),
                ],
          shelfFrontGradient: isDark
              ? const [
                  Color(0xFF2B1C12),
                  Color(0xFF170E08),
                ]
              : const [
                  Color(0xFF452B18),
                  Color(0xFF24150A),
                ],
          shelfTrimGold: const Color(0xFFC7A762),
          beamLabel: 'CELESTIAL DOME MEZZANINE TIER',
          particleColor: const Color(0x80C7A762),
        );

      case 'cat_history':
        return LibraryWingCamera(
          wingSector: 'GROUND FLOOR • EAST STUDY DESK',
          wingName: 'SCHOLAR\'S READING DESK',
          wingSubtitle: 'SEATED AT AMBER LAMP STUDY TABLE',
          bgAsset: isDark
              ? 'assets/rotunda_reading_desk_view.jpg'
              : 'assets/rotunda_reading_desk_view_light.jpg',
          pitch: 0.03,
          yaw: -0.02,
          roll: -0.006,
          dx: 10.0,
          dy: -6.0,
          scale: 1.14,
          ambientTint: isDark
              ? const Color(0x08C79A5B)
              : const Color(0x05E5BA76),
          vignetteGradient: isDark
              ? const [
                  Color(0x6520150B),
                  Colors.transparent,
                  Color(0x80140C05),
                ]
              : const [
                  Color(0x3020150B),
                  Colors.transparent,
                  Color(0x40140C05),
                ],
          wingIcon: Icons.history_edu_rounded,
          crestLetter: 'H',
          shelfTopGradient: isDark
              ? const [
                  Color(0xFF422B1B),
                  Color(0xFF634129),
                  Color(0xFF9E714B),
                  Color(0xFF634129),
                  Color(0xFF422B1B),
                ]
              : const [
                  Color(0xFF654228),
                  Color(0xFF8F613B),
                  Color(0xFFCF9E70),
                  Color(0xFF8F613B),
                  Color(0xFF654228),
                ],
          shelfFrontGradient: isDark
              ? const [
                  Color(0xFF321F13),
                  Color(0xFF190F08),
                ]
              : const [
                  Color(0xFF4C2F1A),
                  Color(0xFF28170B),
                ],
          shelfTrimGold: const Color(0xFFD4AF37),
          beamLabel: 'ARCHIVAL STUDY DESK TIER',
          particleColor: const Color(0x80D4AF37),
        );

      case 'cat_mystery':
        return LibraryWingCamera(
          wingSector: 'WEST SPIRAL ASCENT • TIER II',
          wingName: 'SPIRAL STAIRCASE ARC',
          wingSubtitle: 'CLIMBING THE ROTUNDA BOOKSHELF WALL',
          bgAsset: isDark
              ? 'assets/rotunda_spiral_staircase_view.jpg'
              : 'assets/rotunda_spiral_staircase_view_light.jpg',
          pitch: -0.02,
          yaw: 0.03,
          roll: 0.010,
          dx: -12.0,
          dy: 6.0,
          scale: 1.14,
          ambientTint: isDark
              ? const Color(0x061A1424)
              : const Color(0x04DDD0EE),
          vignetteGradient: isDark
              ? const [
                  Color(0x68120D1A),
                  Colors.transparent,
                  Color(0x850A0710),
                ]
              : const [
                  Color(0x35120D1A),
                  Colors.transparent,
                  Color(0x450A0710),
                ],
          wingIcon: Icons.psychology_alt_rounded,
          crestLetter: 'M',
          shelfTopGradient: isDark
              ? const [
                  Color(0xFF352419),
                  Color(0xFF503625),
                  Color(0xFF825D41),
                  Color(0xFF503625),
                  Color(0xFF352419),
                ]
              : const [
                  Color(0xFF593B26),
                  Color(0xFF7F5637),
                  Color(0xFFBC8E64),
                  Color(0xFF7F5637),
                  Color(0xFF593B26),
                ],
          shelfFrontGradient: isDark
              ? const [
                  Color(0xFF281910),
                  Color(0xFF140C07),
                ]
              : const [
                  Color(0xFF422816),
                  Color(0xFF221309),
                ],
          shelfTrimGold: const Color(0xFFCBB078),
          beamLabel: 'SPIRAL STAIRCASE ASCENT TIER',
          particleColor: const Color(0x80CBB078),
        );

      case 'cat_malayalam':
        return LibraryWingCamera(
          wingSector: 'GROUND FLOOR • SOUTH DESK QUARTER',
          wingName: 'HERITAGE STUDY NOOK',
          wingSubtitle: 'PERSPECTIVE FROM WARM TEAK READING TABLE',
          bgAsset: isDark
              ? 'assets/rotunda_reading_desk_view.jpg'
              : 'assets/rotunda_reading_desk_view_light.jpg',
          pitch: 0.02,
          yaw: -0.03,
          roll: 0.004,
          dx: -6.0,
          dy: -4.0,
          scale: 1.13,
          ambientTint: isDark
              ? const Color(0x08D9923B)
              : const Color(0x06F0B264),
          vignetteGradient: isDark
              ? const [
                  Color(0x651E1208),
                  Colors.transparent,
                  Color(0x80100803),
                ]
              : const [
                  Color(0x301E1208),
                  Colors.transparent,
                  Color(0x40100803),
                ],
          wingIcon: Icons.menu_book_rounded,
          crestLetter: 'M',
          shelfTopGradient: isDark
              ? const [
                  Color(0xFF482D1A),
                  Color(0xFF6B4327),
                  Color(0xFFA56F43),
                  Color(0xFF6B4327),
                  Color(0xFF482D1A),
                ]
              : const [
                  Color(0xFF6B4327),
                  Color(0xFF98623B),
                  Color(0xFFD69F6B),
                  Color(0xFF98623B),
                  Color(0xFF6B4327),
                ],
          shelfFrontGradient: isDark
              ? const [
                  Color(0xFF352011),
                  Color(0xFF1B0F07),
                ]
              : const [
                  Color(0xFF52331B),
                  Color(0xFF2C190D),
                ],
          shelfTrimGold: const Color(0xFFD9B464),
          beamLabel: 'HERITAGE TEAKWOOD STUDY TIER',
          particleColor: const Color(0x80D9B464),
        );

      case 'cat_sleep':
        return LibraryWingCamera(
          wingSector: 'UPPER ROTUNDA • STARLIGHT MEZZANINE',
          wingName: 'STARLIT DOME SANCTUARY',
          wingSubtitle: 'ELEVATED VIEW OF MOONLIT CUPOLA',
          bgAsset: isDark
              ? 'assets/rotunda_top_dome_view.jpg'
              : 'assets/rotunda_top_dome_view_light.jpg',
          pitch: -0.05,
          yaw: -0.02,
          roll: 0.006,
          dx: -4.0,
          dy: 14.0,
          scale: 1.14,
          ambientTint: isDark
              ? const Color(0x06142030)
              : const Color(0x04D6E0EC),
          vignetteGradient: isDark
              ? const [
                  Color(0x70091018),
                  Colors.transparent,
                  Color(0x8504070C),
                ]
              : const [
                  Color(0x35091018),
                  Colors.transparent,
                  Color(0x4504070C),
                ],
          wingIcon: Icons.bedtime_rounded,
          crestLetter: 'S',
          shelfTopGradient: isDark
              ? const [
                  Color(0xFF332317),
                  Color(0xFF4F3624),
                  Color(0xFF7E5A3D),
                  Color(0xFF4F3624),
                  Color(0xFF332317),
                ]
              : const [
                  Color(0xFF563B26),
                  Color(0xFF7C5438),
                  Color(0xFFBA895D),
                  Color(0xFF7C5438),
                  Color(0xFF563B26),
                ],
          shelfFrontGradient: isDark
              ? const [
                  Color(0xFF26180F),
                  Color(0xFF130B07),
                ]
              : const [
                  Color(0xFF412818),
                  Color(0xFF21130A),
                ],
          shelfTrimGold: const Color(0xFFC4A466),
          beamLabel: 'STARLIT DOME TIER',
          particleColor: const Color(0x80C4A466),
        );

      case 'cat_fantasy':
        return LibraryWingCamera(
          wingSector: 'NORTH ROTUNDA • GRAND TIER III',
          wingName: 'HIGH VAULT BALCONY',
          wingSubtitle: 'OVERLOOKING THE ARCHED VAULTS',
          bgAsset: isDark
              ? 'assets/rotunda_spiral_staircase_view.jpg'
              : 'assets/rotunda_spiral_staircase_view_light.jpg',
          pitch: -0.03,
          yaw: -0.03,
          roll: -0.008,
          dx: 8.0,
          dy: 8.0,
          scale: 1.14,
          ambientTint: isDark
              ? const Color(0x06281838)
              : const Color(0x04E4D8EE),
          vignetteGradient: isDark
              ? const [
                  Color(0x68180E24),
                  Colors.transparent,
                  Color(0x85100818),
                ]
              : const [
                  Color(0x35180E24),
                  Colors.transparent,
                  Color(0x45100818),
                ],
          wingIcon: Icons.auto_fix_high_rounded,
          crestLetter: 'F',
          shelfTopGradient: isDark
              ? const [
                  Color(0xFF3D2719),
                  Color(0xFF5B3B26),
                  Color(0xFF946845),
                  Color(0xFF5B3B26),
                  Color(0xFF3D2719),
                ]
              : const [
                  Color(0xFF5F3E28),
                  Color(0xFF885A3B),
                  Color(0xFFC99468),
                  Color(0xFF885A3B),
                  Color(0xFF5F3E28),
                ],
          shelfFrontGradient: isDark
              ? const [
                  Color(0xFF2E1C12),
                  Color(0xFF160D08),
                ]
              : const [
                  Color(0xFF482D1B),
                  Color(0xFF26160C),
                ],
          shelfTrimGold: const Color(0xFFD4AF37),
          beamLabel: 'HIGH VAULT BALCONY TIER',
          particleColor: const Color(0x80D4AF37),
        );

      case 'cat_children':
        return LibraryWingCamera(
          wingSector: 'LOWER ROTUNDA • SUNLIT ALCOVE',
          wingName: 'ALCOVE READING DESK',
          wingSubtitle: 'CLOSE-UP PERSPECTIVE OF WARM LAMPLIT DESK',
          bgAsset: isDark
              ? 'assets/rotunda_reading_desk_view.jpg'
              : 'assets/rotunda_reading_desk_view_light.jpg',
          pitch: 0.02,
          yaw: 0.02,
          roll: 0.0,
          dx: 8.0,
          dy: -4.0,
          scale: 1.14,
          ambientTint: isDark
              ? const Color(0x061C2E1F)
              : const Color(0x05DCEDDE),
          vignetteGradient: isDark
              ? const [
                  Color(0x65121A13),
                  Colors.transparent,
                  Color(0x80080D09),
                ]
              : const [
                  Color(0x30121A13),
                  Colors.transparent,
                  Color(0x40080D09),
                ],
          wingIcon: Icons.child_care_rounded,
          crestLetter: 'K',
          shelfTopGradient: isDark
              ? const [
                  Color(0xFF3A2618),
                  Color(0xFF583A25),
                  Color(0xFF8E6442),
                  Color(0xFF583A25),
                  Color(0xFF3A2618),
                ]
              : const [
                  Color(0xFF5C3C26),
                  Color(0xFF845737),
                  Color(0xFFC38E61),
                  Color(0xFF845737),
                  Color(0xFF5C3C26),
                ],
          shelfFrontGradient: isDark
              ? const [
                  Color(0xFF2A1B10),
                  Color(0xFF140C07),
                ]
              : const [
                  Color(0xFF442B19),
                  Color(0xFF23140A),
                ],
          shelfTrimGold: const Color(0xFFC9A86A),
          beamLabel: 'READING ALCOVE DESK TIER',
          particleColor: const Color(0x80C9A86A),
        );

      case 'cat_philosophy':
        return LibraryWingCamera(
          wingSector: 'CENTRAL FLOOR • BALUSTRADE CORE',
          wingName: 'CENTRAL ROTUNDA BALUSTRADE',
          wingSubtitle: 'STANDING AT THE CIRCULAR BALUSTRADE EDGE',
          bgAsset: isDark
              ? 'assets/grand_library_bg.jpg'
              : 'assets/grand_library_bg_light.jpg',
          pitch: 0.03,
          yaw: 0.01,
          roll: 0.004,
          dx: 0.0,
          dy: -10.0,
          scale: 1.15,
          ambientTint: isDark
              ? const Color(0x08C79A5B)
              : const Color(0x05E5BA76),
          vignetteGradient: isDark
              ? const [
                  Color(0x651E140A),
                  Colors.transparent,
                  Color(0x800E0803),
                ]
              : const [
                  Color(0x301E140A),
                  Colors.transparent,
                  Color(0x400E0803),
                ],
          wingIcon: Icons.lightbulb_rounded,
          crestLetter: 'P',
          shelfTopGradient: isDark
              ? const [
                  Color(0xFF452D1C),
                  Color(0xFF67432A),
                  Color(0xFFA2724D),
                  Color(0xFF67432A),
                  Color(0xFF452D1C),
                ]
              : const [
                  Color(0xFF6A442A),
                  Color(0xFF96623E),
                  Color(0xFFD69D6F),
                  Color(0xFF96623E),
                  Color(0xFF6A442A),
                ],
          shelfFrontGradient: isDark
              ? const [
                  Color(0xFF342013),
                  Color(0xFF1B0F08),
                ]
              : const [
                  Color(0xFF4F321E),
                  Color(0xFF2A190D),
                ],
          shelfTrimGold: const Color(0xFFD4AF37),
          beamLabel: 'CENTRAL BALUSTRADE TIER',
          particleColor: const Color(0x80D4AF37),
        );

      case 'all':
      default:
        return LibraryWingCamera(
          wingSector: 'ROTUNDA MAIN HALL • CENTRAL PANORAMA',
          wingName: 'GRAND ROTUNDA SANCTUARY',
          wingSubtitle: 'PANORAMIC EYE-LEVEL PERSPECTIVE',
          bgAsset: isDark
              ? 'assets/grand_library_bg.jpg'
              : 'assets/grand_library_bg_light.jpg',
          pitch: 0.0,
          yaw: 0.0,
          roll: 0.0,
          dx: 0.0,
          dy: 0.0,
          scale: 1.14,
          ambientTint: Colors.transparent,
          vignetteGradient: isDark
              ? const [
                  Color(0x60000000),
                  Colors.transparent,
                  Color(0x75000000),
                ]
              : const [
                  Color(0x30000000),
                  Colors.transparent,
                  Color(0x40000000),
                ],
          wingIcon: Icons.all_inclusive_rounded,
          crestLetter: 'G',
          shelfTopGradient: isDark
              ? const [
                  Color(0xFF462E1D),
                  Color(0xFF6A462C),
                  Color(0xFFA67650),
                  Color(0xFF6A462C),
                  Color(0xFF462E1D),
                ]
              : const [
                  Color(0xFF6C462C),
                  Color(0xFF99653F),
                  Color(0xFFDAA072),
                  Color(0xFF99653F),
                  Color(0xFF6C462C),
                ],
          shelfFrontGradient: isDark
              ? const [
                  Color(0xFF332013),
                  Color(0xFF1A0E08),
                ]
              : const [
                  Color(0xFF4E311D),
                  Color(0xFF29180C),
                ],
          shelfTrimGold: const Color(0xFFD4AF37),
          beamLabel: 'ROTUNDA SANCTUARY TIER',
          particleColor: const Color(0x80D4AF37),
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
  bool? _lastIsDark;

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
    const isDark = true;

    setState(() {
      _prevCamera = LibraryWingCamera.lerp(
        _prevCamera,
        _targetCamera,
        _cameraCurve.value,
      );
      _selectedCategory = id;
      _targetCamera = LibraryWingCamera.forCategory(id, isDark: isDark);
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
    const isDark = true;
    if (_lastIsDark != isDark) {
      _lastIsDark = isDark;
      _prevCamera = LibraryWingCamera.forCategory(_selectedCategory, isDark: isDark);
      _targetCamera = LibraryWingCamera.forCategory(_selectedCategory, isDark: isDark);
    }
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
                      filterQuality: FilterQuality.high,
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
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFF19130D),
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Settled Current Library Perspective - 100% Crisp Pixel-for-Pixel
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(bgX, bgY),
                  child: Image.asset(
                    currentCamera.bgAsset,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF19130D),
                    ),
                  ),
                ),
              ),
            ],

            // 2. Atmospheric Tint (Dark Mode only - completely clear in Light Mode)
            if (isDark)
              Positioned.fill(
                child: Container(
                  color: currentCamera.ambientTint,
                ),
              ),

            // 3. Ambient Vignette (Dark Mode only - zero fog in Light Mode)
            if (isDark)
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
                              children: [
                                const Text(
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
                                        offset: Offset(0, 1.0),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'YOUR NEXT STORY AWAITS',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.6,
                                    color: Color(0xFFD4AF37),
                                    shadows: [
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Dynamic Library Wing Compass Pill
                          _buildWingCompassBadge(currentCamera, true),
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
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
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
                            isDark: isDark,
                          ),
                          ...widget.categories.map((cat) => _buildCategoryPill(
                                id: cat.id,
                                label: cat.name,
                                icon: _getCategoryIcon(cat.id),
                                isSelected: _selectedCategory.toLowerCase() ==
                                    cat.id.toLowerCase(),
                                isDark: isDark,
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
                      isDark: isDark,
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
                      isDark: isDark,
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
              child: _buildSerendipityBanner(context, isDark),
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

  Widget _buildWingCompassBadge(LibraryWingCamera camera, bool isDark) {
    final goldAccent = isDark ? const Color(0xFFD4AF37) : const Color(0xFF2563EB);

    return Container(
      constraints: const BoxConstraints(maxWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? goldAccent.withValues(alpha: 0.6)
              : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
          ),
        ],
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
                  style: TextStyle(
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
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 8.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: isDark
                        ? const Color(0xFFF9F5EC)
                        : const Color(0xFF0F172A),
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
    required bool isDark,
  }) {
    final activeBg = isDark ? const Color(0xFFD4AF37) : const Color(0xFF2563EB);
    final activeFg = isDark ? const Color(0xFF191107) : Colors.white;
    final textDark = isDark ? const Color(0xFFF9F5EC) : const Color(0xFF334155);
    final iconDark = isDark ? const Color(0xFFE5B869) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _selectCategory(id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6.5),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: isDark
                        ? const [Color(0xFFE5B869), Color(0xFFB58E23)]
                        : const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  )
                : null,
            color: isSelected
                ? null
                : (isDark
                    ? Colors.black.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.94)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? activeBg
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0xFFE2E8F0)),
              width: 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: (isDark
                              ? const Color(0xFFB58E23)
                              : const Color(0xFF2563EB))
                          .withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : (!isDark
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 12,
                color: isSelected ? activeFg : iconDark,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected ? activeFg : textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Open-Air Rotunda Shelf Tier with Authentic Layered Woodcraft & 3D Curved Rotunda Scroll
  Widget _buildOpenRotundaTier({
    required int tierNumber,
    required String tierLabel,
    String? sectorLabel,
    required LibraryWingCamera camera,
    required List<Book> books,
    required bool isReversed,
    required ScrollController controller,
    required bool isDark,
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
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFDE68A),
                        Color(0xFFD4AF37),
                        Color(0xFFB48A3C),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF8C6621),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 6,
                        offset: const Offset(0, 1.5),
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
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: goldAccent.withValues(alpha: 0.5),
                    width: 1.0,
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

        // 2. 3D Curved Rotational Scroll Books Row
        LayoutBuilder(
          builder: (context, constraints) {
            final viewportWidth = constraints.maxWidth;
            final viewportCenter = viewportWidth / 2;

            return SizedBox(
              height: 172,
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  return ListView.builder(
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

                      // Calculate 3D Rotational Curvature & Perspective relative to viewport center
                      final scrollOffset = controller.positions.isNotEmpty
                          ? controller.positions.first.pixels
                          : 0.0;
                      // Approximate horizontal position of book center
                      final bookLeft = 16.0 + index * (spineWidth + 4.0) - scrollOffset;
                      final bookCenter = bookLeft + spineWidth / 2;
                      final distFromCenter = ((bookCenter - viewportCenter) /
                              (viewportWidth * 0.48))
                          .clamp(-1.25, 1.25);

                      // 3D cylindrical rotunda transformation
                      final rotY = distFromCenter * 0.20; // Inward angle curve
                      final zDepth = -(distFromCenter * distFromCenter) * 22.0; // Recedes at edges
                      final yArc = (distFromCenter * distFromCenter) * 3.5; // Slight curved shelf sag
                      final scale = (1.0 - distFromCenter.abs() * 0.04).clamp(0.92, 1.0);

                      return Transform(
                        alignment: Alignment.bottomCenter,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0012)
                          ..translateByDouble(0.0, yArc, zDepth, 1.0)
                          ..rotateY(rotY)
                          ..scaleByDouble(scale, scale, 1.0, 1.0),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: RealisticBookSpineWidget(
                            book: book,
                            index: isReversed ? index + 10 : index,
                            width: spineWidth,
                            height: 160,
                            tiltAngle: tilt,
                            isSelected: isSelected,
                            isHighlighted: isHighlighted,
                            onTap: () => _onBookTapped(book),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),

        // 3. Realistic Architectural Hardwood Table-like Bookshelf Architecture
        _buildRealisticBookshelfPlank(
          camera: camera,
          tierNumber: tierNumber,
          isDark: true,
          goldAccent: goldAccent,
        ),
      ],
    );
  }

  /// Mastercrafted Realistic Hardwood Table-like Shelf Plank with Landing Deck, Beveled Edge & Brass Accents
  Widget _buildRealisticBookshelfPlank({
    required LibraryWingCamera camera,
    required int tierNumber,
    required bool isDark,
    required Color goldAccent,
  }) {
    // Rich, authentic antique polished mahogany & amber library shelf wood tones
    const topDeckColors = [
      Color(0xFF331A0E), // Deep outer grain
      Color(0xFF5E341B), // Warm burnished mahogany
      Color(0xFF965727), // Luminous amber timber
      Color(0xFFBA773E), // Central warm library lamp reflection sheen
      Color(0xFF965727), // Luminous amber timber
      Color(0xFF5E341B), // Warm burnished mahogany
      Color(0xFF331A0E), // Deep outer grain
    ];

    const fasciaFaceColors = [
      Color(0xFF4C2715), // Milled top bullnose bevel
      Color(0xFF30170B), // Solid dark walnut core
      Color(0xFF180A04), // Shadowed underside base
    ];

    const edgeHighlight = Color(0xFFE2BC6A);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Realistic Table-like Structure (Top Landing Deck + Specular Chamfer + Bullnose Fascia)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                // Deep Ambient Occlusion Drop Shadow onto the Library Wall
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
                // Rich Under-Shelf Warm Ambient Hearth Glow
                BoxShadow(
                  color: const Color(0xFF3A1C08).withValues(alpha: 0.55),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Top Landing Table Deck Surface (Deep 18px perspective desk where books physically sit)
                Container(
                  height: 18,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: topDeckColors,
                      stops: [0.0, 0.16, 0.35, 0.50, 0.65, 0.84, 1.0],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                    border: Border.all(
                      color: edgeHighlight.withValues(alpha: 0.35),
                      width: 0.8,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Perspective Gradient Receding into Wall Depth with Warm Amber Luster
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.50), // Rear shadow line against wall
                                const Color(0xFFC88A4B).withValues(alpha: 0.16), // Warm amber wood grain luster
                                const Color(0xFFFDE68A).withValues(alpha: 0.20), // Front tabletop sheen
                              ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Book Base Contact Shadow (Contact ambient occlusion directly beneath spines)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 4,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.70),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Specular Chamfer Highlight Line (Milled 45° timber edge catchlight)
                Container(
                  height: 1.4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        edgeHighlight.withValues(alpha: 0.2),
                        edgeHighlight.withValues(alpha: 0.9),
                        edgeHighlight.withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                ),

                // 3. Front Fascia Board (Sculpted Bullnose Solid Wood Lip with Inlaid Brass Hardware)
                Container(
                  height: 15,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: fasciaFaceColors,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.8),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left Brushed Brass Medallion Pin
                      Container(
                        width: 11,
                        height: 11,
                        margin: const EdgeInsets.only(left: 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFDE68A),
                              Color(0xFFD4AF37),
                              Color(0xFF8C6621),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),

                      // Center Inlaid Gold Rule Line Accent
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            height: 1.0,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  goldAccent.withValues(alpha: 0.6),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Right Brushed Brass Medallion Pin
                      Container(
                        width: 11,
                        height: 11,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFDE68A),
                              Color(0xFFD4AF37),
                              Color(0xFF8C6621),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Under-Shelf Support Brackets (Cast Architectural Brackets)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildArchitecturalBracket(true, goldAccent),
                _buildArchitecturalBracket(true, goldAccent),
                _buildArchitecturalBracket(true, goldAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Elegant Architectural Wall Support Bracket
  Widget _buildArchitecturalBracket(bool isDark, Color goldAccent) {
    return Container(
      width: 12,
      height: 9,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF382314),
            Color(0xFF140D07),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(6),
          bottomRight: Radius.circular(6),
        ),
        border: Border.all(
          color: goldAccent.withValues(alpha: 0.4),
          width: 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  /// Floating Serendipity Discovery Bottom Banner
  Widget _buildSerendipityBanner(BuildContext context, bool isDark) {
    final goldAccent = isDark ? const Color(0xFFD4AF37) : const Color(0xFF2563EB);
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
          color: isDark
              ? Colors.black.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? goldAccent : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.08),
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFFE5B869), Color(0xFFB58E23)]
                      : const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: isDark ? const Color(0xFF191107) : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
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
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? const Color(0xFFF9F5EC)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Inspect',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: goldAccent,
                  ),
                ),
                const SizedBox(width: 2),
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
