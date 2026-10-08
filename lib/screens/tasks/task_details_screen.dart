import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../colors/colors.dart';
import '../../providers/task_provider.dart';
import '../../services/api_client.dart';
import 'add_task_screen.dart';
import 'task_action.dart';

// =============================================================
// TASK SCREEN (List) - Filter by Department only (chips row)
// =============================================================

class TotalTask extends ConsumerStatefulWidget {
  const TotalTask({super.key});

  @override
  ConsumerState<TotalTask> createState() => _TaskScreenState();
}

class _TaskScreenState extends ConsumerState<TotalTask> {
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _departments = [
    'All',
    'IT',
    'HR',
    'Finance',
    'Operations',
    'Marketing',
    'Sales',
    'Design',
  ];

  String selectedDepartment = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Task> _filter(List<Task> tasks) {
    final search = _searchController.text.toLowerCase().trim();

    return tasks.where((task) {
      final matchesSearch = task.title.toLowerCase().contains(search) ||
          task.taskId.toLowerCase().contains(search) ||
          task.employee.toLowerCase().contains(search);

      final matchesDepartment =
          selectedDepartment == 'All' || task.department == selectedDepartment;

      return matchesSearch && matchesDepartment;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final asyncTasks = ref.watch(taskListProvider);
    final counts = _countByDepartment(asyncTasks.value ?? const <Task>[]);

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
          'Tasks Report',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white, size: 24.sp),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.read(taskListProvider.notifier).refresh(),
            icon: Icon(Icons.refresh_rounded, size: 22.sp),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          ).then((_) {
            ref.read(taskListProvider.notifier).refresh();
          });
        },
        backgroundColor: AppColors.blue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Task',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(counts),
          Expanded(
            child: asyncTasks.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _ErrorView(
                message: ApiException.from(err).message,
                onRetry: () => ref.read(taskListProvider.notifier).refresh(),
              ),
              data: (allTasks) {
                final tasksToShow = _filter(allTasks);

                if (tasksToShow.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(taskListProvider.notifier).refresh(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: 120.h),
                        _buildEmptyState(),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(taskListProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 90.h),
                    itemCount: tasksToShow.length,
                    itemBuilder: (context, index) {
                      final task = tasksToShow[index];
                      return _SlideInAnimation(
                        key: ValueKey(task.taskId),
                        index: index,
                        child: _TaskCard(
                          task: task,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TaskDetailsScreen(task: task),
                              ),
                            );
                          },
                          onEdit: () => openTaskForm(context, ref, task: task),
                          onDelete: () => confirmDeleteTask(context, ref, task),
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

  // ===================== TASK COUNT PER DEPARTMENT =====================
  Map<String, int> _countByDepartment(List<Task> tasks) {
    final counts = <String, int>{'All': tasks.length};
    for (final dept in _departments) {
      if (dept == 'All') continue;
      counts[dept] = tasks.where((t) => t.department == dept).length;
    }
    return counts;
  }

  // ===================== SEARCH + DEPARTMENT CHIPS =====================
  Widget _buildSearchAndFilters(Map<String, int> counts) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search task, ID or employee...',
              hintStyle:
              TextStyle(fontSize: 14.sp, color: AppColors.textMuted),
              prefixIcon: Icon(Icons.search_rounded, size: 22.sp),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: Icon(Icons.clear_rounded, size: 20.sp),
              )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 15.h),
            ),
          ),
          SizedBox(height: 12.h),

          // Department filter as a horizontal row of chips
          SizedBox(
            height: 40.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _departments.length,
              separatorBuilder: (_, __) => SizedBox(width: 8.w),
              itemBuilder: (context, index) {
                final dept = _departments[index];
                final selected = dept == selectedDepartment;

                final count = counts[dept] ?? 0;

                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(dept),
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 7.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withOpacity(0.25)
                              : AppColors.blue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color:
                            selected ? Colors.white : AppColors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  selected: selected,
                  showCheckmark: false,
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.blue,
                  side: BorderSide(
                    color: selected ? AppColors.blue : Colors.grey.shade300,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  labelStyle: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                  onSelected: (_) {
                    setState(() => selectedDepartment = dept);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.task_alt_rounded,
            size: 70.sp,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 14.h),
          Text(
            'No tasks found',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Try changing your search or department filter.',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// ERROR VIEW
// =============================================================

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
            Icon(Icons.wifi_off_rounded, size: 60.sp, color: Colors.orange),
            SizedBox(height: 16.h),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, color: AppColors.textMuted),
            ),
            SizedBox(height: 18.h),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// SLIDE-IN ANIMATION
// =============================================================

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

// =============================================================
// TASK CARD (with Edit + Delete)
// =============================================================

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  Color _priorityColor() {
    switch (task.priority) {
      case 'Urgent':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  Color _statusColor() {
    switch (task.status) {
      case 'Completed':
        return Colors.green;
      case 'In Progress':
        return AppColors.blue;
      case 'Overdue':
        return Colors.red;
      case 'Cancelled':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor();
    final statusColor = _statusColor();

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            task.taskId,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildBadge(task.priority, priorityColor),
                  ],
                ),
                SizedBox(height: 16.h),
                _infoRow(Icons.person_outline_rounded, 'Assigned', task.employee),
                SizedBox(height: 9.h),
                _infoRow(Icons.business_outlined, 'Department', task.department),
                SizedBox(height: 9.h),
                _infoRow(Icons.calendar_today_outlined, 'Due', task.dueDate),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    _buildBadge(task.status, statusColor),
                  ],
                ),

                SizedBox(height: 16.h),

                // ---------- EDIT / DELETE BUTTONS ----------
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
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: AppColors.blue),
        SizedBox(width: 9.w),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.textMuted,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// =============================================================
// TASK DETAILS SCREEN (with Edit + Delete)
// =============================================================

class TaskDetailsScreen extends ConsumerWidget {
  final Task task;

  const TaskDetailsScreen({
    super.key,
    required this.task,
  });

  Color _priorityColor() {
    switch (task.priority) {
      case 'Urgent':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  Color _statusColor() {
    switch (task.status) {
      case 'Completed':
        return Colors.green;
      case 'In Progress':
        return AppColors.blue;
      case 'Overdue':
        return Colors.red;
      case 'Cancelled':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  bool _isImage(String name) {
    final lower = name.toLowerCase().split('?').first;
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp') ||
        lower.endsWith('.heic');
  }

  void _openAttachment(BuildContext context, String file) {
    if (_isImage(file)) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _ImageViewerScreen(source: file)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Preview is available for pictures only'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor();

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
          'Task Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white, size: 24.sp),
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: () => openTaskForm(context, ref, task: task),
            icon: Icon(Icons.edit_outlined, color: Colors.white, size: 22.sp),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: () async {
              final deleted = await confirmDeleteTask(context, ref, task);
              if (deleted && context.mounted) Navigator.pop(context);
            },
            icon: Icon(Icons.delete_outline, color: Colors.white, size: 22.sp),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 21.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _badge(task.priority, _priorityColor()),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  task.taskId,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          _detailsSection(
            title: 'Task Information',
            icon: Icons.info_outline_rounded,
            children: [
              _detailRow('Description', task.description),
              _detailRow('Assigned Employee', task.employee),
              _detailRow('Department', task.department),
              _detailRow('Start Date', task.startDate),
              _detailRow('Due Date', task.dueDate),
              _detailRow('Status', task.status, valueColor: statusColor),
              _detailRow('Estimated Hours', task.estimatedHours),
              _detailRow('Created By', task.createdBy),
            ],
          ),
          SizedBox(height: 16.h),
          _detailsSection(
            title: 'Comments',
            icon: Icons.comment_outlined,
            children: task.comments.isEmpty
                ? [
              Text(
                'No comments yet.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13.sp,
                ),
              ),
            ]
                : task.comments
                .map((comment) => _bulletItem(
              comment,
              Icons.chat_bubble_outline_rounded,
            ))
                .toList(),
          ),
          SizedBox(height: 16.h),
          _detailsSection(
            title: 'Attachments',
            icon: Icons.attach_file_rounded,
            children: task.attachments.isEmpty
                ? [
              Text(
                'No attachments.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13.sp,
                ),
              ),
            ]
                : task.attachments.map((file) {
              final isImage = _isImage(file);
              return Container(
                margin: EdgeInsets.only(bottom: 9.h),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10.r),
                    onTap: () => _openAttachment(context, file),
                    child: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Row(
                        children: [
                          Icon(
                            isImage
                                ? Icons.image_outlined
                                : Icons.insert_drive_file_outlined,
                            color: AppColors.blue,
                            size: 22.sp,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              file,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                          Icon(
                            isImage
                                ? Icons.visibility_outlined
                                : Icons.insert_drive_file_outlined,
                            size: 20.sp,
                            color: AppColors.blue,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 16.h),
          _detailsSection(
            title: 'Activity History',
            icon: Icons.history_rounded,
            children: task.activityHistory
                .map((activity) => _bulletItem(activity, Icons.circle))
                .toList(),
          ),

          SizedBox(height: 24.h),

          // ---------- BOTTOM EDIT / DELETE BUTTONS ----------
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => openTaskForm(context, ref, task: task),
                  icon: Icon(Icons.edit_outlined, size: 18.sp),
                  label: Text(
                    'Edit',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blue,
                    side: BorderSide(color: AppColors.blue),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final deleted = await confirmDeleteTask(context, ref, task);
                    if (deleted && context.mounted) Navigator.pop(context);
                  },
                  icon: Icon(Icons.delete_outline, size: 18.sp),
                  label: Text(
                    'Delete',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  Widget _detailsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(17.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.blue, size: 21.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 15.h),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 13.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletItem(String text, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 11.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: icon == Icons.circle ? 8.sp : 18.sp,
            color: AppColors.blue,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// =============================================================
// FULL-SCREEN IMAGE VIEWER (pinch to zoom)
// =============================================================

class _ImageViewerScreen extends StatelessWidget {
  const _ImageViewerScreen({required this.source});

  /// Can be a network URL (http/https), a local file path, or just a file name.
  final String source;

  bool get _isNetwork =>
      source.startsWith('http://') || source.startsWith('https://');

  Widget _fallback() {
    return Padding(
      padding: EdgeInsets.all(28.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64.sp),
          SizedBox(height: 14.h),
          Text(
            'Picture could not be loaded',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            source,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (_isNetwork) {
      return Image.network(
        source,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    final file = File(source);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    return _fallback();
  }

  @override
  Widget build(BuildContext context) {
    final name = source.split('/').last;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          name,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white, fontSize: 15.sp),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5,
          child: _buildImage(),
        ),
      ),
    );
  }
}