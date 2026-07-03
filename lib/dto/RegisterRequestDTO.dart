class RegisterRequestDTO {
  final String fullName;
  final String email;
  final String phone;
  final String password;
  final String role;

  const RegisterRequestDTO({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    this.role = 'PATIENT',
  });

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'password': password,
    'role': role,
  };
}