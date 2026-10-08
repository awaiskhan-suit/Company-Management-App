// lib/providers/employee_list_provider.dart

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import '../services/api_overlay.dart';
import '../services/employee_storage.dart';

// ============================================================
// MODEL
// ============================================================

class Employee {
  const Employee({
    required this.id,
    required this.name,
    this.fatherName = '',
    this.dateOfBirth = '',
    this.gender = '',
    this.cnic = '',
    required this.phone,
    required this.email,
    this.address = '',
    this.city = '',
    required this.department,
    required this.designation,
    this.role = '',
    this.manager = '',
    required this.joiningDate,
    this.employmentType = '',
    required this.status,
    this.branch = '',
    this.employeeCode = '',
    this.workLocation = '',
    this.shift = '',
    this.reportingManager = '',
    this.basicSalary = '',
    this.allowances = '',
    this.salaryType = '',
    this.paymentMethod = '',
    this.bankAccount = '',
    this.imagePath,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String fatherName;
  final String dateOfBirth;
  final String gender;
  final String cnic;
  final String phone;
  final String email;
  final String address;
  final String city;

  final String department;
  final String designation;
  final String role;
  final String manager;
  final String joiningDate;
  final String employmentType;
  final String status;

  final String branch;
  final String employeeCode;
  final String workLocation;
  final String shift;
  final String reportingManager;

  final String basicSalary;
  final String allowances;
  final String salaryType;
  final String paymentMethod;
  final String bankAccount;

  final String? imagePath;
  final String createdAt;

  bool get isApiEmployee => id.startsWith('API-');

  factory Employee.fromMap(Map<String, dynamic> map) {
    String str(dynamic v) => (v ?? '').toString().trim();

    final image = str(map['profileImagePath']).isNotEmpty
        ? str(map['profileImagePath'])
        : str(map['imagePath']);

    return Employee(
      id: str(map['employeeId']).isNotEmpty
          ? str(map['employeeId'])
          : str(map['id']),
      name: str(map['fullName']).isNotEmpty
          ? str(map['fullName'])
          : str(map['name']),
      fatherName: str(map['fatherName']),
      dateOfBirth: _formatDate(map['dateOfBirth']),
      gender: str(map['gender']),
      cnic: str(map['cnic']),
      phone: str(map['phone']),
      email: str(map['email']),
      address: str(map['address']),
      city: str(map['city']),
      department: str(map['department']),
      designation: str(map['designation']),
      role: str(map['role']),
      manager: str(map['manager']),
      joiningDate: _formatDate(map['joiningDate']),
      employmentType: str(map['employmentType']),
      status: str(map['employeeStatus']).isNotEmpty
          ? str(map['employeeStatus'])
          : str(map['status']),
      branch: str(map['branch']),
      employeeCode: str(map['employeeCode']),
      workLocation: str(map['workLocation']),
      shift: str(map['shift']),
      reportingManager: str(map['reportingManager']),
      basicSalary: str(map['basicSalary']),
      allowances: str(map['allowances']),
      salaryType: str(map['salaryType']),
      paymentMethod: str(map['paymentMethod']),
      bankAccount: str(map['bankAccount']),
      imagePath: image.isEmpty ? null : image,
      createdAt: str(map['createdAt']).isNotEmpty
          ? str(map['createdAt'])
          : DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeId': id,
      'fullName': name,
      'fatherName': fatherName,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'cnic': cnic,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'department': department,
      'designation': designation,
      'role': role,
      'manager': manager,
      'joiningDate': joiningDate,
      'employmentType': employmentType,
      'employeeStatus': status,
      'branch': branch,
      'employeeCode': employeeCode,
      'workLocation': workLocation,
      'shift': shift,
      'reportingManager': reportingManager,
      'basicSalary': basicSalary,
      'allowances': allowances,
      'salaryType': salaryType,
      'paymentMethod': paymentMethod,
      'bankAccount': bankAccount,
      'profileImagePath': imagePath ?? '',
      'createdAt': createdAt,
    };
  }

  static String _formatDate(dynamic value) {
    if (value == null) return '';
    final raw = value.toString().trim();
    if (raw.isEmpty) return '';

    if (!raw.contains('T') &&
        raw.length <= 12 &&
        !RegExp(r'^\d{4}-').hasMatch(raw)) {
      return raw;
    }

    final d = DateTime.tryParse(raw);
    if (d == null) return raw;

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }
}

// ============================================================
// EMPLOYEE LIST
// ============================================================

class EmployeeListNotifier extends AsyncNotifier<List<Employee>> {
  static const _usersPath = '/users';

  Dio get _dio => ref.read(dioProvider);

  @override
  Future<List<Employee>> build() => _load();

  // ----------------------------------------------------------
  // Connectivity
  // ----------------------------------------------------------

  Future<bool> isOnline() async {
    try {
      await _dio
          .head(
        _usersPath,
        options: Options(extra: {'noRetry': true}),
      )
          .timeout(const Duration(seconds: 4));
      return true;
    } on DioException catch (e) {
      return e.type == DioExceptionType.badResponse &&
          (e.response?.statusCode ?? 500) < 500;
    } catch (_) {
      return false;
    }
  }

  // ----------------------------------------------------------
  // Helpers
  // ----------------------------------------------------------

  Future<void> _persistLocal(List<Employee> all) {
    return EmployeeStorage.saveEmployees(
      all.where((e) => !e.isApiEmployee).map((e) => e.toMap()).toList(),
    );
  }

  Future<void> _callServer(Future<Response> Function() request) async {
    try {
      final res = await request();
      final code = res.statusCode ?? 0;
      if (code < 200 || code >= 300) {
        throw ApiException('Server error ($code)', statusCode: code);
      }
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  // ----------------------------------------------------------
  // Load — INTERNET REQUIRED
  // ----------------------------------------------------------

  Future<List<Employee>> _load() async {
    final edits = await ApiOverlay.loadEdits();
    final deleted = await ApiOverlay.loadDeleted();

    late Response res;
    try {
      res = await _dio.get(_usersPath);
    } catch (e) {
      throw ApiException.from(e);
    }

    final rawData =
    res.data is String ? jsonDecode(res.data as String) : res.data;
    final list = rawData as List<dynamic>;

    final raw = await EmployeeStorage.loadEmployees();
    final local = raw.map(Employee.fromMap).toList();

    final remote = list
        .map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final company = m['company'];
      final addr = m['address'];

      return Employee(
        id: 'API-${m['id']}',
        name: (m['name'] ?? '').toString(),
        phone: (m['phone'] ?? '').toString(),
        email: (m['email'] ?? '').toString(),
        address: addr is Map ? (addr['street'] ?? '').toString() : '',
        city: addr is Map ? (addr['city'] ?? '').toString() : '',
        department: 'Demo',
        designation: company is Map
            ? (company['name'] ?? 'Staff').toString()
            : 'Staff',
        status: 'Active',
        joiningDate: '-',
        createdAt:
        DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
      );
    })
        .where((e) => !deleted.contains(e.id))
        .map((e) =>
    edits[e.id] != null ? Employee.fromMap(edits[e.id]!) : e)
        .toList();

    final ids = local.map((e) => e.id.toLowerCase()).toSet();
    final merged = [
      ...local,
      ...remote.where((e) => !ids.contains(e.id.toLowerCase())),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return merged;
  }

  // ----------------------------------------------------------
  // Delete
  // ----------------------------------------------------------

  Future<void> deleteEmployee(Employee employee) async {
    final List<Employee> current = await future;

    if (employee.isApiEmployee) {
      final apiId = employee.id.replaceFirst('API-', '');
      await _callServer(
            () => _dio.delete('$_usersPath/$apiId'),
      );
      await ApiOverlay.markDeleted(employee.id);
    }

    final updated = current
        .where((e) => e.id.toLowerCase() != employee.id.toLowerCase())
        .toList();

    await _persistLocal(updated);
    state = AsyncData(updated);
  }

  // ----------------------------------------------------------
  // Update
  // ----------------------------------------------------------

  Future<void> updateEmployee(Employee employee) async {
    final List<Employee> current = await future;

    if (employee.isApiEmployee) {
      final apiId = employee.id.replaceFirst('API-', '');
      await _callServer(
            () => _dio.put(
          '$_usersPath/$apiId',
          data: {
            'id': int.tryParse(apiId) ?? 1,
            'name': employee.name,
            'email': employee.email,
            'phone': employee.phone,
          },
        ),
      );
      await ApiOverlay.saveEdit(employee.id, employee.toMap());
    }

    final updated = current
        .map((e) =>
    e.id.toLowerCase() == employee.id.toLowerCase() ? employee : e)
        .toList();

    await _persistLocal(updated);
    state = AsyncData(updated);
  }

  // ----------------------------------------------------------
  // Refresh / Add
  // ----------------------------------------------------------

  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }

  Future<void> addEmployee(Employee employee) async {
    if (!await isOnline()) {
      throw const ApiException(
        'No internet connection. Connect and try again.',
      );
    }

    final List<Employee> current = await future;

    final exists = current.any(
          (e) => e.id.toLowerCase() == employee.id.toLowerCase(),
    );
    if (exists) {
      throw const ApiException('Employee ID already exists');
    }

    final updated = [employee, ...current];

    await _persistLocal(updated);
    state = AsyncData(updated);
  }
}

final employeeListProvider =
AsyncNotifierProvider<EmployeeListNotifier, List<Employee>>(
  EmployeeListNotifier.new,
);

// ============================================================
// SEARCH
// ============================================================

class EmployeeSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) => state = value.trim().toLowerCase();
}

