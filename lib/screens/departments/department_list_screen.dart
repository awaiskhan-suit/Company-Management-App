import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../colors/colors.dart';
import '../../providers/department_provider.dart';
import 'department_action.dart';
import 'department_detail_screen.dart';

/// Department list. Search by name/code + filter by category (type).
/// View Details works with cached data; Add/Edit/Delete need internet.
class DepartmentListScreen extends ConsumerStatefulWidget {
  const DepartmentListScreen({super.key});

  @override
  ConsumerState<DepartmentListScreen> createState() =>
      _DepartmentListScreenState();
}

class _DepartmentListScreenState extends ConsumerState<DepartmentListScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  late final AnimationController _controller;
  int _listAnimKey = 0;
  String _query = '';
  String _selectedCategory = 'All'; // category filter

  final List<String> _categories = const [
    'All',
    'HR',
    'IT',
    'Finance',
    'Operations',
    'Marketing',
    'Sales',
    'Support',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _searchController.addListener(_onSearchChanged);

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

  void _onSearchChanged() {
    final q = _searchController.text.trim().toLowerCase();
    if (q == _query) return;

    setState(() {
      _query = q;
      _listAnimKey++;
    });
    _controller
      ..reset()
      ..forward();
  }

  void _onCategorySelected(String category) {
    if (category == _selectedCategory) return;
    setState(() {
      _selectedCategory = category;
      _listAnimKey++;
    });
    _controller
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final asyncDepartments = ref.watch(departmentListProvider);

    final all = asyncDepartments.maybeWhen(
      data: (list) => list,
      orElse: () => const <Department>[],
    );

    // 1) Filter by category (type)
    // 2) Then filter by search (name or code)
    final filtered = all.where((d) {
      final matchCategory =
          _selectedCategory == 'All' || d.type == _selectedCategory;

      final matchSearch = _query.isEmpty ||
          d.name.toLowerCase().contains(_query) ||
          d.code.toLowerCase().contains(_query);

      return matchCategory && matchSearch;
    }).toList();

    // Total count of all departments (ignores search/category filters)
    final total = all.length;
    final isFiltering = _selectedCategory != 'All' || _query.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.ctaGradient),
        ),
        iconTheme: IconThemeData(color: Colors.white, size: 24.sp),
        title: Text(
          'Departments',
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
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search by name or department ID',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13.sp,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.blue,
                    size: 22.sp,
                  ),
                  suffixIcon: _query.isNotEmpty
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

          // ===================== CATEGORY CHIPS =====================
          _AnimatedEntrance(
            animation: _controller,
            index: 1,
            child: SizedBox(
              height: 42.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => SizedBox(width: 8.w),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;

                  return GestureDetector(
                    onTap: () => _onCategorySelected(category),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.blue
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.blue
                              : Colors.grey.withOpacity(0.25),
                        ),
                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color: AppColors.blue.withOpacity(0.25),
                            blurRadius: 6.r,
                            offset: Offset(0, 2.h),
                          ),
                        ]
                            : null,
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          SizedBox(height: 10.h),

          // ===================== HEADER + COUNT =====================
          _AnimatedEntrance(
            animation: _controller,
            index: 2,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              child: Row(
                children: [
                  Icon(
                    Icons.apartment_rounded,
                    size: 18.sp,
                    color: AppColors.blue,
                  ),
                  SizedBox(width: 7.w),
                  Text(
                    _selectedCategory == 'All'
                        ? 'Departments'
                        : '$_selectedCategory Departments',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  // Hidden while loading; shows "N total" or "N of TOTAL"
                  if (asyncDepartments.hasValue)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blue.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _CountUpText(
                            value: filtered.length,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.blue,
                            ),
                          ),
                          Text(
                            isFiltering ? ' of $total' : ' total',
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
            child: asyncDepartments.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _ErrorView(
                message: err.toString().replaceFirst('Exception: ', ''),
                onRetry: () =>
                    ref.read(departmentListProvider.notifier).refresh(),
              ),
              data: (departments) {
                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(departmentListProvider.notifier).refresh(),
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
                              hasAnyDepartment: departments.isNotEmpty,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(departmentListProvider.notifier).refresh(),
                  child: ListView.builder(
                    key: ValueKey('list_$_listAnimKey'),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final department = filtered[index];
                      return _AnimatedEntrance(
                        key: ValueKey('${department.id}_$_listAnimKey'),
                        animation: _controller,
                        index: index + 3,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _DepartmentCard(
                            department: department,
                            employeeCount: department.employeeCount ?? 0,
                            onView: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DepartmentDetailsScreen(
                                    department: department,
                                  ),
                                ),
                              );
                            },
                            onEdit: () => openDepartmentForm(
                              context,
                              ref,
                              department: department,
                            ),
                            onDelete: () => confirmDeleteDepartment(
                              context,
                              ref,
                              department,
                            ),
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

  Widget _buildEmptyState({required bool hasAnyDepartment}) {
    final message = hasAnyDepartment
        ? (_selectedCategory != 'All'
        ? 'No departments found in $_selectedCategory category.'
        : 'Try searching with another name or department ID.')
        : 'No departments have been added yet.';

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
                Icons.search_off_rounded,
                size: 38.sp,
                color: AppColors.blue,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'No Departments Found',
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
              style: TextStyle(fontSize: 13.sp, color: AppColors.textMuted),
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
// DEPARTMENT CARD
// ==================================================================

class _DepartmentCard extends StatelessWidget {
  const _DepartmentCard({
    required this.department,
    required this.employeeCount,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final Department department;
  final int employeeCount;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color get _statusColor =>
      department.status == 'Active' ? AppColors.success : Colors.red;

  @override
  Widget build(BuildContext context) {
    final manager = (department.managerName ?? '').trim();

    return _PressableScale(
      onTap: onView,
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
                Container(
                  height: 46.w,
                  width: 46.w,
                  decoration: BoxDecoration(
                    color: AppColors.blue.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.apartment_rounded,
                    color: AppColors.blue,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        department.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          _Chip(text: department.code, color: AppColors.blue),
                          SizedBox(width: 6.w),
                          _Chip(
                            text: department.type,
                            color: AppColors.textMuted,
                          ),
                        ],
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
                        department.status,
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
            if (department.description.isNotEmpty) ...[
              SizedBox(height: 10.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  department.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textMuted,
                    height: 1.35,
                  ),
                ),
              ),
            ],
            SizedBox(height: 12.h),
            Divider(height: 1.h, color: Colors.grey.withOpacity(0.15)),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    icon: Icons.people_alt_rounded,
                    label: 'Employees',
                    value: '$employeeCount',
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _InfoItem(
                    icon: Icons.storefront_outlined,
                    label: 'Branch',
                    value: department.branch,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Manager',
                    value: manager,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _InfoItem(
                    icon: Icons.layers_outlined,
                    label: 'Floor',
                    value: department.floor ?? '',
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // ---------- VIEW DETAILS ----------
            InkWell(
              onTap: onView,
              borderRadius: BorderRadius.circular(9.r),
              child: Container(
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
                      'View Department Details',
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
            ),
            SizedBox(height: 10.h),

            // ---------- EDIT / DELETE ----------
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: Icon(Icons.edit_outlined, size: 16.sp),
                    label: Text(
                      'Edit',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5.sp,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.blue,
                      side: BorderSide(color: AppColors.blue),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline, size: 16.sp),
                    label: Text(
                      'Delete',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5.sp,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

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
                  fontSize: 11.sp,
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

// ==================================================================
// ERROR / OFFLINE VIEW
// ==================================================================

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
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
                color: Colors.orange.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 38.sp,
                color: Colors.orange.shade700,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Internet required',
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
              style: TextStyle(fontSize: 13.sp, color: AppColors.textMuted),
            ),
            SizedBox(height: 14.h),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

