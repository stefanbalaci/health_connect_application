class BookedSlot {
  final DateTime scheduledAt;
  final int durationMinutes;

  const BookedSlot({required this.scheduledAt, required this.durationMinutes});

  DateTime get endsAt => scheduledAt.add(Duration(minutes: durationMinutes));

  factory BookedSlot.fromJson(Map<String, dynamic> json) => BookedSlot(
        scheduledAt: DateTime.parse(json['scheduledAt'] as String),
        durationMinutes: json['durationMinutes'] as int,
      );

  // Returns true if the given slot (start, 30 min) overlaps this booking.
  bool conflictsWith(DateTime slotStart) {
    final slotEnd = slotStart.add(const Duration(minutes: 30));
    return slotStart.isBefore(endsAt) && slotEnd.isAfter(scheduledAt);
  }
}

class DoctorDTO {
  final int id;
  final String fullName;
  final String specialization;
  final String clinicName;
  final String? bio;
  final List<BookedSlot> bookedSlots;
  final List<DateTime> unavailableDates;

  const DoctorDTO({
    required this.id,
    required this.fullName,
    required this.specialization,
    required this.clinicName,
    this.bio,
    required this.bookedSlots,
    this.unavailableDates = const [],
  });

  factory DoctorDTO.fromJson(Map<String, dynamic> json) {
    final slots = (json['appointments'] as List<dynamic>? ?? [])
        .map((e) => BookedSlot.fromJson(e as Map<String, dynamic>))
        .toList();
    final unavailable = (json['unavailableDates'] as List<dynamic>? ?? [])
        .map((e) => DateTime.parse(e as String))
        .toList();

    return DoctorDTO(
      id: json['id'] as int,
      fullName: json['fullName'] as String,
      specialization: json['specialization'] as String,
      clinicName: json['clinicName'] as String? ?? '',
      bio: json['bio'] as String?,
      bookedSlots: slots,
      unavailableDates: unavailable,
    );
  }

  // Returns true if the doctor marked this day as unavailable (day off).
  bool isUnavailableOn(DateTime date) {
    return unavailableDates.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
  }

  // Returns true if the given date has at least one booking.
  bool hasBookingOn(DateTime date) {
    return bookedSlots.any((s) =>
        s.scheduledAt.year == date.year &&
        s.scheduledAt.month == date.month &&
        s.scheduledAt.day == date.day);
  }

  // Returns true if a specific time slot conflicts with any booking.
  bool isSlotTaken(DateTime slotStart) {
    return bookedSlots.any((s) => s.conflictsWith(slotStart));
  }
}
