// lib/services/employee_storage.dart

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class EmployeeStorage {
  static const _key = 'employees';

  static Future<List<Map<String, dynamic>>> loadEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> saveEmployees(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(list));
  }

  static Future<void> saveEmployee(Map<String, dynamic> employee) async {
    final list = await loadEmployees();
    final id = (employee['employeeId'] ?? '').toString().toUpperCase();

    list.removeWhere(
          (e) => (e['employeeId'] ?? '').toString().toUpperCase() == id,
    );
    list.insert(0, employee);

    await saveEmployees(list);
  }

  static Future<Set<String>> loadEmployeeIds() async {
    final list = await loadEmployees();
    return list
        .map((e) => (e['employeeId'] ?? '').toString().trim().toUpperCase())
        .where((id) => id.isNotEmpty)
        .toSet();
  }
}