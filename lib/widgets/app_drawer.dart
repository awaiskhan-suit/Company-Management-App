import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../colors/colors.dart';
import '../providers/dash_board_provider.dart';
import '../providers/dash_board_screen.dart';
import '../role_permission/role_permission_screen.dart';
import '../screens/attendance/attendance_screen.dart';
import '../screens/departments/add_department_screen.dart';
import '../screens/employees/add_employee_screen.dart';
import '../screens/notification/send_notifications_screen.dart'; // ← added
import '../screens/tasks/add_task_screen.dart';
import '../screens/widget/Feature_placeholder_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  void _openPlaceholder(
      BuildContext context, {
        required String title,
        required IconData icon,
      }) {
    Navigator.pop(context); // close drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FeaturePlaceholderScreen(title: title, icon: icon),
      ),
    );
  }

  void _openDashboard(BuildContext context) {
    Navigator.pop(context); // close drawer
    context.go('/dashboard');
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Logout',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14.sp,
            ),
          ),
          actionsPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext); // close dialog
                context.go('/login'); // go to login and clear stack
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 18.w,
                  vertical: 10.h,
                ),
              ),
              child: Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRole = ref.watch(roleProvider);
    final roleState = asyncRole.value ?? const RoleState();
    final role = roleState.role;

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: const BoxDecoration(
                gradient: AppColors.brandGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28.r,
                    backgroundColor: AppColors.surface,
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/images.jpg',
                        width: 56.w,
                        height: 56.h,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 15.h),
                  Text(
                    roleState.companyName,
                    style: TextStyle(
                      color: AppColors.textOnBrand,
                      fontSize: 21.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Workforce Management',
                    style: TextStyle(
                      color: AppColors.border,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 10.h),

            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                children: [
                  DrawerItem(
                    title: 'Dashboard',
                    icon: Icons.dashboard_rounded,
                    selected: true,
                    onTap: () => _openDashboard(context),
                  ),

                  if (role != 'Employee')
                    DrawerItem(
                      title: 'Employees',
                      icon: Icons.people_alt_outlined,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddEmployeeScreen(),
                          ),
                        );
                      },
                    ),

                  if (role == 'Super Admin' ||
                      role == 'Admin' ||
                      role == 'HR')
                    DrawerItem(
                      title: 'Departments',
                      icon: Icons.account_tree_outlined,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddDepartmentScreen(),
                          ),
                        );
                      },
                    ),

                  DrawerItem(
                    title: 'Attendance',
                    icon: Icons.access_time_rounded,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AttendanceScreen(),
                        ),
                      );
                    },
                  ),

                  DrawerItem(
                    title: 'Tasks',
                    icon: Icons.task_alt_outlined,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddTaskScreen(),
                        ),
                      );
                    },
                  ),

                  // ★ Notifications / Send Notification — available to ALL roles
                  DrawerItem(
                    title: 'Notifications',
                    icon: Icons.notifications_outlined,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SendNotificationScreen(),
                        ),
                      );
                    },
                  ),

                  if (role == 'Super Admin')
                    DrawerItem(
                      title: 'Roles & Permissions',
                      icon: Icons.admin_panel_settings_outlined,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RolePermissionScreen(),
                          ),
                        );
                      },
                    ),

                  if (role == 'Super Admin')
                    DrawerItem(
                      title: 'Company Settings',
                      icon: Icons.settings_outlined,
                      onTap: () => _openPlaceholder(
                        context,
                        title: 'Company Settings',
                        icon: Icons.settings_outlined,
                      ),
                    ),
                ],
              ),
            ),

            const Divider(color: AppColors.border),

            DrawerItem(
              title: 'Logout',
              icon: Icons.logout_rounded,
              danger: true,
              onTap: () => _handleLogout(context),
            ),

            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }
}

class DrawerItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final bool danger;
  final VoidCallback onTap;

  const DrawerItem({
    super.key,
    required this.title,
    required this.icon,
    this.selected = false,
    this.danger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      decoration: BoxDecoration(
        color: selected ? AppColors.background : Colors.transparent,
        borderRadius: BorderRadius.circular(9.r),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          size: 22.sp,
          color: danger
              ? AppColors.error
              : selected
              ? AppColors.navy
              : AppColors.textMuted,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: danger
                ? AppColors.error
                : selected
                ? AppColors.navy
                : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13.sp,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}