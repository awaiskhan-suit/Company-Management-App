import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart'; // shared dio + ApiException
import 'employee_list_provider.dart';

// ============================================================
// MODEL
// ============================================================

/// Attendance status for one employee on one day.
enum AttendanceStatus { present, leave, absent, notMarked }

/// Light model used by the attendance screen. Built from API users
/// and from employees added in the Add Employee screen.
class AttendanceEmployee {
  const AttendanceEmployee({
    required this.id,
    required this.name,
    required this.department,
    required this.designation,
    this.imagePath,
  });

  final String id;
  final String name;
  final String department;
  final String designation;
  final String? imagePath;
}

// ============================================================
// EMPLOYEES FROM THE API  (same dio + interceptors as departments)
// ============================================================

const String _usersPath = '/users';

/// Mock endpoint for saving a mark. jsonplaceholder accepts a POST to
/// /posts and answers 201. Change this one line for a real backend.
const String _attendancePath = '/posts';

const List<String> _demoDepartments = [
  'HR',
  'IT',
  'Finance',
  'Operations',
  'Marketing',
  'Sales',
  'Support',
];

final apiEmployeesProvider =
AsyncNotifierProvider<ApiEmployeesNotifier, List<AttendanceEmployee>>(
  ApiEmployeesNotifier.new,
);

class ApiEmployeesNotifier extends AsyncNotifier<List<AttendanceEmployee>> {
  @override
  Future<List<AttendanceEmployee>> build() => _load();

  /// Always requires internet. Offline -> throws ApiException
  /// -> the screen shows "Internet required".
  Future<List<AttendanceEmployee>> _load() async {
    final dio = ref.read(dioProvider);

    try {
      final res = await dio.get(_usersPath);

      final raw =
      res.data is String ? jsonDecode(res.data as String) : res.data;
      final list = raw as List<dynamic>;

      final result = <AttendanceEmployee>[];
      for (var i = 0; i < list.length; i++) {
        final m = Map<String, dynamic>.from(list[i] as Map);
        final apiId = (m['id'] ?? (i + 1)).toString();
        final n = int.tryParse(apiId) ?? (i + 1);

        result.add(
          AttendanceEmployee(
            id: 'API-$apiId',
            name: (m['name'] ?? 'Employee $n').toString(),
            department: _demoDepartments[(n - 1) % _demoDepartments.length],
            designation: 'Employee',
          ),
        );
      }
      return result;
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }
}

// ============================================================
// ROSTER = employees added in the app + employees from the API
// ============================================================

/// Works whether employeeListProvider exposes AsyncValue<List<Employee>>
/// or a plain List<Employee>.
List<AttendanceEmployee> _localEmployees(Object? value) {
  List<dynamic> raw = const [];
  if (value is AsyncValue) {
    final v = value.value;
    if (v is List) raw = v;
  } else if (value is List) {
    raw = value;
  }

  return [
    for (final e in raw.cast<Employee>())
      AttendanceEmployee(
        id: e.id,
        name: e.name,
        department: e.department,
        designation: e.designation,
        imagePath: e.imagePath,
      ),
  ];
}

/// Employees you added first, then the ones from the API.
/// Loading / error state follows the API call, like the department list.
final rosterProvider = Provider<AsyncValue<List<AttendanceEmployee>>>((ref) {
  final api = ref.watch(apiEmployeesProvider);
  final local = _localEmployees(ref.watch(employeeListProvider));

  return api.whenData((fromApi) {
    final seen = <String>{};
    return [
      for (final e in [...local, ...fromApi])
        if (seen.add(e.id)) e,
    ];
  });
});

// ============================================================
// ATTENDANCE MARKS  (AsyncNotifier: loads saved marks before use)
// ============================================================

String _two(int n) => n.toString().padLeft(2, '0');

String _todayIso() {
  final n = DateTime.now();
  return '${n.year}-${_two(n.month)}-${_two(n.day)}';
}

/// One storage key per day, so every day starts fresh.
String _todayKey() => 'attendance_${_todayIso()}';

class AttendanceState {
  const AttendanceState({this.marks = const {}});

  /// employeeId -> status (employees not in the map are "not marked")
  final Map<String, AttendanceStatus> marks;

  AttendanceStatus statusOf(String employeeId) =>
      marks[employeeId] ?? AttendanceStatus.notMarked;

  AttendanceState copyWith({Map<String, AttendanceStatus>? marks}) {
    return AttendanceState(marks: marks ?? this.marks);
  }
}

class AttendanceNotifier extends AsyncNotifier<AttendanceState> {
  /// Awaited: the state stays "loading" until saved marks are read,
  /// so the screen never shows everyone as "Not marked" by mistake.
  @override
  Future<AttendanceState> build() => _load();

  Future<AttendanceState> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_todayKey());

    var marks = <String, AttendanceStatus>{};
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        marks = decoded.map(
              (id, name) => MapEntry(
            id,
            AttendanceStatus.values.firstWhere(
                  (s) => s.name == name,
              orElse: () => AttendanceStatus.notMarked,
            ),
          ),
        );
      } catch (_) {
        marks = {};
      }
    }
    return AttendanceState(marks: marks);
  }

  Future<void> _save(Map<String, AttendanceStatus> marks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _todayKey(),
      jsonEncode(marks.map((id, s) => MapEntry(id, s.name))),
    );
  }

  /// Sends the mark to the server first (shared dio: auth, logging, retry,
  /// error mapping), then saves it on the device.
  /// Returns null on success, or a readable error message.
  /// POST is never retried by RetryInterceptor, so no duplicate records.
  Future<String?> setAttendance(
      String employeeId,
      AttendanceStatus status,
      ) async {
    try {
      await ref.read(dioProvider).post(
        _attendancePath,
        data: {
          'employeeId': employeeId,
          'date': _todayIso(),
          'status': status.name,
        },
      );
    } catch (e) {
      return ApiException.from(e).message;
    }

    // If saved marks are still loading, wait for them first so they
    // can't overwrite this mark.
    final current = state.value ?? await future;

    final updated = Map<String, AttendanceStatus>.from(current.marks);
    if (status == AttendanceStatus.notMarked) {
      updated.remove(employeeId);
    } else {
      updated[employeeId] = status;
    }

    state = AsyncData(current.copyWith(marks: updated));
    await _save(updated);
    return null;
  }

  /// Clears today's marks on the device only (no server call).
  Future<void> resetAll() async {
    state = const AsyncData(AttendanceState());
    await _save(const {});
  }
}

final attendanceProvider =
AsyncNotifierProvider<AttendanceNotifier, AttendanceState>(
  AttendanceNotifier.new,
);
