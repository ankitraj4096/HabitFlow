import 'dart:async';
import 'package:demo/Pages/ui_components/home_page.dart';
import 'package:demo/Pages/ui_components/chat_page_components/chatListPage.dart';
import 'package:demo/Pages/ui_components/profile_page_components/profile_page.dart';
import 'package:demo/services/chat/chat_service.dart';
import 'package:flutter/material.dart';

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
    ChatListPage(),
    Homepage(),
    ProfilePage(),
  ];

  final List<IconData> _icons = [
    Icons.chat_bubble_rounded,
    Icons.home_rounded,
    Icons.person_rounded,
  ];

  final List<String> _labels = ['Chat', 'Home', 'Profile'];

  final List<Color> _colors = [
    const Color(0xFFf093fb),
    const Color(0xFF7C4DFF),
    const Color(0xFF4facfe),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize stream once and cache it
    _unreadStream = _chatService.getUnreadMessagesCount();
    print('🔄 Navbar initialized, stream created');
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      extendBody: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: StreamBuilder<int>(
        stream: _unreadStream,
        initialData: 0, // Start with 0, will update when data arrives
        builder: (context, snapshot) {
          // Log every rebuild
          print('🎨 Navbar rebuild - ConnectionState: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, data: ${snapshot.data}');
          
          // Handle all connection states
          final unreadCount = snapshot.data ?? 0;
          
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            height: 65,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
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
                    print('🔴 Should show badge with count: $unreadCount');
                  }
                  
                  return Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _onItemTapped(index),
                        borderRadius: BorderRadius.circular(30),
                        splashColor: _colors[index].withOpacity(0.1),
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
                                        color: isSelected
                                            ? _colors[index]
                                            : Colors.grey.shade200,
                                        shape: BoxShape.circle,
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
                                            ? _colors[index]
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
                                  child: AnimatedOpacity(
                                    opacity: 1.0,
                                    duration: Duration(milliseconds: 300),
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
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.withOpacity(0.6),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          unreadCount > 99 ? '99+' : '$unreadCount',
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
