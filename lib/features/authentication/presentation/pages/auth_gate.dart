import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) {
        // Do NOT rebuild AuthGate when loading or when an error occurs during login/signup.
        // Only rebuild AuthGate when authentication status changes.
        return current is AuthAuthenticated ||
            current is AuthUnauthenticated ||
            current is AuthInitial;
      },
      builder: (context, state) {
        if (state is AuthInitial) {
          context.read<AuthBloc>().add(AuthCheckRequested());

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is AuthAuthenticated) {
          return const DashboardPage();
        }

        // Returns LoginPage for AuthUnauthenticated or AuthFailure states
        return const LoginPage();
      },
    );
  }
}
