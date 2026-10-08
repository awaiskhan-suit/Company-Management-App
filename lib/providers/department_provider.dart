import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';

// ============================================================
// MODEL
// ============================================================

class Department {
  final String id; // 'API-1' for demo data, 'L<micros>' for your own
  final String code; // DEP-001
  final String name;
  final String description;
  final String type; // HR, IT, Finance, Operations ...
  final String? managerId;
  final String? managerName;
  final String branch;
  final String? floor;
  final String status; // Active / Inactive
  final int employeeCount;
  final DateTime createdAt;

  const Department({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.type,
    this.managerId,
    this.managerName,
    required this.branch,
    this.floor,
    required this.status,
    this.employeeCount = 0,
    required this.createdAt,
  });

  factory Department.fromMap(String id, Map<String, dynamic> data) {
    return Department(
      id: id,
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? '',
      managerId: data['managerId'],
      managerName: data['managerName'],
      branch: data['branch'] ?? '',
      floor: data['floor'],
      status: data['status'] ?? 'Active',
      employeeCount: data['employeeCount'] ?? 0,
      createdAt: data['createdAt'] is DateTime
          ? data['createdAt'] as DateTime
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'description': description,
      'type': type,
      'managerId': managerId,
      'managerName': managerName,
      'branch': branch,
      'floor': floor,
      'status': status,
      'employeeCount': employeeCount,
      'createdAt': createdAt,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'type': type,
      'managerId': managerId,
      'managerName': managerName,
      'branch': branch,
      'floor': floor,
      'status': status,
      'employeeCount': employeeCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Department.fromJson(Map<String, dynamic> j) {
    return Department(
      id: (j['id'] ?? '').toString(),
      code: (j['code'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      type: (j['type'] ?? 'Other').toString(),
      managerId: j['managerId'] as String?,
      managerName: j['managerName'] as String?,
      branch: (j['branch'] ?? '').toString(),
      floor: j['floor'] as String?,
      status: (j['status'] ?? 'Active').toString(),
      employeeCount: (j['employeeCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  Department copyWith({
    String? id,
    String? code,
    String? name,
    String? description,
    String? type,
    String? managerId,
    String? managerName,
    String? branch,
    String? floor,
    String? status,
    int? employeeCount,
  }) {
    return Department(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      branch: branch ?? this.branch,
      floor: floor ?? this.floor,
      status: status ?? this.status,
      employeeCount: employeeCount ?? this.employeeCount,
      createdAt: createdAt,
    );
  }
}

// ============================================================
// DEVICE STORE (local adds / edits / deletes)
// ============================================================

class DepartmentStore {
  static const _addedKey = 'dept_added';
  static const _editsKey = 'dept_edits';
  static const _deletedKey = 'dept_deleted';

  // ---------- user-added departments ----------
  static Future<List<Department>> loadAdded() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_addedKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Department.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAdded(List<Department> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _addedKey,
      jsonEncode(list.map((d) => d.toJson()).toList()),
    );
  }

  // ---------- edits to API (demo) departments ----------
  static Future<Map<String, Department>> loadEdits() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_editsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return m.map(
            (k, v) => MapEntry(
          k,
          Department.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveEdits(Map<String, Department> edits) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _editsKey,
      jsonEncode(edits.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  // ---------- deleted API departments ----------
  static Future<Set<String>> loadDeleted() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_deletedKey) ?? <String>[]).toSet();
  }

  static Future<void> saveDeleted(Set<String> ids) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_deletedKey, ids.toList());
  }

  static Future<void> resetAll() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_addedKey);
    await p.remove(_editsKey);
    await p.remove(_deletedKey);
  }
}

// ============================================================
// LIST PROVIDER  (VIEW requires internet)
// ============================================================

const String _usersPath = '/users';

const List<String> _demoTypes = [
  'HR',
  'IT',
  'Finance',
  'Operations',
  'Marketing',
  'Sales',
  'Support',
];

final departmentListProvider =
AsyncNotifierProvider<DepartmentListNotifier, List<Department>>(
  DepartmentListNotifier.new,
);

class DepartmentListNotifier extends AsyncNotifier<List<Department>> {
  @override
  Future<List<Department>> build() => _load();

