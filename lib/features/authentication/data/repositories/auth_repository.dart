import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;

  static const String _emailForSignInKey = 'email_for_sign_in';

  AuthRepository({
    FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> sendSignInLink({
    required String email,
  }) async {
    final actionCodeSettings = ActionCodeSettings(
      url: 'https://family-task-app-2026.firebaseapp.com',
      handleCodeInApp: true,
      androidPackageName: 'com.example.family_task_app',
      androidInstallApp: true,
    );

    await _firebaseAuth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: actionCodeSettings,
    );

    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _emailForSignInKey,
      email,
    );
  }

  Future<bool> isSignInWithEmailLink(String emailLink) async {
    return _firebaseAuth.isSignInWithEmailLink(emailLink);
  }

  Future<UserCredential> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) {
    return _firebaseAuth.signInWithEmailLink(
      email: email,
      emailLink: emailLink,
    );
  }

  Future<String?> getSavedEmail() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getString(
      _emailForSignInKey,
    );
  }

  Future<void> clearSavedEmail() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(
      _emailForSignInKey,
    );
  }

  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }
}