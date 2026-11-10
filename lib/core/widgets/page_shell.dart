import 'package:flutter/material.dart';

const double kTitleBarHeight = 28.0;

class PageShell extends StatelessWidget {
  final Widget child;
  final Color? color;
  const PageShell({super.key, required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: kTitleBarHeight),
      child: child,
    );
  }
}
