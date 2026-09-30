import 'dart:async';
import 'dart:math' as math;
import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/explore/domain/entities/category.dart';
import 'package:epub_audio/features/explore/domain/entities/category_experience_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// Data model representing a distinct wing/shelf section in the 3D library hall.
class LibraryRoomCorner {
  final String id;
  final String cornerName;
  final String categoryId;
  final String categoryTitle;
  final String subtitle;
  final IconData icon;
  final Color themeColor;
  final String roomAsset;
  final String shelfAsset;
  final String signboardTitle;
  final double shelfX; // Real-world spatial coordinate X (-3.0 to 3.0)
  final double shelfY; // Real-world spatial coordinate Y (-8.0 to 8.0)
  final double mapX;   // 0.0 to 1.0 on top-down floor map
  final double mapY;   // 0.0 to 1.0 on top-down floor map

  const LibraryRoomCorner({
    required this.id,
    required this.cornerName,
    required this.categoryId,
    required this.categoryTitle,
    required this.subtitle,
    required this.icon,
    required this.themeColor,
    required this.roomAsset,
    required this.shelfAsset,
    required this.signboardTitle,
    required this.shelfX,
    required this.shelfY,
    required this.mapX,
    required this.mapY,
  });
}

/// 100% Native Continuous 3D Game-Style Library Walkthrough.
/// Walk freely through the room with continuous virtual joystick physics, head-bobbing,
/// 360° look-around, proximity shelf detection, in-shelf book carousel, and interactive map.
class FirstPersonLibraryWalkthroughWidget extends StatefulWidget {
  final List<Category> categories;
  final Map<String, List<Book>> categoryBooks;
  final Map<String, CategoryExperienceConfig> categoryConfigs;
  final Function(Book book)? onBookSelected;
  final Function(Book book)? onReadBook;
  final Function(Book book)? onListenBook;
  final VoidCallback? onBack;
  final Widget? topHeader;

  const FirstPersonLibraryWalkthroughWidget({
    super.key,
    required this.categories,
    required this.categoryBooks,
    required this.categoryConfigs,
    this.onBookSelected,
    this.onReadBook,
    this.onListenBook,
    this.onBack,
    this.topHeader,
  });

  @override
  State<FirstPersonLibraryWalkthroughWidget> createState() =>
      _FirstPersonLibraryWalkthroughWidgetState();
}

