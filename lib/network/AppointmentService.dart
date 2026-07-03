import 'package:dio/dio.dart';

import '../dto/AppointmentDTO.dart';
import '../dto/DoctorAppointmentDTO.dart';
import '../dto/DoctorDTO.dart';
import '../dto/DoctorPatientDTO.dart';
import 'ApiClient.dart';

class BookingResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  const BookingResult({required this.success, required this.message, this.data});
}

class AppointmentService {
  final Dio _dio = ApiClient.instance.dio;

  Future<BookingResult> bookAppointment({
    required int doctorProfileId,
    required DateTime scheduledAt,
    required String type,
    String? patientNotes,
  }) async {
    try {
      final response = await _dio.post(
        '/api/appointments',
        data: {
          'doctorProfileId': doctorProfileId,
          'scheduledAt': scheduledAt.toIso8601String().substring(0, 19),
          'type': type,
          if (patientNotes != null && patientNotes.isNotEmpty)
            'patientNotes': patientNotes,
        },
      );
      return BookingResult(
        success: true,
        message: 'Appointment booked successfully',
        data: response.data as Map<String, dynamic>?,
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map ? data['message'] as String? : null) ??
          data?.toString() ??
          'Failed to book appointment. Please try again.';
      return BookingResult(success: false, message: msg);
    } catch (e) {
      return BookingResult(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<List<AppointmentDTO>> getMyAppointments() async {
    final response = await _dio.get('/api/appointments/me');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => AppointmentDTO.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BookingResult> checkIn(int id) async {
    try {
      final response = await _dio.post('/api/appointments/$id/check-in');
      return BookingResult(
        success: true,
        message: 'Checked in',
        data: response.data as Map<String, dynamic>?,
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map ? data['message'] as String? : null) ??
          data?.toString() ??
          'Could not check in. Please try again.';
      return BookingResult(success: false, message: msg);
    } catch (e) {
      return BookingResult(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<BookingResult> acceptAppointment(int id) async {
    try {
      await _dio.post('/api/appointments/$id/accept');
      return const BookingResult(success: true, message: 'Appointment accepted');
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map ? data['message'] as String? : null) ??
          data?.toString() ??
          'Failed to accept appointment.';
      return BookingResult(success: false, message: msg);
    } catch (e) {
      return BookingResult(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<BookingResult> declineAppointment(int id) async {
    try {
      await _dio.post('/api/appointments/$id/decline');
      return const BookingResult(success: true, message: 'Appointment declined');
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map ? data['message'] as String? : null) ??
          data?.toString() ??
          'Failed to decline appointment.';
      return BookingResult(success: false, message: msg);
    } catch (e) {
      return BookingResult(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<List<DoctorAppointmentDTO>> getDoctorAppointments() async {
    final response = await _dio.get('/api/appointments/doctor/me');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => DoctorAppointmentDTO.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DoctorAppointmentDTO>> getPatientAppointments(int patientProfileId) async {
    final response =
        await _dio.get('/api/appointments/doctor/patients/$patientProfileId/appointments');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => DoctorAppointmentDTO.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DoctorPatientDTO>> getMyPatients() async {
    final response = await _dio.get('/api/appointments/doctor/patients');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => DoctorPatientDTO.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DoctorDTO>> fetchDoctors() async {
    final response = await _dio.get('/admin/fetchDoctors');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => DoctorDTO.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
