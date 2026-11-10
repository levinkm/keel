import 'package:flutter/material.dart';

/// Breakpoints for the app (desktop-only, min window 900px)
class Breakpoints {
  static const double compact = 900;
  static const double medium = 1100;
  static const double expanded = 1280;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < medium;
  static bool isMedium(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= medium && w < expanded;
  }
  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= expanded;
}

/// Width of the master list panel in master/detail layouts.
/// Scales with window width: 26% clamped between 240–340px.
double listPanelWidth(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  return (w * 0.26).clamp(240.0, 340.0);
}

/// Width of the sidebar panel (narrower, e.g. period list).
double sidebarWidth(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  return (w * 0.22).clamp(220.0, 300.0);
}
