import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/services/friends/friend_service.dart';
import 'package:demo/services/notes/firestore.dart';
import 'package:flutter/material.dart';


class FriendRequestsPage extends StatefulWidget {
  const FriendRequestsPage({super.key});


  @override
  State <FriendRequestsPage> createState() => _FriendRequestsPageState();
}


class _FriendRequestsPageState extends State<FriendRequestsPage> {
  final FriendService _friendService = FriendService();
  final FireStoreService _firestoreService = FireStoreService();

  // Tier colors
  List<Color> tierGradient = [const Color(0xFF667EEA), const Color(0xFF764BA2)];
  Color tierColor = const Color(0xFF667EEA);
  bool isLoadingTier = true;

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
        tierColor = tier['glow'] as Color? ?? const Color(0xFF667EEA);
        tierGradient = (tier['gradient'] as List<dynamic>?)
                ?.map((e) => e as Color)
                .toList() ??
            [const Color(0xFF667EEA), const Color(0xFF764BA2)];
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
      appBar: AppBar(
        title: const Text('Friend Requests'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: tierGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _friendService.getFriendRequestsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error loading requests'),
            );
          }


          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(tierColor),
              ),
            );
          }


          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: tierGradient.map((c) => c.withOpacity(0.2)).toList(),
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.people_alt_outlined,
                      size: 50,
                      color: tierColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No friend requests',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When someone sends you a request,\nit will appear here',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }


          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;


              return _buildRequestCard(
                requestId: doc.id,
                fromUserId: data['from_uid'],
                fromUsername: data['from_username'],
                timestamp: data['timestamp'] as Timestamp,
              );
            },
          );
        },
      ),
    );
  }


  Widget _buildRequestCard({
    required String requestId,
    required String fromUserId,
    required String fromUsername,
    required Timestamp timestamp,
  }) {
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
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                      fromUsername[0].toUpperCase(),
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
                        fromUsername,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getTimeAgo(timestamp),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptRequest(requestId, fromUserId, fromUsername),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tierColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shadowColor: tierColor.withOpacity(0.3),
                    ),
                    child: const Text(
                      'Accept',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _declineRequest(requestId, fromUsername),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  String _getTimeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp.toDate());


    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }


  Future<void> _acceptRequest(String requestId, String fromUserId, String fromUsername) async {
    try {
      await _friendService.acceptFriendRequest(requestId, fromUserId);


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You are now friends with $fromUsername'),
            backgroundColor: tierColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting request: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }


  Future<void> _declineRequest(String requestId, String fromUsername) async {
    try {
      await _friendService.declineFriendRequest(requestId);


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Declined request from $fromUsername'),
            backgroundColor: Colors.grey.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error declining request: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}
