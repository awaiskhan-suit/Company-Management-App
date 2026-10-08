import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../active_tab_provider/active_tab_provider.dart';
import '../../colors/colors.dart';
import '../../providers/report_provider.dart';

import '../attendance/attendance_screen.dart';
import '../attendance/view_attendance.dart';
import '../departments/department_list_screen.dart';
import '../employees/employee_list_screen.dart';
import '../employees/employee_detail_screen.dart';
import '../tasks/task_details_screen.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({
    super.key,
    this.isActive = false,
  });

  final bool isActive;

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Reports tab index in bottom navigation
  static const int _tabIndex = 1;

  @override
  void initState() {
    super.initState();

    // ============================================================
    // MAIN REPORTS ANIMATION CONTROLLER
    // ============================================================

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // ============================================================
    // LISTEN TO BOTTOM NAVIGATION TAB CHANGES
    // ============================================================

    ref.listenManual<int>(
      activeTabIndexProvider,
          (previous, next) {
        if (!mounted) return;

        // When Reports tab becomes active
        if (next == _tabIndex && previous != _tabIndex) {
          _replayAnimation();
        }
      },
    );

    // ============================================================
    // FIRST ANIMATION
    // ============================================================

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  // ============================================================
  // REPLAY REPORTS ANIMATION
  // ============================================================

  void _replayAnimation() {
    if (!mounted) return;

    _controller
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ============================================================
  // CATEGORY COLOR
  // ============================================================

  Color _getCategoryColor(int index) {
    if (index == 0) return AppColors.blue;
    if (index == 1) return AppColors.success;
    return const Color(0xFFF5A623);
  }

  // ============================================================
  // REPORT TAP HANDLER
  // ============================================================

  void _handleReportTap(BuildContext context, ReportItem item) {
    final notifier = ref.read(reportsProvider.notifier);

    notifier.selectReport(item.id);


    if (item.id == 'emp_active') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const EmployeeListScreen(),
        ),
      );
      return;
    }


    // Daily Attendance
    if (item.id == 'att_daily') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AttendanceReportScreen(),
        ),
      );
      return;
    }

    // Total Tasks
    if (item.id == 'task_total') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const TotalTask(),
        ),
      );
      return;
    }

    // Total Departments
    if (item.id == 'dept_total') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const DepartmentListScreen(),
        ),
      );
      return;
    }


    if (item.id == 'att_employee') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AttendanceScreen(),
        ),
      );
      return;
    }

    // Other reports
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.title} — UI only'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportsProvider);
    final notifier = ref.read(reportsProvider.notifier);

    final categories = state.categories;

    return Scaffold(
      backgroundColor: AppColors.background,

      // ========================================================
      // APP BAR
      // ========================================================

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
          'Reports',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16.w,
          16.h,
          16.w,
          28.h,
        ),
        children: [
          // ======================================================
          // SUMMARY CHIPS
          // ======================================================

          _AnimatedEntrance(
            animation: _controller,
            index: 0,
            child: Row(
              children: [
                for (var i = 0; i < categories.length; i++) ...[
                  if (i > 0) SizedBox(width: 8.w),
                  Expanded(
                    child: _SummaryChip(
                      label: categories[i].title.split(' ').first,
                      count: categories[i].items.length,
                      color: _getCategoryColor(i),
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 18.h),

          // ======================================================
          // CATEGORY CARDS
          // ======================================================

          ...categories.asMap().entries.map((entry) {
            final int index = entry.key;
            final category = entry.value;

            final bool expanded = state.expandedIds.contains(category.id);

            return Padding(
              padding: EdgeInsets.only(
                bottom: 12.h,
              ),
              child: _AnimatedEntrance(
                animation: _controller,
                index: index + 1,
                child: _CategoryCard(
                  category: category,
                  expanded: expanded,
                  selectedReportId: state.selectedReportId,
                  onToggle: () {
                    notifier.toggleCategory(
                      category.id,
                    );
                  },
                  onItemTap: (item) {
                    _handleReportTap(
                      context,
                      item,
                    );
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ============================================================
// ANIMATED ENTRANCE
// Left → Right + Fade + Scale
// ============================================================

class _AnimatedEntrance extends StatelessWidget {
  const _AnimatedEntrance({
    required this.child,
    required this.animation,
    required this.index,
  });

  final Widget child;
  final AnimationController animation;
  final int index;

  @override
  Widget build(BuildContext context) {
    final double start = (index * 0.13).clamp(0.0, 0.70);

    final double end = (start + 0.30).clamp(0.0, 1.0);

    final Animation<double> fade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: Interval(
          start,
          end,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    final Animation<Offset> slide = Tween<Offset>(
      begin: const Offset(-0.60, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: Interval(
          start,
          end,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    final Animation<double> scale = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: Interval(
          start,
          end,
          curve: Curves.easeOutBack,
        ),
      ),
    );

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: ScaleTransition(
          scale: scale,
          child: child,
        ),
      ),
    );
  }
}

// ============================================================
// PRESS SCALE
// ============================================================

class _PressableScale extends StatefulWidget {
  const _PressableScale({
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 140,
      ),
    );

    _scale = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
  }

  void _setPressed(bool pressed) {
    if (pressed) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
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
      onTapDown: (_) {
        _setPressed(true);
      },
      onTapUp: (_) {
        _setPressed(false);
      },
      onTapCancel: () {
        _setPressed(false);
      },
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

// ============================================================
// COUNT UP
// ============================================================

class _CountUpText extends StatefulWidget {
  const _CountUpText({
    required this.value,
    required this.style,
  });

  final int value;
  final TextStyle style;

  @override
  State<_CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<_CountUpText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1000,
      ),
    );

    _animation = Tween<double>(
      begin: 0,
      end: widget.value.toDouble(),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(
      covariant _CountUpText oldWidget,
      ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: 0,
        end: widget.value.toDouble(),
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
        ),
      );

      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          _animation.value.round().toString(),
          style: widget.style,
        );
      },
    );
  }
}

// ============================================================
// SUMMARY CHIP
// ============================================================

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: 12.h,
          horizontal: 8.w,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(
            12.r,
          ),
          border: Border.all(
            color: color.withOpacity(0.25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Count
            _CountUpText(
              value: count,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            SizedBox(height: 2.h),
            // Label
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CATEGORY CARD
// ============================================================

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({
    required this.category,
    required this.expanded,
    required this.selectedReportId,
    required this.onToggle,
    required this.onItemTap,
  });

  final ReportCategory category;
  final bool expanded;
  final String? selectedReportId;

  final VoidCallback onToggle;

  final ValueChanged<ReportItem> onItemTap;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 300,
      ),
    );

    _scale = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    if (widget.expanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(
      covariant _CategoryCard oldWidget,
      ) {
    super.didUpdateWidget(oldWidget);

    if (widget.expanded != oldWidget.expanded) {
      if (widget.expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool expanded = widget.expanded;

    final ReportCategory category = widget.category;

    return GestureDetector(
      onTap: widget.onToggle,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: child,
          );
        },
        child: Container(
          margin: EdgeInsets.symmetric(
            vertical: 4.h,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              expanded ? 24.r : 12.r,
            ),
            boxShadow: [
              if (expanded)
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20.r,
                  spreadRadius: -5.r,
                  offset: Offset(
                    0,
                    10.h,
                  ),
                ),
              if (!expanded)
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10.r,
                  offset: Offset(
                    0,
                    4.h,
                  ),
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ==================================================
              // HEADER
              // ==================================================

              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 14.h,
                ),
                child: Row(
                  children: [
                    // Icon container
                    Container(
                      height: 40.h,
                      width: 40.w,
                      decoration: BoxDecoration(
                        color: AppColors.blue.withOpacity(
                          0.12,
                        ),
                        borderRadius: BorderRadius.circular(
                          11.r,
                        ),
                      ),
                      child: Icon(
                        category.icon,
                        color: AppColors.blue,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Title + reports count
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            category.title,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '${category.items.length} reports',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Arrow
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(
                        milliseconds: 300,
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textMuted,
                        size: 24.sp,
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // EXPANDED REPORT LIST
              // ==================================================

              AnimatedCrossFade(
                duration: const Duration(
                  milliseconds: 300,
                ),
                sizeCurve: Curves.easeOut,
                crossFadeState: expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox(
                  width: double.infinity,
                ),
                secondChild: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(height: 1),
                    ...category.items.map(
                          (item) {
                        final bool selected =
                            widget.selectedReportId == item.id;

                        return ListTile(
                          dense: true,
                          selected: selected,
                          leading: Icon(
                            item.icon,
                            size: 20.sp,
                            color: selected
                                ? AppColors.blue
                                : AppColors.navy,
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? AppColors.blue
                                  : AppColors.textPrimary,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 20.sp,
                            color: AppColors.textMuted,
                          ),
                          onTap: () {
                            widget.onItemTap(item);
                          },
                        );
                      },
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

