import 'package:flutter/material.dart';

import '../../dto/DoctorDTO.dart';
import '../../network/AppointmentService.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  static const _teal = Color(0xFF1A9882);
  static const _textDark = Color(0xFF1C2B47);
  static const _textMuted = Color(0xFF7A8399);
  static const _bg = Color(0xFFF5F6FA);
  static const _white = Colors.white;

  final _appointmentService = AppointmentService();

  bool _isInPerson = true;
  int _selectedSpecialty = 0;
  int _selectedDate = 0;
  int _selectedTime = 0;
  final _reasonController = TextEditingController();

  List<DoctorDTO> _doctors = [];
  DoctorDTO? _selectedDoctor;
  bool _loadingDoctors = false;
  String? _doctorError;
  bool _booking = false;

  final _specialties = [
    _Specialty('Cardiology', Icons.favorite_border),
    _Specialty('Dermatology', Icons.face_retouching_natural_outlined),
    _Specialty('General', Icons.local_hospital_outlined),
    _Specialty('Pediatrics', Icons.child_care_outlined),
  ];

  late List<_DateItem> _dates;
  final _times = <String>[];

  @override
  void initState() {
    super.initState();
    _dates = _buildDates(DateTime.now());
    _times.addAll(_defaultTimesForToday());
    _loadDoctors();
  }

  static List<_DateItem> _buildDates(DateTime start) {
    final startOfDay = DateTime(start.year, start.month, start.day);
    return List.generate(5, (i) => _DateItem(startOfDay.add(Duration(days: i))));
  }

  // Picks the next 4 half-hour slots (8:00 AM–6:00 PM) that haven't passed yet today.
  static List<String> _defaultTimesForToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final allSlots = _allDaySlots();

    int firstAvailable = allSlots.indexWhere((s) {
      final dt = _TimePickerDialog.parseTimeLabel(s, today);
      return dt != null && dt.isAfter(now);
    });
    if (firstAvailable < 0) firstAvailable = allSlots.length - 4;

    final start = firstAvailable.clamp(0, (allSlots.length - 4).clamp(0, allSlots.length));
    return allSlots.sublist(start, (start + 4).clamp(0, allSlots.length));
  }

  static List<String> _allDaySlots() {
    final slots = <String>[];
    for (int h = 8; h <= 18; h++) {
      slots.add('${h > 12 ? h - 12 : h}:00 ${h >= 12 ? 'PM' : 'AM'}');
      if (h < 18) slots.add('${h > 12 ? h - 12 : h}:30 ${h >= 12 ? 'PM' : 'AM'}');
    }
    return slots.map((s) => s.replaceAll('0:00 PM', '12:00 PM').replaceAll('0:30 PM', '12:30 PM')).toList();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _loadingDoctors = true;
      _doctorError = null;
    });
    try {
      final doctors = await _appointmentService.fetchDoctors();
      setState(() {
        _doctors = doctors;
        _loadingDoctors = false;
      });
    } catch (e) {
      setState(() {
        _doctorError = 'Could not load doctors';
        _loadingDoctors = false;
      });
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildTypeToggle(),
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 24),
            _sectionTitle('Choose Specialty'),
            const SizedBox(height: 12),
            _buildSpecialties(),
            const SizedBox(height: 24),
            _sectionTitle('Select Doctor'),
            const SizedBox(height: 12),
            _buildDoctorCard(),
            const SizedBox(height: 24),
            _sectionTitle('Select Date'),
            const SizedBox(height: 12),
            _buildDatePicker(),
            const SizedBox(height: 24),
            _sectionTitle('Available Time Slots'),
            const SizedBox(height: 12),
            _buildTimeSlots(),
            const SizedBox(height: 24),
            _sectionTitle('Reason for visit'),
            const SizedBox(height: 12),
            _buildReasonField(),
            const SizedBox(height: 16),
            _buildSummaryCard(),
            const SizedBox(height: 16),
            _buildConfirmButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _bg,
      elevation: 0,
      centerTitle: true,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.arrow_back, color: _teal, size: 22),
      ),
      title: const Text(
        'Book Appointment',
        style: TextStyle(
          color: _textDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Icon(Icons.info_outline, color: _teal, size: 24),
        ),
      ],
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF0F4),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _toggleOption(true, Icons.person_outline, 'In-Person'),
          _toggleOption(false, Icons.videocam_outlined, 'Video Call'),
        ],
      ),
    );
  }

  Widget _toggleOption(bool isInPerson, IconData icon, String label) {
    final selected = _isInPerson == isInPerson;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isInPerson = isInPerson),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: double.infinity,
          decoration: BoxDecoration(
            color: selected ? _teal : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
              BoxShadow(
                color: _teal.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? _white : _textMuted),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? _white : _textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search doctor or specialty',
          hintStyle: const TextStyle(color: _textMuted, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: _textMuted, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSpecialties() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _specialties.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final selected = _selectedSpecialty == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedSpecialty = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 88,
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? _teal : Colors.transparent,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_specialties[i].icon,
                      size: 28,
                      color: selected ? _teal : _textMuted),
                  const SizedBox(height: 6),
                  Text(
                    _specialties[i].name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: selected ? _teal : _textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmAppointment() async {
    if (_selectedDoctor == null) {
      _showError('Please select a doctor first.');
      return;
    }

    final baseDate = _selectedDateTime;
    if (baseDate == null) {
      _showError('Please select a date.');
      return;
    }

    final timeLabel = _times.isEmpty ? null : _times[_selectedTime];
    if (timeLabel == null) {
      _showError('Please select a time slot.');
      return;
    }

    final scheduledAt = _TimePickerDialog.parseTimeLabel(timeLabel, baseDate);
    if (scheduledAt == null) {
      _showError('Could not parse selected time.');
      return;
    }

    if (scheduledAt.isBefore(DateTime.now())) {
      _showError('Please select a future date and time.');
      return;
    }

    setState(() => _booking = true);

    final result = await _appointmentService.bookAppointment(
      doctorProfileId: _selectedDoctor!.id,
      scheduledAt: scheduledAt,
      type: _isInPerson ? 'CONSULTATION' : 'ONLINE',
      patientNotes: _reasonController.text.trim().isEmpty
          ? null
          : _reasonController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _booking = false);

    if (result.success) {
      _showSuccessDialog(scheduledAt);
    } else {
      _showError(result.message);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE57373),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _showSuccessDialog(DateTime scheduledAt) {
    final doctor = _selectedDoctor!;
    final timeStr = _times[_selectedTime];
    final dateStr = _selectedDateLabel;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _teal.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline,
                    color: _teal, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'Appointment Confirmed!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your appointment with Dr. ${doctor.fullName} has been booked.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: _textMuted),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _summaryRow(Icons.person_outline, 'Dr. ${doctor.fullName}'),
                    const SizedBox(height: 8),
                    _summaryRow(Icons.calendar_today_outlined, dateStr),
                    const SizedBox(height: 8),
                    _summaryRow(Icons.schedule_outlined, timeStr),
                    const SizedBox(height: 8),
                    _summaryRow(
                      _isInPerson ? Icons.people_outline : Icons.videocam_outlined,
                      _isInPerson ? 'In-Person' : 'Video Call',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // go back to home
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _teal),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: _textDark),
          ),
        ),
      ],
    );
  }

  void _openDoctorPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DoctorPickerSheet(
        doctors: _doctors,
        selectedId: _selectedDoctor?.id,
        loading: _loadingDoctors,
        error: _doctorError,
        onRetry: () {
          Navigator.pop(context);
          _loadDoctors();
        },
        onSelected: (doctor) {
          setState(() => _selectedDoctor = doctor);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildDoctorCard() {
    final doctor = _selectedDoctor;
    return GestureDetector(
      onTap: _openDoctorPicker,
      child: Container(
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _teal.withOpacity(0.4), width: 1.2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFE0EEF8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_outline,
                  color: Color(0xFF5B8DB8), size: 34),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: doctor == null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _loadingDoctors
                              ? 'Loading doctors...'
                              : 'Tap to choose a doctor',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _loadingDoctors ? _textMuted : _teal,
                          ),
                        ),
                        if (_doctorError != null) ...[
                          const SizedBox(height: 4),
                          Text(_doctorError!,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.redAccent)),
                        ],
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dr. ${doctor.fullName}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(doctor.specialization,
                            style: const TextStyle(
                                fontSize: 13, color: _textMuted)),
                        if (doctor.clinicName.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(children: [
                            const Icon(Icons.location_on_outlined,
                                size: 13, color: _textMuted),
                            const SizedBox(width: 3),
                            Text(doctor.clinicName,
                                style: const TextStyle(
                                    fontSize: 12, color: _textMuted)),
                          ]),
                        ],
                      ],
                    ),
            ),
            const SizedBox(width: 4),
            Icon(
              _loadingDoctors ? Icons.hourglass_top_outlined : Icons.chevron_right,
              color: _textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCalendarPicker() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      selectableDayPredicate: (day) =>
          !(_selectedDoctor?.isUnavailableOn(day) ?? false),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _teal,
              onPrimary: _white,
              onSurface: _textDark,
              surface: _white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _teal),
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dates = _buildDates(picked);
        _selectedDate = 0;
      });
    }
  }

  Widget _buildDatePicker() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ..._dates.asMap().entries.map((e) {
          final i = e.key;
          final d = e.value;
          final selected = _selectedDate == i;
          final unavailable = _selectedDoctor?.isUnavailableOn(d.date) ?? false;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < _dates.length - 1 ? 6 : 0),
              child: GestureDetector(
                onTap: unavailable
                    ? () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('The doctor is off on this day')),
                        )
                    : () => setState(() => _selectedDate = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? _teal
                        : (unavailable ? const Color(0xFFF0F1F4) : _white),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? _teal : const Color(0xFFEEF0F4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Builder(builder: (_) {
                    final hasBooking = _selectedDoctor?.hasBookingOn(d.date) ?? false;
                    final muted = unavailable
                        ? _textMuted.withOpacity(0.45)
                        : _textMuted;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(d.dayLabel,
                            style: TextStyle(
                                fontSize: 11,
                                color: selected ? _white.withOpacity(0.85) : muted,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 1),
                        Text(d.monthLabel,
                            style: TextStyle(
                                fontSize: 11,
                                color: selected ? _white.withOpacity(0.85) : muted)),
                        const SizedBox(height: 4),
                        Text(d.dayNumber,
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? _white
                                    : (unavailable
                                        ? _textMuted.withOpacity(0.55)
                                        : _textDark))),
                        const SizedBox(height: 4),
                        if (unavailable && !selected)
                          const Text('Off',
                              style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFD64545)))
                        else if (selected)
                          const Icon(Icons.check_circle, size: 14, color: _white)
                        else if (hasBooking)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE57373),
                              shape: BoxShape.circle,
                            ),
                          )
                        else
                          const SizedBox(height: 6),
                      ],
                    );
                  }),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: _openCalendarPicker,
          child: Container(
            width: 36,
            height: 88,
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEF0F4), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: const Icon(Icons.chevron_right, color: _textMuted, size: 20),
          ),
        ),
      ],
    );
  }


  Future<void> _openTimePicker() async {
    final baseDate = _selectedDateTime;
    final takenSlots = <String>{};
    if (baseDate != null) {
      takenSlots.addAll(_TimePickerDialog.computePastSlots(baseDate));
      if (_selectedDoctor != null) {
        takenSlots.addAll(
            _TimePickerDialog.computeTakenSlots(_selectedDoctor!.bookedSlots, baseDate));
      }
    }
    String? picked = await showDialog<String>(
      context: context,
      builder: (context) => _TimePickerDialog(
        selectedTime: _times[_selectedTime],
        takenSlots: takenSlots,
      ),
    );
    if (picked != null) {
      setState(() {
        // Build a new 4-slot list anchored at the picked time, staying within 08:00–18:00.
        final allSlots = _allDaySlots();
        final idx = allSlots.indexOf(picked);
        final start = idx.clamp(0, (allSlots.length - 4).clamp(0, allSlots.length));
        _times.clear();
        _times.addAll(allSlots.sublist(start, (start + 4).clamp(0, allSlots.length)));
        _selectedTime = 0;
      });
    }
  }

  bool _isTimeTaken(String timeLabel) {
    final base = _selectedDateTime;
    if (base == null) return false;
    final slotStart = _TimePickerDialog.parseTimeLabel(timeLabel, base);
    if (slotStart == null) return false;

    final isPast = !slotStart.isAfter(DateTime.now());
    final bookedByDoctor = _selectedDoctor?.isSlotTaken(slotStart) ?? false;
    return isPast || bookedByDoctor;
  }

  Widget _buildTimeSlots() {
    return Row(
      children: [
        ..._times.asMap().entries.map((e) {
          final i = e.key;
          final t = e.value;
          final selected = _selectedTime == i;
          final taken = _isTimeTaken(t);
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < _times.length - 1 ? 6 : 0),
              child: GestureDetector(
                onTap: taken ? null : () => setState(() => _selectedTime = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: taken
                        ? const Color(0xFFF0F0F0)
                        : selected ? _teal : _white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: taken
                          ? const Color(0xFFE0E0E0)
                          : selected ? _teal : const Color(0xFFEEF0F4),
                      width: 1.5,
                    ),
                    boxShadow: taken
                        ? null
                        : [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2)),
                          ],
                  ),
                  child: Text(
                    t,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: taken
                          ? const Color(0xFFBDBDBD)
                          : selected ? _white : _textDark,
                      decoration: taken ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: _openTimePicker,
          child: Container(
            width: 36,
            height: 40,
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEF0F4), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: const Icon(Icons.chevron_right, color: _textMuted, size: 18),
          ),
        ),
      ],
    );
  }


  Widget _buildReasonField() {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: _reasonController,
        maxLines: 3,
        maxLength: 300,
        decoration: const InputDecoration(
          hintText: 'Add symptoms or notes (optional)',
          hintStyle: TextStyle(color: _textMuted, fontSize: 13),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(14),
          counterStyle: TextStyle(color: _textMuted, fontSize: 11),
        ),
      ),
    );
  }

  DateTime? get _selectedDateTime {
    if (_dates.isEmpty) return null;
    return _dates[_selectedDate].date;
  }

  String get _selectedDateLabel {
    if (_dates.isEmpty) return '—';
    final d = _dates[_selectedDate];
    return '${d.dayLabel}, ${d.monthLabel} ${d.dayNumber}';
  }

  String get _selectedTimeLabel => _times.isEmpty ? '—' : _times[_selectedTime];

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F7F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _teal.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_month_outlined,
                color: _teal, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Appointment Summary',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _teal,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 12, color: _textMuted),
                    const SizedBox(width: 4),
                    Text(
                      _selectedDoctor != null
                          ? 'Dr. ${_selectedDoctor!.fullName}'
                          : 'No doctor selected',
                      style: const TextStyle(fontSize: 12, color: _textMuted),
                    ),
                    const SizedBox(width: 6),
                    const Text('•', style: TextStyle(fontSize: 12, color: _textMuted)),
                    const SizedBox(width: 6),
                    Icon(
                      _isInPerson ? Icons.people_outline : Icons.videocam_outlined,
                      size: 12,
                      color: _textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isInPerson ? 'In-Person' : 'Video Call',
                      style: const TextStyle(fontSize: 12, color: _textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 12, color: _textMuted),
                    const SizedBox(width: 4),
                    Text(_selectedDateLabel,
                        style: const TextStyle(fontSize: 12, color: _textMuted)),
                    const SizedBox(width: 6),
                    const Text('•', style: TextStyle(fontSize: 12, color: _textMuted)),
                    const SizedBox(width: 6),
                    const Icon(Icons.schedule_outlined, size: 12, color: _textMuted),
                    const SizedBox(width: 4),
                    Text(_selectedTimeLabel,
                        style: const TextStyle(fontSize: 12, color: _textMuted)),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: const Text(
              'Edit',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _teal,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _booking ? null : _confirmAppointment,
        icon: _booking
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : const Icon(Icons.calendar_month_outlined,
                color: Colors.white, size: 20),
        label: Text(
          _booking ? 'Booking...' : 'Confirm Appointment',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _booking ? _teal.withOpacity(0.6) : _teal,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: _textDark,
      ),
    );
  }

}

