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
      floatingActionButton: Container(
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
                        alignment: Alignment.center,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOutCubic,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected ? _colors[index] : Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _icons[index],
                                  color: isSelected ? Colors.white : Colors.grey.shade700,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 2),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? _colors[index] : Colors.grey.shade700,
                                  letterSpacing: 0.3,
                                ),
                                child: Text(
                                  _labels[index],
                                  overflow: TextOverflow.clip,
                                ),
                              ),
                            ],
                          ),
                          
                          // Unread badge for Chat tab
                          if (index == 0)
                            Positioned(
                              top: 8,
                              right: 16,
                              child: StreamBuilder<int>(
                                stream: _chatService.getUnreadMessagesCount(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData || snapshot.data == 0) {
                                    return const SizedBox.shrink();
                                  }
                                  
                                  final unreadCount = snapshot.data!;
                                  
                                  return Container(
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFF5252), Color(0xFFFF1744)],
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(0.5),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        unreadCount > 99 ? '99+' : '$unreadCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                },
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
      ),
    );
  }
}
