import 'package:demo/services/auth/auth_service.dart';
import 'package:demo/services/friends/friend_service.dart';
import 'package:demo/themes/tier_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchUsersPage extends StatefulWidget {
  const SearchUsersPage({super.key});

  @override
  State<SearchUsersPage> createState() => _SearchUsersPageState();
}

class _SearchUsersPageState extends State<SearchUsersPage> {
  final FriendService _friendService = FriendService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  String _query = "";

  // Optimistic state management
  final Map<String, String> _buttonStates = {}; // uid -> 'loading', 'sent', 'friends', etc.
  final Map<String, bool> _isProcessing = {}; // Track if a button is being processed

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String> _getButtonState(String userId) async {
    // Return cached state immediately if available
    if (_buttonStates.containsKey(userId)) {
      return _buttonStates[userId]!;
    }

    try {
      // Check if already friends
      final isFriend = await _friendService.areFriends(userId);
      if (isFriend) {
        _buttonStates[userId] = 'friends';
        return 'friends';
      }

      // Check for existing request
      final requestStatus = await _friendService.checkExistingRequest(userId);
      if (requestStatus == 'sent') {
        _buttonStates[userId] = 'sent';
        return 'sent';
      } else if (requestStatus == 'received') {
        _buttonStates[userId] = 'received';
        return 'received';
      }

      _buttonStates[userId] = 'none';
      return 'none';
    } catch (e) {
      debugPrint('Error getting button state: $e');
      return 'none';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tierProvider = context.watch<TierThemeProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Find Friends',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: tierProvider.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar Section
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: tierProvider.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: tierProvider.glowColor.withValues(alpha:0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by username...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(
                    Icons.search,
                    color: tierProvider.primaryColor,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade400),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _query = "";
                              _buttonStates.clear();
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
                onChanged: (value) {
                  setState(() {
                    _query = value.trim();
                    _buttonStates.clear(); // Clear cache on new search
                  });
                },
              ),
            ),
          ),

          // User List
          Expanded(
            child: _query.isEmpty
                ? _buildBrowseAllUsers(tierProvider)
                : _buildSearchResults(tierProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildBrowseAllUsers(TierThemeProvider tierProvider) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _friendService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                tierProvider.primaryColor,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Error loading users',
                  style: TextStyle(fontSize: 18, color: Colors.red.shade700),
                ),
              ],
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
                      colors: tierProvider.gradientColors
                          .map((c) => c.withValues(alpha:0.2))
                          .toList(),
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.people_outline,
                    size: 64,
                    color: tierProvider.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No users found',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final user = snapshot.data![index];
            return _buildUserCard(user, tierProvider);
          },
        );
      },
    );
  }

  Widget _buildSearchResults(TierThemeProvider tierProvider) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _friendService.searchUsers(_query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                tierProvider.primaryColor,
              ),
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
                      colors: tierProvider.gradientColors
                          .map((c) => c.withValues(alpha:0.2))
                          .toList(),
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.search_off,
                    size: 64,
                    color: tierProvider.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No users found',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try a different username',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        // Filter out current user
        final filteredUsers = snapshot.data!
            .where((user) => user['uid'] != _authService.getCurrentUser()?.uid)
            .toList();

        if (filteredUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: tierProvider.gradientColors
                          .map((c) => c.withValues(alpha:0.2))
                          .toList(),
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_off,
                    size: 64,
                    color: tierProvider.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No other users found',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            return _buildUserCard(user, tierProvider);
          },
        );
      },
    );
  }

  Widget _buildUserCard(
    Map<String, dynamic> user,
    TierThemeProvider tierProvider,
  ) {
    final userId = user['uid'];
    final isProcessing = _isProcessing[userId] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFAFAFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tierProvider.primaryColor.withValues(alpha:0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: tierProvider.primaryColor.withValues(alpha:0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Avatar with tier gradient
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: tierProvider.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: tierProvider.glowColor.withValues(alpha:0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  user['username'][0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['username'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user['email'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Action Button - Now with instant feedback
            FutureBuilder<String>(
              future: _getButtonState(userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        tierProvider.primaryColor,
                      ),
                    ),
                  );
                }

                final state = _buttonStates[userId] ?? snapshot.data!;

                // Show loading state when processing
                if (isProcessing) {
                  return SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        tierProvider.primaryColor,
                      ),
                    ),
                  );
                }

                if (state == 'friends') {
                  return _buildStatusChip(
                    icon: Icons.check_circle,
                    label: 'Friends',
                    color: Colors.green,
                  );
                } else if (state == 'sent') {
                  return _buildCancelableChip(
                    userId,
                    user['username'],
                    tierProvider,
                  );
                } else if (state == 'received') {
                  return _buildStatusChip(
                    icon: Icons.mail,
                    label: 'Respond',
                    color: Colors.blue,
                  );
                } else {
                  // 'none' - can send request
                  return _buildAddButton(user, tierProvider);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color.shade700),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelableChip(
    String userId,
    String username,
    TierThemeProvider tierProvider,
  ) {
    return GestureDetector(
      onTap: () => _showCancelDialog(userId, username, tierProvider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, size: 16, color: Colors.orange.shade700),
            const SizedBox(width: 6),
            Text(
              'Pending',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.close, size: 14, color: Colors.orange.shade700),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(
    Map<String, dynamic> user,
    TierThemeProvider tierProvider,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _sendFriendRequest(user, tierProvider),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: tierProvider.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: tierProvider.glowColor.withValues(alpha:0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_add, size: 16, color: Colors.white),
              SizedBox(width: 6),
              Text(
                'Add',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendFriendRequest(
    Map<String, dynamic> user,
    TierThemeProvider tierProvider,
  ) async {
    final userId = user['uid'];

    // Set processing state immediately for instant UI feedback
    setState(() {
      _isProcessing[userId] = true;
    });

    try {
      await _friendService.sendFriendRequest(userId);

      // Update button state immediately
      setState(() {
        _buttonStates[userId] = 'sent';
        _isProcessing[userId] = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: tierProvider.gradientColors,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Friend request sent to ${user['username']}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: tierProvider.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _buttonStates[userId] = 'none';
        _isProcessing[userId] = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showCancelDialog(
    String userId,
    String username,
    TierThemeProvider tierProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.cancel_outlined, color: tierProvider.primaryColor),
            const SizedBox(width: 12),
            const Text('Cancel Request?'),
          ],
        ),
        content: Text(
          'Do you want to cancel the friend request sent to $username?',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'No',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.orange.shade600],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelFriendRequest(userId, username);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Yes, Cancel',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelFriendRequest(String userId, String username) async {
    // Set processing state immediately
    setState(() {
      _isProcessing[userId] = true;
    });

    try {
      await _friendService.cancelFriendRequest(userId);

      // Update button state immediately
      setState(() {
        _buttonStates[userId] = 'none';
        _isProcessing[userId] = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Friend request to $username cancelled',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.grey.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _buttonStates[userId] = 'sent'; // Revert to sent state
        _isProcessing[userId] = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Error cancelling request')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}
