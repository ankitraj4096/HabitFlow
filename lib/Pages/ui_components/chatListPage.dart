import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/Pages/ui_components/chatPage.dart';
import 'package:demo/services/auth/auth_service.dart';
import 'package:demo/services/chat/chat_service.dart';
import 'package:flutter/material.dart';

class ChatListPage extends StatelessWidget {
  ChatListPage({super.key});

  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      Expanded(child: _buildUserList()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Messages',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.edit, color: Colors.white),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          StreamBuilder(
            stream: _chatService.getUserStream(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                int count = snapshot.data!.length - 1;
                return Text(
                  '$count conversation${count != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                );
              }
              return Text(
                '0 conversations',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search messages...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder(
      stream: _chatService.getUserStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading chats",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
            ),
          );
        }

        return ListView(
          padding: EdgeInsets.symmetric(horizontal: 10),
          children: snapshot.data!
              .map<Widget>((userData) => _buildUserListItem(userData, context))
              .toList(),
        );
      },
    );
  }

  // Get last message for a specific chat
  Stream<QuerySnapshot> _getLastMessage(String userID, String otherUserID) {
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');

    return FirebaseFirestore.instance
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: true)
        .limit(1)
        .snapshots();
  }

  Widget _buildUserListItem(
    Map<String, dynamic> userData,
    BuildContext context,
  ) {
    if (userData["email"] != _authService.getCurrentUser()!.email) {
      String currentUserID = _authService.getCurrentUser()!.uid;
      
      return Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    receiverID: userData["uid"],
                    receiverUsername: userData["username"],
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        userData['username'][0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userData['username'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        // StreamBuilder to show last message
                        StreamBuilder<QuerySnapshot>(
                          stream: _getLastMessage(currentUserID, userData["uid"]),
                          builder: (context, messageSnapshot) {
                            if (messageSnapshot.hasData && 
                                messageSnapshot.data!.docs.isNotEmpty) {
                              // Get the last message
                              var lastMessage = messageSnapshot.data!.docs.first.data() 
                                  as Map<String, dynamic>;
                              String messageText = lastMessage['message'] ?? '';
                              bool isCurrentUserSender = 
                                  lastMessage['senderID'] == currentUserID;
                              
                              // Truncate message if too long
                              String displayMessage = messageText.length > 30
                                  ? '${messageText.substring(0, 30)}...'
                                  : messageText;
                              
                              return Text(
                                isCurrentUserSender 
                                    ? 'You: $displayMessage' 
                                    : displayMessage,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            } else {
                              // No messages yet
                              return Text(
                                'Tap to start chatting',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      return Container();
    }
  }
}