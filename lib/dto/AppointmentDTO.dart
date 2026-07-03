/// Check-in opens this long before the appointment start.
const Duration kCheckInOpensBefore = Duration(hours: 2);

/// Check-in closes this long before the appointment start.
/// Must mirror the backend (AppointmentService.CHECK_IN_CLOSES_BEFORE).
const Duration kCheckInClosesBefore = Duration(minutes: 30);

class AppointmentDTO {
  final int id;
  final String doctorName;
  final String specialization;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String status; // REQUESTED, PENDING, CONFIRMED, IN_PROGRESS, COMPLETED, CANCELLED, NO_SHOW
  final String type; // CONSULTATION, CONTROL, EMERGENCY, ONLINE
  final DateTime? checkedInAt;

  const AppointmentDTO({
    required this.id,
    required this.doctorName,
    required this.specialization,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.status,
    required this.type,
    this.checkedInAt,
  });

  bool get isVideoCall => type == 'ONLINE';

  bool get isInProgress => status == 'IN_PROGRESS';

  bool get isUpcoming =>
      status != 'CANCELLED' && status != 'COMPLETED' && status != 'NO_SHOW';

  bool get isCheckedIn => checkedInAt != null;

  DateTime get checkInOpensAt => scheduledAt.subtract(kCheckInOpensBefore);
  DateTime get checkInClosesAt => scheduledAt.subtract(kCheckInClosesBefore);

  /// Check-in is actionable right now (confirmed, not yet checked in, inside
  /// the [checkInOpensAt, checkInClosesAt] window).
  bool get isCheckInOpen {
    if (status != 'CONFIRMED' || isCheckedIn) return false;
    final now = DateTime.now();
    return !now.isBefore(checkInOpensAt) && !now.isAfter(checkInClosesAt);
  }

  /// Confirmed, not checked in, and the window hasn't closed yet — i.e. a
  /// check-in affordance is still relevant (may be "opens at …" or "open now").
  bool get isCheckInPending =>
      status == 'CONFIRMED' &&
      !isCheckedIn &&
      DateTime.now().isBefore(checkInClosesAt);

  factory AppointmentDTO.fromJson(Map<String, dynamic> json) {
    return AppointmentDTO(
      id: json['id'] as int,
      doctorName: json['doctorName'] as String,
      specialization: json['specialization'] as String? ?? '',
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      durationMinutes: json['durationMinutes'] as int,
      status: json['status'] as String,
      type: json['type'] as String,
      checkedInAt: json['checkedInAt'] != null
          ? DateTime.parse(json['checkedInAt'] as String)
          : null,
    );
  }
}
