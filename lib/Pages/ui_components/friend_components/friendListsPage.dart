import 'package:demo/Pages/ui_components/friend_components/friend_requests_page.dart';
import 'package:demo/Pages/ui_components/chat_page_components/search_users_page.dart';
import 'package:demo/Pages/ui_components/profile_page_components/profile_page.dart';
import 'package:demo/services/friends/friend_service.dart';
import 'package:demo/services/notes/firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class FriendsListPage extends StatefulWidget {
  final String? viewingUserID; // null if viewing own friends
  final String? viewingUsername; // null if viewing own friends


  const FriendsListPage({
    super.key,
    this.viewingUserID,
    this.viewingUsername,
  });

  @override
  State<FriendsListPage> createState() => _FriendsListPageState();
}

class _FriendsListPageState extends State<FriendsListPage> {
  final FireStoreService _firestoreService = FireStoreService();

  // Tier colors
  List<Color> tierGradient = [const Color(0xFF7C4DFF), const Color(0xFF448AFF)];
  Color tierColor = const Color(0xFF7C4DFF);
  bool isLoadingTier = true;

  bool get isOwnProfile => widget.viewingUserID == null;

  @override
  void initState() {
    super.initState();
    _loadTierColors();
  }

  Future<void> _loadTierColors() async {
    try {
      final stats = await _firestoreService.getUserStatistics();
      final completedTasks = stats['completedTasks'] ?? 0;
      final tier = _firestoreService.getUserTier(completedTasks);

      setState(() {
        tierColor = tier['glow'] as Color? ?? const Color(0xFF7C4DFF);
        tierGradient = (tier['gradient'] as List<dynamic>?)
                ?.map((e) => e as Color)
                .toList() ??
            [const Color(0xFF7C4DFF), const Color(0xFF448AFF)];
        isLoadingTier = false;
      });
    } catch (e) {
      print('Error loading tier colors: $e');
      setState(() => isLoadingTier = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF3E5F5), Colors.white, Color(0xFFE3F2FD)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(child: _buildFriendsList(context)),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildHeader(BuildContext context) {
    final FriendService friendService = FriendService();


    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: tierGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: tierColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOwnProfile
                            ? 'My Friends'
                            : '${widget.viewingUsername}\'s Friends',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: isOwnProfile
                            ? friendService.getFriendsStream()
                            : friendService.getFriendsStreamForUser(widget.viewingUserID!),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            int count = snapshot.data!.length;
                            return Text(
                              '$count friend${count != 1 ? 's' : ''}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            );
                          }
                          return const Text(
                            'Loading...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Only show action buttons for own profile
                if (isOwnProfile) ...[
                  // Friend Requests Icon
                  Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.person_add_alt, color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FriendRequestsPage(),
                              ),
                            );
                          },
                        ),
                      ),
                      // Badge for pending requests
                      StreamBuilder<int>(
                        stream: friendService.getFriendRequestsCountStream(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data == 0) {
                            return const SizedBox.shrink();
                          }
                          return Positioned(
                            right: 12,
                            top: 4,
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
                  // Search Users Icon
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.person_search, color: Colors.white),
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
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildFriendsList(BuildContext context) {
    final FriendService friendService = FriendService();


    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: isOwnProfile
          ? friendService.getFriendsStream()
          : friendService.getFriendsStreamForUser(widget.viewingUserID!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                const Text(
                  'Error loading friends',
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
              ],
            ),
          );
        }


        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(tierColor),
            ),
          );
        }


        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: tierGradient.map((c) => c.withOpacity(0.2)).toList(),
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.people_outline,
                    size: 80,
                    color: tierColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isOwnProfile ? 'No friends yet' : 'No friends to show',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isOwnProfile
                      ? 'Tap the search icon to find friends'
                      : 'This user hasn\'t added any friends',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }


        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final friendData = snapshot.data![index];
            return _buildFriendCard(context, friendData, friendService);
          },
        );
      },
    );
  }


  Widget _buildFriendCard(
    BuildContext context,
    Map<String, dynamic> friendData,
    FriendService friendService,
  ) {
    final friendUsername = friendData['username'] ?? 'Unknown';
    final friendUID = friendData['uid'] ?? '';


    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tierColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: tierColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: tierColor.withOpacity(0.1),
          onTap: () {
            // Navigate to friend's profile
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(
                  viewingUserID: friendUID,
                  viewingUsername: friendUsername,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: tierGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: tierColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      friendUsername[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Username
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friendUsername,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${friendUsername.toLowerCase()}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Remove button (only for own profile)
                if (isOwnProfile)
                  IconButton(
                    icon: const Icon(Icons.person_remove, color: Colors.red),
                    onPressed: () {
                      _showRemoveFriendDialog(
                        context,
                        friendUID,
                        friendUsername,
                        friendService,
                      );
                    },
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: tierColor.withOpacity(0.5),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  void _showRemoveFriendDialog(
    BuildContext context,
    String friendUID,
    String friendUsername,
    FriendService friendService,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Remove Friend?'),
          ],
        ),
        content: Text('Are you sure you want to remove $friendUsername from your friends?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final currentUserID = FirebaseAuth.instance.currentUser!.uid;
                await friendService.removeFriend(currentUserID, friendUID);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Removed $friendUsername from friends'),
                      backgroundColor: tierColor,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to remove friend'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
