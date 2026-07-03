// Shared labels/options for medication form & meal-timing enums, mirroring
// the backend `MedicationForm` and `MealRelation` enums.

const List<String> kMedicationForms = [
  'TABLET',
  'CAPSULE',
  'SYRUP',
  'DROPS',
  'INJECTION',
  'CREAM',
  'INHALER',
  'PATCH',
  'SACHET',
  'SPRAY',
  'OTHER',
];

const List<String> kMealRelations = [
  'BEFORE_FOOD',
  'AFTER_FOOD',
  'WITH_FOOD',
  'ANYTIME',
];

String medicationFormLabel(String? form) {
  switch (form) {
    case 'TABLET':
      return 'Tablet';
    case 'CAPSULE':
      return 'Capsule';
    case 'SYRUP':
      return 'Syrup';
    case 'DROPS':
      return 'Drops';
    case 'INJECTION':
      return 'Injection';
    case 'CREAM':
      return 'Cream';
    case 'INHALER':
      return 'Inhaler';
    case 'PATCH':
      return 'Patch';
    case 'SACHET':
      return 'Sachet';
    case 'SPRAY':
      return 'Spray';
    case 'OTHER':
      return 'Other';
    default:
      return '';
  }
}

String mealRelationLabel(String? relation) {
  switch (relation) {
    case 'BEFORE_FOOD':
      return 'Before food';
    case 'AFTER_FOOD':
      return 'After food';
    case 'WITH_FOOD':
      return 'With food';
    case 'ANYTIME':
      return 'Anytime';
    default:
      return '';
  }
}

/// Formats an "HH:mm" or "HH:mm:ss" string as "9:00 AM".
String formatClock(String hhmm) {
  final bits = hhmm.split(':');
  if (bits.length < 2) return hhmm;
  final h = int.tryParse(bits[0]) ?? 0;
  final m = bits[1].padLeft(2, '0');
  final suffix = h >= 12 ? 'PM' : 'AM';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:$m $suffix';
}
