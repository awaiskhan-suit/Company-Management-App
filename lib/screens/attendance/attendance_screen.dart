import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../colors/colors.dart';
import '../../providers/attendance_provider.dart';
import '../../services/api_client.dart';

// ============================================================
// HELPERS
// ============================================================

const Color _leaveColor = Color(0xFFF5A623);

Color _statusColor(AttendanceStatus s) {
  switch (s) {
    case AttendanceStatus.present:
      return AppColors.success;
    case AttendanceStatus.leave:
      return _leaveColor;
    case AttendanceStatus.absent:
      return AppColors.error;
    case AttendanceStatus.notMarked:
      return AppColors.textMuted;
  }
}

String _statusLabel(AttendanceStatus s) {
  switch (s) {
    case AttendanceStatus.present:
      return 'Present';
    case AttendanceStatus.leave:
      return 'Leave';
    case AttendanceStatus.absent:
      return 'Absent';
    case AttendanceStatus.notMarked:
      return 'Not marked';
  }
}

class _Counts {
  int present = 0;
  int leave = 0;
  int absent = 0;
  int notMarked = 0;
  int get total => present + leave + absent + notMarked;
}

_Counts _countFor(
    Iterable<AttendanceEmployee> list,
    Map<String, AttendanceStatus> marks,
    ) {
  final c = _Counts();
  for (final e in list) {
    switch (marks[e.id] ?? AttendanceStatus.notMarked) {
      case AttendanceStatus.present:
        c.present++;
        break;
      case AttendanceStatus.leave:
        c.leave++;
        break;
      case AttendanceStatus.absent:
        c.absent++;
        break;
      case AttendanceStatus.notMarked:
        c.notMarked++;
        break;
    }
  }
  return c;
}

String _today() {
  final n = DateTime.now();
  return '${n.day.toString().padLeft(2, '0')}/'
      '${n.month.toString().padLeft(2, '0')}/'
      '${n.year}';
}

// ============================================================
// SCREEN
// ============================================================

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  String _selected = 'All';

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset attendance?'),
        content: const Text(
          "This clears today's attendance for all employees on this device.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(attendanceProvider.notifier).resetAll();
    }
  }

  Future<void> _refresh() =>
      ref.read(apiEmployeesProvider.notifier).refresh();

  @override
  Widget build(BuildContext context) {
    final roster = ref.watch(rosterProvider);
    final employees = roster.asData?.value ?? const <AttendanceEmployee>[];
    final marksAsync = ref.watch(attendanceProvider);
    final marks =
        marksAsync.value?.marks ?? const <String, AttendanceStatus>{};

    final isLoading = (roster.isLoading && !roster.hasValue) ||
        (marksAsync.isLoading && !marksAsync.hasValue);
    final hasError = roster.hasError && !roster.hasValue;

    // Departments come from the employee list (API + added employees).
    // Grouped case-insensitively so "IT" and "it" are the same department.
    final deptNames = <String, String>{}; // lowercase -> display name
    for (final e in employees) {
      final d = e.department.trim();
      if (d.isNotEmpty) deptNames.putIfAbsent(d.toLowerCase(), () => d);
    }
    final departments = deptNames.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final selected = (_selected == 'All' ||
        deptNames.containsKey(_selected.toLowerCase()))
        ? _selected
        : 'All';

    final scoped = selected == 'All'
        ? employees
        : employees
        .where((e) =>
    e.department.trim().toLowerCase() == selected.toLowerCase())
        .toList();

    final scopedCounts = _countFor(scoped, marks);

    Widget body;
    if (isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (hasError) {
      body = _MessageView(
        icon: Icons.wifi_off_rounded,
        title: 'Internet required',
        message: ApiException.from(roster.error!).message,
        onRetry: _refresh,
      );
    } else if (employees.isEmpty) {
      body = const _MessageView(
        icon: Icons.people_outline_rounded,
        title: 'No employees yet',
        message: 'Add employees first, then mark their attendance here.',
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          children: [
            // ---------- Summary for current selection ----------
            _SummaryCard(
              title: selected == 'All' ? 'All Departments' : selected,
              counts: scopedCounts,
            ),
            SizedBox(height: 14.h),

            // ---------- Department filter ----------
            SizedBox(
              height: 38.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: departments.length + 1,
                separatorBuilder: (_, __) => SizedBox(width: 8.w),
                itemBuilder: (context, i) {
                  final label = i == 0 ? 'All' : departments[i - 1];
                  final isSel = label == selected;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = label),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.blue : Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: isSel
                              ? AppColors.blue
                              : Colors.grey.withOpacity(0.25),
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w700,
                          color: isSel ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 14.h),

            // ---------- Department-wise summary ----------
            _DepartmentSummary(
              departments: departments,
              employees: employees,
              marks: marks,
              onSelect: (d) => setState(() => _selected = d),
            ),
            SizedBox(height: 16.h),

            // ---------- Employee list ----------
            if (scoped.isEmpty)
              const _MessageView(
                icon: Icons.search_off_rounded,
                title: 'No employees',
                message: 'No employees in this department.',
              )
            else
              for (final e in scoped)
                Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: _EmployeeAttendanceCard(employee: e),
                ),
          ],
        ),
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
          decoration: const BoxDecoration(gradient: AppColors.ctaGradient),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mark Attendance',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Reset all',
            icon: Icon(Icons.refresh_rounded, color: Colors.white, size: 24.sp),
            onPressed: employees.isEmpty ? null : _confirmReset,
          ),
        ],
      ),
      body: body,
    );
  }
}

