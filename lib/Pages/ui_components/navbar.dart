import 'dart:async';
import 'package:demo/Pages/ui_components/home_page.dart';
import 'package:demo/Pages/ui_components/chat_page_components/chat_list_page.dart';
import 'package:demo/Pages/ui_components/profile_page_components/profile_page.dart';
import 'package:demo/services/chat/chat_service.dart';
import 'package:demo/themes/tier_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Navbar extends StatefulWidget {
  const Navbar({super.key});

  @override
  State<Navbar> createState() => _NavBarState();
}

class _NavBarState extends State<Navbar> {
  int _selectedIndex = 1;
  final ChatService _chatService = ChatService();

  // Cache the stream to prevent recreation
  late final Stream<int> _unreadStream;

  final List<Widget> _pages = [
    const ChatListPage(),
    const Homepage(),
    const ProfilePage(),
  ];

  final List<IconData> _icons = [
    Icons.chat_bubble_rounded,
    Icons.home_rounded,
    Icons.person_rounded,
  ];

  final List<String> _labels = ['Chat', 'Home', 'Profile'];

  @override
  void initState() {
    super.initState();
    // Initialize stream once and cache it
    _unreadStream = _chatService.getUnreadMessagesCount();
    debugPrint('🔄 Navbar initialized, stream created');
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get tier colors from provider
    final tierProvider = context.watch<TierThemeProvider>();

    // Create dynamic colors array based on tier
    final List<Color> dynamicColors = [
      tierProvider.primaryColor, // Chat uses primary tier color
      tierProvider.gradientColors.length > 1 
          ? tierProvider.gradientColors[1] 
          : tierProvider.primaryColor, // Home uses secondary gradient color
      tierProvider.gradientColors[0], // Profile uses first gradient color
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      extendBody: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: StreamBuilder<int>(
        stream: _unreadStream,
        initialData: 0,
        builder: (context, snapshot) {
          debugPrint('🎨 Navbar rebuild - ConnectionState: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, data: ${snapshot.data}');

          final unreadCount = snapshot.data ?? 0;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            height: 65,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: tierProvider.primaryColor.withValues(alpha: 0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (index) {
                  final isSelected = _selectedIndex == index;
                  final isChatTab = index == 0;
                  final hasUnread = isChatTab && unreadCount > 0;

                  if (hasUnread) {
                    debugPrint('🔴 Should show badge with count: $unreadCount');
                  }

                  return Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _onItemTapped(index),
                        borderRadius: BorderRadius.circular(30),
                        splashColor: dynamicColors[index].withValues(alpha: 0.1),
                        highlightColor: Colors.transparent,
                        child: Container(
                          padding: EdgeInsets.zero,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOutCubic,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: isSelected
                                            ? LinearGradient(
                                                colors: tierProvider.gradientColors,
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : null,
                                        color: isSelected
                                            ? null
                                            : Colors.grey.shade200,
                                        shape: BoxShape.circle,
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: tierProvider.glowColor
                                                      .withValues(alpha: 0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : [],
                                      ),
                                      child: Icon(
                                        _icons[index],
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey.shade700,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    AnimatedDefaultTextStyle(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? dynamicColors[index]
                                            : Colors.grey.shade700,
                                        letterSpacing: 0.3,
                                      ),
                                      child: Text(
                                        _labels[index],
                                        overflow: TextOverflow.clip,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Badge - Always rendered when hasUnread is true
                              if (hasUnread)
                                Positioned(
                                  top: 4,
                                  right: 20,
                                  child: AnimatedScale(
                                    scale: 1.0,
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOutBack,
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      constraints: const BoxConstraints(
                                        minWidth: 20,
                                        minHeight: 20,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFFF5252),
                                            Color(0xFFFF1744)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.withValues(alpha: 0.6),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          unreadCount > 99
                                              ? '99+'
                                              : '$unreadCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            height: 1.0,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }
}
