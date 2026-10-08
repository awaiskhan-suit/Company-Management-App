import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../colors/colors.dart';
import '../../providers/employee_list_provider.dart';
import 'employees_action.dart';

class EmployeeListScreen extends ConsumerStatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  ConsumerState<EmployeeListScreen> createState() =>
      _EmployeeListScreenState();
}

class _EmployeeListScreenState extends ConsumerState<EmployeeListScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  late final AnimationController _controller;
  int _listAnimKey = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _searchController.addListener(() {
      ref
          .read(employeeSearchProvider.notifier)
          .setQuery(_searchController.text);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _replayListAnimation() {
    setState(() => _listAnimKey++);
    _controller
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final asyncEmployees = ref.watch(employeeListProvider);
    final employees = ref.watch(filteredEmployeesProvider);
    final departments = ref.watch(departmentsProvider);
    final searchQuery = ref.watch(employeeSearchProvider);
    final selectedDepartment = ref.watch(selectedDepartmentProvider);

    // Counts for chips
    final totalCount = ref.watch(totalEmployeesCountProvider);
    final perDept = ref.watch(employeesPerDepartmentProvider);

    ref.listen<String>(selectedDepartmentProvider, (prev, next) {
      if (prev != next) _replayListAnimation();
    });

    ref.listen<String>(employeeSearchProvider, (prev, next) {
      if (prev != next) _replayListAnimation();
    });

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
        iconTheme: IconThemeData(color: Colors.white, size: 24.sp),
        title: Text(
          'Total Employees',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // ===================== SEARCH =====================
          _AnimatedEntrance(
            animation: _controller,
            index: 0,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 10.h),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search by name or employee ID',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13.sp,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.blue,
                    size: 22.sp,
                  ),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                    onPressed: () => _searchController.clear(),
                    icon: Icon(Icons.close_rounded, size: 20.sp),
                  )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                  EdgeInsets.symmetric(vertical: 15.h, horizontal: 16.w),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide:
                    BorderSide(color: AppColors.blue, width: 1.2.w),
                  ),
                ),
              ),
            ),
          ),

          // ===================== DEPARTMENT CHIPS =====================
          _AnimatedEntrance(
            animation: _controller,
            index: 1,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 2.h, 16.w, 6.h),
                  child: Row(
                    children: [
                      Icon(
                        Icons.business_rounded,
                        size: 18.sp,
                        color: AppColors.blue,
                      ),
                      SizedBox(width: 7.w),
                      Text(
                        'Departments',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${departments.length - 1} departments',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 42.h,
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: departments.length,
                    separatorBuilder: (_, __) => SizedBox(width: 8.w),
                    itemBuilder: (context, index) {
                      final department = departments[index];
                      final bool selected = selectedDepartment == department;

                      final int count = department == kAllDepartments
                          ? totalCount
                          : (perDept[department] ?? 0);

                      return _DepartmentChip(
                        title: department,
                        count: count,
                        selected: selected,
                        onTap: () {
                          ref
                              .read(selectedDepartmentProvider.notifier)
                              .select(department);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 8.h),

          // ===================== HEADER + COUNT =====================
          _AnimatedEntrance(
            animation: _controller,
            index: 2,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
              child: Row(
                children: [
                  Text(
                    'Employees',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: AppColors.blue.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CountUpText(
                          value: employees.length,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blue,
                          ),
                        ),
                        Text(
                          ' found',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 2.h),

          // ===================== LIST =====================
          Expanded(
            child: asyncEmployees.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _buildErrorState(),
              data: (allEmployees) {
                if (employees.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(employeeListProvider.notifier).refresh(),
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                          child: _AnimatedEntrance(
                            animation: _controller,
                            index: 3,
                            child: _buildEmptyState(
                              hasAnyEmployee: allEmployees.isNotEmpty,
                              selectedDepartment: selectedDepartment,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(employeeListProvider.notifier).refresh(),
                  child: ListView.builder(
                    key: ValueKey('list_$_listAnimKey'),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                    itemCount: employees.length,
                    itemBuilder: (context, index) {
                      final employee = employees[index];
                      return _AnimatedEntrance(
                        key: ValueKey('${employee.id}_$_listAnimKey'),
                        animation: _controller,
                        index: index + 3,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _EmployeeCard(
                            employee: employee,
                            onTap: () =>
                                openEmployeeDetails(context, ref, employee),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required bool hasAnyEmployee,
    required String selectedDepartment,
  }) {
    String message;
    if (!hasAnyEmployee) {
      message =
      'No employees have been added yet.\nAdd one from the Add Employee screen.';
    } else if (selectedDepartment == kAllDepartments) {
      message = 'Try searching with another name or employee ID.';
    } else {
      message = 'No employees found in $selectedDepartment.';
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(30.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 75.w,
              width: 75.w,
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_search_rounded,
                size: 38.sp,
                color: AppColors.blue,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'No Employees Found',
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textMuted,
              ),
            ),
            if (!hasAnyEmployee) ...[
              SizedBox(height: 12.h),
              TextButton.icon(
                onPressed: () =>
                    ref.read(employeeListProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(30.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 46.sp,
              color: Colors.redAccent,
            ),
            SizedBox(height: 12.h),
            Text(
              'Could not load employees',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            TextButton.icon(
              onPressed: () =>
                  ref.read(employeeListProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// ANIMATED ENTRANCE
// ==================================================================

class _AnimatedEntrance extends StatelessWidget {
  const _AnimatedEntrance({
    super.key,
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

    final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );

    final slide = Tween<Offset>(
      begin: const Offset(-0.60, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );

    final scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: Interval(start, end, curve: Curves.easeOutBack),
      ),
    );

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: ScaleTransition(scale: scale, child: child),
      ),
    );
  }
}

// ==================================================================
// PRESS SCALE
// ==================================================================

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
      duration: const Duration(milliseconds: 140),
    );
    _scale = Tween<double>(begin: 1.0, end: widget.pressedScale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
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
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
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

// ==================================================================
// COUNT UP
// ==================================================================

class _CountUpText extends StatefulWidget {
  const _CountUpText({required this.value, required this.style});

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
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween<double>(begin: 0, end: widget.value.toDouble()).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _CountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final current = _animation.value;
      _animation = Tween<double>(
        begin: current,
        end: widget.value.toDouble(),
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
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
        return Text(_animation.value.round().toString(), style: widget.style);
      },
    );
  }
}

// ==================================================================
// DEPARTMENT CHIP (with count)
// ==================================================================

class _DepartmentChip extends StatelessWidget {
  const _DepartmentChip({
    required this.title,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      pressedScale: 0.94,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue : Colors.white,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: selected ? AppColors.blue : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              title == kAllDepartments
                  ? Icons.grid_view_rounded
                  : Icons.business_rounded,
              size: 15.sp,
              color: selected ? Colors.white : AppColors.blue,
            ),
            SizedBox(width: 6.w),
            Text(
              '$title ($count)',
              style: TextStyle(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// EMPLOYEE IMAGE
// ==================================================================

class _EmployeeImage extends StatelessWidget {
  const _EmployeeImage({
    required this.imagePath,
    required this.size,
    required this.radius,
    required this.iconSize,
  });

  final String? imagePath;
  final double size;
  final double radius;
  final double iconSize;

  Widget _placeholder() {
    return Container(
      height: size,
      width: size,
      color: AppColors.blue.withOpacity(0.10),
      child: Icon(Icons.person_rounded, color: AppColors.blue, size: iconSize),
    );
  }

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    final hasImage =
        path != null && path.isNotEmpty && File(path).existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: hasImage
          ? Image.file(
        File(path),
        height: size,
        width: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      )
          : _placeholder(),
    );
  }
}

// ==================================================================
// EMPLOYEE CARD
// ==================================================================

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({required this.employee, required this.onTap});

  final Employee employee;
  final VoidCallback onTap;

  Color get _statusColor {
    if (employee.status == 'Active') return AppColors.success;
    if (employee.status == 'On Leave') return const Color(0xFFF5A623);
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      pressedScale: 0.98,
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.black.withOpacity(0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8.r,
              offset: Offset(0, 3.h),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EmployeeImage(
                  imagePath: employee.imagePath,
                  size: 62.w,
                  radius: 13.r,
                  iconSize: 32.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        employee.designation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                      SizedBox(height: 7.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          employee.id,
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding:
                  EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 6.w,
                        width: 6.w,
                        decoration: BoxDecoration(
                          color: _statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        employee.status,
                        style: TextStyle(
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w700,
                          color: _statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Divider(height: 1.h, color: Colors.grey.withOpacity(0.15)),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    icon: Icons.business_rounded,
                    label: 'Department',
                    value: employee.department,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _InfoItem(
                    icon: Icons.calendar_month_rounded,
                    label: 'Joined',
                    value: employee.joiningDate,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    icon: Icons.phone_rounded,
                    label: 'Phone',
                    value: employee.phone,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _InfoItem(
                    icon: Icons.email_rounded,
                    label: 'Email',
                    value: employee.email,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 9.h),
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.06),
                borderRadius: BorderRadius.circular(9.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Employee Details',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue,
                    ),
                  ),
                  SizedBox(width: 5.w),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 15.sp,
                    color: AppColors.blue,
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

// ==================================================================
// INFO ITEM
// ==================================================================

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15.sp, color: AppColors.blue),
        SizedBox(width: 7.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value.isEmpty ? '-' : value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

