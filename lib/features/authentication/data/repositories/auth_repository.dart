import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;

  AuthRepository({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  // =========================
  // Email & Password Sign In
  // =========================

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final result = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _saveUserProfile(result.user!, provider: 'email');

    return result;
  }

  // =========================
  // Email & Password Sign Up
  // =========================

  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final result = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Save name in Firebase Authentication profile.
    await result.user!.updateDisplayName(name.trim());

    // Reload to get the updated Firebase user data.
    await result.user!.reload();

    final updatedUser = _firebaseAuth.currentUser!;

    await _saveUserProfile(updatedUser, provider: 'email', name: name);

    return result;
  }

  // =========================
  // Google Sign In
  // =========================

  Future<UserCredential> signInWithGoogle() {
    final provider = GoogleAuthProvider();

    provider.addScope('email');
    provider.addScope('profile');

    return _signInWithProvider(provider, 'google');
  }

  // =========================
  // Apple Sign In
  // =========================

  Future<UserCredential> signInWithApple() {
    return _signInWithProvider(OAuthProvider('apple.com'), 'apple');
  }

  // =========================
  // Generic Provider Sign In
  // =========================

  Future<UserCredential> _signInWithProvider(
    AuthProvider provider,
    String providerName,
  ) async {
    final result = await _firebaseAuth.signInWithProvider(provider);

    final user = result.user!;

    String? googleName;

    if (providerName == 'google') {
      final profile = result.additionalUserInfo?.profile;

      if (profile != null) {
        googleName = profile['name'] as String?;
      }
    }

    await _saveUserProfile(user, provider: providerName, name: googleName);

    return result;
  }
  // =========================
  // Save / Update User Profile
  // =========================

  Future<void> _saveUserProfile(
    User user, {
    required String provider,
    String? name,
  }) async {
    final reference = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    // Check whether the user already exists in Firestore.
    final existing = await reference.get();

    // Try to get the display name from provider data.
    String? providerDisplayName;

    for (final providerData in user.providerData) {
      // Prefer the current provider.
      if (providerData.providerId == _getProviderId(provider)) {
        final displayName = providerData.displayName;

        if (displayName != null && displayName.trim().isNotEmpty) {
          providerDisplayName = displayName.trim();
          break;
        }
      }
    }

    // Existing Firestore data.
    final existingData = existing.data();

    final existingName = existingData?['name'] as String?;

    // Name priority:
    //
    // 1. Explicit name (Email Sign Up)
    // 2. Firebase Authentication displayName
    // 3. Provider displayName (Google / Apple)
    // 4. Existing Firestore name
    // 5. Name generated from email
    String? resolvedName;

    if (name != null && name.trim().isNotEmpty) {
      resolvedName = name.trim();
    } else if (user.displayName != null &&
        user.displayName!.trim().isNotEmpty) {
      resolvedName = user.displayName!.trim();
    } else if (providerDisplayName != null &&
        providerDisplayName.trim().isNotEmpty) {
      resolvedName = providerDisplayName.trim();
    } else if (existingName != null && existingName.trim().isNotEmpty) {
      resolvedName = existingName.trim();
    } else {
      resolvedName = _nameFromEmail(user.email);
    }

    final data = <String, dynamic>{
      'uid': user.uid,
      'name': resolvedName,
      'email': user.email,
      'photoUrl': user.photoURL,
      'provider': provider,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Only set createdAt when the user is created for the first time.
    if (!existing.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await reference.set(data, SetOptions(merge: true));
  }

  // =========================
  // Firebase Provider ID
  // =========================

  String _getProviderId(String provider) {
    switch (provider) {
      case 'google':
        return 'google.com';

      case 'apple':
        return 'apple.com';

      case 'email':
        return 'password';

      default:
        return provider;
    }
  }

  // =========================
  // Generate Name From Email
  // =========================

  String _nameFromEmail(String? email) {
    final localPart = email?.split('@').first.trim() ?? '';

    return localPart.isEmpty ? 'Family member' : localPart;
  }

  // =========================
  // Get  User Name
  // =========================

  Future<String> getUserName(String uid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final data = snapshot.data();

    final name = data?['name'] as String?;

    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }

    return 'Family member';
  }

  // =========================
  // Sign Out
  // =========================

  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }
}
