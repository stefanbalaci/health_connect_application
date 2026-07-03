import 'PrescriptionDTO.dart' show parseDoseTimes;
import 'medication_enums.dart';

class MedicationDTO {
  final int itemId;
  final int prescriptionId;
  final String medicationName;
  final String? form; // MedicationForm enum name
  final String? dosage; // strength, e.g. "20 mg"
  final String? amountPerDose;
  final String? mealRelation; // MealRelation enum name
  final String? frequency;
  final int? durationDays;
  final int? quantityToPurchase;
  final String? instructions;

  /// Optional reminder times as "HH:mm" strings; empty when none were set.
  final List<String> doseTimes;
  final DateTime issuedAt;

  const MedicationDTO({
    required this.itemId,
    required this.prescriptionId,
    required this.medicationName,
    this.form,
    this.dosage,
    this.amountPerDose,
    this.mealRelation,
    this.frequency,
    this.durationDays,
    this.quantityToPurchase,
    this.instructions,
    this.doseTimes = const [],
    required this.issuedAt,
  });

  factory MedicationDTO.fromJson(Map<String, dynamic> json) {
    return MedicationDTO(
      itemId: json['itemId'] as int,
      prescriptionId: json['prescriptionId'] as int,
      medicationName: json['medicationName'] as String,
      form: json['form'] as String?,
      dosage: json['dosage'] as String?,
      amountPerDose: json['amountPerDose'] as String?,
      mealRelation: json['mealRelation'] as String?,
      frequency: json['frequency'] as String?,
      durationDays: json['durationDays'] as int?,
      quantityToPurchase: json['quantityToPurchase'] as int?,
      instructions: json['instructions'] as String?,
      doseTimes: parseDoseTimes(json['doseTimes']),
      issuedAt: DateTime.parse(json['issuedAt'] as String),
    );
  }

  bool get hasDoseTimes => doseTimes.isNotEmpty;

  String get doseTimesLabel => doseTimes.map(formatClock).join(', ');

  /// "20 mg • Tablet", used as the strength/form line (image 2 style).
  String get strengthFormLabel {
    final parts = <String>[
      if (dosage != null && dosage!.trim().isNotEmpty) dosage!.trim(),
      if (medicationFormLabel(form).isNotEmpty) medicationFormLabel(form),
    ];
    return parts.join(' • ');
  }

  /// Muted subtitle for the Home "Today" tile: strength/form, times, meal.
  String get scheduleLabel {
    final parts = <String>[
      if (strengthFormLabel.isNotEmpty) strengthFormLabel,
      if (hasDoseTimes) doseTimesLabel,
      if (mealRelationLabel(mealRelation).isNotEmpty)
        mealRelationLabel(mealRelation),
    ];
    if (parts.isNotEmpty) return parts.join(' • ');
    if (instructions != null && instructions!.trim().isNotEmpty) {
      return instructions!.trim();
    }
    return 'As prescribed';
  }
}
