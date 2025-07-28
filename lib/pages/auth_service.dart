import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of user authentication state
  Stream<User?> get user => _auth.authStateChanges();

  // Sign in with email and password
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user != null) {
        await _ensureUserDocument(result.user!);
      }
      return result.user;
    } catch (e) {
      print("Sign in error: $e");
      return null;
    }
  }

  // Register with email and password
  Future<User?> registerWithEmailPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document after registration
      if (result.user != null) {
        await _createUserDocument(result.user!, email);
      }

      return result.user;
    } catch (e) {
      print("Registration error: $e");
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User user, String email) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print("User document created for ${user.uid}");
    } catch (e) {
      print("Error creating user document: $e");
    }
  }

  // Ensure user document exists (for existing users)
  Future<void> _ensureUserDocument(User user) async {
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        await _createUserDocument(user, user.email ?? '');
      }
    } catch (e) {
      print("Error ensuring user document: $e");
    }
  }
}