class _DoctorPickerSheet extends StatelessWidget {
  final List<DoctorDTO> doctors;
  final int? selectedId;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<DoctorDTO> onSelected;

  static const _teal = Color(0xFF1A9882);
  static const _textDark = Color(0xFF1C2B47);
  static const _textMuted = Color(0xFF7A8399);

  const _DoctorPickerSheet({
    required this.doctors,
    required this.selectedId,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDE1EA),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose a Doctor',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(color: _teal),
            )
          else if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              child: Column(
                children: [
                  Text(error!,
                      style: const TextStyle(color: _textMuted, fontSize: 14)),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: onRetry,
                    child: const Text('Retry', style: TextStyle(color: _teal)),
                  ),
                ],
              ),
            )
          else if (doctors.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text('No doctors available',
                  style: TextStyle(color: _textMuted)),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: doctors.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final doctor = doctors[i];
                  final isSelected = doctor.id == selectedId;
                  return GestureDetector(
                    onTap: () => onSelected(doctor),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _teal.withOpacity(0.07)
                            : const Color(0xFFF5F6FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? _teal : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0EEF8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.person_outline,
                                color: Color(0xFF5B8DB8), size: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dr. ${doctor.fullName}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  doctor.specialization,
                                  style: const TextStyle(
                                      fontSize: 12, color: _textMuted),
                                ),
                                if (doctor.clinicName.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Row(children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 12, color: _textMuted),
                                    const SizedBox(width: 3),
                                    Text(doctor.clinicName,
                                        style: const TextStyle(
                                            fontSize: 11, color: _textMuted)),
                                  ]),
                                ],
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle,
                                color: _teal, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Specialty {
  final String name;
  final IconData icon;
  const _Specialty(this.name, this.icon);
}

