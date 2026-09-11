import 'package:epub_audio/features/splash/presentation/screens/feature_guide_screen.dart';
import 'package:flutter/material.dart';

/// An immersive, pristine splash screen for ScribbleVerse.
/// Renders the illuminated artwork seamlessly without duplicate text overlays,
/// and routes to the interactive Feature Guide upon tapping "Get Started".
class SplashScreen extends StatefulWidget {
  final VoidCallback? onGetStarted;

  const SplashScreen({
    super.key,
    this.onGetStarted,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

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

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _navigateToGuide() {
    if (widget.onGetStarted != null) {
      widget.onGetStarted!();
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const FeatureGuideScreen(),
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
    return Scaffold(
      backgroundColor: const Color(0xFF0D0A07),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Pristine Full-Bleed Artwork
          FadeTransition(
            opacity: _fadeAnim,
            child: Image.asset(
              'assets/splash_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.0, 0.2),
                    radius: 1.2,
                    colors: [
                      Color(0xFF3B2816),
                      Color(0xFF140D07),
                      Color(0xFF080503),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Interactive Bottom Touch Areas (Positioned cleanly over the artwork buttons)
          SafeArea(
            child: Column(
              children: [
                // Top & Center interactive tap zone
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _navigateToGuide,
                    child: const SizedBox.expand(),
                  ),
                ),

                // Bottom Interactive Button Overlay
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // "Get Started" Touch Target with Smooth Ripple
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _navigateToGuide,
                          borderRadius: BorderRadius.circular(30),
                          splashColor: const Color(0xFFF1D49B).withValues(alpha: 0.35),
                          highlightColor: const Color(0xFFF1D49B).withValues(alpha: 0.2),
                          child: Container(
                            height: 58,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // "I already have an account" Touch Target
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _navigateToGuide,
                          borderRadius: BorderRadius.circular(12),
                          splashColor: Colors.white.withValues(alpha: 0.1),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: SizedBox(
                              height: 24,
                              child: Center(
                                child: SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
