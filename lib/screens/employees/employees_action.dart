import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../colors/colors.dart';
import '../../providers/employee_list_provider.dart';
import 'edit_employee_screen.dart';
import 'employee_detail_screen.dart';


void showEmployeeSnack(BuildContext context, String text, {Color? color}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: color ?? Colors.orange,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Opens the employee details screen.
/// Viewing still works offline (cached data).
Future<void> openEmployeeDetails(
    BuildContext context,
    WidgetRef ref,
    Employee employee,
    ) async {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EmployeeDetailsScreen(employee: employee),
    ),
  );
}

/// Opens the Edit Employee form.
/// Internet is required for BOTH local and API employees.
Future<void> openEmployeeEdit(
    BuildContext context,
    WidgetRef ref,
    Employee employee,
    ) async {
  final online = await ref.read(employeeListProvider.notifier).isOnline();
  if (!context.mounted) return;

  if (!online) {
    showEmployeeSnack(
      context,
      'Internet required to edit employees',
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EditEmployeeScreen(employee: employee),
    ),
  );
}

/// Asks for confirmation, then deletes.
/// Internet is required for BOTH local and API employees.
Future<bool> confirmDeleteEmployee(
    BuildContext context,
    WidgetRef ref,
    Employee employee,
    ) async {
  final online = await ref.read(employeeListProvider.notifier).isOnline();
  if (!context.mounted) return false;

  if (!online) {
    showEmployeeSnack(context, 'Internet required to delete employees');
    return false;
  }

  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      title: Text(
        'Delete Employee',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 17.sp,
          color: AppColors.textPrimary,
        ),
      ),
      content: Text(
        'Do you want to delete "${employee.name}"?\nThis action cannot be undone.',
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

  try {
    await ref.read(employeeListProvider.notifier).deleteEmployee(employee);
    if (!context.mounted) return false;

    showEmployeeSnack(
      context,
      '${employee.name} deleted successfully',
      color: Colors.redAccent,
    );
    return true;
  } catch (e) {
    if (!context.mounted) return false;
    final msg = e.toString().replaceFirst('Exception: ', '');
    showEmployeeSnack(
      context,
      'Delete failed: $msg',
      color: Colors.redAccent,
    );
    return false;
  }
}

