import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'home_dashboard.dart';
import '../ui/community/community_page.dart';
import 'map_screen.dart';
import 'bookings_screen.dart';
import 'charge_screen.dart';
import 'profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final List<Widget?> _pages = List<Widget?>.filled(6, null);

  Widget _pageAt(int index) {
    return _pages[index] ??= switch (index) {
      0 => HomeDashboard(
        onOpenMap: () => setState(() => _index = 2),
        onOpenBookings: () => setState(() => _index = 3),
        onOpenBattery: () => setState(() => _index = 4),
        onOpenCommunity: () => setState(() => _index = 1),
      ),
      1 => CommunityPage(),
      2 => const MapScreen(),
      3 => const BookingsScreen(),
      4 => const ChargeScreen(),
      5 => const ProfileScreen(),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: List<Widget>.generate(6, _pageAt),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedFontSize: 0,
        unselectedFontSize: 0,
        onTap: (i) => setState(() => _index = i),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            label: l10n.t('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.group_outlined),
            label: l10n.t('community'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.map_outlined),
            label: l10n.t('map'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.book_online_outlined),
            label: l10n.t('bookings'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.flash_on_outlined),
            label: l10n.t('charge'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            label: l10n.t('profile'),
          ),
        ],
      ),
    );
  }
}
