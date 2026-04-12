import 'package:lockify/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:lockify/screens/products/chats/chat_screen.dart';
import 'package:lockify/screens/products/locked_messages/locked_message_list_screen.dart';
import 'package:lockify/screens/products/purchase/purchase_screen.dart';
import 'package:lockify/screens/settings/setting_home_screen.dart';
import 'package:lockify/services/auth/auth_service.dart';

import 'package:lockify/services/contact_service.dart';


class LockifyHomePage extends StatefulWidget {
  const LockifyHomePage({super.key});

  @override
  State<LockifyHomePage> createState() => _LockifyPageState();
}

class _LockifyPageState extends State<LockifyHomePage> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  final ContactService _contactService = ContactService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Mark online on home screen load
    _authService.updateUserPresence(true);
    // Pre-fetch contacts to warm up cache for Chat screens
    _contactService.getCachedContacts(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Mark offline on logout/close (best effort)
    _authService.updateUserPresence(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _authService.updateUserPresence(true);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.detached) {
      _authService.updateUserPresence(false);
    }
  }

  final List<Widget> _pages = [
    ChatScreen(),
    const LockedMessageListScreen(),
    const PurchasePage(),
    const SettingHomePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<IconData> _icons = [
    Icons.chat_bubble_rounded,
    Icons.layers_rounded,
    Icons.shopping_bag_rounded,
    Icons.settings_rounded,
  ];

  final List<String> _labels = ['Chats', 'My Content', 'My Purchases', 'Settings'];

  static const _navAnimDuration = Duration(milliseconds: 350);

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.18 : 1.0,
                duration: _navAnimDuration,
                curve: Curves.easeOutCubic,
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.primaryPurple : AppColors.primaryPurple.withOpacity(0.32),
                  size: isSelected ? 26 : 22,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: _navAnimDuration,
                style: TextStyle(
                  color: isSelected ? AppColors.primaryPurple : AppColors.primaryPurple.withOpacity(0.7),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                  overflow: TextOverflow.ellipsis,
                ),
                child: AnimatedOpacity(
                  opacity: isSelected ? 1.0 : 0.7,
                  duration: _navAnimDuration,
                  child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // This allows the nav bar to float over the body
      backgroundColor: AppColors.grey50, // Subtle background for floating effect
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          elevation: 6,
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: AppColors.white,
          shadowColor: AppColors.primaryPurple.withOpacity(0.18),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, color: AppColors.white, size: 28),
              const SizedBox(width: 10),
              const Text(
                'LOCKIFY',
                style: TextStyle(color: AppColors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 8),
              ),
            ],
          ),
          centerTitle: true,
          toolbarHeight: 60.0,
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 18, right: 18, bottom: 25),
        height: 70,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withOpacity(0.18),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / _icons.length;
            final pillWidth = 80.0;
            final pillHeight = 55.0;
            final pillLeft = (_selectedIndex * tabWidth) + (tabWidth - pillWidth) / 2;
            return Stack(
              alignment: Alignment.center,
              children: [
                AnimatedPositioned(
                  duration: _navAnimDuration,
                  curve: Curves.easeOutCubic,
                  left: pillLeft,
                  top: 7,
                  child: AnimatedContainer(
                    duration: _navAnimDuration,
                    width: pillWidth,
                    height: pillHeight,
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.17),
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
                Row(
                  children: List.generate(_icons.length, (index) {
                    return _buildNavItem(
                      icon: _icons[index],
                      label: _labels[index],
                      isSelected: _selectedIndex == index,
                      onTap: () => _onItemTapped(index),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

