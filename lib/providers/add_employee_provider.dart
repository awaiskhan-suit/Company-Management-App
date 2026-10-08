// lib/providers/add_employee_provider.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';          // ← shared dio + ApiException
import 'employee_list_provider.dart';

// ============================================================
// STATE
// ============================================================

class AddEmployeeState {
  const AddEmployeeState({
    // Personal
    this.employeeId = '',
    this.fullName = '',
    this.fatherName = '',
    this.dateOfBirth,
    this.gender,
    this.cnic = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.city = '',
    // Job
    this.department = '',
    this.designation = '',
    this.role,
    this.manager = '',
    this.joiningDate,
    this.employmentType,
    this.employeeStatus,
    // Company
    this.branch = '',
    this.employeeCode = '',
    this.workLocation = '',
    this.shift = '',
    this.reportingManager = '',
    // Salary
    this.basicSalary = '',
    this.allowances = '',
    this.salaryType,
    this.paymentMethod,
    this.bankAccount = '',
    // Image
    this.imagePath,
    // UI
    this.isSubmitting = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  final String employeeId;
  final String fullName;
  final String fatherName;
  final DateTime? dateOfBirth;
  final String? gender;
  final String cnic;
  final String phone;
  final String email;
  final String address;
  final String city;

  final String department;
  final String designation;
  final String? role;
  final String manager;
  final DateTime? joiningDate;
  final String? employmentType;
  final String? employeeStatus;

  final String branch;
  final String employeeCode;
  final String workLocation;
  final String shift;
  final String reportingManager;

  final String basicSalary;
  final String allowances;
  final String? salaryType;
  final String? paymentMethod;
  final String bankAccount;

  final String? imagePath;

  final bool isSubmitting;
  final String? errorMessage;
  final bool isSuccess;

  AddEmployeeState copyWith({
    String? employeeId,
    String? fullName,
    String? fatherName,
    DateTime? dateOfBirth,
    String? gender,
    String? cnic,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? department,
    String? designation,
    String? role,
    String? manager,
    DateTime? joiningDate,
    String? employmentType,
    String? employeeStatus,
    String? branch,
    String? employeeCode,
    String? workLocation,
    String? shift,
    String? reportingManager,
    String? basicSalary,
    String? allowances,
    String? salaryType,
    String? paymentMethod,
    String? bankAccount,
    String? imagePath,
    bool? isSubmitting,
    String? errorMessage,
    bool? isSuccess,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AddEmployeeState(
      employeeId: employeeId ?? this.employeeId,
      fullName: fullName ?? this.fullName,
      fatherName: fatherName ?? this.fatherName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      cnic: cnic ?? this.cnic,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      role: role ?? this.role,
      manager: manager ?? this.manager,
      joiningDate: joiningDate ?? this.joiningDate,
      employmentType: employmentType ?? this.employmentType,
      employeeStatus: employeeStatus ?? this.employeeStatus,
      branch: branch ?? this.branch,
      employeeCode: employeeCode ?? this.employeeCode,
      workLocation: workLocation ?? this.workLocation,
      shift: shift ?? this.shift,
      reportingManager: reportingManager ?? this.reportingManager,
      basicSalary: basicSalary ?? this.basicSalary,
      allowances: allowances ?? this.allowances,
      salaryType: salaryType ?? this.salaryType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      bankAccount: bankAccount ?? this.bankAccount,
      imagePath: imagePath ?? this.imagePath,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: clearSuccess ? false : (isSuccess ?? this.isSuccess),
    );
  }
}

// ============================================================
// HELPERS
// ============================================================

String _formatDate(DateTime? d) {
  if (d == null) return '';
  return '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';
}

// ============================================================
// NOTIFIER
// ============================================================

class AddEmployeeNotifier extends Notifier<AddEmployeeState> {
  @override
  AddEmployeeState build() => const AddEmployeeState();

  // Personal
  void setEmployeeId(String v) => state = state.copyWith(employeeId: v);
  void setFullName(String v) => state = state.copyWith(fullName: v);
  void setFatherName(String v) => state = state.copyWith(fatherName: v);
  void setDateOfBirth(DateTime v) => state = state.copyWith(dateOfBirth: v);
  void setGender(String? v) => state = state.copyWith(gender: v);
  void setCnic(String v) => state = state.copyWith(cnic: v);
  void setPhone(String v) => state = state.copyWith(phone: v);
  void setEmail(String v) => state = state.copyWith(email: v);
  void setAddress(String v) => state = state.copyWith(address: v);
  void setCity(String v) => state = state.copyWith(city: v);

  // Job
  void setDepartment(String v) => state = state.copyWith(department: v);
  void setDesignation(String v) => state = state.copyWith(designation: v);
  void setRole(String? v) => state = state.copyWith(role: v);
  void setManager(String v) => state = state.copyWith(manager: v);
  void setJoiningDate(DateTime v) => state = state.copyWith(joiningDate: v);
  void setEmploymentType(String? v) =>
      state = state.copyWith(employmentType: v);
  void setEmployeeStatus(String? v) =>
      state = state.copyWith(employeeStatus: v);

  // Company
  void setBranch(String v) => state = state.copyWith(branch: v);
  void setEmployeeCode(String v) => state = state.copyWith(employeeCode: v);
  void setWorkLocation(String v) => state = state.copyWith(workLocation: v);
  void setShift(String v) => state = state.copyWith(shift: v);
  void setReportingManager(String v) =>
      state = state.copyWith(reportingManager: v);

  // Salary
  void setBasicSalary(String v) => state = state.copyWith(basicSalary: v);
  void setAllowances(String v) => state = state.copyWith(allowances: v);
  void setSalaryType(String? v) => state = state.copyWith(salaryType: v);
  void setPaymentMethod(String? v) =>
      state = state.copyWith(paymentMethod: v);
  void setBankAccount(String v) => state = state.copyWith(bankAccount: v);

  // Image
  void setImagePath(String? path) => state = state.copyWith(imagePath: path);

  void reset() => state = const AddEmployeeState();

  void clearStatus() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  String? validate() {
    if (state.employeeId.trim().isEmpty) return 'Employee ID is required';
    if (state.employeeId.trim().toUpperCase().startsWith('API-')) {
      return 'Employee ID cannot start with API- (reserved for demo data)';
    }
    if (state.fullName.trim().isEmpty) return 'Full name is required';
    if (state.fatherName.trim().isEmpty) {
      return 'Father / Guardian name is required';
    }
    if (state.dateOfBirth == null) return 'Date of birth is required';
    if (state.gender == null || state.gender!.isEmpty) {
      return 'Gender is required';
    }
    if (state.cnic.trim().isEmpty) return 'CNIC is required';
    if (!RegExp(r'^\d{13}$').hasMatch(state.cnic.trim())) {
      return 'CNIC must be exactly 13 digits';
    }
    if (state.phone.trim().isEmpty) return 'Phone number is required';
    if (!RegExp(r'^\d{11}$').hasMatch(state.phone.trim())) {
      return 'Phone number must be exactly 11 digits';
    }
    if (state.email.trim().isEmpty) return 'Email is required';
    final email = state.email.trim().toLowerCase();
    if (!email.contains('@gmail.com') ||
        !RegExp(r'^[\w\.\-]+@gmail\.com$').hasMatch(email)) {
      return 'Email must be a valid @gmail.com address';
    }
    if (state.address.trim().isEmpty) return 'Address is required';
    if (state.city.trim().isEmpty) return 'City is required';
    if (state.department.trim().isEmpty) return 'Department is required';
    if (state.designation.trim().isEmpty) return 'Designation is required';
    if (state.role == null || state.role!.isEmpty) return 'Role is required';
    if (state.manager.trim().isEmpty) return 'Manager is required';
    if (state.joiningDate == null) return 'Joining date is required';
    if (state.employmentType == null || state.employmentType!.isEmpty) {
      return 'Employment type is required';
    }
    if (state.employeeStatus == null || state.employeeStatus!.isEmpty) {
      return 'Employee status is required';
    }
    if (state.branch.trim().isEmpty) return 'Branch is required';
    if (state.employeeCode.trim().isEmpty) return 'Employee code is required';
    if (state.workLocation.trim().isEmpty) return 'Work location is required';
    if (state.shift.trim().isEmpty) return 'Shift is required';
    if (state.reportingManager.trim().isEmpty) {
      return 'Reporting manager is required';
    }
    if (state.basicSalary.trim().isEmpty) return 'Basic salary is required';
    if (state.allowances.trim().isEmpty) return 'Allowances is required';
    if (state.salaryType == null || state.salaryType!.isEmpty) {
      return 'Salary type is required';
    }
    if (state.paymentMethod == null || state.paymentMethod!.isEmpty) {
      return 'Payment method is required';
    }
    if (state.bankAccount.trim().isEmpty) return 'Bank account is required';
    return null;
  }

  Employee _toEmployee() {
    return Employee(
      id: state.employeeId.trim().toUpperCase(),
      name: state.fullName.trim(),
      fatherName: state.fatherName.trim(),
      dateOfBirth: _formatDate(state.dateOfBirth),
      gender: state.gender ?? '',
      cnic: state.cnic.trim(),
      phone: state.phone.trim(),
      email: state.email.trim().toLowerCase(),
      address: state.address.trim(),
      city: state.city.trim(),
      department: state.department.trim(),
      designation: state.designation.trim(),
      role: state.role ?? '',
      manager: state.manager.trim(),
      joiningDate: _formatDate(state.joiningDate),
      employmentType: state.employmentType ?? '',
      status: state.employeeStatus ?? 'Active',
      branch: state.branch.trim(),
      employeeCode: state.employeeCode.trim(),
      workLocation: state.workLocation.trim(),
      shift: state.shift.trim(),
      reportingManager: state.reportingManager.trim(),
      basicSalary: state.basicSalary.trim(),
      allowances: state.allowances.trim(),
      salaryType: state.salaryType ?? '',
      paymentMethod: state.paymentMethod ?? '',
      bankAccount: state.bankAccount.trim(),
      imagePath: state.imagePath,
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  // ============================================================
  // SUBMIT → uses shared dioProvider (with all interceptors)
  // ============================================================
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

    try {
      final body = {
        'name': state.fullName.trim(),
        'username': state.employeeId.trim().toUpperCase(),
        'email': state.email.trim().toLowerCase(),
        'phone': state.phone.trim(),
        'address': {
          'street': state.address.trim(),
          'city': state.city.trim(),
        },
        'fatherName': state.fatherName.trim(),
        'dateOfBirth': state.dateOfBirth?.toIso8601String(),
        'gender': state.gender,
        'cnic': state.cnic.trim(),
        'department': state.department.trim(),
        'designation': state.designation.trim(),
        'role': state.role,
        'manager': state.manager.trim(),
        'joiningDate': state.joiningDate?.toIso8601String(),
        'employmentType': state.employmentType,
        'employeeStatus': state.employeeStatus,
        'branch': state.branch.trim(),
        'employeeCode': state.employeeCode.trim(),
        'workLocation': state.workLocation.trim(),
        'shift': state.shift.trim(),
        'reportingManager': state.reportingManager.trim(),
        'basicSalary': state.basicSalary.trim(),
        'allowances': state.allowances.trim(),
        'salaryType': state.salaryType,
        'paymentMethod': state.paymentMethod,
        'bankAccount': state.bankAccount.trim(),
      };

      // ★ Shared Dio (Auth + Logging + Retry + ErrorMapper)
      final dio = ref.read(dioProvider);

      final response = await dio.post('/users', data: body);

      final code = response.statusCode ?? 0;
      if (code != 200 && code != 201) {
        throw ApiException('Server error ($code). Try again.', statusCode: code);
      }

      // Server accepted → save on device
      await ref.read(employeeListProvider.notifier).addEmployee(_toEmployee());

      state = state.copyWith(isSubmitting: false, isSuccess: true);
      return true;
    } catch (e) {
      final apiError = ApiException.from(e);
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: apiError.message,
        isSuccess: false,
      );
      return false;
    }
  }
}

// ============================================================
// PROVIDER
// ============================================================

final addEmployeeProvider =
NotifierProvider.autoDispose<AddEmployeeNotifier, AddEmployeeState>(
  AddEmployeeNotifier.new,
);


