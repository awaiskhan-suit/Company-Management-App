import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../active_tab_provider/active_tab_provider.dart';
import '../../colors/colors.dart';
import '../../providers/dash_board_screen.dart';
import '../../widgets/app_drawer.dart';
import '../../route_observer.dart'; // adjust path if needed

class DashboardScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const DashboardScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final asyncRole = ref.watch(roleProvider);
    final roleState = asyncRole.value ?? const RoleState();
    final role = roleState.role;
    final userName = roleState.userName;
    final isCompact = MediaQuery.of(context).size.width < 400;

    if (asyncRole.isLoading && asyncRole.value == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        titleSpacing: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.ctaGradient,
          ),
        ),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: Icon(Icons.menu_rounded, color: Colors.white, size: 24.sp),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/images.jpg',
                width: 34.w,
                height: 34.h,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 10.w),
            Flexible(
              child: Text(
                'Section Soft',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (!isCompact) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: Colors.white.withOpacity(0.35)),
              ),
              child: Text(
                role,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 6.w),
          ],
          PopupMenuButton<String>(
            onSelected: (value) {
              ref.read(roleProvider.notifier).setRole(value);
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            itemBuilder: (context) {
              return availableRoles
                  .map((r) => PopupMenuItem(value: r, child: Text(r)))
                  .toList();
            },
            child: Padding(
              padding: EdgeInsets.only(right: isCompact ? 8.w : 16.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 19.r,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: AppColors.navy, size: 20.sp),
                  ),
                  if (!isCompact) ...[
                    SizedBox(width: 8.w),
                    Text(
                      userName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(width: 2.w),
                  ],
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: widget.navigationShell,
      bottomNavigationBar: AnimatedBottomNavBar(
        currentIndex: widget.navigationShell.currentIndex,
        onTap: (index) {
          ref.read(activeTabIndexProvider.notifier).state = index;

          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

// ============================================================
// SLIDE-IN ANIMATION
// ============================================================

class _SlideInAnimation extends StatefulWidget {
  final Widget child;
  final int index;

  const _SlideInAnimation({
    super.key,
    required this.child,
    required this.index,
  });

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
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

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
// PRESS-SCALE WRAPPER
// ============================================================

class AnimatedPressable extends StatefulWidget {
  const AnimatedPressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.96,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  @override
  State<AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<AnimatedPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scale = Tween<double>(begin: 1.0, end: widget.pressedScale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pressedScale != widget.pressedScale) {
      _scale = Tween<double>(begin: 1.0, end: widget.pressedScale).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
    }
  }

  void _setPressed(bool pressed) {
    pressed ? _controller.forward() : _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap ?? () {},
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(scale: _scale.value, child: child);
        },
        child: widget.child,
      ),
    );
  }
}

// ============================================================
// BOTTOM NAV
// ============================================================

class _NavTab {
  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class AnimatedBottomNavBar extends StatelessWidget {
  const AnimatedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<_NavTab> _tabs = [
    _NavTab(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
    ),
    _NavTab(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      label: 'Reports',
    ),
    _NavTab(
      icon: Icons.notifications_none_rounded,
      activeIcon: Icons.notifications_rounded,
      label: 'Alerts', // ← kept as requested
    ),
    _NavTab(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16.r,
            offset: Offset(0, -4.h),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
          child: SizedBox(
            height: 60.h,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / _tabs.length;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      left: itemWidth * currentIndex,
                      top: 0,
                      bottom: 0,
                      width: itemWidth,
                      child: Center(
                        child: Container(
                          height: 44.h,
                          margin: EdgeInsets.symmetric(horizontal: 8.w),
                          decoration: BoxDecoration(
                            color: AppColors.blue.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(_tabs.length, (index) {
                        final tab = _tabs[index];
                        final selected = index == currentIndex;
                        return SizedBox(
                          width: itemWidth,
                          child: _NavItem(
                            icon: selected ? tab.activeIcon : tab.icon,
                            label: tab.label,
                            selected: selected,
                            onTap: () => onTap(index),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _d = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 2.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.1 : 1.0,
              duration: _d,
              curve: Curves.easeOutCubic,
              child: Icon(
                icon,
                size: 22.sp,
                color: selected ? AppColors.blue : AppColors.textMuted,
              ),
            ),
            SizedBox(height: 4.h),
            AnimatedDefaultTextStyle(
              duration: _d,
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.blue : AppColors.textMuted,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DASHBOARD BODY
// ============================================================

class DashboardBody extends ConsumerStatefulWidget {
  final String role;
  final String userName;
  final bool isActive;

  const DashboardBody({
    super.key,
    required this.role,
    required this.userName,
    this.isActive = false,
  });

  @override
  ConsumerState<DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends ConsumerState<DashboardBody>
    with SingleTickerProviderStateMixin, RouteAware {
  late final AnimationController _controller;
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;

  int _animationSeed = 0;

  static const int _itemCount = 5;
  static const int _tabIndex = 0; // Dashboard = 0

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fades = List.generate(_itemCount, (i) {
      final start = i * 0.10;
      final end = (start + 0.45).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });

    _slides = List.generate(_itemCount, (i) {
      final start = i * 0.10;
      final end = (start + 0.45).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _controller.forward();
  }

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
    _controller
      ..reset()
      ..forward();
  }

  @override
  void didUpdateWidget(covariant DashboardBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role != widget.role) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _controller.dispose();
    super.dispose();
  }

  Widget _anim(int index, Widget child) {
    return FadeTransition(
      opacity: _fades[index],
      child: SlideTransition(position: _slides[index], child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(activeTabIndexProvider, (previous, next) {
      if (next == _tabIndex) {
        _replayAnimation();
      }
    });

    final dashboardData = getDashboardData(widget.role);
    final role = widget.role;
    final stats = dashboardData['stats'] as List;
    final quickActions = getQuickActions(role);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        final crossAxisCount =
        isDesktop ? 4 : (constraints.maxWidth >= 600 ? 2 : 1);

        return SingleChildScrollView(
          key: ValueKey(_animationSeed),
          padding: EdgeInsets.all(isDesktop ? 28.w : 16.w),
          child: Column(
            key: ValueKey(role),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _anim(
                0,
                _WelcomeBanner(
                  userName: widget.userName,
                  subtitle: dashboardData['subtitle'] as String,
                  isDesktop: isDesktop,
                ),
              ),
              SizedBox(height: 24.h),

              // STAT CARDS
              _anim(
                1,
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stats.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16.w,
                    mainAxisSpacing: 16.h,
                    childAspectRatio: isDesktop ? 1.8 : 2.5,
                  ),
                  itemBuilder: (context, index) {
                    final stat = stats[index] as Map;
                    return _SlideInAnimation(
                      key: ValueKey('stat_${index}_$_animationSeed'),
                      index: index,
                      child: StatCard(
                        title: stat['title'] as String,
                        value: stat['value'] as String,
                        icon: stat['icon'] as IconData,
                        change: stat['change'] as String,
                        iconBackground: stat['background'] as Color,
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 26.h),
              _anim(
                2,
                const SectionTitle(
                  title: 'Quick Actions',
                  subtitle: 'Frequently used actions',
                ),
              ),
              SizedBox(height: 14.h),

              // QUICK ACTIONS
              _anim(
                2,
                Wrap(
                  spacing: 12.w,
                  runSpacing: 12.h,
                  children: quickActions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final action = entry.value;
                    return _SlideInAnimation(
                      key: ValueKey('action_${index}_$_animationSeed'),
                      index: index,
                      child: QuickActionCard(
                        title: action['title'] as String,
                        icon: action['icon'] as IconData,
                        onTap: () {},
                      ),
                    );
                  }).toList(),
                ),
              ),

              SizedBox(height: 28.h),
              _anim(
                3,
                isDesktop
                    ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: AttendanceCard(role: role)),
                    SizedBox(width: 20.w),
                    Expanded(flex: 2, child: RecentActivityCard(role: role)),
                  ],
                )
                    : Column(
                  children: [
                    AttendanceCard(role: role),
                    SizedBox(height: 20.h),
                    RecentActivityCard(role: role),
                  ],
                ),
              ),
              SizedBox(height: 28.h),
              _anim(4, RoleInfoCard(role: role)),
              SizedBox(height: 12.h),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// REST OF THE WIDGETS
// ============================================================

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({
    required this.userName,
    required this.subtitle,
    required this.isDesktop,
  });

  final String userName;
  final String subtitle;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.20),
            blurRadius: 20.r,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getGreeting(userName),
            style: TextStyle(
              fontSize: isDesktop ? 26.sp : 21.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13.5.sp,
              color: Colors.white.withOpacity(0.85),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String change;
  final Color iconBackground;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.change,
    required this.iconBackground,
  });

  bool get _isPositiveTrend => change.trim().startsWith('+');

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14.r,
              offset: Offset(0, 6.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 50.h,
              width: 50.w,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(13.r),
              ),
              child: Icon(icon, color: AppColors.navy, size: 24.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  _CountUpText(
                    value: value,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    change,
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w700,
                      color: _isPositiveTrend
                          ? AppColors.success
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountUpText extends StatelessWidget {
  const _CountUpText({required this.value, required this.style});

  final String value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final numeric = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    final suffix = numeric == null
        ? ''
        : value.replaceFirst(RegExp(r'^[0-9]+'), '');

    if (numeric == null) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        builder: (context, t, child) =>
            Opacity(opacity: t.clamp(0.0, 1.0), child: child),
        child: Text(value, style: style),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: numeric.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Text('${t.round()}$suffix', style: style);
      },
    );
  }
}

class QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      onTap: onTap,
      child: Container(
        width: 176.w,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              height: 40.h,
              width: 40.w,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Icon(icon, color: Colors.white, size: 20.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18.sp,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const SectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class AttendanceCard extends StatelessWidget {
  final String role;

  const AttendanceCard({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 340.h,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance Overview',
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            role == 'Employee'
                ? 'Your attendance this week'
                : 'Company attendance this week',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted),
          ),
          SizedBox(height: 22.h),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AttendanceBar(day: 'Mon', height: 100.h, index: 0),
                AttendanceBar(day: 'Tue', height: 140.h, index: 1),
                AttendanceBar(day: 'Wed', height: 120.h, index: 2),
                AttendanceBar(
                    day: 'Thu', height: 165.h, highlight: true, index: 3),
                AttendanceBar(day: 'Fri', height: 145.h, index: 4),
                AttendanceBar(day: 'Sat', height: 75.h, index: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AttendanceBar extends StatelessWidget {
  final String day;
  final double height;
  final bool highlight;
  final int index;

  const AttendanceBar({
    super.key,
    required this.day,
    required this.height,
    this.highlight = false,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: height),
      duration: Duration(milliseconds: 550 + index * 90),
      curve: Curves.easeOutCubic,
      builder: (context, animatedHeight, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 28.w,
              height: animatedHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: highlight
                      ? [AppColors.navy, AppColors.blue]
                      : [AppColors.blue.withOpacity(0.55), AppColors.blue],
                ),
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(8.r)),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              day,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                color: highlight ? AppColors.navy : AppColors.textMuted,
              ),
            ),
          ],
        );
      },
    );
  }
}

class RecentActivityCard extends StatelessWidget {
  final String role;

  const RecentActivityCard({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final activities = role == 'Employee'
        ? [
      [
        'Task assigned',
        'New task assigned to you',
        Icons.assignment,
        '2h ago',
        AppColors.blue
      ],
      [
        'Leave submitted',
        'Leave request submitted',
        Icons.event,
        '5h ago',
        const Color(0xFFF5A623)
      ],
      [
        'Attendance',
        'Check-in recorded',
        Icons.access_time,
        'Today',
        AppColors.success
      ],
    ]
        : [
      [
        'New employee',
        'John joined the company',
        Icons.person_add,
        '1h ago',
        AppColors.teal
      ],
      [
        'Leave request',
        'Leave request received',
        Icons.event,
        '3h ago',
        const Color(0xFFF5A623)
      ],
      [
        'Task completed',
        'Project task completed',
        Icons.task_alt,
        '6h ago',
        AppColors.success
      ],
    ];

    return Container(
      height: 340.h,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 18.h),
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (_, __) => SizedBox(height: 16.h),
              itemBuilder: (context, index) {
                final item = activities[index];
                final color = item[4] as Color;
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 320 + index * 110),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, child) {
                    return Opacity(
                      opacity: t.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(16.w * (1 - t), 0),
                        child: child,
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        height: 38.h,
                        width: 38.w,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(11.r),
                        ),
                        child: Icon(
                          item[2] as IconData,
                          color: color,
                          size: 19.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item[0] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.sp,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              item[1] as String,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        item[3] as String,
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class RoleInfoCard extends StatelessWidget {
  final String role;

  const RoleInfoCard({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final permissions = getPermissions(role);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$role Access',
            style: TextStyle(
              color: AppColors.textOnBrand,
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Available modules for this role',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: permissions.asMap().entries.map((entry) {
              final index = entry.key;
              final p = entry.value;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 260 + index * 55),
                curve: Curves.easeOutBack,
                builder: (context, t, child) {
                  final clamped = t.clamp(0.0, 1.0);
                  return Opacity(
                    opacity: clamped,
                    child:
                    Transform.scale(scale: 0.85 + (0.15 * t), child: child),
                  );
                },
                child: Container(
                  padding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    p,
                    style: TextStyle(
                      color: AppColors.textOnBrand,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DATA
// ============================================================

Map<String, dynamic> getDashboardData(String role) {
  switch (role) {
    case 'Admin':
      return {
        'subtitle': 'Manage your company operations efficiently.',
        'stats': [
          {
            'title': 'Employees',
            'value': '156',
            'change': '+8.5%',
            'icon': Icons.people_alt_outlined,
            'background': AppColors.background
          },
          {
            'title': 'Present Today',
            'value': '142',
            'change': '+4.2%',
            'icon': Icons.check_circle_outline,
            'background': const Color(0xFFE9F7EF)
          },
          {
            'title': 'On Leave',
            'value': '14',
            'change': 'Today',
            'icon': Icons.event_busy_outlined,
            'background': const Color(0xFFFFF3E8)
          },
          {
            'title': 'Departments',
            'value': '12',
            'change': '+1 new',
            'icon': Icons.account_tree_outlined,
            'background': const Color(0xFFF0ECFF)
          },
        ],
      };
    case 'HR':
      return {
        'subtitle': 'Manage employees and HR operations.',
        'stats': [
          {
            'title': 'Employees',
            'value': '156',
            'change': '+8.5%',
            'icon': Icons.people_alt_outlined,
            'background': AppColors.background
          },
          {
            'title': 'New Employees',
            'value': '8',
            'change': 'This month',
            'icon': Icons.person_add_alt_1_outlined,
            'background': const Color(0xFFE9F7EF)
          },
          {
            'title': 'On Leave',
            'value': '14',
            'change': 'Today',
            'icon': Icons.event_busy_outlined,
            'background': const Color(0xFFFFF3E8)
          },
          {
            'title': 'Pending Leave',
            'value': '6',
            'change': 'Needs review',
            'icon': Icons.pending_actions_outlined,
            'background': const Color(0xFFF0ECFF)
          },
        ],
      };
    case 'Manager':
      return {
        'subtitle': 'Monitor your team and manage daily tasks.',
        'stats': [
          {
            'title': 'Team Members',
            'value': '24',
            'change': '+2 this month',
            'icon': Icons.groups_outlined,
            'background': AppColors.background
          },
          {
            'title': 'Present Today',
            'value': '21',
            'change': '87.5%',
            'icon': Icons.check_circle_outline,
            'background': const Color(0xFFE9F7EF)
          },
          {
            'title': 'Pending Tasks',
            'value': '9',
            'change': 'Needs action',
            'icon': Icons.pending_actions_outlined,
            'background': const Color(0xFFFFF3E8)
          },
          {
            'title': 'Completed',
            'value': '35',
            'change': '+12 this week',
            'icon': Icons.task_alt_outlined,
            'background': const Color(0xFFF0ECFF)
          },
        ],
      };
    case 'Employee':
      return {
        'subtitle': 'Here is your personal work summary for today.',
        'stats': [
          {
            'title': 'Attendance',
            'value': 'Present',
            'change': 'Today',
            'icon': Icons.check_circle_outline,
            'background': const Color(0xFFE9F7EF)
          },
          {
            'title': 'Working Hours',
            'value': '6h 24m',
            'change': 'Today',
            'icon': Icons.access_time_rounded,
            'background': AppColors.background
          },
          {
            'title': 'Leave Balance',
            'value': '12 Days',
            'change': 'Remaining',
            'icon': Icons.event_available_outlined,
            'background': const Color(0xFFFFF3E8)
          },
          {
            'title': 'Pending Tasks',
            'value': '4',
            'change': 'In progress',
            'icon': Icons.task_alt_outlined,
            'background': const Color(0xFFF0ECFF)
          },
        ],
      };
    default:
      return {
        'subtitle': 'Here is your complete company overview.',
        'stats': [
          {
            'title': 'Employees',
            'value': '156',
            'change': '+8.5%',
            'icon': Icons.people_alt_outlined,
            'background': AppColors.background
          },
          {
            'title': 'Active Users',
            'value': '149',
            'change': '+5.4%',
            'icon': Icons.verified_user_outlined,
            'background': const Color(0xFFE9F7EF)
          },
          {
            'title': 'On Leave',
            'value': '14',
            'change': 'Today',
            'icon': Icons.event_busy_outlined,
            'background': const Color(0xFFFFF3E8)
          },
          {
            'title': 'Departments',
            'value': '12',
            'change': '+1 new',
            'icon': Icons.account_tree_outlined,
            'background': const Color(0xFFF0ECFF)
          },
        ],
      };
  }
}

List<Map<String, dynamic>> getQuickActions(String role) {
  switch (role) {
    case 'Super Admin':
      return [
        {'title': 'Add Admin', 'icon': Icons.person_add},
        {'title': 'Add Employee', 'icon': Icons.person_add_alt_1},
        {'title': 'Department', 'icon': Icons.account_tree},
        {'title': 'Roles', 'icon': Icons.admin_panel_settings},
        {'title': 'Reports', 'icon': Icons.bar_chart},
      ];
    case 'Admin':
      return [
        {'title': 'Add Employee', 'icon': Icons.person_add_alt_1},
        {'title': 'Employees', 'icon': Icons.people_alt},
        {'title': 'Departments', 'icon': Icons.account_tree},
        {'title': 'Attendance', 'icon': Icons.access_time},
        {'title': 'Reports', 'icon': Icons.bar_chart},
      ];
    case 'HR':
      return [
        {'title': 'Add Employee', 'icon': Icons.person_add_alt_1},
        {'title': 'Documents', 'icon': Icons.folder_outlined},
        {'title': 'Attendance', 'icon': Icons.access_time},
        {'title': 'Leave Requests', 'icon': Icons.event_available},
        {'title': 'Reports', 'icon': Icons.bar_chart},
      ];
    case 'Manager':
      return [
        {'title': 'Assign Task', 'icon': Icons.add_task},
        {'title': 'My Team', 'icon': Icons.groups},
        {'title': 'Attendance', 'icon': Icons.access_time},
        {'title': 'Leave Requests', 'icon': Icons.event_available},
        {'title': 'Team Reports', 'icon': Icons.bar_chart},
      ];
    default:
      return [
        {'title': 'Check In', 'icon': Icons.login},
        {'title': 'Check Out', 'icon': Icons.logout},
        {'title': 'Apply Leave', 'icon': Icons.event_available},
        {'title': 'My Tasks', 'icon': Icons.task_alt},
      ];
  }
}

List<String> getPermissions(String role) {
  switch (role) {
    case 'Super Admin':
      return [
        'Admins',
        'HR',
        'Managers',
        'Employees',
        'Departments',
        'Attendance',
        'Leave',
        'Reports',
        'Roles',
        'Settings'
      ];
    case 'Admin':
      return [
        'Employees',
        'Departments',
        'Managers',
        'Attendance',
        'Leave',
        'Reports',
        'Notifications'
      ];
    case 'HR':
      return [
        'Employees',
        'Documents',
        'Attendance',
        'Leave',
        'Performance',
        'Reports'
      ];
    case 'Manager':
      return [
        'My Team',
        'Tasks',
        'Attendance',
        'Leave',
        'Performance',
        'Team Reports'
      ];
    default:
      return [
        'My Profile',
        'Attendance',
        'Leave',
        'Tasks',
        'Notifications',
        'Personal Reports'
      ];
  }
}

String getGreeting(String userName) {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning, $userName';
  if (hour < 17) return 'Good Afternoon, $userName';
  return 'Good Evening, $userName';
}