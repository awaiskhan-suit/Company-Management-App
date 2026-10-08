// lib/providers/task_provider.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/tasks/task_storage.dart';
import '../services/api_client.dart'; // ← shared dio + ApiException

// ============================================================
// MODEL
// ============================================================

class Task {
  const Task({
    required this.id,
    required this.taskId,
    required this.title,
    required this.description,
    required this.employee,
    required this.department,
    required this.priority,
    required this.startDate,
    required this.dueDate,
    required this.status,
    required this.progress,
    this.estimatedHours = '0 Hours',
    required this.createdBy,
    this.comments = const [],
    this.attachments = const [],
    this.activityHistory = const [],
    required this.createdAt,
  });

  final String id;
  final String taskId;
  final String title;
  final String description;
  final String employee;
  final String department;
  final String priority;
  final String startDate;
  final String dueDate;
  final String status;
  final double progress; // 0.0 – 1.0
  final String estimatedHours;
  final String createdBy;
  final List<String> comments;
  final List<String> attachments;
  final List<String> activityHistory;
  final String createdAt;

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id']?.toString() ?? '',
      taskId: json['taskId'] ?? json['task_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? json['body'] ?? '',
      employee: json['employee'] ?? json['assignedEmployee'] ?? '',
      department: json['department'] ?? '',
      priority: json['priority'] ?? 'Medium',
      startDate: json['startDate'] ?? json['start_date'] ?? '',
      dueDate: json['dueDate'] ?? json['due_date'] ?? '',
      status: json['status'] ?? 'To Do',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      estimatedHours:
      json['estimatedHours'] ?? json['estimated_hours'] ?? '0 Hours',
      createdBy: json['createdBy'] ?? json['created_by'] ?? '',
      comments: List<String>.from(json['comments'] ?? []),
      attachments: List<String>.from(json['attachments'] ?? []),
      activityHistory: List<String>.from(
          json['activityHistory'] ?? json['activity_history'] ?? []),
      createdAt: json['createdAt'] ??
          json['created_at'] ??
          DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() => {
    'taskId': taskId,
    'title': title,
    'description': description,
    'employee': employee,
    'department': department,
    'priority': priority,
    'startDate': startDate,
    'dueDate': dueDate,
    'status': status,
    'progress': progress,
    'estimatedHours': estimatedHours,
    'createdBy': createdBy,
    'comments': comments,
    'attachments': attachments,
    'activityHistory': activityHistory,
    'createdAt': createdAt,
  };
}

// ============================================================
// FORM STATE (for Add / Edit Task screen)
// ============================================================

class TaskFormState {
  const TaskFormState({
    this.taskId = '',
    this.title = '',
    this.description = '',
    this.assignedEmployee,
    this.department,
    this.priority = 'Medium',
    this.startDate,
    this.dueDate,
    this.status = 'To Do',
    this.progress = 0,
    this.createdBy = 'Awais',
    this.createdDate,
    this.attachmentName = '',
    this.attachmentIsNotes = false,
    this.comments = '',
    this.isSubmitting = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  final String taskId;
  final String title;
  final String description;
  final String? assignedEmployee;
  final String? department;
  final String priority;
  final DateTime? startDate;
  final DateTime? dueDate;
  final String status;
  final int progress;
  final String createdBy;
  final DateTime? createdDate;
  final String attachmentName;
  final bool attachmentIsNotes;
  final String comments;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isSuccess;

  TaskFormState copyWith({
    String? taskId,
    String? title,
    String? description,
    String? assignedEmployee,
    String? department,
    String? priority,
    DateTime? startDate,
    DateTime? dueDate,
    String? status,
    int? progress,
    String? createdBy,
    DateTime? createdDate,
    String? attachmentName,
    bool? attachmentIsNotes,
    String? comments,
    bool? isSubmitting,
    String? errorMessage,
    bool? isSuccess,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return TaskFormState(
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedEmployee: assignedEmployee ?? this.assignedEmployee,
      department: department ?? this.department,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdBy: createdBy ?? this.createdBy,
      createdDate: createdDate ?? this.createdDate,
      attachmentName: attachmentName ?? this.attachmentName,
      attachmentIsNotes: attachmentIsNotes ?? this.attachmentIsNotes,
      comments: comments ?? this.comments,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: clearSuccess ? false : (isSuccess ?? this.isSuccess),
    );
  }
}

// ============================================================
// CONSTANTS
// ============================================================

const List<String> kDepartments = [
  'HR',
  'IT',
  'Finance',
  'Operations',
  'Marketing',
  'Sales',
];

const List<String> kPriorities = ['Low', 'Medium', 'High', 'Urgent'];

const List<String> kTaskStatuses = [
  'To Do',
  'In Progress',
  'On Hold',
  'Completed',
  'Cancelled',
];

// ============================================================
// FORM NOTIFIER (Add / Edit Task)
// ============================================================

class TaskFormNotifier extends Notifier<TaskFormState> {
  @override
  TaskFormState build() {
    return TaskFormState(
      taskId: _generateTaskId(),
      createdDate: DateTime.now(),
      createdBy: 'Awais',
    );
  }

  String _generateTaskId() {
    final n = DateTime.now().millisecondsSinceEpoch % 10000;
    return 'TSK-${n.toString().padLeft(4, '0')}';
  }

  void setTitle(String v) => state = state.copyWith(title: v);
  void setDescription(String v) => state = state.copyWith(description: v);
  void setAssignedEmployee(String? v) =>
      state = state.copyWith(assignedEmployee: v);
  void setDepartment(String? v) => state = state.copyWith(department: v);
  void setPriority(String v) => state = state.copyWith(priority: v);
  void setStartDate(DateTime v) => state = state.copyWith(startDate: v);
  void setDueDate(DateTime v) => state = state.copyWith(dueDate: v);
  void setStatus(String v) => state = state.copyWith(status: v);
  void setProgress(int v) =>
      state = state.copyWith(progress: v.clamp(0, 100));
  void setCreatedBy(String v) => state = state.copyWith(createdBy: v);
  void setAttachmentName(String v) =>
      state = state.copyWith(attachmentName: v);
  void setAttachmentIsNotes(bool v) =>
      state = state.copyWith(attachmentIsNotes: v, attachmentName: '');
  void setComments(String v) => state = state.copyWith(comments: v);

  void reset() {
    state = TaskFormState(
      taskId: _generateTaskId(),
      createdDate: DateTime.now(),
      createdBy: 'Awais',
    );
  }

  String _fmt(DateTime? d) {
    if (d == null) return '';
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day.toString().padLeft(2, '0')} ${m[d.month - 1]} ${d.year}';
  }

  String? validate() {
    if (state.title.trim().isEmpty) return 'Task title is required';
    if (state.assignedEmployee == null || state.assignedEmployee!.isEmpty) {
      return 'Assign an employee';
    }
    if (state.department == null || state.department!.isEmpty) {
      return 'Select department';
    }
    if (state.createdBy.trim().isEmpty) return 'Created By is required';
    if (state.startDate == null) return 'Start date is required';
    if (state.dueDate == null) return 'Due date is required';
    if (state.dueDate!.isBefore(state.startDate!)) {
      return 'Due date must be after start date';
    }
    return null;
  }

  /// Finds the task being edited in the currently loaded list.
  Task? _findOriginal(String id) {
    final list = ref.read(taskListProvider).value ?? const <Task>[];
    for (final t in list) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// [editId] == null  → CREATE a new task (POST)
  /// [editId] != null  → UPDATE the existing task (PUT) – no new record
  Future<bool> submit({String? editId}) async {
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
      final isEdit = editId != null;
      final original = isEdit ? _findOriginal(editId) : null;

      final attachments = <String>[];
      if (state.attachmentName.trim().isNotEmpty) {
        attachments.add(state.attachmentName.trim());
      }

      final taskCode = original?.taskId ?? state.taskId;
      final progress = original?.progress ?? (state.progress / 100.0);

      final body = {
        'title': state.title.trim(),
        'body': state.description.trim(),
        'userId': 1,
        'taskId': taskCode,
        'employee': state.assignedEmployee,
        'department': state.department,
        'priority': state.priority,
        'startDate': state.startDate?.toIso8601String(),
        'dueDate': state.dueDate?.toIso8601String(),
        'status': state.status,
        'progress': progress,
        'createdBy': state.createdBy.trim(),
        'attachments': attachments,
        'comments':
        state.comments.trim().isEmpty ? [] : [state.comments.trim()],
      };

      final dio = ref.read(dioProvider);
      String newId;

      if (isEdit) {
        // ---------------- UPDATE ----------------
        // Tasks created inside the app only exist locally (jsonplaceholder
        // never stored them and answers 404/500 for their id), so there is
        // nothing to update on the server for them.
        // Remove this check when you use a real backend.
        final isLocalOnly =
        ref.read(taskListProvider.notifier).isLocalTask(editId);

        if (!isLocalOnly) {
          final response = await dio.put('/posts/$editId', data: body);
          final code = response.statusCode ?? 0;
          if (code != 200 && code != 201) {
            throw ApiException(
              'Server error ($code). Try again.',
              statusCode: code,
            );
          }
        }
        newId = editId;
      } else {
        // ---------------- CREATE ----------------
        final response = await dio.post('/posts', data: body);
        final code = response.statusCode ?? 0;
        if (code != 200 && code != 201) {
          throw ApiException(
            'Server error ($code). Try again.',
            statusCode: code,
          );
        }
        newId = response.data['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString();
      }

      final task = Task(
        id: newId,
        taskId: taskCode,
        title: state.title.trim(),
        description: state.description.trim(),
        employee: state.assignedEmployee!,
        department: state.department!,
        priority: state.priority,
        startDate: _fmt(state.startDate),
        dueDate: _fmt(state.dueDate),
        status: state.status,
        progress: progress,
        estimatedHours: original?.estimatedHours ?? '0 Hours',
        createdBy: state.createdBy.trim(),
        comments:
        state.comments.trim().isEmpty ? [] : [state.comments.trim()],
        attachments: attachments,
        activityHistory: isEdit
            ? [
          ...?original?.activityHistory,
          'Task updated by ${state.createdBy.trim()}',
        ]
            : [
          'Task created by ${state.createdBy.trim()}',
          'Assigned to ${state.assignedEmployee}',
        ],
        createdAt: original?.createdAt ?? DateTime.now().toIso8601String(),
      );

      final list = ref.read(taskListProvider.notifier);
      if (isEdit) {
        await list.updateTask(task);
      } else {
        await list.addTask(task);
      }

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

final taskProvider =
NotifierProvider.autoDispose<TaskFormNotifier, TaskFormState>(
  TaskFormNotifier.new,
);

// ============================================================
// TASK LIST (no dummy data)
// ============================================================

class TaskListNotifier extends AsyncNotifier<List<Task>> {
  static const _path = '/posts';

  Dio get _dio => ref.read(dioProvider);

  // Tasks created inside the app (jsonplaceholder doesn't persist them)
  List<Task> _localTasks = [];

  // Edited versions of server tasks (id → task)
  final Map<String, Task> _edited = {};

  // Server tasks the user deleted
  final Set<String> _deleted = {};

  bool _restored = false;

  @override
  Future<List<Task>> build() => _load();

  // ------------------------------------------------------------
  // PERSISTENT STORAGE (SharedPreferences)
  // ------------------------------------------------------------

  /// Reads saved tasks from the device (only once per app run).
  Future<void> _restore() async {
    if (_restored) return;

    _localTasks = await TaskStorage.loadLocalTasks();
    _edited
      ..clear()
      ..addAll(await TaskStorage.loadEditedTasks());
    _deleted
      ..clear()
      ..addAll(await TaskStorage.loadDeletedIds());

    _restored = true;
  }

  /// Writes the current local / edited / deleted data to the device.
  Future<void> _persist() {
    return TaskStorage.saveAll(
      local: _localTasks,
      edited: _edited,
      deleted: _deleted,
    );
  }

  /// True for tasks created inside the app (not present on the server).
  bool isLocalTask(String id) => _localTasks.any((t) => t.id == id);

  Future<bool> isOnline() async {
    try {
      await _dio
          .head(
        _path,
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

  Future<List<Task>> _load() async {
    await _restore();

    try {
      final res = await _dio.get(_path);

      final remote = (res.data as List)
          .map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final t = Task.fromJson({
          ...m,
          'description': m['body'],
          'taskId': 'TASK-${m['id']}',
        });
        // Use the locally edited version if this task was edited.
        return _edited[t.id] ?? t;
      })
      // Hide server tasks the user deleted.
          .where((t) => !_deleted.contains(t.id))
          .toList();

      // Merge saved local tasks + remote
      final localIds = _localTasks.map((t) => t.id).toSet();
      final merged = [
        ..._localTasks,
        ...remote.where((t) => !localIds.contains(t.id)),
      ];

      return merged;
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }

  Future<void> addTask(Task task) async {
    if (!await isOnline()) {
      throw const ApiException(
        'No internet connection. Connect and try again.',
      );
    }

    _localTasks = [task, ..._localTasks];
    await _persist(); // ★ save to device

    final current = state.value ?? [];
    state = AsyncData([task, ...current]);
  }

  /// Replaces the existing task (same id) – does NOT create a new one.
  Future<void> updateTask(Task task) async {
    if (!await isOnline()) {
      throw const ApiException(
        'No internet connection. Connect and try again.',
      );
    }

    final isLocal = _localTasks.any((t) => t.id == task.id);
    if (isLocal) {
      _localTasks =
          _localTasks.map((t) => t.id == task.id ? task : t).toList();
    } else {
      _edited[task.id] = task;
    }
    await _persist(); // ★ save to device

    final current = state.value ?? [];
    state = AsyncData(
      current.map((t) => t.id == task.id ? task : t).toList(),
    );
  }

  Future<void> deleteTask(String id) async {
    try {
      await _dio.delete('$_path/$id');

      final wasLocal = _localTasks.any((t) => t.id == id);
      _localTasks = _localTasks.where((t) => t.id != id).toList();
      _edited.remove(id);
      if (!wasLocal) _deleted.add(id); // keep deleted server tasks hidden
      await _persist(); // ★ save to device

      final current = state.value ?? [];
      state = AsyncData(current.where((t) => t.id != id).toList());
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}

final taskListProvider =
AsyncNotifierProvider<TaskListNotifier, List<Task>>(TaskListNotifier.new);