class _DateItem {
  final DateTime date;
  const _DateItem(this.date);

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String get dayLabel => _dayNames[date.weekday - 1];
  String get monthLabel => _monthNames[date.month - 1];
  String get dayNumber => '${date.day}';
}

class _TimePickerDialog extends StatefulWidget {
  final String selectedTime;
  final Set<String> takenSlots;

  const _TimePickerDialog({
    required this.selectedTime,
    this.takenSlots = const {},
  });

  @override
  State<_TimePickerDialog> createState() => _TimePickerDialogState();

  // Parses a label like "9:00 AM" into a DateTime on the given base date.
  static DateTime? parseTimeLabel(String label, DateTime base) {
    final parts = label.trim().split(' ');
    if (parts.length != 2) return null;
    final timeParts = parts[0].split(':');
    if (timeParts.length != 2) return null;
    int hour = int.tryParse(timeParts[0]) ?? -1;
    final minute = int.tryParse(timeParts[1]) ?? -1;
    final isPm = parts[1].toUpperCase() == 'PM';
    if (hour < 0 || minute < 0) return null;
    if (isPm && hour != 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;
    return DateTime(base.year, base.month, base.day, hour, minute);
  }

  // Returns the set of slot labels that conflict with any booked slot on baseDate.
  static Set<String> computeTakenSlots(
      List<BookedSlot> bookedSlots, DateTime baseDate) {
    final taken = <String>{};
    for (final slot in _TimePickerDialogState._allSlots) {
      final slotStart = parseTimeLabel(slot, baseDate);
      if (slotStart == null) continue;
      if (bookedSlots.any((b) => b.conflictsWith(slotStart))) {
        taken.add(slot);
      }
    }
    return taken;
  }

  // Returns the set of slot labels on baseDate that have already passed.
  static Set<String> computePastSlots(DateTime baseDate) {
    final now = DateTime.now();
    final past = <String>{};
    for (final slot in _TimePickerDialogState._allSlots) {
      final slotStart = parseTimeLabel(slot, baseDate);
      if (slotStart == null) continue;
      if (!slotStart.isAfter(now)) past.add(slot);
    }
    return past;
  }
}

class _TimePickerDialogState extends State<_TimePickerDialog> {
  static const _teal = Color(0xFF1A9882);
  static const _textDark = Color(0xFF1C2B47);
  static const _textMuted = Color(0xFF7A8399);

