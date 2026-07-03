class ProfileDTO {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String? phone;
  final int? avatarId;

  // Patient-only
  final DateTime? dateOfBirth;
  final String? bloodType;
  final String? allergies;

  // Doctor-only
  final String? specialization;
  final String? clinicName;
  final String? bio;

  /// Only set when an email change forced a new JWT (the client must store it).
  final String? token;

  const ProfileDTO({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.phone,
    this.avatarId,
    this.dateOfBirth,
    this.bloodType,
    this.allergies,
    this.specialization,
    this.clinicName,
    this.bio,
    this.token,
  });

  bool get isDoctor => role == 'DOCTOR';

  String get fullName => '$firstName $lastName'.trim();

  factory ProfileDTO.fromJson(Map<String, dynamic> json) {
    return ProfileDTO(
      id: json['id'] as int,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'PATIENT',
      phone: json['phone'] as String?,
      avatarId: json['avatarId'] as int?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'] as String)
          : null,
      bloodType: json['bloodType'] as String?,
      allergies: json['allergies'] as String?,
      specialization: json['specialization'] as String?,
      clinicName: json['clinicName'] as String?,
      bio: json['bio'] as String?,
      token: json['token'] as String?,
    );
  }
}
