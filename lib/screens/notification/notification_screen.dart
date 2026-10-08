import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../active_tab_provider/active_tab_provider.dart';
import '../../colors/colors.dart';
import '../../providers/notification_provider.dart';
import '../../route_observer.dart'; // adjust path if needed

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({
    super.key,
    this.showBackButton = true,
    this.isActive = false,
  });

  final bool showBackButton;
  final bool isActive;

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with RouteAware {
  int _animationSeed = 0;

  // Alerts / Notifications tab index in bottom nav
  static const int _tabIndex = 2;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    _replayAnimation();
  }

  void _replayAnimation() {
    setState(() {
      _animationSeed = DateTime.now().millisecondsSinceEpoch;
    });
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(activeTabIndexProvider, (previous, next) {
      if (next == _tabIndex) {
        _replayAnimation();
      }
    });

    final state = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);
    final list = state.notifications;

    if (state.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.ctaGradient,
            ),
          ),
          title: Text(
            'Notifications',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 18.sp,
            ),
          ),
          iconTheme: IconThemeData(
            color: Colors.white,
            size: 24.sp,
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.ctaGradient,
          ),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
          size: 24.sp,
        ),
        actions: [
          if (list.isNotEmpty)
            TextButton(
              onPressed: () => notifier.markAllAsRead(),
              child: Text(
                'Mark all',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                ),
              ),
            ),
        ],
      ),
      body: list.isEmpty
          ? const _EmptyNotifications()
          : Column(
        children: [
          if (state.unreadCount > 0)
            Container(
              width: double.infinity,
              margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
              padding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 10.h,
              ),
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.blue.withOpacity(0.20),
                ),
              ),
              child: Text(
                '${state.unreadCount} unread notification'
                    '${state.unreadCount == 1 ? '' : 's'}',
                style: TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                ),
              ),
            ),
          Expanded(
            child: _AnimatedNotificationsList(
              key: ValueKey(_animationSeed),
              list: list,
              onTap: (id) => notifier.markAsRead(id),
              onDismiss: (id) => notifier.removeNotification(id),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ANIMATED NOTIFICATIONS LIST
// ============================================================

class _AnimatedNotificationsList extends StatefulWidget {
  const _AnimatedNotificationsList({
    super.key,
    required this.list,
    required this.onTap,
    required this.onDismiss,
  });

  final List<AppNotification> list;
  final void Function(String id) onTap;
  final void Function(String id) onDismiss;

  @override
  State<_AnimatedNotificationsList> createState() =>
      _AnimatedNotificationsListState();
}

class _AnimatedNotificationsListState
    extends State<_AnimatedNotificationsList> {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      itemCount: widget.list.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (context, index) {
        final item = widget.list[index];

        return _SlideInAnimation(
          key: ValueKey('notif_${item.id}'),
          index: index,
          child: _NotificationCard(
            notification: item,
            onTap: () => widget.onTap(item.id),
            onDismiss: () => widget.onDismiss(item.id),
          ),
        );
      },
    );
  }
}

// ============================================================
// SLIDE-IN ANIMATION
// ============================================================

class _SlideInAnimation extends StatefulWidget {
  const _SlideInAnimation({
    super.key,
    required this.child,
    required this.index,
  });

  final Widget child;
  final int index;

  @override
  State<_SlideInAnimation> createState() => _SlideInAnimationState();
}

class _SlideInAnimationState extends State<_SlideInAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(-0.4, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    Future.delayed(Duration(milliseconds: 150 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _offsetAnimation,
        child: widget.child,
      ),
    );
  }
}

// ============================================================
// DATE / TIME HELPER
// ============================================================

/// Formats a display string for date + time.
/// Prefer a full value stored in [timeLabel], e.g. "08 Oct 2026, 12:18 PM".
String _formatDateTimeLabel(String timeLabel) {
  final t = timeLabel.trim();
  if (t.isEmpty) return '—';
  return t;
}

// ============================================================
// NOTIFICATION CARD  (with date & time)
// ============================================================

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final color = n.color;
    final dateTimeText = _formatDateTimeLabel(n.timeLabel);

    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Icon(
          Icons.delete_outline,
          color: AppColors.error,
          size: 24.sp,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.r),
          child: Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: n.isRead
                  ? AppColors.surface
                  : AppColors.blue.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: n.isRead
                    ? AppColors.border
                    : AppColors.blue.withOpacity(0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8.r,
                  offset: Offset(0, 3.h),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 42.h,
                  width: 42.w,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(n.icon, color: color, size: 22.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: TextStyle(
                                fontSize: 14.5.sp,
                                fontWeight: n.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (!n.isRead)
                            Container(
                              width: 8.w,
                              height: 8.h,
                              decoration: const BoxDecoration(
                                color: AppColors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        n.message,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          color: AppColors.textMuted,
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: 8.h),

                      // ★ Date & time row
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 12.sp,
                            color: AppColors.textMuted.withOpacity(0.85),
                          ),
                          SizedBox(width: 5.w),
                          Expanded(
                            child: Text(
                              dateTimeText,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted.withOpacity(0.95),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY STATE
// ============================================================

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 72.h,
            width: 72.w,
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 36.sp,
              color: AppColors.blue,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'No notifications',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'You’re all caught up',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}