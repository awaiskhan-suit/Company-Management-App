import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../colors/colors.dart';
import '../../providers/task_provider.dart';
import '../../providers/employee_list_provider.dart';

class AddTaskScreen extends ConsumerStatefulWidget {
  /// null = create a new task, not null = edit this task (fields pre-filled).
  final Task? task;

  const AddTaskScreen({super.key, this.task});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  bool get _isEdit => widget.task != null;

  /// Fields are built only after the provider has been filled with the
  /// task values (TextFormField reads `initialValue` only once).
  bool _ready = false;

  @override
  void initState() {
    super.initState();

    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _prefill(widget.task!);
        if (mounted) setState(() => _ready = true);
      });
    } else {
      _ready = true;
    }
  }

  // ------------------------------------------------------------
  // PRE-FILL FORM WITH EXISTING TASK VALUES
  // ------------------------------------------------------------
  void _prefill(Task t) {
    final n = ref.read(taskProvider.notifier);

    n.setTitle(t.title);
    n.setDescription(t.description);
    n.setAssignedEmployee(t.employee);

    final dept = _matchDepartment(t.department);
    if (dept != null) n.setDepartment(dept);
    if (kPriorities.contains(t.priority)) n.setPriority(t.priority);
    if (kTaskStatuses.contains(t.status)) n.setStatus(t.status);

    final start = _parseDate(t.startDate);
    final due = _parseDate(t.dueDate);
    if (start != null) n.setStartDate(start);
    if (due != null) n.setDueDate(due);

    n.setCreatedBy(t.createdBy);
    n.setComments(t.comments.join('\n'));

    // Attachment: picture name or notes text
    final attachment = t.attachments.isNotEmpty ? t.attachments.first : '';
    final isPicture = _looksLikeImage(attachment);
    n.setAttachmentIsNotes(attachment.isNotEmpty && !isPicture);
    n.setAttachmentName(attachment);
  }

  /// Matches an employee's department with the preset list (ignoring
  /// case/spaces). If it is not in the list, the employee's own text is
  /// used (the dropdown adds it as an extra item). Returns null if empty.
  String? _matchDepartment(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;

    for (final d in kDepartments) {
      if (d.toLowerCase() == value.toLowerCase()) return d;
    }
    return value;
  }

  bool _looksLikeImage(String name) {
    final lower = name.toLowerCase().split('?').first;
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp') ||
        lower.endsWith('.heic');
  }

  /// Accepts "07 Oct 2026" (format saved by the provider),
  /// ISO strings (2025-01-31) and dd/MM/yyyy.
  DateTime? _parseDate(String value) {
    final v = value.trim();
    if (v.isEmpty) return null;

    final iso = DateTime.tryParse(v);
    if (iso != null) return iso;

    // dd MMM yyyy
    const months = [
      'jan', 'feb', 'mar', 'apr', 'may', 'jun',
      'jul', 'aug', 'sep', 'oct', 'nov', 'dec'
    ];
    final words = v.split(RegExp(r'\s+'));
    if (words.length == 3) {
      final d = int.tryParse(words[0]);
      final m = months.indexOf(words[1].toLowerCase());
      final y = int.tryParse(words[2]);
      if (d != null && m != -1 && y != null) return DateTime(y, m + 1, d);
    }

    // dd/MM/yyyy
    final parts = v.split('/');
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d != null && m != null && y != null) return DateTime(y, m, d);
    }
    return null;
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------
  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.navy,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) onPicked(picked);
  }

  String _fmt(DateTime? d) {
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  Future<void> _pickImage() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file != null) {
        ref.read(taskProvider.notifier).setAttachmentName(file.name);
        ref.read(taskProvider.notifier).setAttachmentIsNotes(false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // In edit mode the task id is passed so the provider can update
    // the existing task instead of creating a new one.
    final ok = await ref
        .read(taskProvider.notifier)
        .submit(editId: widget.task?.id);
    if (!mounted) return;

    final state = ref.read(taskProvider);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Task updated successfully'
                : 'Task created successfully',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else if (state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage!),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskProvider);
    final notifier = ref.read(taskProvider.notifier);
    final asyncEmployees = ref.watch(employeeListProvider);

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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEdit ? 'Edit Task' : 'Create Task',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
            children: [
              // ===== Task Information =====
              const _SectionHeader(
                title: 'Task Information',
                icon: Icons.task_alt_outlined,
              ),
              SizedBox(height: 14.h),

              const _FieldLabel('Task ID'),
              _ReadOnlyBox(
                value: _isEdit ? widget.task!.taskId : state.taskId,
                icon: Icons.tag,
              ),

              SizedBox(height: 14.h),
              const _FieldLabel('Task Title *'),
              _RoundedField(
                initialValue: state.title,
                hint: 'Enter task title',
                icon: Icons.title,
                onChanged: notifier.setTitle,
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),

              SizedBox(height: 14.h),
              const _FieldLabel('Task Description'),
              _RoundedField(
                initialValue: state.description,
                hint: 'Describe the task',
                icon: Icons.description_outlined,
                maxLines: 3,
                onChanged: notifier.setDescription,
              ),

              // ★★★ ASSIGNED EMPLOYEE – real employees from Add Employee ★★★
              SizedBox(height: 14.h),
              const _FieldLabel('Assigned Employee *'),
              asyncEmployees.when(
                loading: () =>
                const _LoadingDropdown(hint: 'Loading employees...'),
                error: (_, __) => _RoundedField(
                  initialValue: state.assignedEmployee ?? '',
                  hint: 'Enter employee name',
                  icon: Icons.person_outline,
                  onChanged: (v) => notifier.setAssignedEmployee(v),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                data: (employees) {
                  final names = employees
                      .map((e) => e.name)
                      .where((name) => name.trim().isNotEmpty)
                      .toSet()
                      .toList()
                    ..sort();

                  final currentValue = state.assignedEmployee;
                  final safeValue =
                  names.contains(currentValue) ? currentValue : null;

                  return _DropdownField<String>(
                    value: safeValue,
                    hint: names.isEmpty
                        ? 'No employees found'
                        : 'Select employee',
                    icon: Icons.person_outline,
                    items: names,
                    onChanged: (v) {
                      notifier.setAssignedEmployee(v);

                      // ★ Auto-select the employee's department
                      if (v == null) return;
                      for (final e in employees) {
                        if (e.name == v) {
                          final dept = _matchDepartment(e.department);
                          if (dept != null) notifier.setDepartment(dept);
                          break;
                        }
                      }
                    },
                  );
                },
              ),

              SizedBox(height: 14.h),
              const _FieldLabel('Department *'),
              KeyedSubtree(
                key: ValueKey('dept_${state.department}'),
                child: _DropdownField<String>(
                  value: state.department,
                  hint: 'Select department',
                  icon: Icons.account_tree_outlined,
                  items: [
                    ...kDepartments,
                    // employee department that is not in the preset list
                    if (state.department != null &&
                        state.department!.isNotEmpty &&
                        !kDepartments.contains(state.department))
                      state.department!,
                  ],
                  onChanged: notifier.setDepartment,
                ),
              ),

              SizedBox(height: 14.h),
              const _FieldLabel('Priority *'),
              _DropdownField<String>(
                value: state.priority,
                hint: 'Select priority',
                icon: Icons.flag_outlined,
                items: kPriorities,
                onChanged: (v) {
                  if (v != null) notifier.setPriority(v);
                },
              ),

              SizedBox(height: 14.h),
              const _FieldLabel('Start Date *'),
              _DateField(
                value: _fmt(state.startDate),
                hint: 'Select start date',
                onTap: () => _pickDate(
                  current: state.startDate ?? DateTime.now(),
                  onPicked: notifier.setStartDate,
                ),
              ),

              SizedBox(height: 14.h),
              const _FieldLabel('Due Date *'),
              _DateField(
                value: _fmt(state.dueDate),
                hint: 'Select due date',
                onTap: () => _pickDate(
                  current: state.dueDate ?? DateTime.now(),
                  onPicked: notifier.setDueDate,
                ),
              ),

              SizedBox(height: 14.h),
              const _FieldLabel('Task Status *'),
              _DropdownField<String>(
                value: state.status,
                hint: 'Select status',
                icon: Icons.timelapse_outlined,
                items: kTaskStatuses,
                onChanged: (v) {
                  if (v != null) notifier.setStatus(v);
                },
              ),

              // ★★★ CREATED BY – fully editable ★★★
              SizedBox(height: 14.h),
              const _FieldLabel('Created By *'),
              _RoundedField(
                initialValue: state.createdBy,
                hint: 'Enter your name',
                icon: Icons.person_outline,
                onChanged: notifier.setCreatedBy,
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),

              SizedBox(height: 14.h),
              const _FieldLabel('Created Date'),
              _ReadOnlyBox(
                value: _fmt(state.createdDate),
                icon: Icons.calendar_today_outlined,
              ),

              // ★★★ ATTACHMENT – Picture OR Notes only ★★★
              SizedBox(height: 14.h),
              const _FieldLabel('Attachment (Picture or Notes)'),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Picture'),
                      selected: !state.attachmentIsNotes,
                      selectedColor: AppColors.blue.withOpacity(0.18),
                      labelStyle: TextStyle(
                        color: !state.attachmentIsNotes
                            ? AppColors.blue
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                      onSelected: (_) {
                        notifier.setAttachmentIsNotes(false);
                      },
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Notes only'),
                      selected: state.attachmentIsNotes,
                      selectedColor: AppColors.blue.withOpacity(0.18),
                      labelStyle: TextStyle(
                        color: state.attachmentIsNotes
                            ? AppColors.blue
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                      onSelected: (_) {
                        notifier.setAttachmentIsNotes(true);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              if (!state.attachmentIsNotes) ...[
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.image_outlined, size: 20.sp),
                  label: Text(
                    state.attachmentName.isEmpty
                        ? 'Choose Picture'
                        : state.attachmentName,
                    style: TextStyle(fontSize: 13.sp),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50.h),
                    foregroundColor: AppColors.blue,
                    side: BorderSide(color: AppColors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                ),
              ] else ...[
                _RoundedField(
                  initialValue: state.attachmentName,
                  hint: 'Write notes (saved as attachment)',
                  icon: Icons.notes_rounded,
                  maxLines: 3,
                  onChanged: notifier.setAttachmentName,
                ),
              ],

              SizedBox(height: 14.h),
              const _FieldLabel('Comments / Notes'),
              _RoundedField(
                initialValue: state.comments,
                hint: 'Additional notes',
                icon: Icons.comment_outlined,
                maxLines: 3,
                onChanged: notifier.setComments,
              ),

              SizedBox(height: 28.h),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 54.h,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14.r),
                    gradient: AppColors.ctaGradient,
                  ),
                  child: ElevatedButton(
                    onPressed: state.isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: state.isSubmitting
                        ? SizedBox(
                      height: 22.w,
                      width: 22.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor:
                        AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                        : Text(
                      _isEdit ? 'Update Task' : 'Create Task',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// UI HELPERS
// ============================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 36.w,
          width: 36.w,
          decoration: BoxDecoration(
            color: AppColors.blue.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: AppColors.blue, size: 18.sp),
        ),
        SizedBox(width: 10.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.navy,
          fontSize: 13.sp,
        ),
      ),
    );
  }
}

class _ReadOnlyBox extends StatelessWidget {
  const _ReadOnlyBox({required this.value, required this.icon});
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2F6),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: AppColors.textMuted),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
          ),
          Icon(Icons.lock_outline, size: 16.sp, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}

