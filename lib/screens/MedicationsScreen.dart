import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dto/MedicationScheduleDTO.dart';
import '../dto/TodayMedicationDTO.dart';
import '../dto/medication_enums.dart';
import '../network/MedicationService.dart';
import '../network/NotificationService.dart';
import '../widgets/MedicationPillIcon.dart';

enum _MedTab { today, schedule, history }

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  static const _teal = Color(0xFF1A9882);
  static const _textDark = Color(0xFF1C2B47);
  static const _textMuted = Color(0xFF7A8399);
  static const _bg = Color(0xFFF5F6FA);

  final _service = MedicationService();

  _MedTab _tab = _MedTab.today;
  bool _loading = true;
  String? _error;
  TodayMedicationsDTO? _today;
  final Set<String> _busy = {}; // dose keys currently toggling

  bool _scheduleLoading = true;
  String? _scheduleError;
  List<MedicationScheduleDTO> _schedule = [];
  final Map<int, List<TimeOfDay?>> _edit = {}; // itemId -> editable time slots
  int? _savingItemId;

  static const _remindersPrefKey = 'med_reminders_enabled';
  bool _remindersEnabled = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() =>
          _remindersEnabled = prefs.getBool(_remindersPrefKey) ?? false);
    }
    await Future.wait([_load(), _loadSchedule()]);
    await _resyncRemindersIfEnabled();
  }

  Future<void> _resyncRemindersIfEnabled() async {
    if (!_remindersEnabled) return;
    try {
      await NotificationService.instance.syncMedicationReminders(_schedule);
    } catch (_) {
      // Non-fatal: reminders just won't update this run.
    }
  }

  Future<void> _setupReminders() async {
    final granted = await NotificationService.instance.requestPermissions();
    if (!mounted) return;
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enable notifications in settings to get reminders')),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_remindersPrefKey, true);
    await NotificationService.instance.syncMedicationReminders(_schedule);
    if (!mounted) return;
    setState(() => _remindersEnabled = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reminders on'), backgroundColor: _teal),
    );
  }

  Future<void> _disableReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_remindersPrefKey, false);
    await NotificationService.instance.cancelAll();
    if (!mounted) return;
    setState(() => _remindersEnabled = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reminders off')),
    );
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _scheduleLoading = true;
      _scheduleError = null;
    });
    try {
      final schedule = await _service.getSchedule();
      if (!mounted) return;
      setState(() {
        _schedule = schedule;
        _rebuildEditState();
        _scheduleLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scheduleError = 'Could not load your schedule';
        _scheduleLoading = false;
      });
    }
  }

  /// Seeds the editable time slots from the server data, one entry per item.
  void _rebuildEditState() {
    _edit.clear();
    for (final m in _schedule) {
      if (m.doctorPinned) continue;
      final existing = m.times.map(_parseTime).toList();
      final count = m.timesPerDay ?? (existing.isEmpty ? 1 : existing.length);
      final slots = List<TimeOfDay?>.generate(
        count,
        (i) => i < existing.length ? existing[i] : null,
      );
      _edit[m.itemId] = slots;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final today = await _service.getToday();
      if (!mounted) return;
      setState(() {
        _today = today;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load your medications';
        _loading = false;
      });
    }
  }

  String _key(DoseOccurrenceDTO d) => '${d.itemId}@${d.time ?? 'anytime'}';

  Future<void> _toggle(DoseOccurrenceDTO d) async {
    final key = _key(d);
    setState(() => _busy.add(key));
    try {
      final updated = d.taken
          ? await _service.untakeDose(itemId: d.itemId, time: d.time)
          : await _service.takeDose(itemId: d.itemId, time: d.time);
      if (!mounted) return;
      setState(() => _today = updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _busy.remove(key));
    }
  }

  // Doses that are actionable now: due/past, anytime, or already taken.
  List<DoseOccurrenceDTO> get _todayDoses {
    final now = DateTime.now();
    return _today!.doses.where((d) {
      if (d.taken || !d.hasTime) return true;
      final m = d.minutesUntil(now);
      return m == null || m <= 0;
    }).toList();
  }

  // Not-yet-taken doses with a future time.
  List<DoseOccurrenceDTO> get _upcomingDoses {
    final now = DateTime.now();
    return _today!.doses.where((d) {
      if (d.taken || !d.hasTime) return false;
      final m = d.minutesUntil(now);
      return m != null && m > 0;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildTabToggle(),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Text(
        'Medications',
        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _textDark),
      ),
    );
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
          _tabOption(_MedTab.today, 'Today'),
          _tabOption(_MedTab.schedule, 'Schedule'),
          _tabOption(_MedTab.history, 'History'),
        ],
      ),
    );
  }

  Widget _tabOption(_MedTab tab, String label) {
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

  Widget _buildBody() {
    if (_tab == _MedTab.schedule) {
      return _buildSchedule();
    }
    if (_tab == _MedTab.history) {
      return _stub('History', 'Your past adherence will appear here.');
    }

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
              onPressed: _load,
              child: const Text('Retry', style: TextStyle(color: _teal)),
            ),
          ],
        ),
      );
    }

    final today = _today!;
    final todayDoses = _todayDoses;
    final upcoming = _upcomingDoses;

    return RefreshIndicator(
      color: _teal,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          _adherenceCard(today),
          const SizedBox(height: 22),
          if (today.doses.isEmpty)
            _emptyState()
          else ...[
            if (todayDoses.isNotEmpty) ...[
              _sectionTitle("Today's medications"),
              const SizedBox(height: 12),
              ...todayDoses.map(_doseCard),
            ],
            if (upcoming.isNotEmpty) ...[
              const SizedBox(height: 12),
              _sectionTitle('Upcoming'),
              const SizedBox(height: 12),
              ...upcoming.map(_doseCard),
            ],
          ],
          const SizedBox(height: 12),
          _remindersBanner(),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: _textDark),
      );

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Text('No medications scheduled for today',
            style: TextStyle(fontSize: 14, color: _textMuted)),
      ),
    );
  }

  Widget _adherenceCard(TodayMedicationsDTO t) {
    final pct = t.adherencePct;
    final allDone = t.totalCount > 0 && t.takenCount == t.totalCount;
    final subtitle = t.totalCount == 0
        ? 'Nothing due today.'
        : allDone
            ? 'All done for today!'
            : 'Great job! Keep it up.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _ring(t),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${t.takenCount} of ${t.totalCount} taken today',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(fontSize: 13, color: _textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: t.totalCount == 0 ? 0 : t.adherence,
              minHeight: 8,
              backgroundColor: const Color(0xFFEDEFF3),
              valueColor: const AlwaysStoppedAnimation(_teal),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.check_circle, size: 16, color: _teal),
              const SizedBox(width: 6),
              Text('$pct% adherence',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: _teal)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ring(TodayMedicationsDTO t) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: CircularProgressIndicator(
              value: t.totalCount == 0 ? 0 : t.adherence,
              strokeWidth: 6,
              backgroundColor: const Color(0xFFEDEFF3),
              valueColor: const AlwaysStoppedAnimation(_teal),
            ),
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${t.takenCount}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: _teal),
                ),
                TextSpan(
                  text: ' / ${t.totalCount}',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: _textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _doseCard(DoseOccurrenceDTO d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F7F5),
              shape: BoxShape.circle,
            ),
            child: MedicationFormIcon(form: d.form, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.medicationName,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _textDark)),
                if (d.strengthFormLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(d.strengthFormLabel,
                      style: const TextStyle(fontSize: 12.5, color: _textMuted)),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 13, color: _textMuted),
                    const SizedBox(width: 4),
                    Text(d.timeLabel,
                        style: const TextStyle(fontSize: 12, color: _textMuted)),
                    if (d.mealLabel.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.restaurant, size: 13, color: _textMuted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(d.mealLabel,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontSize: 12, color: _textMuted)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _doseTrailing(d),
        ],
      ),
    );
  }

  Widget _doseTrailing(DoseOccurrenceDTO d) {
    final busy = _busy.contains(_key(d));
    if (busy) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(color: _teal, strokeWidth: 2.5),
      );
    }
    if (d.taken) {
      return GestureDetector(
        onTap: () => _toggle(d),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F6E8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, size: 15, color: Color(0xFF1F9D55)),
              SizedBox(width: 4),
              Text('Taken',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F9D55))),
            ],
          ),
        ),
      );
    }

    // Future, not-yet-taken doses show a countdown instead of a button.
    final mins = d.minutesUntil(DateTime.now());
    if (mins != null && mins > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEDEFF3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule, size: 13, color: _textMuted),
            const SizedBox(width: 4),
            Text('In ${_countdown(mins)}',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: _textMuted)),
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: () => _toggle(d),
      style: ElevatedButton.styleFrom(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text('Take now',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
    );
  }

  Widget _remindersBanner() {
    final on = _remindersEnabled;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F7F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(on ? Icons.notifications_active_outlined : Icons.calendar_month_outlined,
              color: _teal, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(on ? 'Reminders on' : 'Set reminders',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _textDark)),
                const SizedBox(height: 2),
                Text(
                    on
                        ? "You'll be reminded at each dose time."
                        : 'Never miss a dose. Enable medication reminders.',
                    style: const TextStyle(fontSize: 12, color: _textMuted)),
              ],
            ),
          ),
          GestureDetector(
            onTap: on ? _disableReminders : _setupReminders,
            child: Row(
              children: [
                Text(on ? 'Turn off' : 'Set up',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: _teal)),
                if (!on) const Icon(Icons.chevron_right, size: 18, color: _teal),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Schedule tab ───────────────────────────────────────────────────────

  Widget _buildSchedule() {
    if (_scheduleLoading) {
      return const Center(child: CircularProgressIndicator(color: _teal));
    }
    if (_scheduleError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_scheduleError!, style: const TextStyle(color: _textMuted)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadSchedule,
              child: const Text('Retry', style: TextStyle(color: _teal)),
            ),
          ],
        ),
      );
    }
    if (_schedule.isEmpty) {
      return _stub('Schedule', 'You have no current medications.');
    }
    return RefreshIndicator(
      color: _teal,
      onRefresh: _loadSchedule,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          const Text(
            'Set your own times for medications your doctor left unscheduled.',
            style: TextStyle(fontSize: 13, color: _textMuted),
          ),
          const SizedBox(height: 14),
          ..._schedule.map(_scheduleCard),
        ],
      ),
    );
  }

  Widget _scheduleCard(MedicationScheduleDTO m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          Text(m.medicationName,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _textDark)),
          if (m.strengthFormLabel.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(m.strengthFormLabel,
                style: const TextStyle(fontSize: 12.5, color: _textMuted)),
          ],
          if (m.frequencyLabel != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.repeat, size: 13, color: _teal),
                const SizedBox(width: 4),
                Text(m.frequencyLabel!,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: _teal)),
                if (m.mealLabel.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.restaurant, size: 13, color: _textMuted),
                  const SizedBox(width: 4),
                  Text(m.mealLabel,
                      style: const TextStyle(fontSize: 12, color: _textMuted)),
                ],
              ],
            ),
          ],
          const SizedBox(height: 12),
          if (m.doctorPinned)
            _doctorPinnedTimes(m)
          else
            _editableTimes(m),
        ],
      ),
    );
  }

  Widget _doctorPinnedTimes(MedicationScheduleDTO m) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in m.times) _readOnlyChip(formatClock(t)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: const [
            Icon(Icons.lock_outline, size: 13, color: _textMuted),
            SizedBox(width: 4),
            Text('Times set by your doctor',
                style: TextStyle(fontSize: 11.5, color: _textMuted)),
          ],
        ),
      ],
    );
  }

  Widget _editableTimes(MedicationScheduleDTO m) {
    final slots = _edit[m.itemId] ?? <TimeOfDay?>[];
    final flexible = m.timesPerDay == null;
    final allSet = slots.isNotEmpty && slots.every((t) => t != null);
    final saving = _savingItemId == m.itemId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < slots.length; i++)
              _slotChip(m.itemId, i, slots[i], flexible && slots.length > 1),
            if (flexible)
              GestureDetector(
                onTap: () =>
                    setState(() => _edit[m.itemId] = [...slots, null]),
                child: _pillContainer(
                  const Color(0xFFE8F7F5),
                  const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add, size: 15, color: _teal),
                    SizedBox(width: 3),
                    Text('Add time',
                        style: TextStyle(
                            fontSize: 12, color: _teal, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: (!allSet || saving) ? null : () => _saveSchedule(m),
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal,
              disabledBackgroundColor: const Color(0xFFB7D9D2),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text(m.isSet ? 'Update times' : 'Save times',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _slotChip(int itemId, int index, TimeOfDay? time, bool removable) {
    return GestureDetector(
      onTap: () => _pickSlotTime(itemId, index),
      child: _pillContainer(
        const Color(0xFFF5F6FA),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule,
                size: 14, color: time == null ? _textMuted : _teal),
            const SizedBox(width: 5),
            Text(
              time == null ? 'Set time' : time.format(context),
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: time == null ? _textMuted : _textDark),
            ),
            if (removable) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  final slots = [..._edit[itemId]!]..removeAt(index);
                  setState(() => _edit[itemId] = slots);
                },
                child: const Icon(Icons.close, size: 14, color: _textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _readOnlyChip(String label) => _pillContainer(
        const Color(0xFFF5F6FA),
        Text(label,
            style: const TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w600, color: _textDark)),
      );

  Widget _pillContainer(Color bg, Widget child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: child,
      );

  Future<void> _pickSlotTime(int itemId, int index) async {
    final current = _edit[itemId]![index] ?? const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
              primary: _teal, onPrimary: Colors.white, onSurface: _textDark),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => _edit[itemId]![index] = picked);
  }

  Future<void> _saveSchedule(MedicationScheduleDTO m) async {
    final slots = _edit[m.itemId]!;
    final times = slots.whereType<TimeOfDay>().map(_fmtTimeOfDay).toList();

    setState(() => _savingItemId = m.itemId);
    final result = await _service.saveSchedule(itemId: m.itemId, times: times);
    if (!mounted) return;
    setState(() => _savingItemId = null);

    if (result.success) {
      setState(() {
        _schedule = result.schedule;
        _rebuildEditState();
      });
      _load(); // effective dose times changed — refresh Today
      _resyncRemindersIfEnabled(); // re-arm reminders for the new times
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule saved'), backgroundColor: _teal),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(result.message),
            backgroundColor: const Color(0xFFE57373)),
      );
    }
  }

  TimeOfDay _parseTime(String hhmm) {
    final bits = hhmm.split(':');
    return TimeOfDay(
      hour: int.tryParse(bits.isNotEmpty ? bits[0] : '') ?? 0,
      minute: int.tryParse(bits.length > 1 ? bits[1] : '') ?? 0,
    );
  }

  String _fmtTimeOfDay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Widget _stub(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_month_outlined, size: 40, color: _textMuted),
            const SizedBox(height: 12),
            Text('$title — coming soon',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: _textDark)),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: _textMuted)),
          ],
        ),
      ),
    );
  }

  String _countdown(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}
