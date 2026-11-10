import 'package:flutter/material.dart';
import 'package:keel/core/theme/app_colors.dart';

class SetupStepShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget content;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String nextLabel;
  final bool isNextEnabled;
  final bool isLoading;
  final Widget? trailing;

  const SetupStepShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.content,
    this.onBack,
    this.onNext,
    this.nextLabel = 'Continue',
    this.isNextEnabled = true,
    this.isLoading = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Container(
      color: bg,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(48, 48, 48, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing ?? const SizedBox.shrink(),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: content,
            ),
          ),

          // Footer nav
          Padding(
            padding: const EdgeInsets.fromLTRB(48, 16, 48, 32),
            child: Row(
              children: [
                if (onBack != null)
                  OutlinedButton(
                    onPressed: onBack,
                    child: const Text('Back'),
                  ),
                const Spacer(),
                if (onNext != null)
                  FilledButton(
                    onPressed: isNextEnabled && !isLoading ? onNext : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.royalBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(nextLabel),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
