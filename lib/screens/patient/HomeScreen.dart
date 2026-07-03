import 'package:flutter/material.dart';

import '../../dto/AppointmentDTO.dart';
import '../../dto/MedicationDTO.dart';
import '../../dto/ReportDTO.dart';
import '../../network/AppointmentService.dart';
import '../../network/MedicationService.dart';
import '../../network/ProfileStore.dart';
import '../../network/ReportService.dart';
import '../../widgets/AddMyReportSheet.dart';
import '../../widgets/MedicationPillIcon.dart';
import '../../widgets/UserAvatar.dart';
import 'BookAppointmentScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _teal = Color(0xFF1A9882);
  static const _textDark = Color(0xFF1C2B47);
  static const _textMuted = Color(0xFF7A8399);
  static const _bg = Color(0xFFF5F6FA);

  final _appointmentService = AppointmentService();
  final _medicationService = MedicationService();
  final _reportService = ReportService();

  List<AppointmentDTO> _appointments = [];
  List<MedicationDTO> _medications = [];
  List<ReportDTO> _reports = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _appointmentService.getMyAppointments(),
        _medicationService.getMyMedicationsDueToday(),
        _reportService.getMyReports(),
      ]);

      if (!mounted) return;
      setState(() {
        _appointments = results[0] as List<AppointmentDTO>;
        _medications = results[1] as List<MedicationDTO>;
        _reports = results[2] as List<ReportDTO>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load your dashboard';
        _loading = false;
      });
    }
  }

  // ---- Derived data ---------------------------------------------------------

  AppointmentDTO? get _nextAppointment {
    final now = DateTime.now();
    final upcoming = _appointments
        .where((a) => a.isUpcoming && a.scheduledAt.isAfter(now))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  List<AppointmentDTO> get _todayAppointments {
    final now = DateTime.now();
    return _appointments
        .where((a) =>
            a.status != 'CANCELLED' &&
            a.status != 'NO_SHOW' &&
            _isSameDay(a.scheduledAt, now))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  /// Appointments still awaiting a doctor's response — drives the bell badge.
  int get _pendingCount => _appointments
      .where((a) => a.status == 'REQUESTED' || a.status == 'PENDING')
      .length;

  List<ReportDTO> get _recentReports {
    final sorted = [..._reports]
      ..sort((a, b) => b.reportDate.compareTo(a.reportDate));
    return sorted.take(2).toList();
  }

  void _goToBookAppointment() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BookAppointmentScreen()),
    ).then((_) => _load());
  }

  Future<void> _uploadReport() async {
    final added = await showAddMyReportSheet(context);
    if (added == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report uploaded'), backgroundColor: _teal),
      );
      _load();
    }
  }

  Future<void> _checkIn(AppointmentDTO a) async {
    final result = await _appointmentService.checkIn(a.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(result.success ? 'Checked in for your appointment' : result.message),
        backgroundColor: result.success ? _teal : const Color(0xFFE57373),
      ),
    );
    if (result.success) _load();
  }

  // ---- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: SafeArea(
        child: RefreshIndicator(
          color: _teal,
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 24),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(child: CircularProgressIndicator(color: _teal)),
                  )
                else if (_error != null)
                  _buildError()
                else ...[
                  _buildNextAppointment(),
                  const SizedBox(height: 24),
                  _buildTodaySection(),
                  const SizedBox(height: 24),
                  _buildRecentResults(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Center(
        child: Column(
          children: [
            Text(_error!, style: const TextStyle(color: _textMuted)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _load,
              child: const Text('Retry', style: TextStyle(color: _teal)),
            ),
          ],
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
                  name.trim().isEmpty ? 'there' : name.trim(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        Stack(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.notifications_outlined,
                  color: _textDark, size: 22),
            ),
            if (_pendingCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE84040),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$_pendingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ---- Next appointment -----------------------------------------------------

  Widget _buildNextAppointment() {
    final next = _nextAppointment;
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F7F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_month_outlined,
                      color: _teal, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Next Appointment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                const Spacer(),
                if (next != null)
                  const Icon(Icons.chevron_right, color: _textMuted, size: 20),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F1F5)),
          if (next == null)
            _buildNoNextAppointment()
          else
            _buildNextAppointmentBody(next),
        ],
      ),
    );
  }

  Widget _buildNoNextAppointment() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'No upcoming appointments',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: _textDark),
          ),
          const SizedBox(height: 4),
          const Text(
            'Book a visit with one of our doctors.',
            style: TextStyle(fontSize: 12, color: _textMuted),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _goToBookAppointment,
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Book Appointment',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextAppointmentBody(AppointmentDTO a) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0EEF8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_outline,
                    color: Color(0xFF5B8DB8), size: 36),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. ${a.doctorName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      a.specialization.isEmpty ? 'General' : a.specialization,
                      style: const TextStyle(fontSize: 13, color: _textMuted),
                    ),
                    const SizedBox(height: 8),
                    _infoRow(Icons.calendar_today_outlined,
                        '${_formatDate(a.scheduledAt)}  ${_formatTime(a.scheduledAt)}'),
                    const SizedBox(height: 4),
                    _infoRow(
                        a.isVideoCall
                            ? Icons.videocam_outlined
                            : Icons.location_on_outlined,
                        a.isVideoCall ? 'Video Call' : 'HealthConnect Clinic'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              if (a.isCheckInPending && !a.isCheckInOpen)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 13, color: _textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Check-in opens at ${_formatTime(a.checkInOpensAt)}',
                          style: const TextStyle(fontSize: 11.5, color: _textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(child: _checkInButton(a)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _teal,
                        side: const BorderSide(color: _teal),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('View details',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _checkInButton(AppointmentDTO a) {
    if (a.isCheckedIn) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle, size: 18),
        label: const Text('Checked in',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1F9D55),
          disabledBackgroundColor: const Color(0xFF1F9D55),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    final enabled = a.isCheckInOpen;
    return ElevatedButton(
      onPressed: enabled ? () => _checkIn(a) : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _teal,
        disabledBackgroundColor: const Color(0xFFB7D9D2),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text('Check in',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: _textMuted),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: _textMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ---- Today ----------------------------------------------------------------

  Widget _buildTodaySection() {
    // Up to two tiles. If the patient has both a medication and an appointment
    // today, show one of each; otherwise fill from whichever list has items.
    final meds = _medications;
    final appts = _todayAppointments;

    final tiles = <Widget>[];
    if (meds.isNotEmpty && appts.isNotEmpty) {
      tiles.add(_medicationTile(meds.first));
      tiles.add(_todayAppointmentTile(appts.first));
    } else if (meds.isNotEmpty) {
      tiles.addAll(meds.take(2).map(_medicationTile));
    } else if (appts.isNotEmpty) {
      tiles.addAll(appts.take(2).map(_todayAppointmentTile));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
          child: tiles.isEmpty
              ? _emptyToday()
              : Column(
                  children: [
                    for (var i = 0; i < tiles.length; i++) ...[
                      if (i > 0)
                        const Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: Color(0xFFF0F1F5)),
                      tiles[i],
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _emptyToday() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Center(
        child: Text(
          'Nothing scheduled for today',
          style: TextStyle(fontSize: 14, color: _textMuted),
        ),
      ),
    );
  }

  Widget _medicationTile(MedicationDTO m) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7F5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: MedicationFormIcon(form: m.form, size: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Medication reminder',
                  style: TextStyle(fontSize: 12, color: _textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  m.medicationName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  m.scheduleLabel,
                  style: const TextStyle(fontSize: 12, color: _textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _todayAppointmentTile(AppointmentDTO a) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7F5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
                a.isVideoCall
                    ? Icons.videocam_outlined
                    : Icons.calendar_month_outlined,
                color: _teal,
                size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Appointment today',
                  style: TextStyle(fontSize: 12, color: _textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dr. ${a.doctorName}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${_formatTime(a.scheduledAt)} • ${a.isVideoCall ? 'Video Call' : 'In-Person'}',
                  style: const TextStyle(fontSize: 12, color: _textMuted),
                ),
              ],
            ),
          ),
          a.isCheckedIn ? _checkedInBadge() : _statusBadge(a.status),
        ],
      ),
    );
  }

  Widget _checkedInBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: const Color(0xFFE3F6E8),
          borderRadius: BorderRadius.circular(20)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 12, color: Color(0xFF1F9D55)),
          SizedBox(width: 3),
          Text('Checked in',
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F9D55))),
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
        label = 'Now';
        break;
      case 'COMPLETED':
        bg = const Color(0xFFEDEFF3);
        fg = _textMuted;
        label = 'Done';
        break;
      default:
        bg = const Color(0xFFFFF1E0);
        fg = const Color(0xFFE08A1F);
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  // ---- Recent results -------------------------------------------------------

  Widget _buildRecentResults() {
    final recent = _recentReports;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Recent Results & Updates',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
            const Spacer(),
            if (recent.isNotEmpty)
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'View all',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _teal,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
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
          child: recent.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                  child: Center(
                    child: Text('No recent results',
                        style: TextStyle(fontSize: 14, color: _textMuted)),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < recent.length; i++) ...[
                      if (i > 0)
                        const Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: Color(0xFFF0F1F5)),
                      _resultRow(recent[i]),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _resultRow(ReportDTO r) {
    IconData icon;
    Color iconColor;
    Color iconBg;
    switch (r.category) {
      case 'Lab':
        icon = Icons.science_outlined;
        iconColor = _teal;
        iconBg = const Color(0xFFE8F7F5);
        break;
      case 'Imaging':
        icon = Icons.image_outlined;
        iconColor = const Color(0xFF4A6CF7);
        iconBg = const Color(0xFFECF1FF);
        break;
      default:
        icon = Icons.description_outlined;
        iconColor = const Color(0xFFE05A2B);
        iconBg = const Color(0xFFFFF0EC);
    }

    final subtitle = (r.notes != null && r.notes!.trim().isNotEmpty)
        ? r.notes!.trim()
        : 'New ${r.typeLabel} available to view.';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: _textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatDate(r.reportDate),
                  style: const TextStyle(fontSize: 11, color: _textMuted)),
              const SizedBox(height: 4),
              const Icon(Icons.chevron_right, color: _textMuted, size: 18),
            ],
          ),
        ],
      ),
    );
  }

  // ---- Quick actions --------------------------------------------------------

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
          icon: Icons.calendar_month_outlined,
          label: 'Book\nAppointment',
          color: _teal,
          bg: const Color(0xFFE8F7F5),
          onTap: _goToBookAppointment),
      _QuickAction(
          icon: Icons.chat_outlined,
          label: 'Chat with\nDoctor',
          color: const Color(0xFF4A6CF7),
          bg: const Color(0xFFECF1FF),
          onTap: () {}),
      _QuickAction(
          icon: Icons.upload_file_outlined,
          label: 'Upload\nReports',
          color: const Color(0xFFE05A2B),
          bg: const Color(0xFFFFF0EC),
          onTap: _uploadReport),
      _QuickAction(
          icon: Icons.favorite_border,
          label: 'Health\nRecords',
          color: const Color(0xFFD44FAB),
          bg: const Color(0xFFFCEEF8),
          onTap: () {}),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: actions
              .map((a) => Expanded(
                    child: Padding(
                      padding:
                          EdgeInsets.only(right: actions.last == a ? 0 : 10),
                      child: _buildActionButton(a),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildActionButton(_QuickAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: action.bg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(action.icon, color: action.color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _textDark,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Helpers --------------------------------------------------------------

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });
}
