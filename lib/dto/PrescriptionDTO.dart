class PrescriptionItemDTO {
  final int? id;
  final String medicationName;
  final String? form; // MedicationForm enum name, e.g. "TABLET"
  final String? dosage; // strength, e.g. "20 mg"
  final String? amountPerDose; // units per dose, e.g. "1"
  final String? mealRelation; // MealRelation enum name, e.g. "AFTER_FOOD"
  final String? frequency;
  final int? timesPerDay;
  final int? durationDays;
  final int? quantityToPurchase;
  final String? instructions;

  /// Optional reminder times as "HH:mm" strings (e.g. ["09:00", "21:00"]).
  /// Empty when the doctor didn't pin specific clock times for this medication.
  final List<String> doseTimes;

  const PrescriptionItemDTO({
    this.id,
    required this.medicationName,
    this.form,
    this.dosage,
    this.amountPerDose,
    this.mealRelation,
    this.frequency,
    this.timesPerDay,
    this.durationDays,
    this.quantityToPurchase,
    this.instructions,
    this.doseTimes = const [],
  });

  factory PrescriptionItemDTO.fromJson(Map<String, dynamic> json) {
    return PrescriptionItemDTO(
      id: json['id'] as int?,
      medicationName: json['medicationName'] as String,
      form: json['form'] as String?,
      dosage: json['dosage'] as String?,
      amountPerDose: json['amountPerDose'] as String?,
      mealRelation: json['mealRelation'] as String?,
      frequency: json['frequency'] as String?,
      timesPerDay: json['timesPerDay'] as int?,
      durationDays: json['durationDays'] as int?,
      quantityToPurchase: json['quantityToPurchase'] as int?,
      instructions: json['instructions'] as String?,
      doseTimes: parseDoseTimes(json['doseTimes']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'medicationName': medicationName,
      if (form != null) 'form': form,
      if (dosage != null) 'dosage': dosage,
      if (amountPerDose != null) 'amountPerDose': amountPerDose,
      if (mealRelation != null) 'mealRelation': mealRelation,
      if (frequency != null) 'frequency': frequency,
      if (timesPerDay != null) 'timesPerDay': timesPerDay,
      if (durationDays != null) 'durationDays': durationDays,
      if (quantityToPurchase != null) 'quantityToPurchase': quantityToPurchase,
      if (instructions != null) 'instructions': instructions,
      if (doseTimes.isNotEmpty) 'doseTimes': doseTimes,
    };
  }
}

/// Normalises backend dose times ("HH:mm:ss") down to "HH:mm".
List<String> parseDoseTimes(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .map((e) => e.toString())
      .map((s) => s.length >= 5 ? s.substring(0, 5) : s)
      .toList();
}

class PrescriptionDTO {
  final int id;
  final int appointmentId;
  final DateTime issuedAt;
  final String? notes;
  final String status;
  final List<PrescriptionItemDTO> items;

  const PrescriptionDTO({
    required this.id,
    required this.appointmentId,
    required this.issuedAt,
    this.notes,
    required this.status,
    required this.items,
  });

  factory PrescriptionDTO.fromJson(Map<String, dynamic> json) {
    return PrescriptionDTO(
      id: json['id'] as int,
      appointmentId: json['appointmentId'] as int,
      issuedAt: DateTime.parse(json['issuedAt'] as String),
      notes: json['notes'] as String?,
      status: json['status'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => PrescriptionItemDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
