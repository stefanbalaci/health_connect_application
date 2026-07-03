import 'medication_enums.dart';

/// One scheduled dose for today, with taken-state.
class DoseOccurrenceDTO {
  final int itemId;
  final String medicationName;
  final String? form;
  final String? dosage;
  final String? amountPerDose;
  final String? mealRelation;
  final String? instructions;
  final String? time; // "HH:mm" or null for an "anytime" dose
  final bool taken;
  final DateTime? takenAt;

  const DoseOccurrenceDTO({
    required this.itemId,
    required this.medicationName,
    this.form,
    this.dosage,
    this.amountPerDose,
    this.mealRelation,
    this.instructions,
    this.time,
    required this.taken,
    this.takenAt,
  });

  factory DoseOccurrenceDTO.fromJson(Map<String, dynamic> json) {
    final rawTime = json['time'] as String?;
    return DoseOccurrenceDTO(
      itemId: json['itemId'] as int,
      medicationName: json['medicationName'] as String,
      form: json['form'] as String?,
      dosage: json['dosage'] as String?,
      amountPerDose: json['amountPerDose'] as String?,
      mealRelation: json['mealRelation'] as String?,
      instructions: json['instructions'] as String?,
      time: rawTime != null && rawTime.length >= 5 ? rawTime.substring(0, 5) : rawTime,
      taken: json['taken'] as bool? ?? false,
      takenAt: json['takenAt'] != null
          ? DateTime.parse(json['takenAt'] as String)
          : null,
    );
  }

  bool get hasTime => time != null;

  /// "20 mg • Tablet"
  String get strengthFormLabel {
    final parts = <String>[
      if (dosage != null && dosage!.trim().isNotEmpty) dosage!.trim(),
      if (medicationFormLabel(form).isNotEmpty) medicationFormLabel(form),
    ];
    return parts.join(' • ');
  }

  String get timeLabel => hasTime ? formatClock(time!) : 'Anytime';

  String get mealLabel => mealRelationLabel(mealRelation);

  /// Minutes from now until this dose (negative if already past). Null if no time.
  int? minutesUntil(DateTime now) {
    if (!hasTime) return null;
    final bits = time!.split(':');
    final dt = DateTime(now.year, now.month, now.day,
        int.tryParse(bits[0]) ?? 0, int.tryParse(bits[1]) ?? 0);
    return dt.difference(now).inMinutes;
  }
}

class TodayMedicationsDTO {
  final int takenCount;
  final int totalCount;
  final List<DoseOccurrenceDTO> doses;

  const TodayMedicationsDTO({
    required this.takenCount,
    required this.totalCount,
    required this.doses,
  });

  factory TodayMedicationsDTO.fromJson(Map<String, dynamic> json) {
    return TodayMedicationsDTO(
      takenCount: json['takenCount'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
      doses: (json['doses'] as List<dynamic>? ?? [])
          .map((e) => DoseOccurrenceDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  double get adherence => totalCount == 0 ? 0 : takenCount / totalCount;
  int get adherencePct => (adherence * 100).round();
}