class _RoundedField extends StatelessWidget {
  const _RoundedField({
    required this.hint,
    required this.icon,
    required this.onChanged,
    this.initialValue,
    this.validator,
    this.maxLines = 1,
  });

  final String? initialValue;
  final String hint;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final String? Function(String?)? validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      style: TextStyle(color: AppColors.navy, fontSize: 15.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14.sp),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20.sp),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: AppColors.blue, width: 1.6.w),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.redAccent, width: 1.4.w),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.redAccent, width: 1.6.w),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.value,
    required this.hint,
    required this.onTap,
  });

  final String value;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: InputDecorator(
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.calendar_today_outlined,
            color: AppColors.textMuted,
            size: 20.sp,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
          EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Text(
          value.isEmpty ? hint : value,
          style: TextStyle(
            color: value.isEmpty ? AppColors.textMuted : AppColors.navy,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onChanged,
  });

  final T? value;
  final String hint;
  final IconData icon;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.textMuted,
        size: 24.sp,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20.sp),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: AppColors.blue, width: 1.6.w),
        ),
      ),
      hint: Text(
        hint,
        style: TextStyle(color: AppColors.textMuted, fontSize: 14.sp),
      ),
      items: items
          .map(
            (e) => DropdownMenuItem<T>(
          value: e,
          child: Text(
            e.toString(),
            style: TextStyle(color: AppColors.navy, fontSize: 15.sp),
          ),
        ),
      )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _LoadingDropdown extends StatelessWidget {
  const _LoadingDropdown({required this.hint});
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.person_outline, color: AppColors.textMuted, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              hint,
              style: TextStyle(color: AppColors.textMuted, fontSize: 14.sp),
            ),
          ),
          SizedBox(
            width: 18.w,
            height: 18.w,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    );
  }
}