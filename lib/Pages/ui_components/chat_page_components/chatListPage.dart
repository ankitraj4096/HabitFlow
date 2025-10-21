import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/Pages/ui_components/chat_page_components/chatPage.dart';
import 'package:demo/Pages/ui_components/chat_page_components/search_users_page.dart';
import 'package:demo/Pages/ui_components/friend_components/friend_requests_page.dart';
import 'package:demo/services/auth/auth_service.dart';
import 'package:demo/services/chat/chat_service.dart';
import 'package:demo/services/friends/friend_service.dart';
import 'package:flutter/material.dart';

class ChatListPage extends StatelessWidget {
  ChatListPage({super.key});

  final FriendService _friendService = FriendService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    // The entire Scaffold is wrapped in a SafeArea
    return SafeArea(
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      Expanded(child: _buildFriendsList()),
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
              const Text(
                'Messages',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.person_add_alt,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FriendRequestsPage(),
                              ),
                            );
                          },
                        ),
                      ),
                      StreamBuilder<int>(
                        stream: _friendService.getFriendRequestsCountStream(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data == 0) {
                            return const SizedBox.shrink();
                          }
                          return Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                '${snapshot.data}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.person_search,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SearchUsersPage(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _friendService.getFriendsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                int count = snapshot.data!.length;
                return Text(
                  '$count friend${count != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                );
              }
              return Text(
                '0 friends',
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
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search friends...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _friendService.getFriendsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "Error loading friends",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No friends yet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the search icon to find friends',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          children: snapshot.data!
              .map<Widget>(
                (userData) => _buildFriendListItem(userData, context),
              )
              .toList(),
        );
      },
    );
  }

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

  Widget _buildFriendListItem(
    Map<String, dynamic> userData,
    BuildContext context,
  ) {
    String currentUserID = _authService.getCurrentUser()!.uid;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
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
                // Avatar with unread badge
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          userData['username'][0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Unread badge
                    StreamBuilder<int>(
                      stream: ChatService().getUnreadMessagesFromUser(
                        currentUserID,
                        userData["uid"],
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data == 0) {
                          return const SizedBox.shrink();
                        }

                        final unreadCount = snapshot.data!;

                        return Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                unreadCount > 9 ? '9+' : '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData['username'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      StreamBuilder<QuerySnapshot>(
                        stream: _getLastMessage(currentUserID, userData["uid"]),
                        builder: (context, messageSnapshot) {
                          if (messageSnapshot.hasData &&
                              messageSnapshot.data!.docs.isNotEmpty) {
                            var lastMessage =
                                messageSnapshot.data!.docs.first.data()
                                    as Map<String, dynamic>;
                            String messageText = lastMessage['message'] ?? '';
                            bool isCurrentUserSender =
                                lastMessage['senderID'] == currentUserID;
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
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
