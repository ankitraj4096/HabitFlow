import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/models/message.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatService {
  // get instances of firestore & auth
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // get user stream
  Stream<List<Map<String, dynamic>>> getUserStream() {
    return _firestore.collection("users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // go through each individual user
        final user = doc.data();

        // return user
        return user;
      }).toList();
    });
  }

  // send message
  Future<void> sendMessage(String receiverID, message) async {
    // get current user info
    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timeStamp = Timestamp.now();

    // create a new message
    Message newMessage = Message(
      message: message,
      receiverID: receiverID,
      senderEmail: currentUserEmail,
      senderID: currentUserID,
      timestamp: timeStamp,
      isRead: false, // NEW: Message starts as unread
    );

    // construct chat room ID for the two users (sorted to ensure uniqueness)
    List<String> ids = [currentUserID, receiverID];
    ids.sort();
    String chatRoomID = ids.join('_');

    // add new message to database
    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .add(newMessage.toMap());
  }

  // get message
  Stream<QuerySnapshot> getMessages(String userID, otherUserID) {
    // construct a chatroom ID for the two users
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join("_");

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  // NEW: Get count of unread messages for current user
  Stream<int> getUnreadMessagesCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(0);

    return _firestore
        .collectionGroup('messages')
        .where('receiverID', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // NEW: Mark messages as read when chat is opened
  Future<void> markMessagesAsRead(String currentUserID, String otherUserID) async {
    List<String> ids = [currentUserID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');

    try {
      // Get all unread messages sent to current user in this chat
      final unreadMessages = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomID)
          .collection('messages')
          .where('receiverID', isEqualTo: currentUserID)
          .where('isRead', isEqualTo: false)
          .get();

      // Mark each message as read
      for (var doc in unreadMessages.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // NEW: Get unread message count for a specific friend
  Stream<int> getUnreadMessagesFromUser(String currentUserID, String otherUserID) {
    List<String> ids = [currentUserID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomID)
        .collection('messages')
        .where('receiverID', isEqualTo: currentUserID)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
