import 'package:demo/themes/tier_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

class WaterDropletEffect extends StatefulWidget {
  final double progress;
  final bool isRunning;
  final int resetKey;

  const WaterDropletEffect({
    super.key,
    required this.progress,
    required this.isRunning,
    this.resetKey = 0, required Color waterColor,
  });

  @override
  State<WaterDropletEffect> createState() => _WaterDropletEffectState();
}

class _WaterDropletEffectState extends State<WaterDropletEffect>
    with TickerProviderStateMixin {
  late AnimationController _rainController;
  late AnimationController _waveController;
  late AnimationController _rippleController;
  late Animation<double> _waveAnimation;

  final List<RainDrop> _rainDrops = [];
  bool _showRipple = false;
  Offset _ripplePosition = Offset.zero;
  double _rippleProgress = 0.0;
  final math.Random _random = math.Random();
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();

    _rainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(_updateRain);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_waveController);

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _rippleController.addListener(() {
      setState(() {
        _rippleProgress = _rippleController.value;
      });
    });

    _initializeRain();

    if (widget.isRunning) {
      _rainController.repeat();
    }
  }

  void _initializeRain() {
    _rainDrops.clear();

    // Main centered droplet
    _rainDrops.add(RainDrop(
      startX: 0.5,
      startY: -0.2,
      speed: 0.35,
      size: 8.0,
    ));

    // Accent droplets
    for (int i = 0; i < 3; i++) {
      _rainDrops.add(RainDrop(
        startX: 0.2 + (i * 0.3),
        startY: -_random.nextDouble() * 0.5,
        speed: 0.3 + _random.nextDouble() * 0.15,
        size: 5 + _random.nextDouble() * 2,
      ));
    }
  }

  void _updateRain() {
    if (!mounted || _isPaused) return;

    setState(() {
      final waterLevel = widget.progress;

      for (var drop in _rainDrops) {
        drop.y += drop.speed * 0.01;

        // Check if droplet hits water surface
        if (drop.y >= 1.0 - waterLevel - 0.02) {
          _showRipple = true;
          _ripplePosition = Offset(drop.x, 1.0 - waterLevel);
          _rippleController.forward(from: 0.0).then((_) {
            if (mounted) {
              setState(() {
                _showRipple = false;
              });
            }
          });

          // Reset droplet to top
          drop.y = -0.15 - _random.nextDouble() * 0.2;
          drop.x = drop.x == 0.5 ? 0.5 : 0.2 + _random.nextDouble() * 0.6;
          drop.speed = 0.3 + _random.nextDouble() * 0.15;
        }
      }
    });
  }

  @override
  void didUpdateWidget(WaterDropletEffect oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle play/pause state changes
    if (widget.isRunning != oldWidget.isRunning) {
      if (widget.isRunning) {
        _isPaused = false;
        _rainController.repeat();
      } else {
        _isPaused = true;
        _rainController.stop();
      }
    }

    // ONLY trigger reset animation when resetKey changes
    if (widget.resetKey != oldWidget.resetKey) {
      _rainController.reset();
      _rippleController.reset();
      _initializeRain();
      setState(() {
        _showRipple = false;
        _isPaused = false;
      });
      // Restart animation if timer is running
      if (widget.isRunning) {
        _rainController.repeat();
      }
    }
  }

  @override
  void dispose() {
    _rainController.dispose();
    _waveController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  // ✅ Get water color based on progress AND tier
  Color _getWaterColor(TierThemeProvider tierProvider) {
    final progress = widget.progress;
    
    // Use tier colors as base
    final baseColor = tierProvider.primaryColor;
    
    // Adjust opacity/brightness based on progress
    if (progress < 0.33) {
      return baseColor.withValues(alpha:0.6);
    } else if (progress < 0.66) {
      return baseColor.withValues(alpha:0.8);
    } else {
      return baseColor;
    }
  }

  // ✅ Get background gradient based on tier
  List<Color> _getBackgroundGradient(TierThemeProvider tierProvider) {
    final colors = tierProvider.gradientColors;
    return [
      colors.first.withValues(alpha:0.1),
      colors.last.withValues(alpha:0.15),
      Colors.grey.shade100,
    ];
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Watch tier provider for real-time updates
    final tierProvider = context.watch<TierThemeProvider>();
    
    final boxHeight = 120.0;
    final boxWidth = MediaQuery.of(context).size.width;
    final waterLevel = widget.progress.clamp(0.0, 1.0);
    final waterColor = _getWaterColor(tierProvider);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: boxHeight,
        width: boxWidth,
        child: Stack(
          children: [
            // ✅ Background gradient using tier colors
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _getBackgroundGradient(tierProvider),
                ),
              ),
            ),

            // Glass highlight border
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha:0.25),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            // ✅ Water with tier-colored gradient
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedBuilder(
                animation: _waveAnimation,
                builder: (context, child) {
                  return ClipPath(
                    clipper: WaveClipper(
                      animation: _waveAnimation.value,
                      waveHeight: widget.progress > 0 ? 5.0 : 0.0,
                    ),
                    child: AnimatedContainer(
                      key: ValueKey(widget.resetKey),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      height: boxHeight * waterLevel,
                      width: boxWidth,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            waterColor.withValues(alpha:0.45),
                            waterColor.withValues(alpha:0.7),
                            waterColor.withValues(alpha:0.88),
                            waterColor,
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Shimmer effect
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _waveAnimation,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: ShimmerPainter(
                                    animation: _waveAnimation.value,
                                    color: Colors.white.withValues(alpha:0.1),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Ripple effect when droplet hits water
                          if (_showRipple && waterLevel > 0)
                            Positioned(
                              left: _ripplePosition.dx * boxWidth - 40,
                              top: 0,
                              child: AnimatedBuilder(
                                animation: _rippleController,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: RipplePainter(
                                      progress: _rippleProgress,
                                      color: Colors.white.withValues(alpha:0.45),
                                    ),
                                    size: const Size(80, 80),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Main centered droplet
            if (widget.isRunning && waterLevel < 1.0)
              AnimatedBuilder(
                animation: _rainController,
                builder: (context, child) {
                  final drop = _rainDrops[0];
                  final dropY =
                      (drop.y.clamp(-0.3, 1.0 - waterLevel)) * boxHeight;

                  if (drop.y >= 1.0 - waterLevel - 0.02) {
                    return const SizedBox.shrink();
                  }

                  return Positioned(
                    left: boxWidth / 2 - drop.size * 0.65,
                    top: dropY,
                    child: _buildDroplet(
                      size: drop.size * 1.4,
                      opacity: 0.95,
                      waterColor: waterColor,
                    ),
                  );
                },
              ),

            // Accent droplets
            if (widget.isRunning && waterLevel < 1.0)
              ...List.generate(_rainDrops.length - 1, (i) {
                final drop = _rainDrops[i + 1];
                final dropY =
                    (drop.y.clamp(-0.3, 1.0 - waterLevel)) * boxHeight;

                if (drop.y >= 1.0 - waterLevel - 0.02) {
                  return const SizedBox.shrink();
                }

                return Positioned(
                  left: boxWidth * drop.x.clamp(0.1, 0.9) - drop.size / 2,
                  top: dropY,
                  child: _buildDroplet(
                    size: drop.size * 0.9,
                    opacity: 0.3,
                    waterColor: waterColor,
                  ),
                );
              }),

            // Sparkle highlight
            Positioned(
              top: boxHeight * 0.12,
              left: boxWidth * 0.18,
              child: Container(
                width: boxWidth * 0.24,
                height: boxHeight * 0.09,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha:0.22),
                      Colors.white.withValues(alpha:0.0),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDroplet({
    required double size,
    required double opacity,
    required Color waterColor,
  }) {
    return Container(
      width: size,
      height: size * 1.6,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 0.75,
          colors: [
            Colors.white.withValues(alpha:0.96 * opacity),
            waterColor.withValues(alpha:0.82 * opacity),
            waterColor.withValues(alpha:opacity),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(size / 2),
          topRight: Radius.circular(size / 2),
          bottomLeft: Radius.circular(size),
          bottomRight: Radius.circular(size),
        ),
        boxShadow: [
          BoxShadow(
            color: waterColor.withValues(alpha:0.35 * opacity),
            blurRadius: 10,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: CustomPaint(
        painter: DropletHighlightPainter(
          color: Colors.white.withValues(alpha:0.72 * opacity),
        ),
      ),
    );
  }
}

// Rain drop data class
class RainDrop {
  double x;
  double y;
  double speed;
  double size;

  RainDrop({
    required double startX,
    required double startY,
    required this.speed,
    required this.size,
  })  : x = startX,
        y = startY;
}

// Wave clipper for realistic water surface
class WaveClipper extends CustomClipper<Path> {
  final double animation;
  final double waveHeight;

  WaveClipper({required this.animation, required this.waveHeight});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);

    for (double i = 0; i <= size.width; i++) {
      final y =
          math.sin((i / size.width * 3 * math.pi) + animation) * waveHeight;
      path.lineTo(size.width - i, y);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(WaveClipper oldClipper) => true;
}

// Shimmer effect painter
class ShimmerPainter extends CustomPainter {
  final double animation;
  final Color color;

  ShimmerPainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 2; i++) {
      final xOffset = (animation + i * 0.4) % 1.0;
      final path = Path();
      path.moveTo(size.width * xOffset, 0);
      path.lineTo(size.width * xOffset + 60, 0);
      path.lineTo(size.width * xOffset + 35, size.height);
      path.lineTo(size.width * xOffset - 25, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(ShimmerPainter oldDelegate) => true;
}

// Ripple effect painter
class RipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  RipplePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, 0);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 2; i++) {
      final rippleProgress = (progress + i * 0.2).clamp(0.0, 1.0);
      final radius = maxRadius * rippleProgress;
      final opacity = (1.0 - rippleProgress) * 0.45;

      final paint = Paint()
        ..color = color.withValues(alpha:opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) => true;
}

// Droplet highlight painter
class DropletHighlightPainter extends CustomPainter {
  final Color color;

  DropletHighlightPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.addOval(
      Rect.fromLTWH(
        size.width * 0.26,
        size.height * 0.16,
        size.width * 0.34,
        size.height * 0.24,
      ),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(DropletHighlightPainter oldDelegate) => false;
}
