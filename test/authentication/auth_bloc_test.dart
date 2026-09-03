import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:family_task_app/features/authentication/data/repositories/auth_repository.dart';
import 'package:family_task_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:family_task_app/features/authentication/presentation/bloc/auth_event.dart';
import 'package:family_task_app/features/authentication/presentation/bloc/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

void main() {
  late MockAuthRepository repository;
  late MockUserCredential credential;
  late MockUser user;

  setUp(() {
    repository = MockAuthRepository();
    credential = MockUserCredential();
    user = MockUser();
    when(() => credential.user).thenReturn(user);
    when(() => user.uid).thenReturn('user-123');
    when(() => repository.getUserName('user-123'))
        .thenAnswer((_) async => 'Test User');
  });

  test('login emits loading then authenticated', () async {
    when(() => repository.signIn(email: 'user@test.com', password: 'secret'))
        .thenAnswer((_) async => credential);
    final bloc = AuthBloc(authRepository: repository);

    final states = expectLater(
      bloc.stream,
      emitsInOrder([isA<AuthLoading>(), isA<AuthAuthenticated>()]),
    );
    bloc.add(AuthLoginRequested(email: 'user@test.com', password: 'secret'));

    await states;
    verify(() => repository.signIn(email: 'user@test.com', password: 'secret'))
        .called(1);
    await bloc.close();
  });

  test('login failure emits an auth failure', () async {
    when(() => repository.signIn(email: 'user@test.com', password: 'secret'))
        .thenThrow(FirebaseAuthException(code: 'invalid-credential'));
    final bloc = AuthBloc(authRepository: repository);

    final states = expectLater(bloc.stream, emitsThrough(isA<AuthFailure>()));
    bloc.add(AuthLoginRequested(email: 'user@test.com', password: 'secret'));

    await states;
    expect(bloc.state, isA<AuthFailure>());
    await bloc.close();
  });

  test('logout signs out and emits unauthenticated', () async {
    when(() => repository.signOut()).thenAnswer((_) async {});
    final bloc = AuthBloc(authRepository: repository);

    final states = expectLater(bloc.stream, emits(isA<AuthUnauthenticated>()));
    bloc.add(AuthLogoutRequested());

    await states;
    verify(() => repository.signOut()).called(1);
    await bloc.close();
  });
}
