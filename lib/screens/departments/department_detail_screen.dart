import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../colors/colors.dart';
import '../../providers/department_provider.dart';
import 'department_action.dart';

/// Full details of one department.
/// Viewing works offline from the passed department (or cache).
/// Editing and deleting need internet (checked in department_action.dart).
class DepartmentDetailsScreen extends ConsumerWidget {
  const DepartmentDetailsScreen({super.key, required this.department});

  final Department department;

  String _fmtDate(DateTime d) {
    // demo departments have a placeholder 1970 date: show '-'
    if (d.year <= 1970) return '-';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Prefer latest data from list (works online + offline cache).
    // If list is loading/error/empty → fall back to the department that was passed.
    final dept = ref.watch(departmentListProvider).maybeWhen(
      data: (list) {
        try {
          return list.firstWhere((d) => d.id == department.id);
        } catch (_) {
          return department;
        }
      },
      orElse: () => department,
    );

    final employeeCount = dept.employeeCount;

    final statusColor =
    dept.status == 'Active' ? AppColors.success : Colors.red;

    Future<void> onDelete() async {
      final deleted = await confirmDeleteDepartment(context, ref, dept);
      if (deleted && context.mounted) Navigator.pop(context);
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
          onPressed: () => Navigator.pop(context),
          icon:
          Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24.sp),
        ),
        title: Text(
          'Department Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: () => openDepartmentForm(context, ref, department: dept),
            icon: Icon(Icons.edit_outlined, color: Colors.white, size: 22.sp),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: onDelete,
            icon:
            Icon(Icons.delete_outline, color: Colors.white, size: 22.sp),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // ==================== HEADER CARD ====================
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
                  Container(
                    height: 76.w,
                    width: 76.w,
                    decoration: BoxDecoration(
                      color: AppColors.blue.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                    child: Icon(
                      Icons.apartment_rounded,
                      color: AppColors.blue,
                      size: 40.sp,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    dept.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 21.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    dept.type,
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
                          dept.code,
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
                          dept.status,
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

            // ==================== DEPARTMENT ====================
            _DetailSection(
              title: 'Department Information',
              children: [
                _DetailRow(
                  icon: Icons.tag,
                  title: 'Department ID',
                  value: dept.code,
                ),
                _DetailRow(
                  icon: Icons.business_center_outlined,
                  title: 'Name',
                  value: dept.name,
                ),
                _DetailRow(
                  icon: Icons.category_outlined,
                  title: 'Type',
                  value: dept.type,
                ),
                _DetailRow(
                  icon: Icons.description_outlined,
                  title: 'Description',
                  value: dept.description,
                  showDivider: false,
                ),
              ],
            ),

            SizedBox(height: 14.h),

            // ==================== MANAGEMENT ====================
            _DetailSection(
              title: 'Management',
              children: [
                _DetailRow(
                  icon: Icons.person_outline_rounded,
                  title: 'Manager',
                  value: (dept.managerName ?? '').trim(),
                ),
                _DetailRow(
                  icon: Icons.people_alt_rounded,
                  title: 'Employees',
                  value: '$employeeCount',
                  showDivider: false,
                ),
              ],
            ),

            SizedBox(height: 14.h),

            // ==================== LOCATION ====================
            _DetailSection(
              title: 'Location',
              children: [
                _DetailRow(
                  icon: Icons.storefront_outlined,
                  title: 'Branch / Office',
                  value: dept.branch,
                ),
                _DetailRow(
                  icon: Icons.layers_outlined,
                  title: 'Floor / Location',
                  value: dept.floor ?? '',
                ),
                _DetailRow(
                  icon: Icons.calendar_month_rounded,
                  title: 'Created',
                  value: _fmtDate(dept.createdAt),
                  showDivider: false,
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // ==================== INFO NOTE ====================
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
                      'Editing and deleting a department need an internet connection.',
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

            // ==================== ACTION BUTTONS ====================
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        openDepartmentForm(context, ref, department: dept),
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
                    onPressed: onDelete,
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

// ==================================================================
// DETAIL SECTION / ROW
// ==================================================================

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
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String value;
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
                    color: AppColors.textPrimary,
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
