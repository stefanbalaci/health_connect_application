import 'package:dio/dio.dart';

import '../dto/DayOffDTO.dart';
import 'ApiClient.dart';

class AvailabilityService {
  final Dio _dio = ApiClient.instance.dio;

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<List<DayOffDTO>> getDaysOff() async {
    final response = await _dio.get('/api/me/availability');
    final list = response.data as List<dynamic>;
    return list.map((e) => DayOffDTO.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Marks a day off; returns the refreshed list.
  Future<List<DayOffDTO>> addDayOff({required DateTime date, String? reason}) async {
    final response = await _dio.post('/api/me/availability', data: {
      'date': _ymd(date),
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
    final list = response.data as List<dynamic>;
    return list.map((e) => DayOffDTO.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Removes a day off; returns the refreshed list.
  Future<List<DayOffDTO>> removeDayOff(DateTime date) async {
    final response = await _dio.delete('/api/me/availability/${_ymd(date)}');
    final list = response.data as List<dynamic>;
    return list.map((e) => DayOffDTO.fromJson(e as Map<String, dynamic>)).toList();
  }
}
