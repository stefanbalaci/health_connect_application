import 'package:flutter/material.dart';

import '../../dto/DayOffDTO.dart';
import '../../network/AvailabilityService.dart';
import 'EditProfileScreen.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  static const _teal = Color(0xFF1A9882);
  static const _textDark = Color(0xFF1C2B47);
  static const _textMuted = Color(0xFF7A8399);
  static const _bg = Color(0xFFF5F6FA);
  static const _danger = Color(0xFFD64545);

  final _service = AvailabilityService();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<DayOffDTO> _days = [];
  final Set<DateTime> _removing = {};

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
      final days = await _service.getDaysOff();
      if (!mounted) return;
      setState(() {
        _days = days;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load your availability';
        _loading = false;
      });
    }
  }

  Future<void> _addDays() async {
    final today = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Select day(s) off',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
              primary: _teal, onPrimary: Colors.white, onSurface: _textDark),
        ),
        child: child!,
      ),
    );
    if (range == null) return;

    setState(() => _saving = true);
    try {
      List<DayOffDTO> latest = _days;
      var d = DateTime(range.start.year, range.start.month, range.start.day);
      final end = DateTime(range.end.year, range.end.month, range.end.day);
      while (!d.isAfter(end)) {
        latest = await _service.addDayOff(date: d);
        d = d.add(const Duration(days: 1));
      }
      if (!mounted) return;
      setState(() {
        _days = latest;
        _saving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast('Could not save days off');
    }
  }

  Future<void> _remove(DayOffDTO day) async {
    setState(() => _removing.add(day.date));
    try {
      final list = await _service.removeDayOff(day.date);
      if (!mounted) return;
      setState(() {
        _days = list;
        _removing.remove(day.date);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _removing.remove(day.date));
      _toast('Could not remove that day');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: _teal, size: 22),
        ),
        title: const Text('Profile & Availability',
            style: TextStyle(
                color: _textDark, fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        color: _teal,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            _editProfileTile(),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(
                  child: Text('Days off',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _textDark)),
                ),
                _addButton(),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Patients can\'t book you on these days.',
              style: TextStyle(fontSize: 13, color: _textMuted),
            ),
            const SizedBox(height: 14),
            _daysSection(),
          ],
        ),
      ),
    );
  }

  Widget _editProfileTile() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F7F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_outline, color: _teal, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Edit profile',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textDark)),
            ),
            const Icon(Icons.chevron_right, color: _textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _addButton() {
    return GestureDetector(
      onTap: _saving ? null : _addDays,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _saving ? const Color(0xFFB7D9D2) : _teal,
          borderRadius: BorderRadius.circular(10),
        ),
        child: _saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child:
                    CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Row(
                children: [
                  Icon(Icons.add, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('Mark days off',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }

  Widget _daysSection() {
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
                onPressed: _load,
                child: const Text('Retry', style: TextStyle(color: _teal))),
          ],
        ),
      );
    }
    if (_days.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Center(
          child: Text('No days off scheduled',
              style: TextStyle(fontSize: 14, color: _textMuted)),
        ),
      );
    }
    return Column(children: _days.map(_dayCard).toList());
  }

  Widget _dayCard(DayOffDTO day) {
    final removing = _removing.contains(day.date);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFCE9E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_busy_outlined, color: _danger, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatFull(day.date),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _textDark)),
                if (day.reason != null && day.reason!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(day.reason!,
                      style: const TextStyle(fontSize: 12, color: _textMuted)),
                ],
              ],
            ),
          ),
          if (removing)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: _danger, strokeWidth: 2),
            )
          else
            GestureDetector(
              onTap: () => _remove(day),
              child: const Icon(Icons.close, color: _textMuted, size: 20),
            ),
        ],
      ),
    );
  }

  String _formatFull(DateTime dt) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
