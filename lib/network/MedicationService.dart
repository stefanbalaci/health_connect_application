import 'package:dio/dio.dart';

import '../dto/MedicationDTO.dart';
import '../dto/MedicationScheduleDTO.dart';
import '../dto/TodayMedicationDTO.dart';
import 'ApiClient.dart';

class ScheduleResult {
  final bool success;
  final String message;
  final List<MedicationScheduleDTO> schedule;

  const ScheduleResult({
    required this.success,
    required this.message,
    this.schedule = const [],
  });
}

class MedicationService {
  final Dio _dio = ApiClient.instance.dio;

  /// Medications the signed-in patient should take today (active prescriptions
  /// whose course still covers the current date). Backed by GET /api/medications/me.
  Future<List<MedicationDTO>> getMyMedicationsDueToday() async {
    final response = await _dio.get('/api/medications/me');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => MedicationDTO.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Today's dose schedule with taken-state and adherence tally.
  Future<TodayMedicationsDTO> getToday() async {
    final response = await _dio.get('/api/medications/today');
    return TodayMedicationsDTO.fromJson(response.data as Map<String, dynamic>);
  }

  /// Marks a dose taken; returns the refreshed today view.
  Future<TodayMedicationsDTO> takeDose({required int itemId, String? time}) async {
    final response = await _dio.post('/api/medications/take', data: {
      'itemId': itemId,
      if (time != null) 'time': time,
    });
    return TodayMedicationsDTO.fromJson(response.data as Map<String, dynamic>);
  }

  /// Un-marks a dose; returns the refreshed today view.
  Future<TodayMedicationsDTO> untakeDose({required int itemId, String? time}) async {
    final response = await _dio.post('/api/medications/untake', data: {
      'itemId': itemId,
      if (time != null) 'time': time,
    });
    return TodayMedicationsDTO.fromJson(response.data as Map<String, dynamic>);
  }

  /// The patient's medication schedule (doctor-pinned + patient-set times).
  Future<List<MedicationScheduleDTO>> getSchedule() async {
    final response = await _dio.get('/api/medications/schedule');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => MedicationScheduleDTO.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Saves the patient's chosen dose times ("HH:mm") for one medication.
  Future<ScheduleResult> saveSchedule({
    required int itemId,
    required List<String> times,
  }) async {
    try {
      final response = await _dio.put(
        '/api/medications/$itemId/schedule',
        data: {'times': times},
      );
      final list = response.data as List<dynamic>;
      return ScheduleResult(
        success: true,
        message: 'Schedule saved',
        schedule: list
            .map((e) => MedicationScheduleDTO.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map ? data['message'] as String? : null) ??
          data?.toString() ??
          'Could not save schedule.';
      return ScheduleResult(success: false, message: msg);
    } catch (e) {
      return ScheduleResult(success: false, message: 'Unexpected error: $e');
    }
  }
}