// ============================================================
// SUMMARY CARD (selected department or all)
// ============================================================

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.counts});

  final String title;
  final _Counts counts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${_today()}  ·  ${counts.total} employees',
                style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _StatTile(
                label: 'Present',
                count: counts.present,
                color: AppColors.success,
              ),
              SizedBox(width: 8.w),
              _StatTile(
                label: 'Leave',
                count: counts.leave,
                color: _leaveColor,
              ),
              SizedBox(width: 8.w),
              _StatTile(
                label: 'Absent',
                count: counts.absent,
                color: AppColors.error,
              ),
              SizedBox(width: 8.w),
              _StatTile(
                label: 'Pending',
                count: counts.notMarked,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5.sp,
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
// DEPARTMENT-WISE SUMMARY
// ============================================================

class _DepartmentSummary extends StatelessWidget {
  const _DepartmentSummary({
    required this.departments,
    required this.employees,
    required this.marks,
    required this.onSelect,
  });

  final List<String> departments;
  final List<AttendanceEmployee> employees;
  final Map<String, AttendanceStatus> marks;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: EdgeInsets.symmetric(horizontal: 14.w),
          childrenPadding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 10.h),
          leading: Icon(
            Icons.apartment_rounded,
            color: AppColors.blue,
            size: 22.sp,
          ),
          title: Text(
            'Department-wise summary',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          children: [
            for (final d in departments) _deptRow(d),
          ],
        ),
      ),
    );
  }

  Widget _deptRow(String dept) {
    final list = employees
        .where((e) => e.department.trim().toLowerCase() == dept.toLowerCase())
        .toList();
    final c = _countFor(list, marks);

    return InkWell(
      onTap: () => onSelect(dept),
      borderRadius: BorderRadius.circular(10.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dept,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${c.total} employees',
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            _MiniCount(label: 'P', count: c.present, color: AppColors.success),
            SizedBox(width: 6.w),
            _MiniCount(label: 'L', count: c.leave, color: _leaveColor),
            SizedBox(width: 6.w),
            _MiniCount(label: 'A', count: c.absent, color: AppColors.error),
          ],
        ),
      ),
    );
  }
}

class _MiniCount extends StatelessWidget {
  const _MiniCount({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        '$label $count',
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ============================================================
// EMPLOYEE CARD
// ============================================================

class _EmployeeAttendanceCard extends ConsumerWidget {
  const _EmployeeAttendanceCard({required this.employee});

  final AttendanceEmployee employee;

  void _showAttendanceSheet(BuildContext context, WidgetRef ref) {
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // lets the sheet grow past the default 9/16 height
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      builder: (ctx) {
        final current = ref
            .read(attendanceProvider)
            .value
            ?.statusOf(employee.id) ??
            AttendanceStatus.notMarked;

        Widget option(AttendanceStatus status, IconData icon) {
          return _AttendanceOption(
            label: _statusLabel(status),
            color: _statusColor(status),
            icon: icon,
            selected: current == status,
            onTap: () async {
              // Saved through the shared dio (needs internet)
              final error = await ref
                  .read(attendanceProvider.notifier)
                  .setAttendance(employee.id, status);

              if (ctx.mounted) Navigator.pop(ctx);

              if (error != null) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(error),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
          );
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  employee.name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${employee.id} · ${employee.department}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textMuted,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Set attendance',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                SizedBox(height: 10.h),
                option(AttendanceStatus.present, Icons.check_circle_outline),
                option(AttendanceStatus.leave, Icons.beach_access_outlined),
                option(AttendanceStatus.absent, Icons.cancel_outlined),
                option(AttendanceStatus.notMarked, Icons.remove_circle_outline),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      attendanceProvider.select(
            (s) => s.value?.statusOf(employee.id) ?? AttendanceStatus.notMarked,
      ),
    );
    final statusColor = _statusColor(status);

    ImageProvider? photo;
    final path = employee.imagePath;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      photo = FileImage(File(path));
    }

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24.r,
            backgroundColor: AppColors.navy.withOpacity(0.12),
            backgroundImage: photo,
            child: photo == null
                ? Text(
              employee.name.isNotEmpty
                  ? employee.name[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
                fontSize: 18.sp,
              ),
            )
                : null,
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
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'ID: ${employee.id}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textMuted,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${employee.department} · ${employee.designation}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textMuted,
                  ),
                ),
                SizedBox(height: 6.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          SizedBox(
            height: 40.h,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                gradient: AppColors.ctaGradient,
              ),
              child: ElevatedButton(
                onPressed: () => _showAttendanceSheet(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: Text(
                  'Attendance',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5.sp,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceOption extends StatelessWidget {
  const _AttendanceOption({
    required this.label,
    required this.color,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 24.sp),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      trailing:
      selected ? Icon(Icons.check_rounded, color: color, size: 22.sp) : null,
      onTap: onTap,
    );
  }
}

// ============================================================
// EMPTY / ERROR MESSAGE
// ============================================================

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(30.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 75.w,
              width: 75.w,
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38.sp, color: AppColors.blue),
            ),
            SizedBox(height: 16.h),
            Text(
              title,
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
            if (onRetry != null) ...[
              SizedBox(height: 14.h),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}