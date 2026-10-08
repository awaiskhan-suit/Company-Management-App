import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../colors/colors.dart';
import '../../providers/department_provider.dart';
import 'add_department_screen.dart';

// Shared by the department list and the department details screens.
// Editing and deleting both need internet: without it, nothing happens
// except a message.

void showDepartmentSnack(BuildContext context, String text, {Color? color}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: color ?? Colors.orange,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Opens the Add / Edit form. Edit is blocked while offline.
Future<void> openDepartmentForm(
    BuildContext context,
    WidgetRef ref, {
      Department? department,
    }) async {
  final online =
  await ref.read(departmentNotifierProvider.notifier).isOnline();
  if (!context.mounted) return;

  if (!online) {
    showDepartmentSnack(
      context,
      department == null
          ? 'Internet required to add departments'
          : 'Internet required to edit departments',
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AddDepartmentScreen(department: department),
    ),
  );
}

/// Asks for confirmation, then deletes through the API.
/// Returns true only when the department was really deleted.
/// Offline: shows a message and deletes nothing.
Future<bool> confirmDeleteDepartment(
    BuildContext context,
    WidgetRef ref,
    Department department,
    ) async {
  final online =
  await ref.read(departmentNotifierProvider.notifier).isOnline();
  if (!context.mounted) return false;

  if (!online) {
    showDepartmentSnack(context, 'Internet required to delete departments');
    return false;
  }

  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      title: Text(
        'Delete Department',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 17.sp,
          color: AppColors.textPrimary,
        ),
      ),
      content: Text(
        'Do you want to delete "${department.name}"?\nThis action cannot be undone.',
        style: TextStyle(
          fontSize: 13.sp,
          color: AppColors.textMuted,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            'No',
            style: TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            'Yes, Delete',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w700,
              fontSize: 14.sp,
            ),
          ),
        ),
      ],
    ),
  );

  if (confirm != true) return false;

  final ok = await ref
      .read(departmentNotifierProvider.notifier)
      .deleteDepartment(department.id);
  if (!context.mounted) return false;

  if (ok) {
    showDepartmentSnack(
      context,
      '${department.name} deleted successfully',
      color: Colors.redAccent,
    );
    return true;
  }

  final err = ref.read(departmentNotifierProvider).error;
  final msg = err?.toString().replaceFirst('Exception: ', '') ??
      'Something went wrong';
  showDepartmentSnack(context, 'Delete failed: $msg', color: Colors.redAccent);
  return false;
}

