import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      _isLoading = true;

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Save user profile to RTDB
      if (userCredential.user != null) {
        final user = userCredential.user!;
        await _db.ref('users/${user.uid}/profile').update({
          'uid': user.uid,
          'displayName': user.displayName ?? '',
          'email': user.email ?? '',
          'photoUrl': user.photoURL ?? '',
          'lastLogin': DateTime.now().toIso8601String(),
        });
      }

      _isLoading = false;
      return userCredential;
    } catch (e) {
      _isLoading = false;
      rethrow;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } finally {
      _isLoading = false;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = currentUser;
    if (user == null) return null;
    final snap = await _db.ref('users/${user.uid}/profile').get();
    if (snap.exists) return Map<String, dynamic>.from(snap.value as Map);
    return null;
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final user = currentUser;
    if (user == null) return;
    await _db.ref('users/${user.uid}/profile').update(data);
  }
}
