import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/ProfileService.dart';
import '../network/ProfileStore.dart';
import '../widgets/UserAvatar.dart';
import 'patient/EditProfileScreen.dart';
import 'LoginScreen.dart';

class PatientMoreScreen extends StatefulWidget {
  const PatientMoreScreen({super.key});

  @override
  State<PatientMoreScreen> createState() => _PatientMoreScreenState();
}

class _PatientMoreScreenState extends State<PatientMoreScreen> {
  static const _teal = Color(0xFF1A9882);
  static const _textDark = Color(0xFF1C2B47);
  static const _textMuted = Color(0xFF7A8399);
  static const _bg = Color(0xFFF5F6FA);
  static const _danger = Color(0xFFE05A4D);

  String _patientName = 'Patient';
  int? _avatarId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedName = prefs.getString('user_name');
    final cachedAvatar = prefs.getInt('user_avatar');
    if (mounted) {
      setState(() {
        if (cachedName != null && cachedName.trim().isNotEmpty) {
          _patientName = cachedName;
        }
        _avatarId = cachedAvatar;
      });
    }
    // Refresh from the server so name/avatar are correct after a fresh login.
    try {
      final p = await ProfileService().getMe();
      await prefs.setString('user_name', p.fullName);
      if (p.avatarId != null) {
        await prefs.setInt('user_avatar', p.avatarId!);
      } else {
        await prefs.remove('user_avatar');
      }
      if (!mounted) return;
      setState(() {
        if (p.fullName.isNotEmpty) _patientName = p.fullName;
        _avatarId = p.avatarId;
      });
    } catch (_) {
      // Keep cached values on failure.
    }
  }

  Future<void> _openEdit() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (changed == true) _loadProfile();
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature — coming soon')),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out',
                style: TextStyle(color: _danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_role');
    await prefs.remove('user_name');
    await prefs.remove('user_avatar');
    ProfileStore.clear();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('More',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _textDark)),
              const SizedBox(height: 16),
              _buildProfileCard(),
              const SizedBox(height: 20),
              _buildMenuCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          UserAvatar(avatarId: _avatarId, name: _patientName, size: 60),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_patientName,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700, color: _textDark)),
                const SizedBox(height: 4),
                const Text('Patient', style: TextStyle(fontSize: 13, color: _textMuted)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _openEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: _teal),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.edit_outlined, size: 14, color: _teal),
                  SizedBox(width: 4),
                  Text('Edit', style: TextStyle(fontSize: 12, color: _teal, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard() {
    final items = <_MenuItem>[
      _MenuItem(Icons.person_outline, 'Personal Information'),
      _MenuItem(Icons.health_and_safety_outlined, 'Insurance Details'),
      _MenuItem(Icons.folder_outlined, 'Health Records'),
      _MenuItem(Icons.notifications_outlined, 'Notifications'),
      _MenuItem(Icons.credit_card_outlined, 'Payment Methods'),
      _MenuItem(Icons.lock_outline, 'Privacy & Security'),
      _MenuItem(Icons.help_outline, 'Help & Support'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _menuRow(items[i].icon, items[i].label, onTap: () => _comingSoon(items[i].label)),
            const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F1F5)),
          ],
          _menuRow(Icons.logout, 'Logout', onTap: _logout, isDanger: true),
        ],
      ),
    );
  }

  Widget _menuRow(
    IconData icon,
    String label, {
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDanger ? const Color(0xFFFCE9E9) : const Color(0xFFE8F7F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 19, color: isDanger ? _danger : _teal),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDanger ? _danger : _textDark)),
            ),
            Icon(Icons.chevron_right, size: 20, color: isDanger ? _danger : _textMuted),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  const _MenuItem(this.icon, this.label);
}
