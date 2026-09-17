import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

/// Fullscreen real-time interactive 3D Rotunda walkthrough powered by the user's Blender model.
class Interactive3DRotundaScreen extends StatefulWidget {
  const Interactive3DRotundaScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            const Interactive3DRotundaScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 0.08);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: animation.drive(tween),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  State<Interactive3DRotundaScreen> createState() =>
      _Interactive3DRotundaScreenState();
}

class _Interactive3DRotundaScreenState
    extends State<Interactive3DRotundaScreen> {
  bool _autoRotate = false;
  String _currentPreset = 'overview';
  String _cameraOrbit = '0deg 85deg 0.5m';
  String _cameraTarget = '0m 0m 1.8m';
  static const Key _stableViewerKey = ValueKey('model_viewer_rotunda_stable');

  void _selectPreset(String preset, String orbit, String target) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentPreset = preset;
      _cameraOrbit = orbit;
      _cameraTarget = target;
    });
  }

  void _toggleAutoRotate() {
    HapticFeedback.selectionClick();
    setState(() {
      _autoRotate = !_autoRotate;
    });
  }

  @override
  Widget build(BuildContext context) {
    const goldAccent = Color(0xFFD4AF37);
    const canvasBg = Color(0xFF140C07);
    final hasPlatformWebView = WebViewPlatform.instance != null;

    return Scaffold(
      backgroundColor: canvasBg,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Real-Time 3D Blender GLB Model Viewport (Interior Eye-Level 360° Walkthrough)
            Positioned.fill(
              child: hasPlatformWebView
                  ? ModelViewer(
                      key: _stableViewerKey,
                      src: 'assets/demolibrary.glb',
                      alt: 'The Grand 3D Rotunda Library Interior',
                      ar: false,
                      autoRotate: _autoRotate,
                      autoRotateDelay: 1000,
                      rotationPerSecond: '4deg',
                      cameraControls: true,
                      cameraOrbit: _cameraOrbit,
                      cameraTarget: _cameraTarget,
                      minCameraOrbit: 'auto auto 0.1m',
                      maxCameraOrbit: 'auto auto 4.5m',
                      fieldOfView: '75deg',
                      minFieldOfView: '35deg',
                      maxFieldOfView: '95deg',
                      backgroundColor: canvasBg,
                      shadowIntensity: 1.0,
                      shadowSoftness: 1.0,
                      exposure: 0.92,
                    )
                  : Image.asset(
                      'assets/blender_rotunda_main.png',
                      fit: BoxFit.cover,
                    ),
            ),

            // 2. Atmospheric Dark Amber Vignette (Melts the 3D canvas seamlessly into the dark theme)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        canvasBg.withValues(alpha: 0.75),
                        Colors.transparent,
                        Colors.transparent,
                        canvasBg.withValues(alpha: 0.85),
                      ],
                      stops: const [0.0, 0.15, 0.75, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Top Header Overlay (Title, Info, Close Button)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title & Subtitle Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.70),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: goldAccent.withValues(alpha: 0.5),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.view_in_ar_rounded,
                              size: 14,
                              color: goldAccent,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '3D GRAND ROTUNDA',
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.6,
                                color: Color(0xFFF9F5EC),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'INTERACTIVE 360° BLENDER MODEL',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: goldAccent.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Close Button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.70),
                        border: Border.all(
                          color: goldAccent.withValues(alpha: 0.5),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: Color(0xFFF9F5EC),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4. Gesture Navigation Hint Tooltip
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        size: 13,
                        color: goldAccent.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Drag to Orbit • Pinch to Zoom • Two Fingers to Pan',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE2E8F0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 5. Bottom Perspective Presets & Auto-Rotate Controls Dock
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: goldAccent.withValues(alpha: 0.35),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Preset Chips (Interior Walkthrough Angles)
                        _buildPresetChip(
                          id: 'overview',
                          label: 'Interior 360°',
                          icon: Icons.panorama_photosphere_rounded,
                          orbit: '0deg 85deg 0.5m',
                          target: '0m 0m 1.8m',
                          goldAccent: goldAccent,
                        ),
                        const SizedBox(width: 4),
                        _buildPresetChip(
                          id: 'desks',
                          label: 'Study Desk',
                          icon: Icons.menu_book_rounded,
                          orbit: '180deg 80deg 1.2m',
                          target: '0m -6.5m 1.0m',
                          goldAccent: goldAccent,
                        ),
                        const SizedBox(width: 4),
                        _buildPresetChip(
                          id: 'chandelier',
                          label: 'Dome Vault',
                          icon: Icons.lightbulb_rounded,
                          orbit: '0deg 30deg 1.5m',
                          target: '0m 0m 6.0m',
                          goldAccent: goldAccent,
                        ),
                        const SizedBox(width: 4),
                        _buildPresetChip(
                          id: 'balcony',
                          label: 'Balcony',
                          icon: Icons.balcony_rounded,
                          orbit: '60deg 75deg 2.0m',
                          target: '0m 0m 4.0m',
                          goldAccent: goldAccent,
                        ),
                        const SizedBox(width: 6),
                        // Divider
                        Container(
                          height: 18,
                          width: 1,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        const SizedBox(width: 6),
                        // Auto-Rotate Icon Button
                        GestureDetector(
                          onTap: _toggleAutoRotate,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _autoRotate
                                  ? goldAccent
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                            child: Icon(
                              _autoRotate
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 15,
                              color: _autoRotate
                                  ? const Color(0xFF140C07)
                                  : goldAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip({
    required String id,
    required String label,
    required IconData icon,
    required String orbit,
    required String target,
    required Color goldAccent,
  }) {
    final isSelected = _currentPreset == id;

    return GestureDetector(
      onTap: () => _selectPreset(id, orbit, target),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5.5),
        decoration: BoxDecoration(
          color: isSelected
              ? goldAccent
              : Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? goldAccent
                : Colors.white.withValues(alpha: 0.2),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isSelected ? const Color(0xFF140C07) : goldAccent,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF140C07)
                    : const Color(0xFFF9F5EC),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
