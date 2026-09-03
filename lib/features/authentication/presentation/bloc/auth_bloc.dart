// ignore_for_file: prefer_initializing_formals

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthSignupRequested>(_onSignupRequested);
    on<AuthGoogleLoginRequested>(_onGoogleLoginRequested);
    on<AuthAppleLoginRequested>(_onAppleLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = _authRepository.currentUser;

    if (user != null) {
      final userName = await _authRepository.getUserName(user.uid);

      emit(AuthAuthenticated(user, userName));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final result = await _authRepository.signIn(
        email: event.email,
        password: event.password,
      );

      final user = result.user!;

      final userName = await _authRepository.getUserName(user.uid);

      emit(AuthAuthenticated(user, userName));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(e.message ?? 'Login failed.'));
    } catch (_) {
      emit(AuthFailure('Something went wrong.'));
    }
  }

  Future<void> _onSignupRequested(
    AuthSignupRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final result = await _authRepository.signUp(
        name: event.name,
        email: event.email,
        password: event.password,
      );

      final user = result.user!;

      final userName = await _authRepository.getUserName(user.uid);

      emit(AuthAuthenticated(user, userName));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(e.message ?? 'Signup failed.'));
    } catch (_) {
      emit(AuthFailure('Something went wrong.'));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.signOut();

    emit(AuthUnauthenticated());
  }

  Future<void> _onGoogleLoginRequested(
    AuthGoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _socialLogin(
      _authRepository.signInWithGoogle,
      emit,
      'Google login failed.',
    );
  }

  Future<void> _onAppleLoginRequested(
    AuthAppleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _socialLogin(
      _authRepository.signInWithApple,
      emit,
      'Apple login failed.',
    );
  }

  Future<void> _socialLogin(
    Future<UserCredential> Function() login,
    Emitter<AuthState> emit,
    String fallback,
  ) async {
    emit(AuthLoading());

    try {
      final result = await login();

      final user = result.user!;

      final userName = await _authRepository.getUserName(user.uid);

      emit(AuthAuthenticated(user, userName));
    } on FirebaseAuthException catch (error) {
      emit(AuthFailure(error.message ?? fallback));
    } catch (_) {
      emit(AuthFailure(fallback));
    }
  }
}
