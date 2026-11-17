import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/floating_bottom_nav.dart';

/// Shell that wraps main pages with a truly floating nav.
///
/// Key Flutter pattern:
///   - [Scaffold] with extendBody: true → body fills all the way to the
///     physical screen bottom (no white bar, no surface injected).
///   - No bottomNavigationBar property → zero system-drawn chrome.
///   - [Stack] inside body → floating pill overlays page content.
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final navIndex = FloatingBottomNav.indexFromRoute(location);

    return Scaffold(
      // extendBody: true is the Flutter-approved way to let body content
      // render behind/beneath the floating overlay with no background bleed.
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Page fills the entire Scaffold body
          Positioned.fill(child: child),

          // Floating pill — pinned to the bottom, over page content
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingBottomNav(currentIndex: navIndex),
          ),
        ],
      ),
    );
  }
}
