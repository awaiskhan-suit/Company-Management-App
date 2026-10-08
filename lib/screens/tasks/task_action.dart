// lib/screens/tasks/task_action.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../colors/colors.dart';
import '../../providers/task_provider.dart';
import 'add_task_screen.dart';

// ============================================================
// SHARED SNACK
// ============================================================

void showTaskSnack(BuildContext context, String text, {Color? color}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: color ?? Colors.orange,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// ============================================================
// OPEN ADD / EDIT TASK
// ============================================================

/// Opens the Create / Edit Task form.
/// When [task] is passed, the form opens in Edit mode with all fields
/// pre-filled with the task's saved values.
/// Internet is required.
Future<void> openTaskForm(
    BuildContext context,
    WidgetRef ref, {
      Task? task, // null = Add, not null = Edit
    }) async {
  final online = await ref.read(taskListProvider.notifier).isOnline();
  if (!context.mounted) return;

  if (!online) {
    showTaskSnack(
      context,
      task == null
          ? 'Internet required to add tasks'
          : 'Internet required to edit tasks',
    );
    return;
  }

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AddTaskScreen(task: task),
    ),
  );

  // Refresh the list so the edited / new task shows up-to-date values.
  ref.read(taskListProvider.notifier).refresh();
}

// ============================================================
// CONFIRM + DELETE TASK
// ============================================================

/// Asks for confirmation, then deletes the task through the API.
/// Returns true only when the task was really deleted.
/// Offline → shows message and deletes nothing.
Future<bool> confirmDeleteTask(
    BuildContext context,
    WidgetRef ref,
    Task task,
    ) async {
  final online = await ref.read(taskListProvider.notifier).isOnline();
  if (!context.mounted) return false;

  if (!online) {
    showTaskSnack(context, 'Internet required to delete tasks');
    return false;
  }

  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      title: Text(
        'Delete Task',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 17.sp,
          color: AppColors.textPrimary,
        ),
      ),
      content: Text(
        'Do you want to delete "${task.title}"?\nThis action cannot be undone.',
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
    await ref.read(taskListProvider.notifier).deleteTask(task.id);

    if (!context.mounted) return false;

    showTaskSnack(
      context,
      '${task.title} deleted successfully',
      color: Colors.redAccent,
    );
    return true;
  } catch (e) {
    if (!context.mounted) return false;

    final msg = e.toString().replaceFirst('Exception: ', '');
    showTaskSnack(
      context,
      'Delete failed: $msg',
      color: Colors.redAccent,
    );
    return false;
  }
}