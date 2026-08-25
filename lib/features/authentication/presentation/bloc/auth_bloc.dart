import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/deep_link_service.dart';

import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final DeepLinkService _deepLinkService;

  StreamSubscription<Uri>? _deepLinkSubscription;

  AuthBloc({required this._authRepository, required this._deepLinkService})
    : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthEmailLinkReceived>(_onEmailLinkReceived);
    on<AuthLogoutRequested>(_onLogoutRequested);

    _deepLinkSubscription = _deepLinkService.uriStream.listen((uri) {
      add(AuthEmailLinkReceived(emailLink: uri.toString()));
    });
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = _authRepository.currentUser;

    if (user != null) {
      emit(AuthAuthenticated(user));
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
      await _authRepository.sendSignInLink(email: event.email);

      emit(AuthLinkSent());
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(e.message ?? 'Failed to send sign-in link.'));
    } catch (_) {
      emit(AuthFailure('Something went wrong while sending the sign-in link.'));
    }
  }

  Future<void> _onEmailLinkReceived(
    AuthEmailLinkReceived event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final isEmailLink = await _authRepository.isSignInWithEmailLink(
        event.emailLink,
      );

      if (!isEmailLink) {
        emit(AuthFailure('Invalid sign-in link.'));
        return;
      }

      final email = await _authRepository.getSavedEmail();

      if (email == null || email.isEmpty) {
        emit(AuthFailure('Could not find the email used for sign-in.'));
        return;
      }

      final result = await _authRepository.signInWithEmailLink(
        email: email,
        emailLink: event.emailLink,
      );

      await _authRepository.clearSavedEmail();

      final user = result.user;

      if (user == null) {
        emit(AuthFailure('Authentication failed.'));
        return;
      }

      emit(AuthAuthenticated(user));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(e.message ?? 'Email link authentication failed.'));
    } catch (_) {
      emit(AuthFailure('Something went wrong while completing sign-in.'));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.signOut();

      emit(AuthUnauthenticated());
    } catch (_) {
      emit(AuthFailure('Logout failed.'));
    }
  }

  Future<void> checkInitialDeepLink() async {
    final uri = await _deepLinkService.getInitialLink();

    if (uri != null) {
      add(AuthEmailLinkReceived(emailLink: uri.toString()));
    }
  }

  @override
  Future<void> close() {
    _deepLinkSubscription?.cancel();
    return super.close();
  }
}
