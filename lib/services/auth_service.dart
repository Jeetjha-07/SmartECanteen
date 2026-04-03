import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static AppUser? _currentUser;

  static AppUser? get currentUser => _currentUser;
  static bool get isLoggedIn =>
      _auth.currentUser != null && _currentUser != null;
  static String get userName => _currentUser?.name ?? '';
  static String get userEmail => _currentUser?.email ?? '';
  static bool get isRestaurant => _currentUser?.isRestaurant ?? false;

  // Stream to listen to auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Load user data from MongoDB backend
  static Future<AppUser?> loadCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    try {
      // Fetch user data from MongoDB backend instead of Firestore
      final userData = await ApiService.getCurrentUser();

      _currentUser = AppUser(
        uid: userData['_id'] ?? firebaseUser.uid,
        name: userData['name'] ?? '',
        email: userData['email'] ?? '',
        role: userData['role'] == 'restaurant'
            ? UserRole.restaurant
            : UserRole.customer,
        createdAt: DateTime.parse(
            userData['createdAt'] as String? ?? DateTime.now().toString()),
      );
      return _currentUser;
    } catch (e) {
      print('Error loading user: $e');
      return null;
    }
  }

  // Register new user with email/password
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String role = 'customer',
  }) async {
    try {
      // Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Sync user with MongoDB backend
      final result = await ApiService.syncUser(
        name: name,
        role: role,
      );

      if (result['success']) {
        final userRole =
            role == 'restaurant' ? UserRole.restaurant : UserRole.customer;
        _currentUser = AppUser(
          uid: credential.user!.uid,
          name: name,
          email: email,
          role: userRole,
          createdAt: DateTime.now(),
        );
        return {'success': true, 'user': _currentUser};
      } else {
        return {'success': false, 'error': 'Failed to sync user'};
      }
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getAuthError(e.code)};
    } catch (e) {
      return {'success': false, 'error': 'An unexpected error occurred: $e'};
    }
  }

  // Login with email/password
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = await loadCurrentUser();

      if (user == null) {
        return {'success': false, 'error': 'User data not found'};
      }

      return {'success': true, 'user': user};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getAuthError(e.code)};
    } catch (e) {
      return {'success': false, 'error': 'An unexpected error occurred: $e'};
    }
  }

  // Google Sign-In
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'error': 'Google sign-in cancelled'};
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Sync user with MongoDB backend
      await ApiService.syncUser(
        name: googleUser.displayName ?? 'User',
        role: 'customer',
      );

      final user = await loadCurrentUser();
      if (user == null) {
        return {'success': false, 'error': 'Failed to load user data'};
      }

      return {'success': true, 'user': user};
    } catch (e) {
      return {'success': false, 'error': 'Google sign-in failed: $e'};
    }
  }

  // Logout
  static Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  // Password reset
  static Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {'success': true, 'message': 'Password reset email sent'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': _getAuthError(e.code)};
    } catch (e) {
      return {'success': false, 'error': 'An error occurred: $e'};
    }
  }

  // Error message helper
  static String _getAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'Email already registered';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      default:
        return 'Authentication error: $code';
    }
  }
}
