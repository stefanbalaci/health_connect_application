class ClinicDTO {
  final String? clinicName;
  final String? clinicAddress;
  final String? clinicDetails;

  const ClinicDTO({this.clinicName, this.clinicAddress, this.clinicDetails});

  factory ClinicDTO.fromJson(Map<String, dynamic> json) {
    return ClinicDTO(
      clinicName: json['clinicName'] as String?,
      clinicAddress: json['clinicAddress'] as String?,
      clinicDetails: json['clinicDetails'] as String?,
    );
  }
}