  /// Always requires internet.
  /// Offline → throws → list shows "Internet required".
  Future<List<Department>> _load() async {
    final dio = ref.read(dioProvider);

    try {
      final res = await dio.get(_usersPath);

      final raw =
      res.data is String ? jsonDecode(res.data as String) : res.data;
      final list = raw as List<dynamic>;

      final deleted = await DepartmentStore.loadDeleted();
      final edits = await DepartmentStore.loadEdits();
      final added = await DepartmentStore.loadAdded();

      final fromApi = <Department>[];
      for (var i = 0; i < list.length; i++) {
        final m = Map<String, dynamic>.from(list[i] as Map);
        final apiId = (m['id'] ?? (i + 1)).toString();
        final id = 'API-$apiId';
        if (deleted.contains(id)) continue;

        final n = int.tryParse(apiId) ?? (i + 1);
        final company = m['company'];
        final addr = m['address'];

        final base = Department(
          id: id,
          code: 'DEP-${n.toString().padLeft(3, '0')}',
          name: company is Map
              ? (company['name'] ?? 'Department $n').toString()
              : 'Department $n',
          description:
          company is Map ? (company['catchPhrase'] ?? '').toString() : '',
          type: _demoTypes[(n - 1) % _demoTypes.length],
          branch: addr is Map
              ? (addr['city'] ?? 'Head Office').toString()
              : 'Head Office',
          status: 'Active',
          employeeCount: 0,
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        );

        fromApi.add(edits[id] ?? base);
      }

      // your own departments first, then the demo ones
      return [...added, ...fromApi];
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }

  Future<List<Department>> _current() async {
    final v = state.asData?.value;
    if (v != null) return v;
    return _load();
  }

  Future<void> applyAdd(Department department) async {
    final added = await DepartmentStore.loadAdded();
    await DepartmentStore.saveAdded([department, ...added]);

    final current = await _current();
    state = AsyncData([department, ...current]);
  }

  Future<void> applyUpdate(String id, Department updated) async {
    if (id.startsWith('API-')) {
      final edits = await DepartmentStore.loadEdits();
      edits[id] = updated;
      await DepartmentStore.saveEdits(edits);
    } else {
      final added = await DepartmentStore.loadAdded();
      await DepartmentStore.saveAdded([
        for (final d in added)
          if (d.id == id) updated else d,
      ]);
    }

    final current = await _current();
    state = AsyncData([
      for (final d in current)
        if (d.id == id) updated else d,
    ]);
  }

  Future<void> applyDelete(String id) async {
    if (id.startsWith('API-')) {
      final deleted = await DepartmentStore.loadDeleted();
      deleted.add(id);
      await DepartmentStore.saveDeleted(deleted);

      final edits = await DepartmentStore.loadEdits();
      edits.remove(id);
      await DepartmentStore.saveEdits(edits);
    } else {
      final added = await DepartmentStore.loadAdded();
      await DepartmentStore.saveAdded(
        added.where((d) => d.id != id).toList(),
      );
    }

    final current = await _current();
    state = AsyncData(current.where((d) => d.id != id).toList());
  }

  String generateNextCode() {
    final list = state.asData?.value ?? const <Department>[];
    var highest = 0;
    for (final dept in list) {
      final match = RegExp(r'DEP-(\d+)').firstMatch(dept.code);
      if (match != null) {
        final number = int.tryParse(match.group(1) ?? '') ?? 0;
        if (number > highest) highest = number;
      }
    }
    return 'DEP-${(highest + 1).toString().padLeft(3, '0')}';
  }
}

// ============================================================
// ACTION PROVIDER (ADD / EDIT / DELETE)
// ============================================================

final departmentNotifierProvider =
StateNotifierProvider<DepartmentNotifier, AsyncValue<void>>((ref) {
  return DepartmentNotifier(ref);
});

class DepartmentNotifier extends StateNotifier<AsyncValue<void>> {
  DepartmentNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Dio get _dio => _ref.read(dioProvider);

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

  String _serverId(String id) {
    if (id.startsWith('API-')) {
      final n = int.tryParse(id.replaceFirst('API-', ''));
      if (n != null && n >= 1 && n <= 10) return '$n';
    }
    return '1';
  }

  Map<String, dynamic> _body(Department d) => {
    'name': d.name,
    'username': d.code,
    'company': {'name': d.name, 'catchPhrase': d.description},
    'address': {'city': d.branch, 'street': d.floor ?? ''},
    'type': d.type,
    'status': d.status,
    'managerName': d.managerName,
    'employeeCount': d.employeeCount,
  };

  Future<bool> addDepartment(Department department) async {
    state = const AsyncValue.loading();
    try {
      await _dio.post(_usersPath, data: _body(department));

      final saved = department.copyWith(
        id: 'L${DateTime.now().microsecondsSinceEpoch}',
      );
      await _ref.read(departmentListProvider.notifier).applyAdd(saved);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(ApiException.from(e), st);
      return false;
    }
  }

  Future<bool> updateDepartment(String id, Department department) async {
    state = const AsyncValue.loading();
    try {
      await _dio.put(
        '$_usersPath/${_serverId(id)}',
        data: _body(department),
      );

      await _ref
          .read(departmentListProvider.notifier)
          .applyUpdate(id, department);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(ApiException.from(e), st);
      return false;
    }
  }

  Future<bool> deleteDepartment(String id) async {
    state = const AsyncValue.loading();
    try {
      await _dio.delete('$_usersPath/${_serverId(id)}');

      await _ref.read(departmentListProvider.notifier).applyDelete(id);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(ApiException.from(e), st);
      return false;
    }
  }

  String generateNextCode() {
    return _ref.read(departmentListProvider.notifier).generateNextCode();
  }
}

