import 'package:flutter/material.dart';

import '../../dto/DoctorAppointmentDTO.dart';
import '../../network/AppointmentService.dart';

enum _ScheduleTab { today, upcoming, requests }

class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  static const _teal = Color(0xFF1A9882);
  static const _textDark = Color(0xFF1C2B47);
  static const _textMuted = Color(0xFF7A8399);
  static const _bg = Color(0xFFF5F6FA);

  final _appointmentService = AppointmentService();

  _ScheduleTab _tab = _ScheduleTab.today;
  bool _loading = false;
  String? _error;
  List<DoctorAppointmentDTO> _appointments = [];
  late DateTime _selectedDay;
  final Set<int> _actioningIds = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
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
        _error = 'Could not load schedule';
        _loading = false;
      });
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<DateTime> get _weekDays {
    final monday = _selectedDay.subtract(Duration(days: _selectedDay.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  List<DoctorAppointmentDTO> get _selectedDayAppointments => _appointments
      .where((a) => _isSameDay(a.scheduledAt, _selectedDay) && a.status != 'CANCELLED')
      .toList();

  List<DoctorAppointmentDTO> get _pendingRequests => _appointments
      .where((a) => a.status == 'REQUESTED' && a.scheduledAt.isAfter(DateTime.now()))
      .toList();

  List<DoctorAppointmentDTO> get _upcomingAppointments {
    final now = DateTime.now();
    return _appointments
        .where((a) =>
            a.status != 'CANCELLED' &&
            a.status != 'COMPLETED' &&
            a.status != 'NO_SHOW' &&
            a.scheduledAt.isAfter(now))
        .toList();
  }

  Future<void> _respond(DoctorAppointmentDTO a, {required bool accept}) async {
    setState(() => _actioningIds.add(a.id));
    final result = accept
        ? await _appointmentService.acceptAppointment(a.id)
        : await _appointmentService.declineAppointment(a.id);

    if (!mounted) return;
    setState(() => _actioningIds.remove(a.id));

    if (result.success) {
      await _loadAppointments();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: const Color(0xFFE57373)),
      );
    }
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
                const SizedBox(height: 18),
                _buildTabToggle(),
                const SizedBox(height: 18),
                if (_tab == _ScheduleTab.today) ..._buildTodayTab(),
                if (_tab == _ScheduleTab.upcoming) ..._buildUpcomingTab(),
                if (_tab == _ScheduleTab.requests) ..._buildRequestsTab(),
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
        const Expanded(
          child: Text(
            'Schedule',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          ),
        ),
        _headerIcon(Icons.calendar_month_outlined, onTap: _pickDate),
        const SizedBox(width: 10),
        _headerIcon(Icons.filter_list),
      ],
    );
  }

  Widget _headerIcon(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, color: _teal, size: 20),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
              primary: _teal, onPrimary: Colors.white, onSurface: _textDark),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDay = DateTime(picked.year, picked.month, picked.day);
        _tab = _ScheduleTab.today;
      });
    }
  }

  Widget _buildTabToggle() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF0F4),
        borderRadius: BorderRadius.circular(13),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _tabOption(_ScheduleTab.today, 'Today'),
          _tabOption(_ScheduleTab.upcoming, 'Upcoming'),
          _tabOption(_ScheduleTab.requests, 'Requests'),
        ],
      ),
    );
  }

  Widget _tabOption(_ScheduleTab tab, String label) {
    final selected = _tab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _teal : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : _textMuted,
            ),
          ),
        ),
      ),
    );
  }

  // ── Today tab ──────────────────────────────────────────────────────────

  List<Widget> _buildTodayTab() {
    return [
      _buildDayStrip(),
      const SizedBox(height: 16),
      _buildStatsRow(),
      const SizedBox(height: 24),
      Text(
        _isSameDay(_selectedDay, DateTime.now())
            ? "Today's Appointments"
            : 'Appointments on ${_formatSelectedDay(_selectedDay)}',
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: _textDark),
      ),
      const SizedBox(height: 12),
      _buildLoadableSection(
        items: _selectedDayAppointments,
        emptyText: 'No appointments for this day',
        builder: (a) => _appointmentRow(a),
      ),
      const SizedBox(height: 24),
      Row(
        children: [
          const Expanded(
            child: Text('Appointment Requests',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textDark)),
          ),
          GestureDetector(
            onTap: () => setState(() => _tab = _ScheduleTab.requests),
            child: const Text('View all',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _teal)),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _buildLoadableSection(
        items: _pendingRequests.take(3).toList(),
        emptyText: 'No pending requests',
        builder: (a) => _requestCard(a),
      ),
    ];
  }

  Widget _buildDayStrip() {
    return SizedBox(
      height: 64,
      child: Row(
        children: _weekDays.map((day) {
          final selected = _isSameDay(day, _selectedDay);
          const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: () => setState(() => _selectedDay = day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: selected ? _teal : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(dayNames[day.weekday - 1],
                          style: TextStyle(
                              fontSize: 11,
                              color: selected ? Colors.white.withOpacity(0.85) : _textMuted)),
                      const SizedBox(height: 4),
                      Text('${day.day}',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : _textDark)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsRow() {
    final dayItems = _selectedDayAppointments;
    final confirmed = dayItems.where((a) => a.status == 'CONFIRMED').length;
    final pending = dayItems
        .where((a) => a.status == 'REQUESTED' || a.status == 'PENDING')
        .length;
    final completed = dayItems.where((a) => a.status == 'COMPLETED').length;

    return Row(
      children: [
        Expanded(
            child: _statCard(Icons.calendar_month_outlined, _teal, const Color(0xFFE8F7F5),
                'Confirmed', confirmed)),
        const SizedBox(width: 10),
        Expanded(
            child: _statCard(Icons.assignment_outlined, const Color(0xFF9C5FCB),
                const Color(0xFFF3EAFB), 'Pending', pending)),
        const SizedBox(width: 10),
        Expanded(
            child: _statCard(Icons.check_circle_outline, const Color(0xFF1F9D55),
                const Color(0xFFE3F6E8), 'Completed', completed)),
      ],
    );
  }

  Widget _statCard(IconData icon, Color color, Color bg, String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 15),
            ),
          ]),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, color: _textMuted)),
          const SizedBox(height: 2),
          Text('$count',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _textDark)),
        ],
      ),
    );
  }

  Widget _appointmentRow(DoctorAppointmentDTO a) {
    final checkIn = _checkInIndicator(a);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Text(_formatHourMinute(a.scheduledAt),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textDark)),
                Text(_formatAmPm(a.scheduledAt),
                    style: const TextStyle(fontSize: 11, color: _textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE0EEF8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_outline, color: Color(0xFF5B8DB8), size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.patientName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textDark)),
                const SizedBox(height: 2),
                Text(
                  (a.patientNotes != null && a.patientNotes!.trim().isNotEmpty)
                      ? a.patientNotes!
                      : (a.isVideoCall ? 'Video Call' : 'In-Person Visit'),
                  style: const TextStyle(fontSize: 12, color: _textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (checkIn != null) ...[
                  const SizedBox(height: 3),
                  checkIn,
                ],
              ],
            ),
          ),
          _statusBadge(a.status),
        ],
      ),
    );
  }

  /// Shows the doctor whether the patient has confirmed attendance:
  /// green "Checked in" once they have, amber "Awaiting check-in" while a
  /// confirmed upcoming appointment is still pending.
  Widget? _checkInIndicator(DoctorAppointmentDTO a) {
    if (a.isCheckedIn) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 12, color: Color(0xFF1F9D55)),
          SizedBox(width: 4),
          Text('Checked in',
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F9D55))),
        ],
      );
    }
    if (a.status == 'CONFIRMED' && a.scheduledAt.isAfter(DateTime.now())) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 12, color: Color(0xFFE08A1F)),
          SizedBox(width: 4),
          Text('Awaiting check-in',
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE08A1F))),
        ],
      );
    }
    return null;
  }

  // ── Upcoming tab ───────────────────────────────────────────────────────

  List<Widget> _buildUpcomingTab() {
    return [
      const Text('Upcoming Appointments',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textDark)),
      const SizedBox(height: 12),
      _buildLoadableSection(
        items: _upcomingAppointments,
        emptyText: 'No upcoming appointments',
        builder: (a) => _appointmentRow(a),
      ),
    ];
  }

  // ── Requests tab ───────────────────────────────────────────────────────

  List<Widget> _buildRequestsTab() {
    return [
      const Text('Appointment Requests',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textDark)),
      const SizedBox(height: 12),
      _buildLoadableSection(
        items: _pendingRequests,
        emptyText: 'No pending requests',
        builder: (a) => _requestCard(a),
      ),
    ];
  }

  Widget _requestCard(DoctorAppointmentDTO a) {
    final acting = _actioningIds.contains(a.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0EEF8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_outline, color: Color(0xFF5B8DB8), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.patientName,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700, color: _textDark)),
                    const SizedBox(height: 2),
                    Text(
                      (a.patientNotes != null && a.patientNotes!.trim().isNotEmpty)
                          ? a.patientNotes!
                          : (a.isVideoCall ? 'Video Call' : 'In-Person Visit'),
                      style: const TextStyle(fontSize: 12, color: _textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.event_outlined, size: 12, color: Color(0xFFE08A1F)),
                      const SizedBox(width: 4),
                      Text(_formatRequestDate(a.scheduledAt),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE08A1F))),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (acting)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Center(child: CircularProgressIndicator(color: _teal, strokeWidth: 2.5)),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respond(a, accept: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                    ),
                    child: const Text('Accept',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respond(a, accept: false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textMuted,
                      side: const BorderSide(color: Color(0xFFD8DCE3)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                    ),
                    child: const Text('Decline',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ── Shared ─────────────────────────────────────────────────────────────

  Widget _buildLoadableSection({
    required List<DoctorAppointmentDTO> items,
    required String emptyText,
    required Widget Function(DoctorAppointmentDTO) builder,
  }) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
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
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text(emptyText, style: const TextStyle(color: _textMuted, fontSize: 13))),
      );
    }
    return Column(children: items.map(builder).toList());
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
        bg = const Color(0xFFFDEBD0);
        fg = const Color(0xFFC0392B);
        label = 'No-show';
        break;
      default:
        bg = const Color(0xFFFFF1E0);
        fg = const Color(0xFFE08A1F);
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  String _formatHourMinute(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatAmPm(DateTime dt) => dt.hour >= 12 ? 'PM' : 'AM';

  String _formatSelectedDay(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatRequestDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = target.difference(today).inDays;
    final time = '${_formatHourMinute(dt)} ${_formatAmPm(dt)}';
    if (diff == 0) return 'Today, $time';
    if (diff == 1) return 'Tomorrow, $time';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, $time';
  }
}
