import 'package:flutter/material.dart';

import '../dto/AppointmentDTO.dart';
import '../network/AppointmentService.dart';
import 'patient/BookAppointmentScreen.dart';

class AppointmentsListScreen extends StatefulWidget {
  const AppointmentsListScreen({super.key});

  @override
  State<AppointmentsListScreen> createState() => _AppointmentsListScreenState();
}

class _AppointmentsListScreenState extends State<AppointmentsListScreen> {
  static const _teal = Color(0xFF1A9882);
  static const _textDark = Color(0xFF1C2B47);
  static const _textMuted = Color(0xFF7A8399);
  static const _bg = Color(0xFFF5F6FA);

  final _appointmentService = AppointmentService();

  bool _showUpcoming = true;
  bool _loading = false;
  String? _error;
  List<AppointmentDTO> _appointments = [];
  final _searchController = TextEditingController();
  final Set<int> _checkingIds = {};

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final appointments = await _appointmentService.getMyAppointments();
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

  void _goToBookAppointment() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BookAppointmentScreen()),
    ).then((_) => _loadAppointments());
  }

  Future<void> _checkIn(AppointmentDTO a) async {
    setState(() => _checkingIds.add(a.id));
    final result = await _appointmentService.checkIn(a.id);
    if (!mounted) return;
    setState(() => _checkingIds.remove(a.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            result.success ? 'Checked in for your appointment' : result.message),
        backgroundColor: result.success ? _teal : const Color(0xFFE57373),
      ),
    );
    if (result.success) _loadAppointments();
  }

  List<AppointmentDTO> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    final bucket = _appointments.where((a) =>
        _showUpcoming ? a.isUpcoming : !a.isUpcoming);
    final sorted = bucket.toList()
      ..sort((a, b) => _showUpcoming
          ? a.scheduledAt.compareTo(b.scheduledAt)
          : b.scheduledAt.compareTo(a.scheduledAt));
    if (query.isEmpty) return sorted;
    return sorted
        .where((a) =>
            a.doctorName.toLowerCase().contains(query) ||
            a.specialization.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Appointments',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _textDark),
                  ),
                  const SizedBox(height: 16),
                  _buildTabToggle(),
                  const SizedBox(height: 14),
                  _buildSearchBar(),
                ],
              ),
            ),
            Expanded(child: _buildList()),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _buildBookButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabToggle() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF0F4),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _tabOption(true, 'Upcoming'),
          _tabOption(false, 'Past'),
        ],
      ),
    );
  }

  Widget _tabOption(bool upcoming, String label) {
    final selected = _showUpcoming == upcoming;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _showUpcoming = upcoming),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _teal : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : _textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          hintText: 'Search appointments',
          hintStyle: TextStyle(color: _textMuted, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: _textMuted, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _teal));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

    final items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: Text(
          _showUpcoming ? 'No upcoming appointments' : 'No past appointments',
          style: const TextStyle(color: _textMuted, fontSize: 14),
        ),
      );
    }

    return RefreshIndicator(
      color: _teal,
      onRefresh: _loadAppointments,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _appointmentCard(items[i]),
      ),
    );
  }

  Widget _appointmentCard(AppointmentDTO a) {
    final dateStr = _formatDate(a.scheduledAt);
    final timeStr = _formatTime(a.scheduledAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0EEF8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.person_outline,
                    color: Color(0xFF5B8DB8), size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dr. ${a.doctorName}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _textDark)),
                    const SizedBox(height: 2),
                    Text(a.specialization,
                        style: const TextStyle(fontSize: 13, color: _textMuted)),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 13, color: _textMuted),
                      const SizedBox(width: 4),
                      Text(dateStr,
                          style: const TextStyle(fontSize: 12, color: _textMuted)),
                    ]),
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.schedule_outlined,
                          size: 13, color: _textMuted),
                      const SizedBox(width: 4),
                      Text(timeStr,
                          style: const TextStyle(fontSize: 12, color: _textMuted)),
                    ]),
                  ],
                ),
              ),
              _statusBadge(a.status),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F1F5)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                a.isVideoCall ? Icons.videocam_outlined : Icons.location_on_outlined,
                size: 15,
                color: a.isVideoCall ? const Color(0xFF4A6CF7) : const Color(0xFF9C5FCB),
              ),
              const SizedBox(width: 6),
              Text(
                a.isVideoCall ? 'Video Call' : 'In-Person Visit',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _textDark),
              ),
              const Spacer(),
              _checkInTrailing(a),
            ],
          ),
        ],
      ),
    );
  }

  Widget _checkInTrailing(AppointmentDTO a) {
    if (a.isCheckedIn) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 15, color: Color(0xFF1F9D55)),
          SizedBox(width: 4),
          Text('Checked in',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F9D55))),
        ],
      );
    }
    if (!a.isCheckInOpen) return const SizedBox.shrink();
    final checking = _checkingIds.contains(a.id);
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: checking ? null : () => _checkIn(a),
        style: ElevatedButton.styleFrom(
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: checking
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Text('Check in',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
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
      case 'NO_SHOW':
        bg = const Color(0xFFFCE9E9);
        fg = const Color(0xFFD64545);
        label = 'No-show';
        break;
      default:
        bg = const Color(0xFFFFF1E0);
        fg = const Color(0xFFE08A1F);
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  Widget _buildBookButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _goToBookAppointment,
        icon: const Icon(Icons.calendar_month_outlined, color: Colors.white, size: 20),
        label: const Text(
          'Book Appointment',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _teal,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}
