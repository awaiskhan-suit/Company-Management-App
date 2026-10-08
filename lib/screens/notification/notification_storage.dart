import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/notification_provider.dart';


class NotificationStorage {
  static const _key = 'app_notifications';

  /// Load all saved notifications (newest first is preserved by the list order).
  static Future<List<AppNotification>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Save the full list.
  static Future<void> save(List<AppNotification> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      notifications.map((n) => n.toJson()).toList(),
    );
    await prefs.setString(_key, encoded);
  }

  /// Clear everything.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}