class ReportDTO {
  final int id;
  final String title;
  final String type; // BLOOD_TEST, MRI, CT_SCAN, X_RAY, ULTRASOUND, ECG, LAB_RESULT, OTHER
  final DateTime reportDate;
  final String? notes;
  final String? doctorName; // null when self-uploaded
  final bool selfUploaded;
  final String? fileUrl;

  const ReportDTO({
    required this.id,
    required this.title,
    required this.type,
    required this.reportDate,
    this.notes,
    this.doctorName,
    this.selfUploaded = false,
    this.fileUrl,
  });

  factory ReportDTO.fromJson(Map<String, dynamic> json) {
    return ReportDTO(
      id: json['id'] as int,
      title: json['title'] as String,
      type: json['type'] as String,
      reportDate: DateTime.parse(json['reportDate'] as String),
      notes: json['notes'] as String?,
      doctorName: json['doctorName'] as String?,
      selfUploaded: json['selfUploaded'] as bool? ?? false,
      fileUrl: json['fileUrl'] as String?,
    );
  }

  /// "Added by you" / "Dr. X" — for the patient's own reports view.
  String get patientSourceLabel =>
      selfUploaded ? 'Added by you' : 'Dr. ${doctorName ?? ''}';

  /// "Patient-provided" / "Added by Dr. X" — for the doctor's view.
  String get doctorSourceLabel =>
      selfUploaded ? 'Patient-provided' : 'Added by Dr. ${doctorName ?? ''}';

  String get typeLabel {
    switch (type) {
      case 'BLOOD_TEST':
        return 'Blood Test';
      case 'MRI':
        return 'MRI';
      case 'CT_SCAN':
        return 'CT Scan';
      case 'X_RAY':
        return 'X-Ray';
      case 'ULTRASOUND':
        return 'Ultrasound';
      case 'ECG':
        return 'ECG';
      case 'LAB_RESULT':
        return 'Lab Result';
      default:
        return 'Other';
    }
  }

  // Broad grouping used for the filter pills (All/Lab/Imaging/Other).
  String get category {
    switch (type) {
      case 'BLOOD_TEST':
      case 'LAB_RESULT':
        return 'Lab';
      case 'MRI':
      case 'CT_SCAN':
      case 'X_RAY':
      case 'ULTRASOUND':
        return 'Imaging';
      default:
        return 'Other';
    }
  }

  String? get _extension {
    final url = fileUrl;
    if (url == null || !url.contains('.')) return null;
    return url.substring(url.lastIndexOf('.') + 1).toLowerCase();
  }

  bool get isPdf => _extension == 'pdf';

  bool get isImage => const {'jpg', 'jpeg', 'png'}.contains(_extension);

  bool get hasFile => fileUrl != null && fileUrl!.trim().isNotEmpty;
}
