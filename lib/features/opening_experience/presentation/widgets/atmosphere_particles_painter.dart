import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated atmospheric overlay with particle effects corresponding to effect IDs:
/// 'starfield', 'ink_dust', 'golden_glow', 'shadow_mist', 'magical_sparkles', 'cosmic_pulse'.
class AtmosphereParticlesOverlay extends StatefulWidget {
  final String effectId;
  final Color accentColor;

  const AtmosphereParticlesOverlay({
    super.key,
    required this.effectId,
    required this.accentColor,
  });

  @override
  State<AtmosphereParticlesOverlay> createState() => _AtmosphereParticlesOverlayState();
}

class _AtmosphereParticlesOverlayState extends State<AtmosphereParticlesOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    final rand = math.Random(42);
    _particles = List.generate(35, (index) {
      return _Particle(
        x: rand.nextDouble(),
        y: rand.nextDouble(),
        radius: 1.5 + rand.nextDouble() * 3.5,
        speed: 0.05 + rand.nextDouble() * 0.15,
        opacity: 0.2 + rand.nextDouble() * 0.6,
        phase: rand.nextDouble() * math.pi * 2,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _AtmospherePainter(
            effectId: widget.effectId,
            accentColor: widget.accentColor,
            progress: _controller.value,
            particles: _particles,
          ),
        );
      },
    );
  }
}

class _Particle {
  double x;
  double y;
  double radius;
  double speed;
  double opacity;
  double phase;

  _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.phase,
  });
}

class _AtmospherePainter extends CustomPainter {
  final String effectId;
  final Color accentColor;
  final double progress;
  final List<_Particle> particles;

  _AtmospherePainter({
    required this.effectId,
    required this.accentColor,
    required this.progress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      // Calculate dynamic positions
      final currentY = (p.y - (progress * p.speed)) % 1.0;
      final currentX = (p.x + math.sin(progress * math.pi * 2 + p.phase) * 0.03) % 1.0;
      final posX = currentX * size.width;
      final posY = currentY * size.height;

      // Pulse opacity
      final pulse = (math.sin(progress * math.pi * 4 + p.phase) + 1.0) / 2.0;
      final dynamicOpacity = (p.opacity * (0.4 + pulse * 0.6)).clamp(0.0, 1.0);

      if (effectId == 'starfield') {
        // Twinkling stars
        paint.color = Colors.white.withValues(alpha: dynamicOpacity * 0.85);
        canvas.drawCircle(Offset(posX, posY), p.radius * 0.7, paint);
      } else if (effectId == 'magical_sparkles') {
        // Star diamond sparkles
        paint.color = accentColor.withValues(alpha: dynamicOpacity);
        _drawSparkle(canvas, Offset(posX, posY), p.radius * 1.5, paint);
      } else if (effectId == 'shadow_mist') {
        // Soft misty glow spots
        paint.color = accentColor.withValues(alpha: dynamicOpacity * 0.15);
        canvas.drawCircle(Offset(posX, posY), p.radius * 4.0, paint);
      } else {
        // Golden dust / warm ember specks (default)
        paint.color = accentColor.withValues(alpha: dynamicOpacity * 0.75);
        canvas.drawCircle(Offset(posX, posY), p.radius, paint);
      }
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..lineTo(center.dx + size * 0.3, center.dy - size * 0.3)
      ..lineTo(center.dx + size, center.dy)
      ..lineTo(center.dx + size * 0.3, center.dy + size * 0.3)
      ..lineTo(center.dx, center.dy + size)
      ..lineTo(center.dx - size * 0.3, center.dy + size * 0.3)
      ..lineTo(center.dx - size, center.dy)
      ..lineTo(center.dx - size * 0.3, center.dy - size * 0.3)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter oldDelegate) => true;
}
