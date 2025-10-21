import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Search for users by their username
  Stream<List<Map<String, dynamic>>> searchUsers(String query) {
    if (query.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
  }

  /// Get all users (for browsing)
  Stream<List<Map<String, dynamic>>> getAllUsers() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => doc.data())
          .where(
            (user) => user['uid'] != currentUser.uid,
          ) // Exclude current user
          .toList();
    });
  }

  /// Check if a friend request already exists between two users
  Future<String?> checkExistingRequest(String toUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    // Check if current user sent a request to this user
    final sentRequest = await _firestore
        .collection('friend_requests')
        .where('from_uid', isEqualTo: currentUser.uid)
        .where('to_uid', isEqualTo: toUserId)
        .where('status', isEqualTo: 'pending')
        .get();

    if (sentRequest.docs.isNotEmpty) {
      return 'sent'; // You sent a request
    }

    // Check if this user sent a request to current user
    final receivedRequest = await _firestore
        .collection('friend_requests')
        .where('from_uid', isEqualTo: toUserId)
        .where('to_uid', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .get();

    if (receivedRequest.docs.isNotEmpty) {
      return 'received'; // You received a request
    }

    return null; // No pending request
  }

  /// Check if two users are already friends
  Future<bool> areFriends(String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    final userDoc = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (!userDoc.exists || userDoc.data()?['friends'] == null) {
      return false;
    }

    List<String> friends = List<String>.from(userDoc.data()!['friends']);
    return friends.contains(userId);
  }

  /// Send a friend request to another user
  Future<void> sendFriendRequest(String toUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Check if a request already exists
    final existingRequest = await checkExistingRequest(toUserId);
    if (existingRequest != null) {
      throw Exception('A friend request already exists');
    }

    // Check if already friends
    final alreadyFriends = await areFriends(toUserId);
    if (alreadyFriends) {
      throw Exception('Already friends with this user');
    }

    // Get current user's username
    final userDoc = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final username = userDoc.data()?['username'] ?? 'Unknown User';

    // Create the friend request
    await _firestore.collection('friend_requests').add({
      'from_uid': currentUser.uid,
      'from_username': username,
      'to_uid': toUserId,
      'status': 'pending',
      'timestamp': Timestamp.now(),
    });
  }

  /// Accept a friend request
  Future<void> acceptFriendRequest(String requestId, String fromUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Use a transaction to ensure both users' friend lists are updated atomically
      await _firestore.runTransaction((transaction) async {
        final requestRef = _firestore
            .collection('friend_requests')
            .doc(requestId);
        final currentUserRef = _firestore
            .collection('users')
            .doc(currentUser.uid);
        final friendUserRef = _firestore.collection('users').doc(fromUserId);

        // 1. Update the request status to "accepted"
        transaction.update(requestRef, {'status': 'accepted'});

        // 2. Add each user to the other's friend list
        transaction.update(currentUserRef, {
          'friends': FieldValue.arrayUnion([fromUserId]),
        });
        transaction.update(friendUserRef, {
          'friends': FieldValue.arrayUnion([currentUser.uid]),
        });
      });
    } catch (e) {
      print('Error accepting friend request: $e');
      rethrow;
    }
  }

  /// Decline a friend request
  Future<void> declineFriendRequest(String requestId) async {
    await _firestore.collection('friend_requests').doc(requestId).update({
      'status': 'declined',
    });
  }

  /// Cancel a sent friend request
  Future<void> cancelFriendRequest(String toUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final requestQuery = await _firestore
        .collection('friend_requests')
        .where('from_uid', isEqualTo: currentUser.uid)
        .where('to_uid', isEqualTo: toUserId)
        .where('status', isEqualTo: 'pending')
        .get();

    for (var doc in requestQuery.docs) {
      await doc.reference.delete();
    }
  }

  /// Get a stream of incoming friend requests for the current user
  Stream<QuerySnapshot> getFriendRequestsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.empty();

    // Remove orderBy to avoid index requirement issue
    return _firestore
        .collection('friend_requests')
        .where('to_uid', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  /// Get count of pending friend requests
  Stream<int> getFriendRequestsCountStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(0);

    return _firestore
        .collection('friend_requests')
        .where('to_uid', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get a stream of the current user's friends
  Stream<List<Map<String, dynamic>>> getFriendsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .asyncMap((userDoc) async {
          if (!userDoc.exists || userDoc.data()?['friends'] == null) {
            return [];
          }

          List<String> friendIds = List<String>.from(
            userDoc.data()!['friends'],
          );
          if (friendIds.isEmpty) {
            return [];
          }

          // Firestore 'whereIn' has a limit of 10 items, so we need to batch if more friends
          List<Map<String, dynamic>> allFriends = [];

          for (int i = 0; i < friendIds.length; i += 10) {
            final batch = friendIds.sublist(
              i,
              i + 10 > friendIds.length ? friendIds.length : i + 10,
            );
            final friendDocs = await _firestore
                .collection('users')
                .where('uid', whereIn: batch)
                .get();

            allFriends.addAll(
              friendDocs.docs.map((doc) => doc.data()).toList(),
            );
          }

          return allFriends;
        });
  }

  /// Remove a friend
  Future<void> removeFriend(String friendId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _firestore.runTransaction((transaction) async {
      final currentUserRef = _firestore
          .collection('users')
          .doc(currentUser.uid);
      final friendUserRef = _firestore.collection('users').doc(friendId);

      // Remove each user from the other's friend list
      transaction.update(currentUserRef, {
        'friends': FieldValue.arrayRemove([friendId]),
      });
      transaction.update(friendUserRef, {
        'friends': FieldValue.arrayRemove([currentUser.uid]),
      });
    });
  }
}
