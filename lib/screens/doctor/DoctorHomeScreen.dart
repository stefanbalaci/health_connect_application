import 'package:flutter/material.dart';

import '../../dto/DoctorAppointmentDTO.dart';
import '../../network/AppointmentService.dart';
import '../../network/ProfileStore.dart';
import '../../widgets/UserAvatar.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  static const _teal = Color(0xFF1A9882);
  static const _textDark = Color(0xFF1C2B47);
  static const _textMuted = Color(0xFF7A8399);
  static const _bg = Color(0xFFF5F6FA);

  final _appointmentService = AppointmentService();

  bool _loading = false;
  String? _error;
  List<DoctorAppointmentDTO> _appointments = [];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final appointments = await _appointmentService.getDoctorAppointments();
      appointments.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      setState(() {
        _appointments = appointments;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load appointments';
        _loading = false;
      });
    }
  }

  List<DoctorAppointmentDTO> get _upcoming =>
      _appointments.where((a) => a.isUpcoming).toList();

  int get _todayCount {
    final now = DateTime.now();
    return _appointments
        .where((a) =>
            a.scheduledAt.year == now.year &&
            a.scheduledAt.month == now.month &&
            a.scheduledAt.day == now.day &&
            a.status != 'CANCELLED')
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: SafeArea(
        child: RefreshIndicator(
          color: _teal,
          onRefresh: _loadAppointments,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 24),
                _buildTodayCard(),
                const SizedBox(height: 24),
                _buildSectionTitle('Upcoming Appointments'),
                const SizedBox(height: 12),
                _buildAppointmentsList(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        ValueListenableBuilder<int?>(
          valueListenable: ProfileStore.avatarId,
          builder: (_, avatarId, __) =>
              UserAvatar(avatarId: avatarId, name: ProfileStore.name.value, size: 52),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: const TextStyle(
                  fontSize: 14,
                  color: _textMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),
              ValueListenableBuilder<String>(
                valueListenable: ProfileStore.name,
                builder: (_, name, __) => Text(
                  'Dr. ${name.trim().isEmpty ? 'Doctor' : name.trim()}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTodayCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7F5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.calendar_month_outlined,
                color: _teal, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_todayCount',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
                const Text(
                  'Appointments Today',
                  style: TextStyle(fontSize: 13, color: _textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: _textDark,
      ),
    );
  }

  Widget _buildAppointmentsList() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: _teal)),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text(_error!, style: const TextStyle(color: _textMuted)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadAppointments,
              child: const Text('Retry', style: TextStyle(color: _teal)),
            ),
          ],
        ),
      );
    }

    final items = _upcoming;
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text('No upcoming appointments',
              style: TextStyle(color: _textMuted, fontSize: 14)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _appointmentRow(items[i], isNext: i == 0),
            if (i < items.length - 1)
              const Divider(
                  height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F1F5)),
          ],
        ],
      ),
    );
  }

  Widget _appointmentRow(DoctorAppointmentDTO a, {required bool isNext}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Column(
              children: [
                if (isNext)
                  const Text('NEXT',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _teal)),
                if (isNext) const SizedBox(height: 2),
                Text(
                  _formatHourMinute(a.scheduledAt),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isNext ? _teal : _textDark,
                  ),
                ),
                Text(
                  _formatAmPm(a.scheduledAt),
                  style: const TextStyle(fontSize: 11, color: _textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE0EEF8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_outline,
                color: Color(0xFF5B8DB8), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.patientName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: _textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  a.isVideoCall ? 'Video Call' : 'In-Person Visit',
                  style: const TextStyle(fontSize: 12, color: _textMuted),
                ),
              ],
            ),
          ),
          _statusBadge(a.status),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'CONFIRMED':
        bg = const Color(0xFFE3F6E8);
        fg = const Color(0xFF1F9D55);
        label = 'Confirmed';
        break;
      case 'IN_PROGRESS':
        bg = const Color(0xFFECF1FF);
        fg = const Color(0xFF4A6CF7);
        label = 'In Progress';
        break;
      case 'COMPLETED':
        bg = const Color(0xFFEDEFF3);
        fg = _textMuted;
        label = 'Completed';
        break;
      case 'CANCELLED':
        bg = const Color(0xFFFCE9E9);
        fg = const Color(0xFFD64545);
        label = 'Cancelled';
        break;
      default:
        bg = const Color(0xFFFFF1E0);
        fg = const Color(0xFFE08A1F);
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  String _formatHourMinute(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatAmPm(DateTime dt) => dt.hour >= 12 ? 'PM' : 'AM';
}
