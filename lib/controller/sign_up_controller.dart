// lib/controller/sign_up_controller.dart

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;

import '../auth_river_pod/auth_state.dart';

class SignUpController extends StateNotifier<AuthState> {
  SignUpController() : super(const AuthState());

  Future<void> signUp({
    required String name,
    required String username,
    required String password,
  }) async {
    // Start loading
    state = state.copyWith(
      status: AuthStatus.loading,
      errorMessage: null,
    );

    try {
      final response = await http.post(
        Uri.parse('https://jsonplaceholder.typicode.com/users'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'name': name.trim(),
          'username': username.trim(),
          'password': password, // optional field (API will just echo it)
          // you can also send email if you want:
          // 'email': '$username@example.com',
        }),
      );

      final data = jsonDecode(response.body);

      // JSONPlaceholder returns 201 Created on successful POST
      if (response.statusCode == 201 || response.statusCode == 200) {
        state = state.copyWith(
          status: AuthStatus.success,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: data['message']?.toString() ??
              'Sign up failed. Please try again.',
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

/// Provider
final signUpControllerProvider =
StateNotifierProvider<SignUpController, AuthState>((ref) {
  return SignUpController();
});