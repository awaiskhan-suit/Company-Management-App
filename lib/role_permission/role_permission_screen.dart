import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../colors/colors.dart';
import '../../providers/role_permission_provider.dart';

class RolePermissionScreen extends ConsumerStatefulWidget {
  const RolePermissionScreen({super.key});

  @override
  ConsumerState<RolePermissionScreen> createState() =>
      _RolePermissionScreenState();
}

class _RolePermissionScreenState extends ConsumerState<RolePermissionScreen> {
  final _formKey = GlobalKey<FormState>();

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await ref.read(rolePermissionProvider.notifier).submit();
    if (!mounted) return;

    final state = ref.read(rolePermissionProvider);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User "${state.name}" saved as ${state.role}',
          ),
        ),
      );
      Navigator.pop(context);
    } else if (state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rolePermissionProvider);
    final notifier = ref.read(rolePermissionProvider.notifier);

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
          'Roles & Permissions',
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
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
            children: [
              // Header card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assign Role',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Create a user and select their access level',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5.sp,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 22.h),

              const _FieldLabel('Full Name'),
              _RoundedField(
                initialValue: state.name,
                hint: 'Enter full name',
                icon: Icons.person_outline,
                onChanged: notifier.setName,
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),

              SizedBox(height: 14.h),
              const _FieldLabel('Email'),
              _RoundedField(
                initialValue: state.email,
                hint: 'name@company.com',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                onChanged: notifier.setEmail,
                validator: (v) {
                  final email = v?.trim() ?? '';
                  if (email.isEmpty) return 'Required';
                  if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$')
                      .hasMatch(email)) {
                    return 'Invalid email';
                  }
                  return null;
                },
              ),

              SizedBox(height: 14.h),
              const _FieldLabel('Password'),
              _RoundedField(
                initialValue: state.password,
                hint: 'Min. 8 characters',
                icon: Icons.lock_outline,
                obscureText: state.obscurePassword,
                onChanged: notifier.setPassword,
                validator: (v) {
                  if (v == null || v.length < 8) {
                    return 'Min. 8 characters';
                  }
                  return null;
                },
                suffixIcon: IconButton(
                  icon: Icon(
                    state.obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textMuted,
                    size: 20.sp,
                  ),
                  onPressed: notifier.toggleObscurePassword,
                ),
              ),

              SizedBox(height: 14.h),
              const _FieldLabel('Select Role'),
              _DropdownField<String>(
                value: state.role,
                hint: 'Choose role',
                icon: Icons.admin_panel_settings_outlined,
                items: kAppRoles,
                onChanged: notifier.setRole,
              ),

              // Role hint chips
              SizedBox(height: 12.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: kAppRoles.map((r) {
                  final selected = state.role == r;
                  return GestureDetector(
                    onTap: () => notifier.setRole(r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.blue.withOpacity(0.15)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: selected ? AppColors.blue : AppColors.border,
                        ),
                      ),
                      child: Text(
                        r,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                          color:
                          selected ? AppColors.blue : AppColors.textMuted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              SizedBox(height: 32.h),

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
                      'Save Role',
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
// UI helpers
// ============================================================

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

class _RoundedField extends StatelessWidget {
  const _RoundedField({
    required this.hint,
    required this.icon,
    required this.onChanged,
    this.initialValue,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  final String? initialValue;
  final String hint;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      style: TextStyle(color: AppColors.navy, fontSize: 15.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14.sp),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20.sp),
        suffixIcon: suffixIcon,
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