import 'package:flutter/material.dart';
import 'package:demo/themes/tier_theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;
  final DateTime timestamp;
  final bool isRead;
  
  const ChatBubble({
    super.key,
    required this.isCurrentUser,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final tierProvider = context.watch<TierThemeProvider>();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
      child: Row(
        mainAxisAlignment: isCurrentUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                gradient: isCurrentUser
                    ? LinearGradient(
                        colors: tierProvider.gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isCurrentUser ? null : const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isCurrentUser 
                      ? const Radius.circular(16) 
                      : const Radius.circular(2),
                  bottomRight: isCurrentUser 
                      ? const Radius.circular(2) 
                      : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isCurrentUser 
                        ? tierProvider.glowColor.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Message text with padding for timestamp
                  Padding(
                    padding: const EdgeInsets.only(right: 50),
                    child: Text(
                      message,
                      style: TextStyle(
                        color: isCurrentUser ? Colors.white : Colors.black87,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Timestamp at bottom right with read receipt
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: isCurrentUser 
                              ? Colors.white.withValues(alpha: 0.8)
                              : Colors.grey.shade600,
                        ),
                      ),
                      // Show checkmark only for current user's messages
                      if (isCurrentUser) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 14,
                          color: isRead 
                              ? const Color(0xFF4FC3F7)
                              : Colors.white.withValues(alpha: 0.6),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
