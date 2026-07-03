import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../dto/MedicationScheduleDTO.dart';
import '../dto/medication_enums.dart';

/// Schedules on-device medication reminders. Finite courses get one-shot
/// notifications per remaining dose (so nothing fires after the course ends);
/// open-ended medications get daily-repeating ones.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _channelId = 'med_reminders';
  static const _channelName = 'Medication reminders';

  // Don't pre-schedule further than this; the app re-arms whenever the
  // Medications screen loads, which keeps long courses topped up.
  static const _horizonDays = 14;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()));
    } catch (_) {
      // Fall back to UTC if the device zone can't be resolved.
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios));
    _ready = true;
  }

  /// Requests OS permission (notifications + exact alarms). Returns whether
  /// notifications are allowed.
  Future<bool> requestPermissions() async {
    await init();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission() ?? false;
      // Exact alarms (Android 12+) — best-effort; reminders still work inexactly.
      await android.requestExactAlarmsPermission();
      return granted;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return true;
  }

  /// Cancels all medication reminders and re-schedules from the given schedule.
  Future<void> syncMedicationReminders(List<MedicationScheduleDTO> meds) async {
    await init();
    await _plugin.cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    final horizon = now.add(const Duration(days: _horizonDays));
    var id = 1000;

    for (final m in meds) {
      for (final t in m.times) {
        final parts = t.split(':');
        if (parts.length < 2) continue;
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;

        if (m.endDate == null) {
          // Open-ended: one daily-repeating reminder at this time.
          var first = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
          if (!first.isAfter(now)) first = first.add(const Duration(days: 1));
          await _schedule(id++, m, first, repeatDaily: true);
        } else {
          // Finite course: a one-shot per remaining dose day, up to endDate
          // (exclusive) and capped at the horizon — nothing after the course.
          final end = tz.TZDateTime(
              tz.local, m.endDate!.year, m.endDate!.month, m.endDate!.day);
          var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
          while (when.isBefore(end) && when.isBefore(horizon)) {
            if (when.isAfter(now)) {
              await _schedule(id++, m, when, repeatDaily: false);
            }
            when = when.add(const Duration(days: 1));
          }
        }
      }
    }
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  Future<void> _schedule(int id, MedicationScheduleDTO m, tz.TZDateTime when,
      {required bool repeatDaily}) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Reminders to take your medication',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id,
      'Time for ${m.medicationName}',
      _body(m),
      when,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  String _body(MedicationScheduleDTO m) {
    final form = medicationFormLabel(m.form).toLowerCase();
    final parts = <String>[
      if (m.amountPerDose != null && m.amountPerDose!.trim().isNotEmpty)
        '${m.amountPerDose} ${form.isEmpty ? 'dose' : form}'.trim()
      else if (m.dosage != null && m.dosage!.trim().isNotEmpty)
        m.dosage!.trim(),
      if (m.mealLabel.isNotEmpty) m.mealLabel,
    ];
    return parts.isEmpty ? 'Tap to open and mark as taken' : parts.join(' • ');
  }
}
