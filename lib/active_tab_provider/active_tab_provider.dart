import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// ============================================================
// ACTIVE TAB PROVIDER
// ============================================================
//
// Tracks which bottom-nav tab is currently active.
//
// Why this exists:
// StatefulShellRoute.indexedStack keeps every tab's widget alive in
// memory (via an IndexedStack) so state isn't lost when switching tabs.
// This means each tab's widget is only ever built ONCE — initState()
// runs the first time, but never again on later visits, and
// didUpdateWidget() won't fire just from switching tabs back and forth
// since GoRouter isn't passing the widget a new configuration.
//
// This provider gives each tab a reliable, lifecycle-independent signal
// to know "I just became the active tab" — via ref.listen, which keeps
// firing even while a tab's widget is alive-but-offstage. Tabs can use
// this to replay entrance animations every time they're switched to,
// not just the first time.
//
// Usage:
// 1. In DashboardScreen's bottom nav onTap, before calling goBranch:
//      ref.read(activeTabIndexProvider.notifier).state = index;
//
// 2. In each tab screen's build() method:
//      ref.listen<int>(activeTabIndexProvider, (previous, next) {
//        if (next == myTabIndex) {
//          _replayAnimation();
//        }
//      });

final activeTabIndexProvider = StateProvider<int>((ref) => 0);