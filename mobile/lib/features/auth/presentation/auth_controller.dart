import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/token_storage.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState(this.status, {this.user});
  const AuthState.unknown() : this(AuthStatus.unknown);

  final AuthStatus status;
  final AppUser? user;
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    _restoreSession();
    return const AuthState.unknown();
  }

  Future<void> _restoreSession() async {
    final storage = ref.read(tokenStorageProvider);
    final token = await storage.readToken();

    if (token == null || token.isEmpty) {
      state = const AuthState(AuthStatus.unauthenticated);
      return;
    }

    try {
      final user = await ref.read(authRepositoryProvider).me();
      state = AuthState(AuthStatus.authenticated, user: user);
    } catch (_) {
      await storage.clear();
      state = const AuthState(AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    final result = await ref
        .read(authRepositoryProvider)
        .login(email, password);
    await ref.read(tokenStorageProvider).saveToken(result.token);
    state = AuthState(AuthStatus.authenticated, user: result.user);
  }

  Future<void> register({
    required String fullName,
    required String identificationNumber,
    required String email,
    required String password,
  }) {
    return ref
        .read(authRepositoryProvider)
        .register(
          fullName: fullName,
          identificationNumber: identificationNumber,
          email: email,
          password: password,
        );
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AuthState(AuthStatus.unauthenticated);
  }
}
