import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../dto/ReportDTO.dart';
import 'ApiClient.dart';

class ReportResult {
  final bool success;
  final String message;
  final ReportDTO? report;

  const ReportResult({required this.success, required this.message, this.report});
}

class ReportService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<ReportDTO>> getPatientReports(int patientProfileId) async {
    final response = await _dio.get('/api/reports/patient/$patientProfileId');
    final list = response.data as List<dynamic>;
    return list.map((e) => ReportDTO.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ReportDTO>> getMyReports() async {
    final response = await _dio.get('/api/reports/me');
    final list = response.data as List<dynamic>;
    return list.map((e) => ReportDTO.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Downloads a report's file bytes from the authenticated endpoint
  /// (JWT is attached by the ApiClient interceptor).
  Future<Uint8List> fetchReportFile(int reportId) async {
    final response = await _dio.get<List<int>>(
      '/api/reports/$reportId/file',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? const []);
  }

  Future<ReportResult> addReport({
    required int patientProfileId,
    required String title,
    required String type,
    required DateTime reportDate,
    String? notes,
    String? filePath,
  }) async {
    try {
      final data = {
        'patientProfileId': patientProfileId,
        'title': title,
        'type': type,
        'reportDate': reportDate.toIso8601String().substring(0, 10),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final formData = FormData.fromMap({
        'data': MultipartFile.fromString(
          jsonEncode(data),
          contentType: MediaType('application', 'json'),
        ),
        if (filePath != null)
          'file': await MultipartFile.fromFile(
            filePath,
            filename: filePath.split(Platform.pathSeparator).last,
            contentType: _mediaTypeForPath(filePath),
          ),
      });

      final response = await _dio.post('/api/reports', data: formData);
      return ReportResult(
        success: true,
        message: 'Report added',
        report: ReportDTO.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map ? data['message'] as String? : null) ??
          data?.toString() ??
          'Failed to add report.';
      return ReportResult(success: false, message: msg);
    } catch (e) {
      return ReportResult(success: false, message: 'Unexpected error: $e');
    }
  }

  /// Patient self-upload — no patientProfileId; the server attributes it to
  /// the signed-in patient with no doctor. Backed by POST /api/reports/me.
  Future<ReportResult> addMyReport({
    required String title,
    required String type,
    required DateTime reportDate,
    String? notes,
    String? filePath,
  }) async {
    try {
      final data = {
        'title': title,
        'type': type,
        'reportDate': reportDate.toIso8601String().substring(0, 10),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final formData = FormData.fromMap({
        'data': MultipartFile.fromString(
          jsonEncode(data),
          contentType: MediaType('application', 'json'),
        ),
        if (filePath != null)
          'file': await MultipartFile.fromFile(
            filePath,
            filename: filePath.split(Platform.pathSeparator).last,
            contentType: _mediaTypeForPath(filePath),
          ),
      });

      final response = await _dio.post('/api/reports/me', data: formData);
      return ReportResult(
        success: true,
        message: 'Report added',
        report: ReportDTO.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map ? data['message'] as String? : null) ??
          data?.toString() ??
          'Failed to add report.';
      return ReportResult(success: false, message: msg);
    } catch (e) {
      return ReportResult(success: false, message: 'Unexpected error: $e');
    }
  }

  static MediaType _mediaTypeForPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      default:
        return MediaType('application', 'octet-stream');
    }
  }
}
