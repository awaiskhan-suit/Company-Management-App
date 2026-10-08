import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================
// STATE
// ============================================================

class ProfileState {
  const ProfileState({
    this.fullName = 'Awais',
    this.email = 'awais@worknexa.com',
    this.phone = '0300-1234567',
    this.role = 'Super Admin',
    this.department = 'Management',
    this.designation = 'System Administrator',
    this.employeeId = 'EMP-001',
    this.companyName = 'WorkNexa',
    this.branch = 'Head Office',
    this.joiningDate = '01/01/2024',
    this.address = 'Lahore, Pakistan',
    this.isEditing = false,
    this.isSaving = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String department;
  final String designation;
  final String employeeId;
  final String companyName;
  final String branch;
  final String joiningDate;
  final String address;
  final bool isEditing;
  final bool isSaving;
  final String? errorMessage;
  final bool isSuccess;

  ProfileState copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? role,
    String? department,
    String? designation,
    String? employeeId,
    String? companyName,
    String? branch,
    String? joiningDate,
    String? address,
    bool? isEditing,
    bool? isSaving,
    String? errorMessage,
    bool? isSuccess,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ProfileState(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      employeeId: employeeId ?? this.employeeId,
      companyName: companyName ?? this.companyName,
      branch: branch ?? this.branch,
      joiningDate: joiningDate ?? this.joiningDate,
      address: address ?? this.address,
      isEditing: isEditing ?? this.isEditing,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: clearSuccess ? false : (isSuccess ?? this.isSuccess),
    );
  }
}

// ============================================================
// NOTIFIER
// ============================================================

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() => const ProfileState();

  void setFullName(String v) => state = state.copyWith(fullName: v);
  void setEmail(String v) => state = state.copyWith(email: v);
  void setPhone(String v) => state = state.copyWith(phone: v);
  void setDepartment(String v) => state = state.copyWith(department: v);
  void setDesignation(String v) => state = state.copyWith(designation: v);
  void setBranch(String v) => state = state.copyWith(branch: v);
  void setAddress(String v) => state = state.copyWith(address: v);

  void startEditing() => state = state.copyWith(isEditing: true);

  void cancelEditing() {
    // Reload defaults (or keep last saved — here we just exit edit mode)
    state = state.copyWith(isEditing: false, clearError: true);
  }

  String? validate() {
    if (state.fullName.trim().isEmpty) return 'Name is required';
    if (state.email.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$')
        .hasMatch(state.email.trim())) {
      return 'Invalid email';
    }
    if (state.phone.trim().isEmpty) return 'Phone is required';
    return null;
  }

  /// UI-only save (no Firebase / API)
  Future<bool> save() async {
    final error = validate();
    if (error != null) {
      state = state.copyWith(errorMessage: error, isSuccess: false);
      return false;
    }

    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );

    await Future.delayed(const Duration(milliseconds: 700));

    state = state.copyWith(
      isSaving: false,
      isEditing: false,
      isSuccess: true,
    );
    return true;
  }
}

final profileProvider =
NotifierProvider.autoDispose<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
);
