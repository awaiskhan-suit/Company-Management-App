import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dummy repository standing in for real network calls.
/// Replace the body of each method with your actual API/auth SDK calls.
class AuthRepository {
  const AuthRepository();

  Future<void> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    // TODO: replace with a real login API call.
    if (email == 'fail@example.com') {
      throw Exception('Invalid email or password');
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    // TODO: replace with a real sign-up API call.
    if (email == 'taken@example.com') {
      throw Exception('An account with this email already exists');
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return const AuthRepository();
});