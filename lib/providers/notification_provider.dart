import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/notification/notification_storage.dart';


// ============================================================
// MODEL
// ============================================================

enum NotificationType {
  leave,
  attendance,
  task,
  employee,
  system,
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timeLabel,
    this.isRead = false,
    this.employeeName,
    this.department,
  });

  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final String timeLabel;
  final bool isRead;
  final String? employeeName;
  final String? department;

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    String? timeLabel,
    bool? isRead,
    String? employeeName,
    String? department,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timeLabel: timeLabel ?? this.timeLabel,
      isRead: isRead ?? this.isRead,
      employeeName: employeeName ?? this.employeeName,
      department: department ?? this.department,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'type': type.name,
    'timeLabel': timeLabel,
    'isRead': isRead,
    'employeeName': employeeName,
    'department': department,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: NotificationType.values.firstWhere(
            (e) => e.name == json['type'],
        orElse: () => NotificationType.system,
      ),
      timeLabel: json['timeLabel'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      employeeName: json['employeeName'] as String?,
      department: json['department'] as String?,
    );
  }

  IconData get icon {
    switch (type) {
      case NotificationType.leave:
        return Icons.event_available_outlined;
      case NotificationType.attendance:
        return Icons.access_time_rounded;
      case NotificationType.task:
        return Icons.task_alt_outlined;
      case NotificationType.employee:
        return Icons.person_add_alt_1_outlined;
      case NotificationType.system:
        return Icons.notifications_outlined;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.leave:
        return const Color(0xFFF5A623);
      case NotificationType.attendance:
        return const Color(0xFF2E7D32);
      case NotificationType.task:
        return const Color(0xFF1565C0);
      case NotificationType.employee:
        return const Color(0xFF00897B);
      case NotificationType.system:
        return const Color(0xFF5C6BC0);
    }
  }
}

// ============================================================
// STATE
// ============================================================

class NotificationState {
  const NotificationState({
    this.notifications = const [],
    this.isLoading = true,
  });

  final List<AppNotification> notifications;
  final bool isLoading;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ============================================================
// NOTIFIER  (persistent via SharedPreferences)
// ============================================================

class NotificationNotifier extends Notifier<NotificationState> {
  @override
  NotificationState build() {
    // Load saved data as soon as the provider is created
    Future.microtask(_loadFromStorage);
    return const NotificationState(notifications: [], isLoading: true);
  }

  Future<void> _loadFromStorage() async {
    final list = await NotificationStorage.load();
    state = state.copyWith(notifications: list, isLoading: false);
  }

  Future<void> _persist() async {
    await NotificationStorage.save(state.notifications);
  }

  /// Adds a new notification at the top and saves it.
  Future<void> addNotification(AppNotification notification) async {
    state = state.copyWith(
      notifications: [notification, ...state.notifications],
      isLoading: false,
    );
    await _persist();
  }

  Future<void> markAsRead(String id) async {
    final updated = state.notifications.map((n) {
      if (n.id == id) return n.copyWith(isRead: true);
      return n;
    }).toList();
    state = state.copyWith(notifications: updated);
    await _persist();
  }

  Future<void> markAllAsRead() async {
    final updated =
    state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updated);
    await _persist();
  }

  Future<void> removeNotification(String id) async {
    final updated =
    state.notifications.where((n) => n.id != id).toList();
    state = state.copyWith(notifications: updated);
    await _persist();
  }

  Future<void> clearAll() async {
    state = const NotificationState(notifications: [], isLoading: false);
    await NotificationStorage.clear();
  }
}

// Not autoDispose so data survives navigation
final notificationProvider =
NotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);