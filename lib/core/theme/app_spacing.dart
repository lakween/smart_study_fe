import 'package:flutter/widgets.dart';

/// Shared spacing tokens for screen-level layout.
///
/// Use these for the outer edge of pages. Components such as cards, chips,
/// and buttons may use their own smaller internal padding.
abstract final class AppSpacing {
  static const double pageGutter = 20;
  static const double itemGap = 12;
  static const double sectionGap = 24;

  static const EdgeInsets page = EdgeInsets.all(pageGutter);
  static const EdgeInsets pageHorizontal =
      EdgeInsets.symmetric(horizontal: pageGutter);
  static const EdgeInsets form =
      EdgeInsets.fromLTRB(pageGutter, 16, pageGutter, 32);
  static const EdgeInsets search =
      EdgeInsets.fromLTRB(pageGutter, 10, pageGutter, 2);
  static const EdgeInsets filters =
      EdgeInsets.symmetric(horizontal: pageGutter, vertical: 8);
  static const EdgeInsets list =
      EdgeInsets.fromLTRB(pageGutter, 16, pageGutter, 24);
  static const EdgeInsets listWithFab =
      EdgeInsets.fromLTRB(pageGutter, 16, pageGutter, 96);
}
