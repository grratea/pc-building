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
  Future<User?> registerWithEmailPassword(String email, String password,
      String username) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user != null) {
        await _createUserDocument(
            result.user!, email, username); // Pass username
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
  Future<void> _createUserDocument(User user, String email,
      String username) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'email': email,
        'username': username, // Store the username
        'createdAt': FieldValue.serverTimestamp(),
      });
      print("User document created for ${user.uid}");
    } catch (e) {
      print("Error creating user document: $e");
    }
  }

  Future<void> _ensureUserDocument(User user, [String username = '']) async {
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        // Pass username or fallback to empty string
        await _createUserDocument(user, user.email ?? '', username);
      }
    } catch (e) {
      print("Error ensuring user document: $e");
    }
  }

}