

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ApiOverlay {
  static const _editsKey = 'api_edits';
  static const _deletedKey = 'api_deleted';

  // ---------------- EDITS ----------------

  static Future<Map<String, Map<String, dynamic>>> loadEdits() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_editsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return m.map(
            (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
      );
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveEdit(String id, Map<String, dynamic> data) async {
    final p = await SharedPreferences.getInstance();
    final edits = await loadEdits();
    edits[id] = data;
    await p.setString(_editsKey, jsonEncode(edits));
  }

  // ---------------- DELETES ----------------

  static Future<Set<String>> loadDeleted() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_deletedKey) ?? <String>[]).toSet();
  }

  static Future<void> markDeleted(String id) async {
    final p = await SharedPreferences.getInstance();

    final deleted = await loadDeleted();
    deleted.add(id);
    await p.setStringList(_deletedKey, deleted.toList());

    final edits = await loadEdits();
    edits.remove(id);
    await p.setString(_editsKey, jsonEncode(edits));
  }

  /// Optional: bring all demo employees back.
  static Future<void> resetAll() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_editsKey);
    await p.remove(_deletedKey);
  }
}

