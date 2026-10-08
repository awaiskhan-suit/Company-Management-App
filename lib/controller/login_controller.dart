// lib/controller/login_controller.dart

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;

import '../auth_river_pod/auth_state.dart';

class LoginController extends StateNotifier<AuthState> {
  LoginController() : super(const AuthState());

  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      errorMessage: null,
    );

    try {
      final response = await http.post(
        Uri.parse('https://dummyjson.com/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.trim(),
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Optional: save tokens
        // final accessToken = data['accessToken'];
        // final refreshToken = data['refreshToken'];

        state = state.copyWith(status: AuthStatus.success);
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: data['message'] ?? 'Invalid username or password',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Something went wrong. Check your internet connection.',
      );
    }
  }

  void reset() {
    state = const AuthState();
  }
}

final loginControllerProvider =
StateNotifierProvider<LoginController, AuthState>((ref) {
  return LoginController();
});