class _FirstPersonLibraryWalkthroughWidgetState
    extends State<FirstPersonLibraryWalkthroughWidget>
    with TickerProviderStateMixin {
  // Continuous 3D Player Coordinates in the Hallway (-3.2 to 3.2, -8.0 to 8.0)
  double _playerX = 0.0;
  double _playerY = 0.0;
  double _walkOdometer = 0.0;

  // 360° Directional Look-Around
  double _yawAngle = 0.0;
  double _pitchAngle = 0.0;

  // Mode: Walk (default) or Look (360° pan)
  bool _isWalkMode = true;

  // Virtual Joystick offset (-1.0 to 1.0)
  Offset _joystickKnobOffset = Offset.zero;

  // Continuous 60 FPS Game Loop Ticker
  late Ticker _gameTicker;

  // Nearby Shelf Proximity (< 3.2m)
  LibraryRoomCorner? _nearbyShelf;

  // Screen States
  Category? _openedCategory; // Screen 3: Browse Books
  LibraryRoomCorner? _openedCorner;
  Book? _selectedDetailsBook; // Screen 4: Book Details
  bool _showTopDownMap = false; // Screen 6: Interactive Library Map
  bool _showReturnToast = false; // Screen 5: "Returned to library" toast
  Timer? _returnToastTimer;

  // In-Shelf Carousel Controller
  late PageController _shelfCarouselController;
  int _carouselPage = 0;

  // Zoom Transition Animation
  late AnimationController _zoomController;
  late Animation<double> _zoomAnimation;

  late List<LibraryRoomCorner> _corners;

  @override
  void initState() {
    super.initState();
    _initCorners();
    _shelfCarouselController = PageController(viewportFraction: 0.72);

    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _zoomAnimation = CurvedAnimation(
      parent: _zoomController,
      curve: Curves.easeInOutCubic,
    );

    // Initial proximity check
    _checkShelfProximity();

    // Start 60 FPS Game Engine Loop
    _gameTicker = createTicker(_onGameTick)..start();
  }

  void _initCorners() {
    _corners = [
      // 1. Science (Middle Left Aisle)
      const LibraryRoomCorner(
        id: 'corner_science',
        cornerName: 'SCIENCE & NATURE',
        categoryId: 'cat_scifi',
        categoryTitle: 'Science',
        subtitle: 'Visions of spacetime, biology & quantum physics',
        icon: Icons.science_rounded,
        themeColor: Color(0xFF0284C7),
        roomAsset: 'assets/library_hall_game_bg.jpg',
        shelfAsset: 'assets/library_shelf_close_bg.jpg',
        signboardTitle: 'Science',
        shelfX: -2.0,
        shelfY: 0.5,
        mapX: 0.27,
        mapY: 0.44,
      ),

      // 2. Fiction (Top Right Aisle)
      const LibraryRoomCorner(
        id: 'corner_fiction',
        cornerName: 'FICTION & LITERATURE',
        categoryId: 'cat_mystery',
        categoryTitle: 'Fiction',
        subtitle: 'Timeless storytelling & gripping narratives',
        icon: Icons.auto_stories_rounded,
        themeColor: Color(0xFFE11D48),
        roomAsset: 'assets/library_hall_game_bg.jpg',
        shelfAsset: 'assets/library_shelf_close_bg.jpg',
        signboardTitle: 'Fiction',
        shelfX: 2.0,
        shelfY: 5.0,
        mapX: 0.73,
        mapY: 0.20,
      ),

      // 3. History (Top Left Aisle)
      const LibraryRoomCorner(
        id: 'corner_history',
        cornerName: 'HISTORY & LORE',
        categoryId: 'cat_history',
        categoryTitle: 'History',
        subtitle: 'Ancient chronicles & evolutionary epics',
        icon: Icons.history_edu_rounded,
        themeColor: Color(0xFFC5A059),
        roomAsset: 'assets/library_hall_game_bg.jpg',
        shelfAsset: 'assets/library_shelf_close_bg.jpg',
        signboardTitle: 'History',
        shelfX: -2.0,
        shelfY: 5.0,
        mapX: 0.27,
        mapY: 0.20,
      ),

      // 4. Comics (Middle Right Aisle)
      const LibraryRoomCorner(
        id: 'corner_comics',
        cornerName: 'COMICS & GRAPHIC NOVELS',
        categoryId: 'cat_fantasy',
        categoryTitle: 'Comics',
        subtitle: 'Illustrated sagas and hero journeys',
        icon: Icons.theater_comedy_rounded,
        themeColor: Color(0xFF9333EA),
        roomAsset: 'assets/library_hall_game_bg.jpg',
        shelfAsset: 'assets/library_shelf_close_bg.jpg',
        signboardTitle: 'Comics',
        shelfX: 2.0,
        shelfY: 0.5,
        mapX: 0.73,
        mapY: 0.44,
      ),

      // 5. Technology (Bottom Left Aisle)
      const LibraryRoomCorner(
        id: 'corner_tech',
        cornerName: 'TECHNOLOGY & INNOVATION',
        categoryId: 'cat_sleep',
        categoryTitle: 'Technology',
        subtitle: 'Modern algorithms, machines and code',
        icon: Icons.memory_rounded,
        themeColor: Color(0xFF0D9488),
        roomAsset: 'assets/library_hall_game_bg.jpg',
        shelfAsset: 'assets/library_shelf_close_bg.jpg',
        signboardTitle: 'Technology',
        shelfX: -2.0,
        shelfY: -4.5,
        mapX: 0.27,
        mapY: 0.70,
      ),

      // 6. Arts (Bottom Right Aisle)
      const LibraryRoomCorner(
        id: 'corner_arts',
        cornerName: 'ARTS & CULTURE',
        categoryId: 'cat_malayalam',
        categoryTitle: 'Arts',
        subtitle: 'Visual arts, architecture and aesthetics',
        icon: Icons.palette_rounded,
        themeColor: Color(0xFFEA580C),
        roomAsset: 'assets/library_hall_game_bg.jpg',
        shelfAsset: 'assets/library_shelf_close_bg.jpg',
        signboardTitle: 'Arts',
        shelfX: 2.0,
        shelfY: -4.5,
        mapX: 0.73,
        mapY: 0.70,
      ),
    ];
  }

  @override
  void dispose() {
    _gameTicker.dispose();
    _returnToastTimer?.cancel();
    _shelfCarouselController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  Category _getCategory(String catId) {
    return widget.categories.firstWhere(
      (c) => c.id == catId,
      orElse: () => Category(
        id: catId,
        name: catId,
        tagline: '',
        iconName: 'menu_book',
        experienceId: 'exp_default',
      ),
    );
  }

  // --- 60 FPS Game Loop Engine ---
  void _onGameTick(Duration elapsed) {
    if (_openedCategory != null || _showTopDownMap) return;

    if (_joystickKnobOffset != Offset.zero) {
      const double speed = 0.15;
      final moveY = -_joystickKnobOffset.dy * speed;
      final moveX = _joystickKnobOffset.dx * speed;

      setState(() {
        _playerX = (_playerX + moveX).clamp(-2.8, 2.8);
        _playerY = (_playerY + moveY).clamp(-8.0, 8.0);
        _walkOdometer += (moveX.abs() + moveY.abs());

        // Steering yaw while steering with joystick
        if (moveX.abs() > 0.08) {
          _yawAngle = (_yawAngle - moveX * 2.2).clamp(-180.0, 180.0);
        }
      });

      _checkShelfProximity();
    }
  }

  void _checkShelfProximity() {
    LibraryRoomCorner? closest;
    double minDistance = 999.0;

    for (final c in _corners) {
      final dist = math.sqrt(
        math.pow(_playerX - c.shelfX, 2) + math.pow(_playerY - c.shelfY, 2),
      );
      if (dist < minDistance) {
        minDistance = dist;
        closest = c;
      }
    }

    if (minDistance < 3.4) {
      if (_nearbyShelf != closest) {
        setState(() {
          _nearbyShelf = closest;
        });
      }
    } else {
      if (_nearbyShelf != null) {
        setState(() {
          _nearbyShelf = null;
        });
      }
    }
  }

  void _teleportToShelf(LibraryRoomCorner corner) {
    HapticFeedback.mediumImpact();
    setState(() {
      _playerX = corner.shelfX > 0 ? corner.shelfX - 0.8 : corner.shelfX + 0.8;
      _playerY = corner.shelfY;
      _yawAngle = corner.shelfX > 0 ? -45.0 : 45.0;
      _pitchAngle = 0.0;
      _nearbyShelf = corner;
      _showTopDownMap = false;
    });
  }

  void _approachAndOpenShelf(LibraryRoomCorner corner) {
    final category = _getCategory(corner.categoryId);
    HapticFeedback.mediumImpact();

    setState(() {
      _openedCorner = corner;
      _openedCategory = category;
      _carouselPage = 0;
    });

    _zoomController.forward(from: 0.0);
  }

  void _closeShelf() {
    HapticFeedback.lightImpact();
    _zoomController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _openedCategory = null;
          _openedCorner = null;
          _selectedDetailsBook = null;
        });
        _triggerReturnToast();
      }
    });
  }

  void _openBookDetails(Book book) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDetailsBook = book;
    });
  }

  void _closeBookDetails() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedDetailsBook = null;
    });
  }

  void _triggerReturnToast() {
    _returnToastTimer?.cancel();
    setState(() {
      _showReturnToast = true;
    });
    _returnToastTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) {
        setState(() {
          _showReturnToast = false;
        });
      }
    });
  }

  // --- Virtual Joystick Dragging ---
  void _updateJoystickOffset(Offset localPosition, double maxRadius) {
    final localPos = localPosition - Offset(maxRadius, maxRadius);
    final distance = localPos.distance;
    final clampedDistance = math.min(distance, maxRadius);
    final normalized = distance == 0
        ? Offset.zero
        : Offset(
            (localPos.dx / distance) * (clampedDistance / maxRadius),
            (localPos.dy / distance) * (clampedDistance / maxRadius),
          );

    setState(() {
      _joystickKnobOffset = normalized;
    });
  }

  void _onJoystickEnd(DragEndDetails details) {
    setState(() {
      _joystickKnobOffset = Offset.zero;
    });
  }

  void _onHallPanUpdate(DragUpdateDetails details) {
    if (_openedCategory != null) return;
    setState(() {
      if (_isWalkMode) {
        // Direct Swipe to Walk in Walk Mode
        final deltaY = -details.delta.dy * 0.055;
        final deltaX = details.delta.dx * 0.025;
        _playerY = (_playerY + deltaY).clamp(-8.0, 8.0);
        _playerX = (_playerX + deltaX).clamp(-2.8, 2.8);
        _walkOdometer += (deltaY.abs() + deltaX.abs());
        _yawAngle = (_yawAngle - details.delta.dx * 0.18).clamp(-180.0, 180.0);
      } else {
        // 360° Pan & Tilt in Look Mode
        _yawAngle = (_yawAngle - details.delta.dx * 0.38).clamp(-180.0, 180.0);
        _pitchAngle = (_pitchAngle + details.delta.dy * 0.22).clamp(-25.0, 25.0);
      }
    });
    _checkShelfProximity();
  }

  // Stride single step forward / backward
  void _strideStep(double dy) {
    HapticFeedback.lightImpact();
    setState(() {
      _playerY = (_playerY + dy).clamp(-8.0, 8.0);
      _walkOdometer += dy.abs();
    });
    _checkShelfProximity();
  }

  @override
  Widget build(BuildContext context) {
    final activeShelf = _nearbyShelf ?? _corners.first;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            // ==========================================
            // SCREEN 1 & 2: CONTINUOUS 3D GAME-STYLE HALLWAY EXPLORATION
            // ==========================================
            Positioned.fill(
              child: GestureDetector(
                onPanUpdate: _onHallPanUpdate,
                child: ClipRect(
                  child: AnimatedBuilder(
                    animation: _zoomAnimation,
                    builder: (context, child) {
                      final zoomT = _zoomAnimation.value;

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          // 1. Continuous Photorealistic 3D Room Hallway with Dynamic Walking Transformations
                          if (_openedCategory == null || zoomT < 0.98) ...[
                            _buildContinuous3DHallway(zoomT),

                            // Ambient Daylight Vignette
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.35),
                                        Colors.transparent,
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.55),
                                      ],
                                      stops: const [0.0, 0.16, 0.80, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // 2. In-Hallway Shelves with Signboards & "Tap to open" (Screen 1 & 2)
                            _buildHallwaySignboardsAndPrompts(zoomT),
                          ],

                          // 3. Screen 3: In-Shelf Horizontal Book Carousel
                          if (_openedCategory != null && zoomT > 0.02 && _selectedDetailsBook == null)
                            Opacity(
                              opacity: (zoomT * 1.2 - 0.2).clamp(0.0, 1.0),
                              child: _buildBrowseBooksScreen(_openedCorner ?? activeShelf),
                            ),

                          // 4. Screen 4: Book Details Screen
                          if (_selectedDetailsBook != null)
                            _buildBookDetailsScreen(_selectedDetailsBook!, _openedCorner ?? activeShelf),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            // ==========================================
            // HUD OVERLAYS (Top Header, Virtual Joystick, Mode Buttons)
            // ==========================================
            if (_openedCategory == null && _selectedDetailsBook == null && !_showTopDownMap) ...[
              // Top Bar: ← Library & Map Pin Button
              Positioned(
                top: 8,
                left: 14,
                right: 14,
                child: _buildHallTopBar(),
              ),

              // Bottom-Left: Virtual Joystick & Stride Buttons (Screen 1)
              Positioned(
                bottom: 24,
                left: 20,
                child: _buildVirtualJoystick(),
              ),

              // Bottom-Right: Walk & Look Action Mode Buttons (Screen 1)
              Positioned(
                bottom: 28,
                right: 20,
                child: _buildModeActionButtons(),
              ),

              // Screen 5: "Returned to library" Toast Notification
              if (_showReturnToast)
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _buildReturnedToLibraryToast(),
                  ),
                ),
            ],

            // ==========================================
            // SCREEN 6: INTERACTIVE TOP-DOWN LIBRARY MAP
            // ==========================================
            if (_showTopDownMap)
              _buildTopDownLibraryMapModal(),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. High-Performance Native 3D Spatial Room Engine
  // -------------------------------------------------------------
  Widget _buildContinuous3DHallway(double zoomT) {
    // Dynamic scale zooms deeply as the player advances towards the sunlit arched window
    final walkProgress = ((_playerY + 8.0) / 16.0).clamp(0.0, 1.0);
    final depthScale = 1.05 + (walkProgress * 1.35) + (zoomT * 0.40);
    final headBob = math.sin(_walkOdometer * 9.0) * 4.2;

    final rotY = (_yawAngle * math.pi / 180.0) * 0.35;
    final rotX = (-_pitchAngle * math.pi / 180.0) * 0.25;
    final transX = -_playerX * 65.0 - _yawAngle * 2.8;
    final transY = (_playerY * 8.5) + _pitchAngle * 2.5 + headBob;

    final windowStudyBlend = (_playerY > 2.5) ? ((_playerY - 2.5) / 4.0).clamp(0.0, 1.0) : 0.0;
    final turnAroundBlend = (_yawAngle.abs() > 65.0) ? ((_yawAngle.abs() - 65.0) / 55.0).clamp(0.0, 1.0) : 0.0;
    final shelfBlend = zoomT > 0.0 ? zoomT : (_playerX.abs() > 1.2 ? ((_playerX.abs() - 1.2) / 1.2).clamp(0.0, 1.0) : 0.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..translateByDouble(transX, transY, 0.0, 1.0)
            ..rotateY(rotY.clamp(-0.40, 0.40))
            ..rotateX(rotX.clamp(-0.25, 0.25))
            ..scaleByDouble(depthScale, depthScale, 1.0, 1.0),
          child: Image.asset(
            'assets/library_hall_game_bg.jpg',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFF1E293B),
            ),
          ),
        ),

        if (windowStudyBlend > 0.01 && turnAroundBlend < 0.9)
          Opacity(
            opacity: (windowStudyBlend * (1.0 - turnAroundBlend)).clamp(0.0, 1.0),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..translateByDouble(transX, transY, 0.0, 1.0)
                ..rotateY(rotY.clamp(-0.40, 0.40))
                ..rotateX(rotX.clamp(-0.25, 0.25))
                ..scaleByDouble(depthScale * 0.95, depthScale * 0.95, 1.0, 1.0),
              child: Image.asset(
                'assets/library_window_study_view.jpg',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ),

        if (turnAroundBlend > 0.01)
          Opacity(
            opacity: turnAroundBlend.clamp(0.0, 1.0),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..translateByDouble(-transX * 0.5, transY, 0.0, 1.0)
                ..rotateY((-rotY).clamp(-0.40, 0.40))
                ..rotateX(rotX.clamp(-0.25, 0.25))
                ..scaleByDouble(1.25 + (1.0 - walkProgress) * 0.35, 1.25 + (1.0 - walkProgress) * 0.35, 1.0, 1.0),
              child: Image.asset(
                'assets/library_entrance_back_view.jpg',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ),

        if (shelfBlend > 0.01)
          Opacity(
            opacity: shelfBlend.clamp(0.0, 1.0),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..translateByDouble(transX * 0.3, transY * 0.3, 0.0, 1.0)
                ..scaleByDouble(1.05 + zoomT * 0.15, 1.05 + zoomT * 0.15, 1.0, 1.0),
              child: Image.asset(
                'assets/library_shelf_close_bg.jpg',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 2. Symmetrical Hallway Signboards & Proximity "Tap to open" (Screen 1 & 2)
  // -------------------------------------------------------------
  Widget _buildHallwaySignboardsAndPrompts(double zoomT) {
    final nearby = _nearbyShelf ?? _corners.first;

    return Positioned.fill(
      child: Center(
        child: Opacity(
          opacity: (1.0 - zoomT * 1.5).clamp(0.0, 1.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Wall-Mounted Dark Wooden Category Signboard (Screen 1 & 2)
              GestureDetector(
                onTap: () => _approachAndOpenShelf(nearby),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF2E1C12),
                        Color(0xFF1C100A),
                        Color(0xFF0F0805),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.65),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    nearby.signboardTitle,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Screen 2: "Tap to open" Floating Pill Button (Matching Reference)
              GestureDetector(
                onTap: () => _approachAndOpenShelf(nearby),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.32),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        size: 17,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Tap to open',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // Top App Bar for Hallway: ← Library & Location Pin Button
  // -------------------------------------------------------------
  Widget _buildHallTopBar() {
    String locationLabel;
    if (_playerY > 3.0) {
      locationLabel = 'Window Study Wing';
    } else if (_playerY < -3.0) {
      locationLabel = 'Entrance Hall';
    } else {
      locationLabel = 'Central Corridor';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ← Library Back / Title
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.of(context).maybePop();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 14,
                  color: Colors.white,
                ),
                SizedBox(width: 6),
                Text(
                  'Library',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Live Room Sector Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.explore_rounded,
                size: 13,
                color: Color(0xFFD4AF37),
              ),
              const SizedBox(width: 6),
              Text(
                locationLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // [📍] Library Map Pin Button (Opens Screen 6)
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            setState(() {
              _showTopDownMap = true;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // Virtual Joystick & Quick Stride Controls (Screen 1: Bottom-Left)
  // -------------------------------------------------------------
  Widget _buildVirtualJoystick() {
    const double radius = 48.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Main Virtual Joystick Pad
        GestureDetector(
          onPanStart: (d) => _updateJoystickOffset(d.localPosition, radius),
          onPanUpdate: (d) => _updateJoystickOffset(d.localPosition, radius),
          onPanEnd: _onJoystickEnd,
          child: Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.38),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Directional hint chevrons
                Positioned(
                  top: 6,
                  child: Icon(Icons.keyboard_arrow_up_rounded, size: 16, color: Colors.white.withValues(alpha: 0.5)),
                ),
                Positioned(
                  bottom: 6,
                  child: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.white.withValues(alpha: 0.5)),
                ),
                Positioned(
                  left: 6,
                  child: Icon(Icons.keyboard_arrow_left_rounded, size: 16, color: Colors.white.withValues(alpha: 0.5)),
                ),
                Positioned(
                  right: 6,
                  child: Icon(Icons.keyboard_arrow_right_rounded, size: 16, color: Colors.white.withValues(alpha: 0.5)),
                ),

                // Thumb Knob
                Transform.translate(
                  offset: Offset(
                    _joystickKnobOffset.dx * (radius - 16),
                    _joystickKnobOffset.dy * (radius - 16),
                  ),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.90),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Quick Forward / Backward Stride Buttons
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Walk Forward Button [▲]
            GestureDetector(
              onTap: () => _strideStep(1.2),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Step Backward Button [▼]
            GestureDetector(
              onTap: () => _strideStep(-1.2),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_downward_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // Mode Action Buttons (Screen 1: Bottom-Right Walk [🚶] & Look [👁️])
  // -------------------------------------------------------------
  Widget _buildModeActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Walk Mode Toggle [🚶]
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _isWalkMode = true;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isWalkMode
                  ? Colors.white.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.4),
              border: Border.all(
                color: _isWalkMode ? Colors.white : Colors.white24,
                width: 1.2,
              ),
            ),
            child: const Icon(
              Icons.directions_walk_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Look 360° Toggle [👁️]
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _isWalkMode = false;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: !_isWalkMode
                  ? Colors.white.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.4),
              border: Border.all(
                color: !_isWalkMode ? Colors.white : Colors.white24,
                width: 1.2,
              ),
            ),
            child: const Icon(
              Icons.visibility_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // Screen 5: "Returned to library" Toast
  // -------------------------------------------------------------
  Widget _buildReturnedToLibraryToast() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 15,
            color: Colors.white,
          ),
          SizedBox(width: 8),
          Text(
            'Returned to library',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SCREEN 3: BROWSE BOOKS HORIZONTAL CAROUSEL
  // -------------------------------------------------------------
  Widget _buildBrowseBooksScreen(LibraryRoomCorner corner) {
    final category = _getCategory(corner.categoryId);
    final books = widget.categoryBooks[category.id] ?? [];

    return Container(
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          // Top Navigation Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _closeShelf,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Library',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.bookmark_outline_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ],
            ),
          ),

          // Large Centered Category Title (e.g. Science)
          const SizedBox(height: 16),
          Text(
            corner.signboardTitle,
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),

          // Horizontal Book Cover Carousel (Screen 3)
          if (books.isNotEmpty)
            Expanded(
              child: PageView.builder(
                controller: _shelfCarouselController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (idx) {
                  setState(() {
                    _carouselPage = idx;
                  });
                },
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  final isCurrent = index == _carouselPage;

                  return GestureDetector(
                    onTap: () => _openBookDetails(book),
                    child: AnimatedScale(
                      scale: isCurrent ? 1.0 : 0.88,
                      duration: const Duration(milliseconds: 250),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Book Cover Card
                          Container(
                            height: 250,
                            width: 170,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Realistic Cover Art
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          corner.themeColor,
                                          const Color(0xFF0F172A),
                                        ],
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          corner.icon,
                                          size: 36,
                                          color: Colors.white70,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          book.metadata.title,
                                          textAlign: TextAlign.center,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'serif',
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Spine Lighting Highlight
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    bottom: 0,
                                    width: 10,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0x40FFFFFF),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Book Title
                          Text(
                            book.metadata.title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Book Author
                          Text(
                            book.metadata.author,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // Page Dots Indicator (Screen 3: [ • • • • ])
          if (books.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                math.min(books.length, 6),
                (dotIdx) {
                  final isSelected = dotIdx == _carouselPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isSelected ? 8 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.white30,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SCREEN 4: BOOK DETAILS SCREEN
  // -------------------------------------------------------------
  Widget _buildBookDetailsScreen(Book book, LibraryRoomCorner corner) {
    return Container(
      color: const Color(0xFF0F172A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: ← Back & [🔖] Bookmark
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _closeBookDetails,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.bookmark_outline_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Book Cover + Title, Author, Rating & Tag Pills
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Large Book Cover
                      Container(
                        width: 110,
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            color: corner.themeColor,
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  corner.icon,
                                  size: 28,
                                  color: Colors.white70,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  book.metadata.title,
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'serif',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Metadata column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.metadata.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'serif',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              book.metadata.author,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Rating: ★ 4.7 (12.4k reviews)
                            const Row(
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: Color(0xFFFBBF24),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '4.7',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '(12.4k reviews)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Category Tag Pills
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _buildTagPill(corner.categoryTitle),
                                _buildTagPill('Anthology'),
                                _buildTagPill('Classics'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Synopsis Description Paragraph
                  Text(
                    'A groundbreaking exploration that uncovers timeless narratives, deep human knowledge, and perspectives that reshape our understanding of literature, history, and life.',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.55,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Primary Action Button: Read Now (Blue Pill Button)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        widget.onReadBook?.call(book);
                      },
                      icon: const Icon(Icons.menu_book_rounded, size: 18),
                      label: const Text(
                        'Read Now',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Secondary Audio Narration Button: Listen Now
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        widget.onListenBook?.call(book);
                      },
                      icon: const Icon(Icons.headphones_rounded, size: 18),
                      label: const Text(
                        'Listen Audiobook',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tertiary: Add to Favorites
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added "${book.metadata.title}" to favorites!'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.favorite_border_rounded, size: 18),
                      label: const Text(
                        'Add to Favorites',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.white70,
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // SCREEN 6: INTERACTIVE TOP-DOWN LIBRARY MAP (Screen 6)
  // -------------------------------------------------------------
  Widget _buildTopDownLibraryMapModal() {
    return Container(
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          // Top Header: ← Library & [📍] Map Icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _showTopDownMap = false;
                    });
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Library',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Interactive Top-Down Floor Map with Section Badges
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final mapW = constraints.maxWidth;
                    final mapH = constraints.maxHeight;

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // Top-Down Isometric Map Background Image
                        Image.asset(
                          'assets/library_map_isometric_bg.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: const Color(0xFF1E293B),
                          ),
                        ),

                        // Section Badges & Teleport Buttons
                        ...List.generate(_corners.length, (idx) {
                          final c = _corners[idx];
                          final posX = c.mapX * mapW;
                          final posY = c.mapY * mapH;
                          final isCurrent = _nearbyShelf?.id == c.id;

                          return Positioned(
                            left: posX - 44,
                            top: posY - 16,
                            child: GestureDetector(
                              onTap: () => _teleportToShelf(c),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF141414).withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isCurrent ? Colors.white : Colors.white24,
                                    width: 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  c.signboardTitle,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                        // Current User Location Pin with Pulsing Glow [📍]
                        Positioned(
                          left: (_nearbyShelf?.mapX ?? 0.32) * mapW - 14,
                          top: (_nearbyShelf?.mapY ?? 0.44) * mapH + 14,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.6),
                                  blurRadius: 16,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.my_location_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),

          // Bottom Bar: Instructions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Text(
              'Tap any section above to quickly navigate to that shelf in the 3D hall.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
