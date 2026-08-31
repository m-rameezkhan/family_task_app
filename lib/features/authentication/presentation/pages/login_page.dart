import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const _darkTeal = Color(0xff173F4F);
  static const _teal = Color(0xff246B73);
  static const _yellow = Color(0xffF6B44B);
  static const _textGrey = Color(0xff4D6870);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Maps backend/Firebase errors to user-friendly messages
  String _formatErrorMessage(String rawError) {
    final lower = rawError.toLowerCase();
    if (lower.contains('credential') ||
        lower.contains('password') ||
        lower.contains('user-not-found') ||
        lower.contains('invalid-email') ||
        lower.contains('expired')) {
      return 'Invalid email or password';
    }
    return rawError;
  }

  void _login() {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    // Email validation
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email');
      return;
    } else if (!emailRegex.hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    // Password validation
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password');
      return;
    } else if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    // Clear local error if validation passes
    setState(() => _errorMessage = null);

    context.read<AuthBloc>().add(
      AuthLoginRequested(email: email, password: password),
    );
  }

  void _navigateToSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignupPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          setState(() {
            _errorMessage = _formatErrorMessage(state.message);
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // App branding
                          Container(
                            width: 78,
                            height: 78,
                            decoration: const BoxDecoration(
                              color: _yellow,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.family_restroom,
                              size: 44,
                              color: _darkTeal,
                            ),
                          ),

                          const SizedBox(height: 16),

                          const Text(
                            'Welcome Back',
                            style: TextStyle(
                              color: _darkTeal,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 6),

                          const Text(
                            'Sign in to continue managing your family tasks',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _textGrey,
                              fontSize: 15,
                              height: 1.35,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Server or Validation Error Display
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _errorMessage != null
                                ? Container(
                                    key: const ValueKey('error_box'),
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xffFDE8E8),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.red.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox(
                                    key: ValueKey('empty_box'),
                                    height: 12,
                                  ),
                          ),

                          // Email
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) {
                              if (_errorMessage != null) {
                                setState(() => _errorMessage = null);
                              }
                            },
                            decoration: _inputDecoration(
                              label: 'Email',
                              hint: 'Enter your email',
                              icon: Icons.email_outlined,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Password
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _login(),
                            onChanged: (_) {
                              if (_errorMessage != null) {
                                setState(() => _errorMessage = null);
                              }
                            },
                            decoration: _inputDecoration(
                              label: 'Password',
                              hint: 'Enter your password',
                              icon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: _textGrey,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Login button
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              final isLoading = state is AuthLoading;

                              return SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _teal,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Sign In',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          // Divider
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(color: Color(0xffE0E7E9)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                child: Text(
                                  'or continue with',
                                  style: TextStyle(
                                    color: _textGrey.withValues(alpha: 0.8),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(color: Color(0xffE0E7E9)),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Google login
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              final isLoading = state is AuthLoading;

                              return _SocialLoginButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        context.read<AuthBloc>().add(
                                          AuthGoogleLoginRequested(),
                                        );
                                      },
                                icon: const _GoogleLogo(),
                                label: 'Continue with Google',
                              );
                            },
                          ),

                          const SizedBox(height: 10),

                          // Apple login
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              final isLoading = state is AuthLoading;

                              return _SocialLoginButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        context.read<AuthBloc>().add(
                                          AuthAppleLoginRequested(),
                                        );
                                      },
                                icon: const Icon(
                                  Icons.apple,
                                  size: 25,
                                  color: Colors.black,
                                ),
                                label: 'Continue with Apple',
                              );
                            },
                          ),

                          const SizedBox(height: 14),

                          // Signup
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account?",
                                style: TextStyle(
                                  color: _textGrey,
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: _navigateToSignup,
                                style: TextButton.styleFrom(
                                  foregroundColor: _teal,
                                  padding: const EdgeInsets.only(left: 6),
                                ),
                                child: const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _teal),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xffF8FAFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xffDCE5E7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xffDCE5E7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _teal, width: 1.8),
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String label;

  const _SocialLoginButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xff173F4F),
          side: const BorderSide(color: Color(0xffDCE5E7)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        color: Color(0xff4285F4),
        fontSize: 23,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
