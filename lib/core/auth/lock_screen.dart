import 'package:flutter/material.dart';
import 'package:keel/core/auth/auth_service.dart';
import 'package:keel/core/theme/app_colors.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  bool _authenticating = false;
  bool _failed = false;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    setState(() {
      _authenticating = true;
      _failed = false;
    });
    _pulse.repeat(reverse: true);

    final success = await AuthService.instance.authenticate(
      reason: 'Unlock Keel to access your financial data',
    );

    if (!mounted) return;
    _pulse.stop();
    _pulse.reset();

    if (!success) {
      setState(() {
        _authenticating = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    'assets/png/logos/keel_icon_1024.png',
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Keel is locked',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Use Touch ID or your password to unlock.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: textSecondary),
              ),
              const SizedBox(height: 28),

              // Auth card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 28),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    // Fingerprint icon — pulses while authenticating
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, _) => Opacity(
                        opacity: _authenticating
                            ? 0.4 + (_pulse.value * 0.6)
                            : 1.0,
                        child: Icon(
                          Icons.fingerprint,
                          size: 56,
                          color: _failed
                              ? AppColors.error
                              : AppColors.royalBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _authenticating
                          ? 'Touch the fingerprint sensor…'
                          : _failed
                              ? 'Authentication failed'
                              : 'Ready to authenticate',
                      style: TextStyle(
                        fontSize: 13,
                        color: _failed ? AppColors.error : textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _authenticating ? null : _authenticate,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.royalBlue,
                          disabledBackgroundColor:
                              AppColors.royalBlue.withValues(alpha: 0.4),
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
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
            ],
          ),
        ),
      ),
    );
  }
}
