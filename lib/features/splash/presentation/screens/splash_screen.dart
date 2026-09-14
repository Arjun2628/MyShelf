import 'dart:async';
import 'package:epub_audio/features/library/data/datasources/hive_storage_service.dart';
import 'package:epub_audio/features/library/presentation/screens/library_screen.dart';
import 'package:epub_audio/features/navigation/presentation/main_navigation_shell.dart';
import 'package:epub_audio/features/splash/presentation/screens/feature_guide_screen.dart';
import 'package:flutter/material.dart';

/// An immersive, premium splash screen showcasing the illuminated open book emblem.
/// Displays on every app opening, then smoothly transitions to the Library (or
/// the Feature Guide on first launch).
class SplashScreen extends StatefulWidget {
  final VoidCallback? onGetStarted;
  final bool autoAdvance;

  const SplashScreen({
    super.key,
    this.onGetStarted,
    this.autoAdvance = true,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  Timer? _autoTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _scaleAnim = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _animController.forward();

    if (widget.autoAdvance) {
      _autoTimer = Timer(const Duration(milliseconds: 2200), () {
        if (mounted && !_hasNavigated) {
          _advance();
        }
      });
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _advance() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    _autoTimer?.cancel();

    if (widget.onGetStarted != null) {
      widget.onGetStarted!();
      return;
    }

    final hasSeenGuide = HiveStorageService().hasSeenOnboarding();
    final Widget targetScreen = hasSeenGuide
        ? const MainNavigationShell()
        : const FeatureGuideScreen();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF090807),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Ambient Golden Radial Background Glow
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.15),
                  radius: 1.1,
                  colors: [
                    Color(0xFF332010),
                    Color(0xFF1B1109),
                    Color(0xFF090807),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // 2. Main Splash Content (Logo, Typography, Features, and Button)
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      // Illuminated Logo with Ambient Glow Halo
                      Container(
                        width: size.width * 0.62,
                        height: size.width * 0.44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEAB308).withValues(alpha: 0.28),
                              blurRadius: 40,
                              spreadRadius: 4,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'assets/app_logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1610),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFFF1D49B).withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.auto_stories_rounded,
                                  size: 64,
                                  color: Color(0xFFF1D49B),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // App Title & Tagline
                      const Text(
                        'EPUB & Audiobooks',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                          color: Color(0xFFFBF4EB),
                          shadows: [
                            Shadow(
                              color: Color(0xFFF59E0B),
                              blurRadius: 16,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'Immersive Reading • Live Voice Narration • Smart OCR',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          color: const Color(0xFFE5D5C2).withValues(alpha: 0.85),
                          letterSpacing: 0.2,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Feature Pills
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildFeaturePill(Icons.book_rounded, 'EPUB & PDF'),
                          const SizedBox(width: 8),
                          _buildFeaturePill(Icons.record_voice_over_rounded, 'Audiobook'),
                          const SizedBox(width: 8),
                          _buildFeaturePill(Icons.document_scanner_rounded, 'OCR Scan'),
                        ],
                      ),

                      const Spacer(flex: 3),

                      // "Get Started" Action Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFF59E0B),
                              Color(0xFFD97706),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _advance,
                            borderRadius: BorderRadius.circular(28),
                            splashColor: Colors.white.withValues(alpha: 0.25),
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Get Started',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF26190E).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF1D49B).withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFFF59E0B)),
          const SizedBox(width: 4.5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE5D5C2),
            ),
          ),
        ],
      ),
    );
  }
}
