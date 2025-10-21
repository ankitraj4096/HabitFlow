import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AuthService {
  // Firebase Auth and Firestore instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  User? getCurrentUser() {
    return _auth.currentUser;
  }


  // Sign in with email and password
  Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }


  // Sign up with email, password, and username
  Future<UserCredential> signUpWithEmailPassword(
    String email,
    String password,
    String username,
  ) async {
    try {
      // Step 1: Create the user with email and password
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);


      // Step 2: Save the user's information in a 'users' collection in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'username': username,
        'friends': [], // Initialize empty friends list
      });


      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Catch and re-throw specific Firebase exceptions
      throw Exception(e.message);
    }
  }


  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }


  // Update username
  Future<void> updateUsername(String newUsername) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');


      // Check if username already exists
      final usernameQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: newUsername)
          .get();


      if (usernameQuery.docs.isNotEmpty) {
        // Check if it's not the current user's username
        if (usernameQuery.docs.first.id != user.uid) {
          throw Exception('Username already taken');
        }
      }


      // Update username in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'username': newUsername,
      });
    } catch (e) {
      throw Exception(e.toString());
    }
  }


  // Change password (Instagram style - requires current password)
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');


      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );


      await user.reauthenticateWithCredential(credential);


      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('Current password is incorrect');
      } else if (e.code == 'weak-password') {
        throw Exception('New password is too weak');
      } else {
        throw Exception(e.message ?? 'Failed to change password');
      }
    }
  }


  // Get current username
  Future<String> getCurrentUsername() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');


      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data()?['username'] ?? 'User';
    } catch (e) {
      return 'User';
    }
  }
}
