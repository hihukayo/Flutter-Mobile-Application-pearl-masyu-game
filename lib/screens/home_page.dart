import 'package:flutter/material.dart';
import 'game_page.dart';
import 'rank_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  final String username;
  final String phone;

  const HomePage({super.key, required this.username, required this.phone});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final _rankKey = GlobalKey<RankPageState>();
  final _profileKey = GlobalKey<ProfilePageState>();

  void _switchToGame() {
    setState(() => _currentIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      GamePage(username: widget.username),
      RankPage(key: _rankKey, username: widget.username),
      ProfilePage(key: _profileKey, username: widget.username, phone: widget.phone, onGoToGame: _switchToGame),
    ];

    return Center(
      child: SizedBox(
        width: 480,
        child: Scaffold(
          body: IndexedStack(index: _currentIndex, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) {
              setState(() => _currentIndex = i);
              if (i == 1) _rankKey.currentState?.refresh();
              if (i == 2) _profileKey.currentState?.refresh();
            },
            destinations: const [
              NavigationDestination(icon: Icon(Icons.grid_on, color: Color(0xFF455A64)), label: '数独'),
              NavigationDestination(icon: Icon(Icons.emoji_events, color: Color(0xFF455A64)), label: '排行榜'),
              NavigationDestination(icon: Icon(Icons.person, color: Color(0xFF455A64)), label: '我的'),
            ],
          ),
        ),
      ),
    );
  }
}
