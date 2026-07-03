import 'package:dio/dio.dart';

import '../dto/ClinicDTO.dart';
import '../dto/ProfileDTO.dart';
import 'ApiClient.dart';

class ProfileResult {
  final bool success;
  final String message;
  final ProfileDTO? profile;

  const ProfileResult({required this.success, required this.message, this.profile});
}

class ClinicResult {
  final bool success;
  final String message;

  const ClinicResult({required this.success, required this.message});
}

class ProfileService {
  final Dio _dio = ApiClient.instance.dio;

  Future<ProfileDTO> getMe() async {
    final response = await _dio.get('/api/me');
    return ProfileDTO.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ClinicDTO> getClinic() async {
    final response = await _dio.get('/api/me/clinic');
    return ClinicDTO.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ClinicResult> updateClinic({
    String? clinicName,
    String? clinicAddress,
    String? clinicDetails,
  }) async {
    try {
      await _dio.put('/api/me/clinic', data: {
        if (clinicName != null) 'clinicName': clinicName,
        if (clinicAddress != null) 'clinicAddress': clinicAddress,
        if (clinicDetails != null) 'clinicDetails': clinicDetails,
      });
      return const ClinicResult(success: true, message: 'Clinic details saved');
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map ? data['message'] as String? : null) ??
          data?.toString() ??
          'Could not save clinic details.';
      return ClinicResult(success: false, message: msg);
    } catch (e) {
      return ClinicResult(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<ProfileResult> updateMe({
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
    int? avatarId,
    DateTime? dateOfBirth,
    String? bloodType,
    String? allergies,
    String? specialization,
    String? bio,
  }) async {
    try {
      final response = await _dio.put('/api/me', data: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        if (phone != null) 'phone': phone,
        if (avatarId != null) 'avatarId': avatarId,
        if (dateOfBirth != null)
          'dateOfBirth': dateOfBirth.toIso8601String().substring(0, 10),
        if (bloodType != null) 'bloodType': bloodType,
        if (allergies != null) 'allergies': allergies,
        if (specialization != null) 'specialization': specialization,
        if (bio != null) 'bio': bio,
      });
      return ProfileResult(
        success: true,
        message: 'Profile updated',
        profile: ProfileDTO.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map ? data['message'] as String? : null) ??
          data?.toString() ??
          'Could not update profile.';
      return ProfileResult(success: false, message: msg);
    } catch (e) {
      return ProfileResult(success: false, message: 'Unexpected error: $e');
    }
  }
}