final employeeSearchProvider =
NotifierProvider.autoDispose<EmployeeSearchNotifier, String>(
  EmployeeSearchNotifier.new,
);

// ============================================================
// DEPARTMENT
// ============================================================

const String kAllDepartments = 'All Departments';

class SelectedDepartmentNotifier extends Notifier<String> {
  @override
  String build() => kAllDepartments;

  void select(String department) => state = department;
}

final selectedDepartmentProvider =
NotifierProvider.autoDispose<SelectedDepartmentNotifier, String>(
  SelectedDepartmentNotifier.new,
);

// ============================================================
// DERIVED
// ============================================================

final departmentsProvider = Provider.autoDispose<List<String>>((ref) {
  final employees = ref.watch(employeeListProvider).maybeWhen(
    data: (list) => list,
    orElse: () => const <Employee>[],
  );

  final departments = employees
      .map((e) => e.department)
      .where((d) => d.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  return [kAllDepartments, ...departments];
});

final filteredEmployeesProvider = Provider.autoDispose<List<Employee>>((ref) {
  final employees = ref.watch(employeeListProvider).maybeWhen(
    data: (list) => list,
    orElse: () => const <Employee>[],
  );
  final query = ref.watch(employeeSearchProvider);
  final selectedDepartment = ref.watch(selectedDepartmentProvider);

  return employees.where((employee) {
    final matchesSearch = query.isEmpty ||
        employee.name.toLowerCase().contains(query) ||
        employee.id.toLowerCase().contains(query);

    final matchesDepartment = selectedDepartment == kAllDepartments ||
        employee.department == selectedDepartment;

    return matchesSearch && matchesDepartment;
  }).toList();
});

// ============================================================
// COUNTS (for Total Employees screen)
// ============================================================

/// Total employees across all departments
final totalEmployeesCountProvider = Provider.autoDispose<int>((ref) {
  final employees = ref.watch(employeeListProvider).maybeWhen(
    data: (list) => list,
    orElse: () => const <Employee>[],
  );
  return employees.length;
});

/// Count of employees per department name
/// e.g. { 'HR': 5, 'IT': 12, 'Demo': 8 }
final employeesPerDepartmentProvider =
Provider.autoDispose<Map<String, int>>((ref) {
  final employees = ref.watch(employeeListProvider).maybeWhen(
    data: (list) => list,
    orElse: () => const <Employee>[],
  );

  final map = <String, int>{};
  for (final e in employees) {
    final dept = e.department.trim();
    if (dept.isEmpty) continue;
    map[dept] = (map[dept] ?? 0) + 1;
  }
  return map;
});

/// Count for one department (by name)
final employeeCountForDepartmentProvider =
Provider.autoDispose.family<int, String>((ref, departmentName) {
  if (departmentName == kAllDepartments) {
    return ref.watch(totalEmployeesCountProvider);
  }
  final map = ref.watch(employeesPerDepartmentProvider);
  return map[departmentName] ?? 0;
});

