import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================
// MODELS
// ============================================================

class ReportItem {
  const ReportItem({
    required this.id,
    required this.title,
    required this.icon,
  });

  final String id;
  final String title;
  final IconData icon;
}

class ReportCategory {
  const ReportCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.items,
  });

  final String id;
  final String title;
  final IconData icon;
  final List<ReportItem> items;
}

// ============================================================
// STATE
// ============================================================

class ReportsState {
  const ReportsState({
    this.categories = const [],
    this.expandedIds = const {'employee'},
    this.selectedReportId,
  });

  final List<ReportCategory> categories;
  final Set<String> expandedIds;
  final String? selectedReportId;

  ReportsState copyWith({
    List<ReportCategory>? categories,
    Set<String>? expandedIds,
    String? selectedReportId,
    bool clearSelected = false,
  }) {
    return ReportsState(
      categories: categories ?? this.categories,
      expandedIds: expandedIds ?? this.expandedIds,
      selectedReportId:
      clearSelected ? null : (selectedReportId ?? this.selectedReportId),
    );
  }
}

// ============================================================
// STATIC DATA
// ============================================================

const List<ReportCategory> kStaticReportCategories = [
  ReportCategory(
    id: 'employee',
    title: 'Employee Reports',
    icon: Icons.people_alt_outlined,
    items: [
      ReportItem(
          id: 'emp_total',
          title: 'Total employees',
          icon: Icons.groups_outlined),
      ReportItem(
          id: 'emp_active',
          title: 'Active employees',
          icon: Icons.verified_user_outlined),
      ReportItem(
          id: 'emp_inactive',
          title: 'Inactive employees',
          icon: Icons.person_off_outlined),
      ReportItem(
          id: 'emp_by_dept',
          title: 'Employees by department',
          icon: Icons.account_tree_outlined),
      ReportItem(
          id: 'emp_by_desig',
          title: 'Employees by designation',
          icon: Icons.badge_outlined),
      ReportItem(
          id: 'emp_by_type',
          title: 'Employees by employment type',
          icon: Icons.work_outline),
    ],
  ),
  ReportCategory(
    id: 'attendance',
    title: 'Attendance Reports',
    icon: Icons.access_time_rounded,
    items: [
      ReportItem(
          id: 'att_daily',
          title: 'Daily attendance',
          icon: Icons.today_outlined),
      ReportItem(
          id: 'att_weekly',
          title: 'Weekly attendance',
          icon: Icons.date_range_outlined),
      ReportItem(
          id: 'att_monthly',
          title: 'Monthly attendance',
          icon: Icons.calendar_month_outlined),
      ReportItem(
          id: 'att_employee',
          title: 'Employee attendance',
          icon: Icons.person_search_outlined),
      ReportItem(
          id: 'att_dept',
          title: 'Department attendance',
          icon: Icons.apartment_outlined),
      ReportItem(
          id: 'att_present',
          title: 'Present employees',
          icon: Icons.check_circle_outline),
      ReportItem(
          id: 'att_absent',
          title: 'Absent employees',
          icon: Icons.cancel_outlined),
      ReportItem(
          id: 'att_late',
          title: 'Late employees',
          icon: Icons.schedule_outlined),
      ReportItem(
          id: 'att_half',
          title: 'Half-day employees',
          icon: Icons.timelapse_outlined),
      ReportItem(
          id: 'att_hours',
          title: 'Working hours report',
          icon: Icons.timer_outlined),
    ],
  ),
  ReportCategory(
    id: 'task',
    title: 'Task Reports',
    icon: Icons.task_alt_outlined,
    items: [
      ReportItem(
          id: 'task_total',
          title: 'Total tasks',
          icon: Icons.list_alt_outlined),
      ReportItem(
          id: 'task_pending',
          title: 'Pending tasks',
          icon: Icons.pending_actions_outlined),
      ReportItem(
          id: 'task_progress',
          title: 'In-progress tasks',
          icon: Icons.autorenew_rounded),
      ReportItem(
          id: 'task_done', title: 'Completed tasks', icon: Icons.task_alt),
      ReportItem(
          id: 'task_overdue',
          title: 'Overdue tasks',
          icon: Icons.warning_amber_rounded),
      ReportItem(
          id: 'task_employee',
          title: 'Employee task report',
          icon: Icons.assignment_ind_outlined),
      ReportItem(
          id: 'task_dept',
          title: 'Department task report',
          icon: Icons.account_tree_outlined),
      ReportItem(
          id: 'task_priority',
          title: 'Tasks by priority',
          icon: Icons.flag_outlined),
      ReportItem(
          id: 'task_completion',
          title: 'Task completion report',
          icon: Icons.pie_chart_outline),
    ],
  ),
  ReportCategory(
    id: 'department',
    title: 'Department Reports',
    icon: Icons.apartment_outlined,
    items: [
      ReportItem(
          id: 'dept_total',
          title: 'Total departments',
          icon: Icons.business_outlined),
      ReportItem(
          id: 'dept_active',
          title: 'Active departments',
          icon: Icons.check_circle_outline),
      ReportItem(
          id: 'dept_inactive',
          title: 'Inactive departments',
          icon: Icons.cancel_outlined),
      ReportItem(
          id: 'dept_by_employee',
          title: 'Departments by employee count',
          icon: Icons.groups_outlined),
      ReportItem(
          id: 'dept_hierarchy',
          title: 'Department hierarchy',
          icon: Icons.account_tree_outlined),
      ReportItem(
          id: 'dept_performance',
          title: 'Department performance',
          icon: Icons.insights_outlined),
      ReportItem(
          id: 'dept_budget',
          title: 'Department budget report',
          icon: Icons.account_balance_wallet_outlined),
    ],
  ),
];

// ============================================================
// NOTIFIER
// ============================================================

class ReportsNotifier extends Notifier<ReportsState> {
  @override
  ReportsState build() {
    return const ReportsState(
      categories: kStaticReportCategories,
      expandedIds: {'employee'},
    );
  }

  void toggleCategory(String categoryId) {
    final next = Set<String>.from(state.expandedIds);
    if (next.contains(categoryId)) {
      next.remove(categoryId);
    } else {
      next.add(categoryId);
    }
    state = state.copyWith(expandedIds: next);
  }

  void selectReport(String reportId) {
    state = state.copyWith(selectedReportId: reportId);
  }

  void clearSelection() {
    state = state.copyWith(clearSelected: true);
  }
}

final reportsProvider =
NotifierProvider.autoDispose<ReportsNotifier, ReportsState>(
  ReportsNotifier.new,
);