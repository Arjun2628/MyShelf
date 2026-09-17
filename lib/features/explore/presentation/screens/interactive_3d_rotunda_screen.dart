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
  bool _autoRotate = true;
  String _currentPreset = 'overview';
  String _cameraOrbit = '0deg 75deg 10m';
  String _cameraTarget = 'auto auto auto';
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
            // 1. Real-Time 3D Blender GLB Model Viewport
            Positioned.fill(
              child: hasPlatformWebView
                  ? ModelViewer(
                      key: _stableViewerKey,
                      src: 'assets/demolibrary.glb',
                      alt: 'The Grand 3D Rotunda Library',
                      ar: false,
                      autoRotate: _autoRotate,
                      autoRotateDelay: 1000,
                      rotationPerSecond: '15deg',
                      cameraControls: true,
                      cameraOrbit: _cameraOrbit,
                      cameraTarget: _cameraTarget,
                      fieldOfView: '45deg',
                      backgroundColor: canvasBg,
                      shadowIntensity: 1.0,
                      shadowSoftness: 0.8,
                      exposure: 1.1,
                    )
                  : Image.asset(
                      'assets/blender_rotunda_main.png',
                      fit: BoxFit.cover,
                    ),
            ),

            // 2. Top Header Overlay (Title, Info, Close Button)
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

            // 3. Gesture Navigation Hint Tooltip
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

            // 4. Bottom Perspective Presets & Auto-Rotate Controls
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quick Perspective Preset Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPresetChip(
                          id: 'overview',
                          label: 'Overview',
                          icon: Icons.hub_rounded,
                          orbit: '0deg 75deg 10m',
                          target: 'auto auto auto',
                          goldAccent: goldAccent,
                        ),
                        const SizedBox(width: 8),
                        _buildPresetChip(
                          id: 'chandelier',
                          label: 'Chandelier',
                          icon: Icons.lightbulb_rounded,
                          orbit: '0deg 85deg 5.5m',
                          target: '0m 0m 2m',
                          goldAccent: goldAccent,
                        ),
                        const SizedBox(width: 8),
                        _buildPresetChip(
                          id: 'desks',
                          label: 'Study Desks',
                          icon: Icons.menu_book_rounded,
                          orbit: '45deg 80deg 5m',
                          target: '1.5m -2m 1m',
                          goldAccent: goldAccent,
                        ),
                        const SizedBox(width: 8),
                        _buildPresetChip(
                          id: 'balcony',
                          label: 'Upper Balcony',
                          icon: Icons.balcony_rounded,
                          orbit: '0deg 45deg 8m',
                          target: '0m 0m 3.5m',
                          goldAccent: goldAccent,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Auto-Rotate Button
                  GestureDetector(
                    onTap: _toggleAutoRotate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _autoRotate
                            ? goldAccent
                            : Colors.black.withValues(alpha: 0.70),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: goldAccent,
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: goldAccent.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _autoRotate
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded,
                            size: 16,
                            color: _autoRotate
                                ? const Color(0xFF140C07)
                                : goldAccent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _autoRotate ? 'Pause 360° Orbit' : 'Auto 360° Orbit',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _autoRotate
                                  ? const Color(0xFF140C07)
                                  : goldAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? goldAccent
              : Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(16),
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
              size: 13,
              color: isSelected ? const Color(0xFF140C07) : goldAccent,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
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
