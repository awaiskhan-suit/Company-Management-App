import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart'; // shared dio + ApiException
import 'notification_provider.dart';

// ============================================================
// STATE
// ============================================================

class SendNotificationState {
  const SendNotificationState({
    this.employeeName = '',
    this.department = '',
    this.description = '',
    this.isSubmitting = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  final String employeeName;
  final String department;
  final String description;

  final bool isSubmitting;
  final String? errorMessage;
  final bool isSuccess;

  SendNotificationState copyWith({
    String? employeeName,
    String? department,
    String? description,
    bool? isSubmitting,
    String? errorMessage,
    bool? isSuccess,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return SendNotificationState(
      employeeName: employeeName ?? this.employeeName,
      department: department ?? this.department,
      description: description ?? this.description,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: clearSuccess ? false : (isSuccess ?? this.isSuccess),
    );
  }
}

// ============================================================
// DATE / TIME HELPER
// ============================================================

/// Returns a readable date + time, e.g. "08 Oct 2026, 12:22 PM"
String _formatNow() {
  final n = DateTime.now();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final day = n.day.toString().padLeft(2, '0');
  final month = months[n.month - 1];
  final year = n.year;
  final hour12 = n.hour % 12 == 0 ? 12 : n.hour % 12;
  final minute = n.minute.toString().padLeft(2, '0');
  final ampm = n.hour >= 12 ? 'PM' : 'AM';
  return '$day $month $year, $hour12:$minute $ampm';
}

// ============================================================
// NOTIFIER
// ============================================================

class SendNotificationNotifier extends Notifier<SendNotificationState> {
  @override
  SendNotificationState build() => const SendNotificationState();

  void setEmployee(String name, String department) {
    state = state.copyWith(
      employeeName: name,
      department: department,
    );
  }

  void setDescription(String v) => state = state.copyWith(description: v);

  void reset() => state = const SendNotificationState();

  void clearStatus() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  String? validate() {
    if (state.employeeName.trim().isEmpty) {
      return 'Please select an employee';
    }
    if (state.description.trim().isEmpty) {
      return 'Description is required';
    }
    if (state.description.trim().length < 5) {
      return 'Description must be at least 5 characters';
    }
    return null;
  }

  // ============================================================
  // SUBMIT → API + persistent local save (SharedPreferences)
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
        'title': 'Notification for ${state.employeeName.trim()}',
        'body': state.description.trim(),
        'userId': 1,
        'employeeName': state.employeeName.trim(),
        'department': state.department.trim(),
      };

      // ★ Shared Dio (Auth + Logging + Retry + ErrorMapper)
      final dio = ref.read(dioProvider);

      final response = await dio.post('/posts', data: body);

      final code = response.statusCode ?? 0;
      if (code != 200 && code != 201) {
        throw ApiException(
          'Server error ($code). Try again.',
          statusCode: code,
        );
      }

      // Server accepted → save locally (SharedPreferences)
      final newId = DateTime.now().millisecondsSinceEpoch.toString();

      final notification = AppNotification(
        id: newId,
        title: 'Notification • ${state.employeeName.trim()}',
        message: state.description.trim(),
        type: NotificationType.system,
        timeLabel: _formatNow(), // e.g. "08 Oct 2026, 12:22 PM"
        employeeName: state.employeeName.trim(),
        department: state.department.trim(),
      );

      // ★ await so data is written to SharedPreferences before success
      await ref
          .read(notificationProvider.notifier)
          .addNotification(notification);

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

final sendNotificationProvider = NotifierProvider.autoDispose<
    SendNotificationNotifier, SendNotificationState>(
  SendNotificationNotifier.new,
);
