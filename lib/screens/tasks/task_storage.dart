// lib/services/task_storage.dart

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/task_provider.dart';


/// Saves tasks on the device with SharedPreferences so they are still
/// there after the app is closed and opened again.
///
///  • local   → tasks created inside the app
///  • edited  → edited versions of server tasks (id → task)
///  • deleted → ids of server tasks the user deleted
class TaskStorage {
  static const _localKey = 'tasks_local_v1';
  static const _editedKey = 'tasks_edited_v1';
  static const _deletedKey = 'tasks_deleted_v1';

  // ------------------------------------------------------------
  // SAVE
  // ------------------------------------------------------------
  static Future<void> saveAll({
    required List<Task> local,
    required Map<String, Task> edited,
    required Set<String> deleted,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _localKey,
      jsonEncode(local.map(_toMap).toList()),
    );

    await prefs.setString(
      _editedKey,
      jsonEncode(edited.map((id, t) => MapEntry(id, _toMap(t)))),
    );

    await prefs.setStringList(_deletedKey, deleted.toList());
  }

  // ------------------------------------------------------------
  // LOAD
  // ------------------------------------------------------------
  static Future<List<Task>> loadLocalTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Task.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, Task>> loadEditedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_editedKey);
    if (raw == null || raw.isEmpty) return {};

    try {
      final map = jsonDecode(raw) as Map;
      return map.map(
            (id, e) => MapEntry(
          id.toString(),
          Task.fromJson(Map<String, dynamic>.from(e as Map)),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  static Future<Set<String>> loadDeletedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_deletedKey) ?? const <String>[]).toSet();
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------
  static Map<String, dynamic> _toMap(Task t) => {
    ...t.toJson(),
    'id': t.id, // toJson() does not include the id
  };
}