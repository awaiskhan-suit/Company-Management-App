import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/dash_board_screen.dart';
import '../../role_permission/role_permission_screen.dart';

import '../attendance/attendance_screen.dart';
import '../auth/login_screen.dart';
import '../auth/sign_up_screen.dart';
import '../auth/forgot_password_screen.dart';
import '../departments/add_department_screen.dart';
import '../employees/add_employee_screen.dart';
import '../notification/notification_screen.dart';
import '../notification/send_notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../reports/report_screen.dart';
import '../splash/splash_screen.dart';
import '../tasks/add_task_screen.dart';
import '../widget/Feature_placeholder_screen.dart';

import 'dashboard_screen.dart';
import '../../route_observer.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,

  // App starts from Splash
  initialLocation: '/splash',

  // Root navigator observer
  observers: [routeObserver],

  routes: [
    // ============================================================
    // AUTH ROUTES
    // ============================================================

    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),

    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    GoRoute(
      path: '/sign-up',
      builder: (context, state) => const SignUpScreen(),
    ),

    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),

    // ============================================================
    // FULL SCREEN ROUTES
    // These routes appear above the bottom navigation
    // ============================================================

    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/employees',
      builder: (context, state) => const AddEmployeeScreen(),
    ),

    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/departments',
      builder: (context, state) => const AddDepartmentScreen(),
    ),

    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/attendance',
      builder: (context, state) => const AttendanceScreen(),
    ),

    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/tasks',
      builder: (context, state) => const AddTaskScreen(),
    ),

    // ★ NEW – Add Notification form (employee, department, description)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/send-notification',
      builder: (context, state) => const SendNotificationScreen(),
    ),

    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/roles-permissions',
      builder: (context, state) => const RolePermissionScreen(),
    ),

    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/company-settings',
      builder: (context, state) => const FeaturePlaceholderScreen(
        title: 'Company Settings',
        icon: Icons.settings_outlined,
      ),
    ),

    // ============================================================
    // BOTTOM NAVIGATION SHELL
    // ============================================================

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return DashboardScreen(
          navigationShell: navigationShell,
        );
      },

      branches: [
        // ========================================================
        // TAB 0 - DASHBOARD
        // ========================================================

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) {
                return Consumer(
                  builder: (context, ref, _) {
                    final roleState =
                        ref.watch(roleProvider).value ?? const RoleState();

                    return DashboardBody(
                      role: roleState.role,
                      userName: roleState.userName,
                      isActive: true,
                    );
                  },
                );
              },
            ),
          ],
        ),

        // ========================================================
        // TAB 1 - REPORTS
        // ========================================================

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/reports',
              builder: (context, state) {
                return const ReportsScreen(
                  isActive: true,
                );
              },
            ),
          ],
        ),

        // ========================================================
        // TAB 2 - NOTIFICATIONS
        // ========================================================

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/notifications',
              builder: (context, state) {
                return const NotificationsScreen(
                  isActive: true,
                );
              },
            ),
          ],
        ),

        // ========================================================
        // TAB 3 - PROFILE
        // ========================================================

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) {
                return const ProfileScreen(
                  isActive: true,
                );
              },
            ),
          ],
        ),
      ],
    ),
  ],
);