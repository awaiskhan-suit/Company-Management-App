import 'package:flutter_riverpod/flutter_riverpod.dart';

const List<String> kAppRoles = [
  'Super Admin',
  'Admin',
  'HR',
  'Manager',
  'Employee',
];

class RolePermissionState {
  const RolePermissionState({
    this.name = '',
    this.email = '',
    this.password = '',
    this.role,
    this.obscurePassword = true,
    this.isSubmitting = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  final String name;
  final String email;
  final String password;
  final String? role;
  final bool obscurePassword;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isSuccess;

  RolePermissionState copyWith({
    String? name,
    String? email,
    String? password,
    String? role,
    bool? obscurePassword,
    bool? isSubmitting,
    String? errorMessage,
    bool? isSuccess,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return RolePermissionState(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: clearSuccess ? false : (isSuccess ?? this.isSuccess),
    );
  }
}

class RolePermissionNotifier extends Notifier<RolePermissionState> {
  @override
  RolePermissionState build() => const RolePermissionState();

  void setName(String v) => state = state.copyWith(name: v);
  void setEmail(String v) => state = state.copyWith(email: v);
  void setPassword(String v) => state = state.copyWith(password: v);
  void setRole(String? v) => state = state.copyWith(role: v);

  void toggleObscurePassword() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  void reset() => state = const RolePermissionState();

  String? validate() {
    if (state.name.trim().isEmpty) return 'Name is required';
    if (state.email.trim().isEmpty) return 'Email is required';
    final email = state.email.trim();
    if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      return 'Invalid email';
    }
    if (state.password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (state.role == null || state.role!.isEmpty) {
      return 'Please select a role';
    }
    return null;
  }

  /// UI-only (no Firebase / API)
  Future<bool> submit() async {
    final error = validate();
    if (error != null) {
      state = state.copyWith(errorMessage: error, isSuccess: false);
      return false;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearSuccess: true,
    );

    await Future.delayed(const Duration(milliseconds: 700));

    state = state.copyWith(isSubmitting: false, isSuccess: true);
    return true;
  }
}

final rolePermissionProvider =
NotifierProvider.autoDispose<RolePermissionNotifier, RolePermissionState>(
  RolePermissionNotifier.new,
);