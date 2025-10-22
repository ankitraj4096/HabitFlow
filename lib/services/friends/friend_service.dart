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
          .where((user) => user['uid'] != currentUser.uid)
          .toList();
    });
  }

  /// Check if a friend request already exists between two users
  Future<String?> checkExistingRequest(String toUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    final sentRequest = await _firestore
        .collection('friend_requests')
        .where('from_uid', isEqualTo: currentUser.uid)
        .where('to_uid', isEqualTo: toUserId)
        .where('status', isEqualTo: 'pending')
        .get();

    if (sentRequest.docs.isNotEmpty) {
      return 'sent';
    }

    final receivedRequest = await _firestore
        .collection('friend_requests')
        .where('from_uid', isEqualTo: toUserId)
        .where('to_uid', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .get();

    if (receivedRequest.docs.isNotEmpty) {
      return 'received';
    }

    return null;
  }

  /// Check if two users are already friends
  Future<bool> areFriends(String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    final userDoc =
        await _firestore.collection('users').doc(currentUser.uid).get();

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

    final existingRequest = await checkExistingRequest(toUserId);
    if (existingRequest != null) {
      throw Exception('A friend request already exists');
    }

    final alreadyFriends = await areFriends(toUserId);
    if (alreadyFriends) {
      throw Exception('Already friends with this user');
    }

    final userDoc =
        await _firestore.collection('users').doc(currentUser.uid).get();
    final username = userDoc.data()?['username'] ?? 'Unknown User';

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
      await _firestore.runTransaction((transaction) async {
        final requestRef =
            _firestore.collection('friend_requests').doc(requestId);
        final currentUserRef =
            _firestore.collection('users').doc(currentUser.uid);
        final friendUserRef = _firestore.collection('users').doc(fromUserId);

        transaction.update(requestRef, {'status': 'accepted'});

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

      List<String> friendIds = List<String>.from(userDoc.data()!['friends']);
      if (friendIds.isEmpty) {
        return [];
      }

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

        allFriends.addAll(friendDocs.docs.map((doc) => doc.data()).toList());
      }

      return allFriends;
    });
  }

  /// NEW: Delete chat room between two users
  Future<void> _deleteChatRoom(String userId1, String userId2) async {
    try {
      // Construct chat room ID
      List<String> ids = [userId1, userId2];
      ids.sort();
      String chatRoomID = ids.join('_');

      // Get the chat room reference
      final chatRoomRef = _firestore.collection('chat_rooms').doc(chatRoomID);

      // Delete all messages in the chat room
      final messagesSnapshot =
          await chatRoomRef.collection('messages').get();

      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the chat room document itself
      await chatRoomRef.delete();

      print('✅ Chat room deleted: $chatRoomID');
    } catch (e) {
      print('Error deleting chat room: $e');
    }
  }

  /// UPDATED: Remove a friend AND delete their chat history
  Future<void> removeFriend(String currentUserId, String friendId) async {
    final userId = currentUserId.isNotEmpty ? currentUserId : _auth.currentUser?.uid;

    if (userId == null) return;

    try {
      // 1. Remove from friends list
      await _firestore.runTransaction((transaction) async {
        final currentUserRef = _firestore.collection('users').doc(userId);
        final friendUserRef = _firestore.collection('users').doc(friendId);

        transaction.update(currentUserRef, {
          'friends': FieldValue.arrayRemove([friendId]),
        });
        transaction.update(friendUserRef, {
          'friends': FieldValue.arrayRemove([userId]),
        });
      });

      // 2. Delete chat history between them
      await _deleteChatRoom(userId, friendId);

      print('✅ Friend removed and chat deleted');
    } catch (e) {
      print('Error removing friend: $e');
      rethrow;
    }
  }

  /// Get friends stream for a specific user
  Stream<List<Map<String, dynamic>>> getFriendsStreamForUser(String userID) {
    return _firestore
        .collection('users')
        .doc(userID)
        .snapshots()
        .asyncMap((userDoc) async {
      if (!userDoc.exists || userDoc.data()?['friends'] == null) {
        return [];
      }

      List<String> friendIds = List<String>.from(userDoc.data()!['friends']);
      if (friendIds.isEmpty) {
        return [];
      }

      List<Map<String, dynamic>> allFriends = [];

      for (int i = 0; i < friendIds.length; i += 10) {
        final batch = friendIds.sublist(
          i,
          i + 10 > friendIds.length ? friendIds.length : i + 10,
        );

        try {
          final friendDocs = await _firestore
              .collection('users')
              .where('uid', whereIn: batch)
              .get();

          allFriends
              .addAll(friendDocs.docs.map((doc) => doc.data()).toList());
        } catch (e) {
          print('Error fetching friends batch: $e');
        }
      }

      return allFriends;
    });
  }
}