  late String _selected;

  static final List<String> _allSlots = () {
    final slots = <String>[];
    for (int h = 8; h <= 18; h++) {
      final label12 = h == 12 ? 12 : (h > 12 ? h - 12 : h);
      final suffix = h >= 12 ? 'PM' : 'AM';
      slots.add('$label12:00 $suffix');
      if (h < 18) slots.add('$label12:30 $suffix');
    }
    return slots;
  }();

  @override
  void initState() {
    super.initState();
    _selected = _allSlots.contains(widget.selectedTime)
        ? widget.selectedTime
        : _allSlots.first;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Pick a time',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _textDark),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: _textMuted, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Available 8:00 AM – 6:00 PM',
                style: TextStyle(fontSize: 12, color: _textMuted)),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.4,
                ),
                itemCount: _allSlots.length,
                itemBuilder: (_, i) {
                  final slot = _allSlots[i];
                  final sel = _selected == slot;
                  final taken = widget.takenSlots.contains(slot);
                  return GestureDetector(
                    onTap: taken ? null : () => setState(() => _selected = slot),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: taken
                            ? const Color(0xFFF0F0F0)
                            : sel ? _teal : const Color(0xFFF5F6FA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: taken
                              ? const Color(0xFFE0E0E0)
                              : sel ? _teal : const Color(0xFFEEF0F4),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        slot,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: taken
                              ? const Color(0xFFBDBDBD)
                              : sel ? Colors.white : _textDark,
                          decoration:
                              taken ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Confirm time',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}