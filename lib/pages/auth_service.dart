import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Stream<User?> get user => auth.authStateChanges();

  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user != null) {
        await checkUserDocument(result.user!);
      }
      return result.user;
    } catch (e) {
      print("Sign in error: $e");
      return null;
    }
  }
  Future<User?> register(
    String email,
    String password,
    String username,
  ) async {
    try {
      UserCredential result = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user != null) {
        await createUserDocument(result.user!, email, username);
      }
      return result.user;
    } catch (e) {
      print("Registration error: $e");
      return null;
    }
  }
  Future<void> signOut() async {
    await auth.signOut();
  }

  Future<void> createUserDocument(
    User user,
    String email,
    String username,
  ) async {
    try {
      await firestore.collection('users').doc(user.uid).set({
        'email': email,
        'username': username,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print("User document created for ${user.uid}");
    } catch (e) {
      print("Error creating user document: $e");
    }
  }

  Future<void> checkUserDocument(User user, [String username = '']) async {
    try {
      final doc = await firestore.collection('users').doc(user.uid).get();

      /*if (!doc.exists) {
        await createUserDocument(user, user.email ?? '', username);
      }*/
    } catch (e) {
      print("Error ensuring user document: $e");
    }
  }
}
