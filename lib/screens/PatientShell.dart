import 'package:flutter/material.dart';

import '../network/ProfileService.dart';
import '../network/ProfileStore.dart';
import '../widgets/MedicationPillIcon.dart';
import 'AppointmentsListScreen.dart';
import 'patient/HomeScreen.dart';
import 'MedicationsScreen.dart';
import 'PatientMoreScreen.dart';
import 'ReportsScreen.dart';

/// Hosts the patient-side tabs behind a single shared bottom nav bar.
///
/// Tabs are kept alive in an [IndexedStack] instead of being pushed as
/// routes, so switching tabs is an instant swap (no page transition, no
/// re-fetching data) rather than feeling like opening a new screen.
class PatientShell extends StatefulWidget {
  const PatientShell({super.key});

  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  static const _teal = Color(0xFF1A9882);
  static const _textMuted = Color(0xFF7A8399);
  static const _bg = Color(0xFFF5F6FA);

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _syncProfile();
  }

  Future<void> _syncProfile() async {
    try {
      final p = await ProfileService().getMe();
      await ProfileStore.setName(p.fullName);
      await ProfileStore.setAvatar(p.avatarId);
    } catch (_) {
      // Keep whatever was loaded from prefs.
    }
  }

  final List<Widget> _tabs = const [
    HomeScreen(),
    AppointmentsListScreen(),
    MedicationsScreen(),
    ReportsScreen(),
    PatientMoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, -4)),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: _teal,
          unselectedItemColor: _textMuted,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: [
            const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon: Icon(Icons.calendar_today),
                label: 'Appointments'),
            const BottomNavigationBarItem(
                icon: MedicationPillIcon(size: 24, color: _textMuted),
                activeIcon: MedicationPillIcon(size: 24, color: _teal),
                label: 'Medications'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.description_outlined),
                activeIcon: Icon(Icons.description),
                label: 'Reports'),
            const BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
          ],
        ),
      ),
    );
  }
}
