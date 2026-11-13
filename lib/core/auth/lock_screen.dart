import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:keel/core/auth/auth_service.dart';
import 'package:keel/core/sync/sync_service.dart';
import 'package:keel/core/theme/app_colors.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with TickerProviderStateMixin {
  bool _authenticating = false;
  bool _failed = false;

  late final AnimationController _pulseCtrl;
  late final AnimationController _rotateCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    setState(() { _authenticating = true; _failed = false; });
    _pulseCtrl.repeat(reverse: true);

    final success = await AuthService.instance.authenticate(
      reason: 'Unlock Keel to access your financial data',
    );

    if (!mounted) return;
    _pulseCtrl.stop();
    _pulseCtrl.reset();

    if (!success) {
      setState(() { _authenticating = false; _failed = true; });
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    final name = SyncService.instance.googleDisplayName?.split(' ').first;
    final suffix = name != null && name.isNotEmpty ? ', $name' : '';
    if (h < 12) return 'Good morning$suffix';
    if (h < 17) return 'Good afternoon$suffix';
    return 'Good evening$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background ──────────────────────────────────────────────────
          _Background(isDark: isDark, rotateCtrl: _rotateCtrl),

          // ── Frosted overlay ─────────────────────────────────────────────
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Container(
              color: (isDark ? AppColors.darkBackground : const Color(0xFF1a1f35))
                  .withValues(alpha: 0.55),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────
          FadeTransition(
            opacity: _fadeIn,
            child: Center(
              child: SizedBox(
                width: min(400, size.width * 0.9),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar
                    _Avatar(size: 88),
                    const SizedBox(height: 20),

                    // Greeting
                    Text(
                      _greeting,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Email
                    if (SyncService.instance.currentUser.value?.email != null)
                      Text(
                        SyncService.instance.currentUser.value!.email!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),

                    const SizedBox(height: 40),

                    // Fingerprint ring + icon
                    _FingerprintRing(
                      pulseCtrl: _pulseCtrl,
                      authenticating: _authenticating,
                      failed: _failed,
                    ),

                    const SizedBox(height: 20),

                    Text(
                      _authenticating
                          ? 'Touch the fingerprint sensor…'
                          : _failed
                              ? 'Authentication failed'
                              : 'Touch ID or password',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Unlock button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _authenticating ? null : _authenticate,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.royalBlue,
                          disabledBackgroundColor:
                              AppColors.royalBlue.withValues(alpha: 0.4),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Text(
                          _authenticating ? 'Authenticating…' : 'Unlock',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Background with animated geometric pattern ────────────────────────────────

class _Background extends StatelessWidget {
  final bool isDark;
  final AnimationController rotateCtrl;
  const _Background({required this.isDark, required this.rotateCtrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0f1729),
                Color(0xFF1a2340),
                Color(0xFF0d1520),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Rotating geometric pattern
        AnimatedBuilder(
          animation: rotateCtrl,
          builder: (_, _) => CustomPaint(
            painter: _GeometricPainter(
              progress: rotateCtrl.value,
            ),
          ),
        ),
        // Accent orbs
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.royalBlue.withValues(alpha: 0.3),
                  AppColors.royalBlue.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -80,
          child: Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.slateBlue.withValues(alpha: 0.2),
                  AppColors.slateBlue.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GeometricPainter extends CustomPainter {
  final double progress;
  _GeometricPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Concentric rotating hexagons
    for (int ring = 1; ring <= 6; ring++) {
      final radius = ring * 80.0;
      final rotation = progress * 2 * pi * (ring.isEven ? 1 : -1);
      final opacity = (0.04 + ring * 0.01).clamp(0.0, 0.12);
      paint.color = Colors.white.withValues(alpha: opacity);

      final path = Path();
      for (int i = 0; i < 6; i++) {
        final angle = rotation + (i * pi / 3);
        final x = cx + radius * cos(angle);
        final y = cy + radius * sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }

    // Grid of dots
    final dotPaint = Paint()..style = PaintingStyle.fill;
    const spacing = 48.0;
    final cols = (size.width / spacing).ceil() + 2;
    final rows = (size.height / spacing).ceil() + 2;
    final offsetX = (progress * spacing) % spacing;
    final offsetY = (progress * spacing * 0.3) % spacing;

    for (int r = -1; r < rows; r++) {
      for (int c = -1; c < cols; c++) {
        final x = c * spacing - offsetX;
        final y = r * spacing - offsetY;
        final dist = sqrt(pow(x - cx, 2) + pow(y - cy, 2));
        final opacity = (0.06 - dist / (size.width * 3)).clamp(0.01, 0.06);
        dotPaint.color = Colors.white.withValues(alpha: opacity);
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_GeometricPainter old) => old.progress != progress;
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final double size;
  const _Avatar({required this.size});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = SyncService.instance.googleAvatarUrl;
    final name = SyncService.instance.googleDisplayName ?? 'K';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.4),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: avatarUrl != null
            ? Image.network(
                avatarUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _initials(name, size),
              )
            : _appIcon(size),
      ),
    );
  }

  Widget _initials(String name, double size) {
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : name[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      color: AppColors.royalBlue,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _appIcon(double size) => Image.asset(
        'assets/png/logos/keel_icon_1024.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
      );
}

// ── Animated fingerprint ring ─────────────────────────────────────────────────

class _FingerprintRing extends StatelessWidget {
  final AnimationController pulseCtrl;
  final bool authenticating;
  final bool failed;

  const _FingerprintRing({
    required this.pulseCtrl,
    required this.authenticating,
    required this.failed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (_, _) {
        final pulse = authenticating ? pulseCtrl.value : 0.0;
        return Icon(
          Icons.fingerprint,
          size: 64,
          color: Colors.white.withValues(alpha: 0.5 + pulse * 0.4),
        );
      },
    );
  }
}
