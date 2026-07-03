class DoctorPatientDTO {
  final int patientProfileId;
  final String fullName;
  final int? age;
  final DateTime? lastVisit;
  final DateTime? nextAppointment;
  final int totalAppointments;

  const DoctorPatientDTO({
    required this.patientProfileId,
    required this.fullName,
    this.age,
    this.lastVisit,
    this.nextAppointment,
    required this.totalAppointments,
  });

  factory DoctorPatientDTO.fromJson(Map<String, dynamic> json) {
    return DoctorPatientDTO(
      patientProfileId: json['patientProfileId'] as int,
      fullName: json['fullName'] as String,
      age: json['age'] as int?,
      lastVisit: json['lastVisit'] != null ? DateTime.parse(json['lastVisit'] as String) : null,
      nextAppointment: json['nextAppointment'] != null
          ? DateTime.parse(json['nextAppointment'] as String)
          : null,
      totalAppointments: json['totalAppointments'] as int,
    );
  }
}
