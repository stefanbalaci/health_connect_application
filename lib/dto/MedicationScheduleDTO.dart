import 'PrescriptionDTO.dart' show parseDoseTimes;
import 'medication_enums.dart';

/// A medication on the patient's Schedule tab.
/// When [doctorPinned] is true the [times] are fixed by the doctor (read-only);
/// otherwise the patient sets them (expected count = [timesPerDay]).
class MedicationScheduleDTO {
  final int itemId;
  final String medicationName;
  final String? form;
  final String? dosage;
  final String? amountPerDose;
  final String? mealRelation;
  final int? timesPerDay;
  final bool doctorPinned;
  final List<String> times; // "HH:mm"

  /// Exclusive last day of the course (issuedAt + durationDays); null = ongoing.
  /// Reminders stop being scheduled on/after this date.
  final DateTime? endDate;

  const MedicationScheduleDTO({
    required this.itemId,
    required this.medicationName,
    this.form,
    this.dosage,
    this.amountPerDose,
    this.mealRelation,
    this.timesPerDay,
    required this.doctorPinned,
    this.times = const [],
    this.endDate,
  });

  factory MedicationScheduleDTO.fromJson(Map<String, dynamic> json) {
    return MedicationScheduleDTO(
      itemId: json['itemId'] as int,
      medicationName: json['medicationName'] as String,
      form: json['form'] as String?,
      dosage: json['dosage'] as String?,
      amountPerDose: json['amountPerDose'] as String?,
      mealRelation: json['mealRelation'] as String?,
      timesPerDay: json['timesPerDay'] as int?,
      doctorPinned: json['doctorPinned'] as bool? ?? false,
      times: parseDoseTimes(json['times']),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
    );
  }

  bool get isSet => times.isNotEmpty;

  String get strengthFormLabel {
    final parts = <String>[
      if (dosage != null && dosage!.trim().isNotEmpty) dosage!.trim(),
      if (medicationFormLabel(form).isNotEmpty) medicationFormLabel(form),
    ];
    return parts.join(' • ');
  }

  String get mealLabel => mealRelationLabel(mealRelation);

  /// "2 times per day", "Once a day", or null when not specified.
  String? get frequencyLabel {
    if (timesPerDay == null) return null;
    return timesPerDay == 1 ? 'Once a day' : '$timesPerDay times per day';
  }
}
