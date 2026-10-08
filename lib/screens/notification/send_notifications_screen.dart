import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../colors/colors.dart';
import '../../providers/employee_list_provider.dart';
import '../../providers/send_notification_provider.dart';

class SendNotificationScreen extends ConsumerStatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  ConsumerState<SendNotificationScreen> createState() =>
      _SendNotificationScreenState();
}

class _SendNotificationScreenState
    extends ConsumerState<SendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();

  // ★ FIXED: no parameter
  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await ref.read(sendNotificationProvider.notifier).submit();
    if (!mounted) return;

    final state = ref.read(sendNotificationProvider);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification added successfully'),
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sendNotificationProvider);
    final notifier = ref.read(sendNotificationProvider.notifier);
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
          icon:
          Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Notification',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
            children: [
              const _SectionHeader(
                title: 'Notification Details',
                icon: Icons.notifications_active_outlined,
              ),
              SizedBox(height: 14.h),

              // ===== Employee =====
              const _FieldLabel('Employee *'),
              asyncEmployees.when(
                loading: () =>
                const _LoadingBox(hint: 'Loading employees...'),
                error: (_, __) => _ErrorBox(
                  message: 'Could not load employees',
                  onRetry: () => ref.invalidate(employeeListProvider),
                ),
                data: (employees) {
                  final names = employees
                      .map((e) => e.name)
                      .where((name) => name.trim().isNotEmpty)
                      .toSet()
                      .toList()
                    ..sort();

                  final current = state.employeeName;
                  final safeValue =
                  names.contains(current) ? current : null;

                  return _DropdownField<String>(
                    value: safeValue,
                    hint: names.isEmpty
                        ? 'No employees found'
                        : 'Select employee',
                    icon: Icons.person_outline,
                    items: names,
                    validator: (v) =>
                    (v == null || v.isEmpty) ? 'Select an employee' : null,
                    onChanged: (v) {
                      if (v == null) return;

                      String dept = '';
                      for (final e in employees) {
                        if (e.name == v) {
                          dept = e.department.toString().trim();
                          break;
                        }
                      }
                      notifier.setEmployee(v, dept);
                    },
                  );
                },
              ),

              // ===== Department (auto-filled) =====
              SizedBox(height: 14.h),
              const _FieldLabel('Department'),
              _ReadOnlyBox(
                value: state.department,
                placeholder: 'Auto-selected from employee',
                icon: Icons.account_tree_outlined,
              ),

              // ===== Description =====
              SizedBox(height: 14.h),
              const _FieldLabel('Description *'),
              _RoundedField(
                hint: 'Write description, complaint or any note...',
                icon: Icons.description_outlined,
                maxLines: 6,
                maxLength: 500,
                onChanged: notifier.setDescription,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Description is required'
                    : null,
              ),

              SizedBox(height: 28.h),

              // ===== Submit =====
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
                      'Add Notification',
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
  const _ReadOnlyBox({
    required this.value,
    required this.placeholder,
    required this.icon,
  });

  final String value;
  final String placeholder;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final empty = value.trim().isEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 15.h),
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
              empty ? placeholder : value,
              style: TextStyle(
                fontSize: empty ? 14.sp : 15.sp,
                fontWeight: empty ? FontWeight.w400 : FontWeight.w600,
                color: empty ? AppColors.textMuted : AppColors.navy,
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
    this.validator,
    this.maxLines = 1,
    this.maxLength,
  });

  final String hint;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final String? Function(String?)? validator;
  final int maxLines;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      onChanged: onChanged,
      style: TextStyle(color: AppColors.navy, fontSize: 15.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14.sp),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20.sp),
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

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  final T? value;
  final String hint;
  final IconData icon;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      validator: validator,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.textMuted,
        size: 24.sp,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20.sp),
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

class _LoadingBox extends StatelessWidget {
  const _LoadingBox({required this.hint});
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

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.redAccent, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.redAccent, fontSize: 13.sp),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: TextStyle(
                color: AppColors.blue,
                fontWeight: FontWeight.w700,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}