import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================
// STATE (multiple values)
// ============================================================

class RoleState {
  const RoleState({
    this.role = 'Super Admin',
    this.userName = 'Awais',
    this.userEmail = '',
    this.companyName = 'Section Soft',
  });

  final String role;
  final String userName;
  final String userEmail;
  final String companyName;

  RoleState copyWith({
    String? role,
    String? userName,
    String? userEmail,
    String? companyName,
  }) {
    return RoleState(
      role: role ?? this.role,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      companyName: companyName ?? this.companyName,
    );
  }
}

// ============================================================
// ASYNC NOTIFIER
// ============================================================

class RoleNotifier extends AsyncNotifier<RoleState> {
  @override
  Future<RoleState> build() async {

    return const RoleState();
  }

  RoleState get _current => state.value ?? const RoleState();

  void setRole(String role) {
    state = AsyncData(_current.copyWith(role: role));
  }

  void setUserName(String name) {
    state = AsyncData(_current.copyWith(userName: name));
  }

  void setUserEmail(String email) {
    state = AsyncData(_current.copyWith(userEmail: email));
  }

  void setCompanyName(String name) {
    state = AsyncData(_current.copyWith(companyName: name));
  }

  void setProfile({
    String? role,
    String? userName,
    String? userEmail,
    String? companyName,
  }) {
    state = AsyncData(
      _current.copyWith(
        role: role,
        userName: userName,
        userEmail: userEmail,
        companyName: companyName,
      ),
    );
  }


  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // TODO: real fetch

      return const RoleState();
    });
  }

  void reset() {
    state = const AsyncData(RoleState());
  }
}


final roleProvider =
AsyncNotifierProvider<RoleNotifier, RoleState>(RoleNotifier.new);

const List<String> availableRoles = [
  'Super Admin',
  'Admin',
  'HR',
  'Manager',
  'Employee',
];

