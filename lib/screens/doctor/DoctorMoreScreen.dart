import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../network/AppointmentService.dart';
import '../../network/ProfileService.dart';
import '../../network/ProfileStore.dart';
import '../../widgets/UserAvatar.dart';
import '../patient/AvailabilityScreen.dart';
import 'ClinicDetailsScreen.dart';
import '../patient/EditProfileScreen.dart';
import '../LoginScreen.dart';

class DoctorMoreScreen extends StatefulWidget {
  const DoctorMoreScreen({super.key});

  @override
  State<DoctorMoreScreen> createState() => _DoctorMoreScreenState();
}

class _DoctorMoreScreenState extends State<DoctorMoreScreen> {
  static const _teal = Color(0xFF1A9882);
  static const _textDark = Color(0xFF1C2B47);
  static const _textMuted = Color(0xFF7A8399);
  static const _bg = Color(0xFFF5F6FA);
  static const _danger = Color(0xFFE05A4D);

  final _appointmentService = AppointmentService();

  String _doctorName = 'Doctor';
  int? _avatarId;
  int _patientCount = 0;
  int _todayCount = 0;
  int _pendingCount = 0;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadStats();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedName = prefs.getString('user_name');
    final cachedAvatar = prefs.getInt('user_avatar');
    if (mounted) {
      setState(() {
        if (cachedName != null && cachedName.trim().isNotEmpty) {
          _doctorName = cachedName;
        }
        _avatarId = cachedAvatar;
      });
    }
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
        if (p.fullName.isNotEmpty) _doctorName = p.fullName;
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

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final appointments = await _appointmentService.getDoctorAppointments();
      final patients = await _appointmentService.getMyPatients();
      final now = DateTime.now();

      setState(() {
        _patientCount = patients.length;
        _todayCount = appointments
            .where((a) =>
                a.scheduledAt.year == now.year &&
                a.scheduledAt.month == now.month &&
                a.scheduledAt.day == now.day &&
                a.status != 'CANCELLED')
            .length;
        _pendingCount = appointments.where((a) => a.status == 'REQUESTED').length;
        _loadingStats = false;
      });
    } catch (e) {
      setState(() => _loadingStats = false);
    }
  }

  void _openClinicDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ClinicDetailsScreen()),
    );
  }

  void _openAvailability() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AvailabilityScreen()),
    );
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
              const SizedBox(height: 20),
              const Text('Quick Tools',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textDark)),
              const SizedBox(height: 10),
              _buildQuickTools(),
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
      child: Column(
        children: [
          Row(
            children: [
              UserAvatar(avatarId: _avatarId, name: _doctorName, size: 60),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dr. $_doctorName',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700, color: _textDark)),
                    const SizedBox(height: 4),
                    const Text('Doctor', style: TextStyle(fontSize: 13, color: _textMuted)),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _statTile(Icons.people_outline, 'Patients', _patientCount)),
              const SizedBox(width: 10),
              Expanded(child: _statTile(Icons.calendar_today_outlined, 'Today', _todayCount)),
              const SizedBox(width: 10),
              Expanded(child: _statTile(Icons.schedule_outlined, 'Pending', _pendingCount)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile(IconData icon, String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F7F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: _teal, size: 20),
          const SizedBox(height: 6),
          Text(
            _loadingStats ? '—' : '$count',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textDark),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: _textMuted)),
        ],
      ),
    );
  }

  Widget _buildMenuCard() {
    final items = <_MenuItem>[
      _MenuItem(Icons.person_outline, 'Profile & Availability'),
      _MenuItem(Icons.apartment_outlined, 'Clinic Details'),
      _MenuItem(Icons.description_outlined, 'Consultation Notes'),
      _MenuItem(Icons.upload_outlined, 'Reports & Uploads'),
      _MenuItem(Icons.notifications_outlined, 'Notifications'),
      _MenuItem(Icons.account_balance_wallet_outlined, 'Billing & Payouts'),
      _MenuItem(Icons.shield_outlined, 'Privacy & Security'),
      _MenuItem(Icons.help_outline, 'Help Center'),
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
            _menuRow(items[i].icon, items[i].label,
                onTap: switch (items[i].label) {
                  'Clinic Details' => _openClinicDetails,
                  'Profile & Availability' => _openAvailability,
                  _ => () => _comingSoon(items[i].label),
                }),
            const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F1F5)),
          ],
          _menuRow(Icons.logout, 'Logout', onTap: _logout, isDanger: true, showDivider: false),
        ],
      ),
    );
  }

  Widget _menuRow(
    IconData icon,
    String label, {
    required VoidCallback onTap,
    bool isDanger = false,
    bool showDivider = true,
  }) {
    final color = isDanger ? _danger : _textDark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isDanger ? _danger : _teal),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
            ),
            Icon(Icons.chevron_right, size: 20, color: isDanger ? _danger : _textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTools() {
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
          _quickToolRow(Icons.videocam_outlined, 'Start Video Call',
              'Connect with a patient instantly'),
          const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F1F5)),
          _quickToolRow(Icons.bar_chart_outlined, 'View Weekly Summary',
              'See your appointments & insights'),
        ],
      ),
    );
  }

  Widget _quickToolRow(IconData icon, String title, String subtitle) {
    return InkWell(
      onTap: () => _comingSoon(title),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F7F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _teal, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: _textDark)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: _textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: _textMuted),
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
