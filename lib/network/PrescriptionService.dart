import 'package:dio/dio.dart';

import '../dto/PrescriptionDTO.dart';
import 'ApiClient.dart';

class PrescriptionResult {
  final bool success;
  final String message;
  final PrescriptionDTO? prescription;

  const PrescriptionResult({required this.success, required this.message, this.prescription});
}

class PrescriptionService {
  final Dio _dio = ApiClient.instance.dio;

  Future<PrescriptionDTO?> getPrescription(int appointmentId) async {
    try {
      final response = await _dio.get('/api/appointments/$appointmentId/prescription');
      return PrescriptionDTO.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<PrescriptionResult> savePrescription({
    required int appointmentId,
    String? notes,
    required List<PrescriptionItemDTO> items,
  }) async {
    try {
      final response = await _dio.post(
        '/api/appointments/$appointmentId/prescription',
        data: {
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          'items': items.map((i) => i.toJson()).toList(),
        },
      );
      return PrescriptionResult(
        success: true,
        message: 'Prescription saved',
        prescription: PrescriptionDTO.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map ? data['message'] as String? : null) ??
          data?.toString() ??
          'Failed to save prescription.';
      return PrescriptionResult(success: false, message: msg);
    } catch (e) {
      return PrescriptionResult(success: false, message: 'Unexpected error: $e');
    }
  }
}
