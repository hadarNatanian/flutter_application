import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'feed_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final index = context.watch<AppProvider>().tabIndex;

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [FeedScreen(), ProfileScreen()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        selectedItemColor: const Color(0xFF2E7D32),
        onTap: (i) => context.read<AppProvider>().setTabIndex(i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'פיד'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'פרופיל'),
        ],
      ),
    );
  }
}