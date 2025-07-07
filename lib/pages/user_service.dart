import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUserDocument(User user) async {
    if (user.email == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email!,
    });
  }
}
