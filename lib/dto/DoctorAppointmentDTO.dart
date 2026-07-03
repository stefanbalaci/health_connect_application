class DoctorAppointmentDTO {
  final int id;
  final String patientName;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String status; // REQUESTED, PENDING, CONFIRMED, IN_PROGRESS, COMPLETED, CANCELLED, NO_SHOW
  final String type; // CONSULTATION, CONTROL, EMERGENCY, ONLINE
  final String? patientNotes;
  final DateTime? checkedInAt;

  const DoctorAppointmentDTO({
    required this.id,
    required this.patientName,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.status,
    required this.type,
    this.patientNotes,
    this.checkedInAt,
  });

  bool get isVideoCall => type == 'ONLINE';

  bool get isInProgress => status == 'IN_PROGRESS';

  bool get isUpcoming =>
      status != 'CANCELLED' && status != 'COMPLETED' && status != 'NO_SHOW';

  bool get isCheckedIn => checkedInAt != null;

  factory DoctorAppointmentDTO.fromJson(Map<String, dynamic> json) {
    return DoctorAppointmentDTO(
      id: json['id'] as int,
      patientName: json['patientName'] as String,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      durationMinutes: json['durationMinutes'] as int,
      status: json['status'] as String,
      type: json['type'] as String,
      patientNotes: json['patientNotes'] as String?,
      checkedInAt: json['checkedInAt'] != null
          ? DateTime.parse(json['checkedInAt'] as String)
          : null,
    );
  }
}
