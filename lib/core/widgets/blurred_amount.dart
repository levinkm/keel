import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:keel/core/auth/auth_service.dart';

/// Wraps a monetary text value and blurs it when privacy mode is on.
/// Hover to reveal; blurs again when the pointer leaves.
class BlurredAmount extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const BlurredAmount({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  State<BlurredAmount> createState() => _BlurredAmountState();
}

class _BlurredAmountState extends State<BlurredAmount> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AuthService.instance.privacyMode,
      builder: (context, privacy, _) {
        final text = Text(
          widget.text,
          style: widget.style,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
        );

        // MouseRegion is always in the tree so onExit always fires
        return MouseRegion(
          cursor: privacy ? SystemMouseCursors.click : MouseCursor.defer,
          onEnter: (_) { if (privacy) setState(() => _hovered = true); },
          onExit: (_) { if (_hovered) setState(() => _hovered = false); },
          child: privacy && !_hovered
              ? ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: text,
                )
              : text,
        );
      },
    );
  }
}
