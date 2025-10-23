import 'package:demo/Pages/ui_components/friend_components/friend_requests_page.dart';
import 'package:demo/Pages/ui_components/chat_page_components/search_users_page.dart';
import 'package:demo/Pages/ui_components/profile_page_components/profile_page.dart';
import 'package:demo/services/friends/friend_service.dart';
import 'package:demo/services/notes/firestore.dart';
import 'package:demo/themes/tier_theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FriendsListPage extends StatefulWidget {
  final String? viewingUserID;
  final String? viewingUsername;

  const FriendsListPage({super.key, this.viewingUserID, this.viewingUsername});

  @override
  State<FriendsListPage> createState() => _FriendsListPageState();
}

class _FriendsListPageState extends State<FriendsListPage> {
  final FireStoreService _firestoreService = FireStoreService();

  bool get isOwnProfile => widget.viewingUserID == null;

  // Friend's tier colors
  List<Color> friendGradientColors = [
    const Color(0xFF7C4DFF),
    const Color(0xFF448AFF),
  ];
  Color friendPrimaryColor = const Color(0xFF7C4DFF);
  Color friendGlowColor = const Color(0xFF7C4DFF);
  bool isLoadingFriendTier = true;

  @override
  void initState() {
    super.initState();
    if (!isOwnProfile) {
      _loadFriendTier();
    } else {
      setState(() => isLoadingFriendTier = false);
    }
  }

  Future<void> _loadFriendTier() async {
    try {
      // Get friend's stats to determine their tier
      final stats = await _firestoreService.getUserStatisticsForUser(
        widget.viewingUserID!,
      );
      final tier = _firestoreService.getUserTier(stats['completedTasks']);

      setState(() {
        friendGlowColor = tier['glow'] as Color? ?? const Color(0xFF7C4DFF);
        friendGradientColors =
            (tier['gradient'] as List<dynamic>?)
                ?.map((e) => e as Color)
                .toList() ??
            [const Color(0xFF7C4DFF), const Color(0xFF448AFF)];
        friendPrimaryColor = friendGradientColors[0];
        isLoadingFriendTier = false;
      });
    } catch (e) {
      debugPrint('Error loading friend tier: $e');
      setState(() => isLoadingFriendTier = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use friend's colors if viewing friend profile, otherwise use own colors from provider
    final tierProvider = context.watch<TierThemeProvider>();

    final displayGradientColors = isOwnProfile
        ? tierProvider.gradientColors
        : friendGradientColors;
    final displayPrimaryColor = isOwnProfile
        ? tierProvider.primaryColor
        : friendPrimaryColor;
    final displayGlowColor = isOwnProfile
        ? tierProvider.glowColor
        : friendGlowColor;

    if (!isOwnProfile && isLoadingFriendTier) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(displayPrimaryColor),
          ),
        ),
      );
    }

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
              _buildHeader(
                context,
                displayGradientColors,
                displayPrimaryColor,
                displayGlowColor,
              ),
              Expanded(
                child: _buildFriendsList(
                  context,
                  displayGradientColors,
                  displayPrimaryColor,
                  displayGlowColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    List<Color> gradientColors,
    Color primaryColor,
    Color glowColor,
  ) {
    final FriendService friendService = FriendService();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.3),
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
                            : friendService.getFriendsStreamForUser(
                                widget.viewingUserID!,
                              ),
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
                          color: Colors.white.withValues(alpha: 0.2),
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
                                builder: (context) =>
                                    const FriendRequestsPage(),
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
                      color: Colors.white.withValues(alpha: 0.2),
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsList(
    BuildContext context,
    List<Color> gradientColors,
    Color primaryColor,
    Color glowColor,
  ) {
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
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
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
                      colors: gradientColors
                          .map((c) => c.withValues(alpha: 0.2))
                          .toList(),
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.people_outline,
                    size: 80,
                    color: primaryColor,
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
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
            return _buildFriendCard(
              context,
              friendData,
              friendService,
              gradientColors,
              primaryColor,
              glowColor,
            );
          },
        );
      },
    );
  }

  Widget _buildFriendCard(
    BuildContext context,
    Map<String, dynamic> friendData,
    FriendService friendService,
    List<Color> gradientColors,
    Color primaryColor,
    Color glowColor,
  ) {
    final friendUsername = friendData['username'] ?? 'Unknown';
    final friendUID = friendData['uid'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: primaryColor.withValues(alpha: 0.1),
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
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(alpha: 0.2),
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
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Remove button (only for own profile)
                if (isOwnProfile)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.person_remove, color: Colors.red),
                      onPressed: () {
                        _showRemoveFriendDialog(
                          context,
                          friendUID,
                          friendUsername,
                          friendService,
                          primaryColor,
                        );
                      },
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: primaryColor.withValues(alpha: 0.5),
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
    Color primaryColor,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.red.shade400.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.shade400.withValues(alpha: 0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_remove_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Remove Friend?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 12),

              // Friend Name Card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  friendUsername,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),

              // Warning Message
              Text(
                'This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 28),

              // Action Buttons
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Remove Button
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade400, Colors.red.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.shade400.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            final currentUserID =
                                FirebaseAuth.instance.currentUser!.uid;
                            await friendService.removeFriend(
                              currentUserID,
                              friendUID,
                            );

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Removed $friendUsername from friends',
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.red.shade400,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to remove friend'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_remove_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Remove',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
