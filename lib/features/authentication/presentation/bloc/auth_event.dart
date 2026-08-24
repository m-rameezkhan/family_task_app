abstract class AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;

  AuthLoginRequested({
    required this.email,
  });
}

class AuthEmailLinkReceived extends AuthEvent {
  final String emailLink;

  AuthEmailLinkReceived({
    required this.emailLink,
  });
}

class AuthLogoutRequested extends AuthEvent {}