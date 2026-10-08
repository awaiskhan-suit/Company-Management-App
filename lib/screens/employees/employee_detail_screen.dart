import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../colors/colors.dart';
import '../../providers/employee_list_provider.dart';
import 'employees_action.dart';

class EmployeeDetailsScreen extends ConsumerWidget {
  const EmployeeDetailsScreen({super.key, required this.employee});

  final Employee employee;

  Color _statusColorOf(Employee e) {
    if (e.status == 'Active') return AppColors.success;
    if (e.status == 'On Leave') return const Color(0xFFF5A623);
    return Colors.red;
  }

  Future<void> _deleteAndClose(
      BuildContext context,
      WidgetRef ref,
      Employee emp,
      ) async {
    final deleted = await confirmDeleteEmployee(context, ref, emp);
    if (deleted && context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emp = ref.watch(employeeListProvider).maybeWhen(
      data: (list) => list.firstWhere(
            (e) => e.id == employee.id,
        orElse: () => employee,
      ),
      orElse: () => employee,
    );

    final bool isApi = emp.isApiEmployee;
    final statusColor = _statusColorOf(emp);

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
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24.sp),
        ),
        title: Text(
          'Employee Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: () => openEmployeeEdit(context, ref, emp),
            icon: Icon(Icons.edit_outlined, color: Colors.white, size: 22.sp),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: () => _deleteAndClose(context, ref, emp),
            icon: Icon(Icons.delete_outline, color: Colors.white, size: 22.sp),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // ===== HEADER =====
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _EmployeeImage(
                    imagePath: emp.imagePath,
                    size: 100.w,
                    radius: 18.r,
                    iconSize: 55.sp,
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    emp.name,
                    style: TextStyle(
                      fontSize: 21.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    emp.designation,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: AppColors.blue.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          emp.id,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blue,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          emp.status,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 14.h),

            // ===== PERSONAL =====
            _DetailSection(
              title: 'Personal Information',
              children: [
                _DetailRow(icon: Icons.badge_rounded, title: 'Employee ID', value: emp.id),
                _DetailRow(icon: Icons.person_outline_rounded, title: 'Full Name', value: emp.name),
                _DetailRow(icon: Icons.family_restroom_rounded, title: 'Father / Guardian', value: emp.fatherName),
                _DetailRow(icon: Icons.cake_outlined, title: 'Date of Birth', value: emp.dateOfBirth),
                _DetailRow(icon: Icons.wc_outlined, title: 'Gender', value: emp.gender),
                _DetailRow(icon: Icons.credit_card_outlined, title: 'CNIC', value: emp.cnic),
                _DetailRow(icon: Icons.phone_rounded, title: 'Phone', value: emp.phone),
                _DetailRow(icon: Icons.email_rounded, title: 'Email', value: emp.email),
                _DetailRow(icon: Icons.home_outlined, title: 'Address', value: emp.address),
                _DetailRow(icon: Icons.location_city_outlined, title: 'City', value: emp.city, showDivider: false),
              ],
            ),

            SizedBox(height: 14.h),

            // ===== JOB =====
            _DetailSection(
              title: 'Job Information',
              children: [
                _DetailRow(icon: Icons.account_tree_outlined, title: 'Department', value: emp.department),
                _DetailRow(icon: Icons.work_outline_rounded, title: 'Designation', value: emp.designation),
                _DetailRow(icon: Icons.admin_panel_settings_outlined, title: 'Role', value: emp.role),
                _DetailRow(icon: Icons.supervisor_account_outlined, title: 'Manager', value: emp.manager),
                _DetailRow(icon: Icons.calendar_month_rounded, title: 'Joining Date', value: emp.joiningDate),
                _DetailRow(icon: Icons.business_center_outlined, title: 'Employment Type', value: emp.employmentType),
                _DetailRow(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Status',
                  value: emp.status,
                  valueColor: statusColor,
                  showDivider: false,
                ),
              ],
            ),

            SizedBox(height: 14.h),

            // ===== COMPANY =====
            _DetailSection(
              title: 'Company Information',
              children: [
                _DetailRow(icon: Icons.store_outlined, title: 'Branch / Office', value: emp.branch),
                _DetailRow(icon: Icons.qr_code_outlined, title: 'Employee Code', value: emp.employeeCode),
                _DetailRow(icon: Icons.place_outlined, title: 'Work Location', value: emp.workLocation),
                _DetailRow(icon: Icons.schedule_outlined, title: 'Shift', value: emp.shift),
                _DetailRow(
                  icon: Icons.person_search_outlined,
                  title: 'Reporting Manager',
                  value: emp.reportingManager,
                  showDivider: false,
                ),
              ],
            ),

            SizedBox(height: 14.h),

            // ===== SALARY =====
            _DetailSection(
              title: 'Salary Information',
              children: [
                _DetailRow(icon: Icons.attach_money_rounded, title: 'Basic Salary', value: emp.basicSalary),
                _DetailRow(icon: Icons.account_balance_wallet_outlined, title: 'Allowances', value: emp.allowances),
                _DetailRow(icon: Icons.calendar_view_month_outlined, title: 'Salary Type', value: emp.salaryType),
                _DetailRow(icon: Icons.payment_outlined, title: 'Payment Method', value: emp.paymentMethod),
                _DetailRow(
                  icon: Icons.account_balance_outlined,
                  title: 'Bank Account / IBAN',
                  value: emp.bankAccount,
                  showDivider: false,
                ),
              ],
            ),

            SizedBox(height: 20.h),

            if (isApi) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14.w),
                margin: EdgeInsets.only(bottom: 14.h),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.orange.withOpacity(0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: Colors.orange.shade700, size: 22.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Demo employee loaded from the API.\nViewing, editing and deleting need an internet connection.',
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          color: Colors.orange.shade800,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => openEmployeeEdit(context, ref, emp),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _deleteAndClose(context, ref, emp),
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

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}

// ---------- local helpers (only used by this screen) ----------

class _EmployeeImage extends StatelessWidget {
  const _EmployeeImage({
    required this.imagePath,
    required this.size,
    required this.radius,
    required this.iconSize,
  });

  final String? imagePath;
  final double size;
  final double radius;
  final double iconSize;

  Widget _placeholder() {
    return Container(
      height: size,
      width: size,
      color: AppColors.blue.withOpacity(0.10),
      child: Icon(Icons.person_rounded, color: AppColors.blue, size: iconSize),
    );
  }

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    final hasImage =
        path != null && path.isNotEmpty && File(path).existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: hasImage
          ? Image.file(
        File(path),
        height: size,
        width: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      )
          : _placeholder(),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 11.h),
          child: Row(
            children: [
              Container(
                height: 36.w,
                width: 36.w,
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(9.r),
                ),
                child: Icon(icon, size: 18.sp, color: AppColors.blue),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Flexible(
                child: Text(
                  value.isEmpty ? '-' : value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1.h, color: Colors.grey.withOpacity(0.12)),
      ],
    );
  }
}
