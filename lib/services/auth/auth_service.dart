import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
      // Step 1: Validate username format
      if (username.trim().isEmpty) {
        throw Exception('Username cannot be empty');
      }

      if (username.length < 3) {
        throw Exception('Username must be at least 3 characters');
      }

      if (username.length > 20) {
        throw Exception('Username must be less than 20 characters');
      }

      // Only allow alphanumeric and underscores
      final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
      if (!usernameRegex.hasMatch(username)) {
        throw Exception(
          'Username can only contain letters, numbers, and underscores',
        );
      }

      // Step 2: Check if username already exists (case-insensitive)
      final usernameQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.trim())
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        throw Exception('Username already taken. Please choose another one.');
      }

      // Step 3: Create the user with email and password
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Step 4: Save the user's information in a 'users' collection in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'username': username.trim(),
        'friends': [], // Initialize empty friends list
        'lifetimeCompletedTasks': 0, // Lifetime completed tasks counter
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth specific errors
      if (e.code == 'email-already-in-use') {
        throw Exception('This email is already registered');
      } else if (e.code == 'weak-password') {
        throw Exception('Password should be at least 6 characters');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email address');
      } else {
        throw Exception(e.message ?? 'Registration failed');
      }
    } catch (e) {
      // Re-throw custom exceptions
      rethrow;
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

  // ✅ NEW: Get lifetime completed tasks
  Future<int> getLifetimeCompletedTasks() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data()?['lifetimeCompletedTasks'] ?? 0;
    } catch (e) {
      debugPrint('Error getting lifetime tasks: $e');
      return 0;
    }
  }

  // ✅ NEW: Increment lifetime completed tasks
  Future<void> incrementLifetimeCompletedTasks() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'lifetimeCompletedTasks': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error incrementing lifetime tasks: $e');
    }
  }

  // ✅ NEW: Decrement lifetime completed tasks (when uncompleting)
  Future<void> decrementLifetimeCompletedTasks() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get current count to prevent negative values
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final currentCount = doc.data()?['lifegtimeCompletedTasks'] ?? 0;

      if (currentCount > 0) {
        await _firestore.collection('users').doc(user.uid).update({
          'lifetimeCompletedTasks': FieldValue.increment(-1),
        });
      }
    } catch (e) {
      debugPrint('Error decrementing lifetime tasks: $e');
    }
  }
}
