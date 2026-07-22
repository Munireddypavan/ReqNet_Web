import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'broadcast_screen.dart';
import 'chats_screen.dart';
import 'status_screen.dart';
import 'profile_screen.dart';
import '../theme.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      MapScreen(onNavigateToChat: () {
        setState(() => _currentIndex = 2);
      }),
      const BroadcastScreen(),
      const ChatsScreen(),
      const StatusScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hub_rounded, color: AppTheme.primary, size: 20),
            SizedBox(width: 8),
            Text(
              'MESH ACTIVE',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.onSurface,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: const [
          Icon(Icons.bluetooth_connected, color: AppTheme.primary, size: 20),
          SizedBox(width: 20),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: _screens[_currentIndex],
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.background.withValues(alpha: 0.95),
            border: const Border(top: BorderSide(color: AppTheme.surfaceContainerHighest, width: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.map_rounded, 'MAP'),
              _buildNavItem(1, Icons.cell_tower_rounded, 'BROADCAST'),
              _buildNavItem(2, Icons.forum_rounded, 'CHATS'),
              _buildNavItem(3, Icons.analytics_rounded, 'STATUS'),
              _buildNavItem(4, Icons.person_rounded, 'PROFILE'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppTheme.primary : AppTheme.outline;
    
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 10,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: isSelected ? 16 : 0,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
