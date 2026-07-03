import 'package:dio/dio.dart';

import '../dto/RegisterRequestDTO.dart';
import 'ApiClient.dart';

class AuthResult {
  final bool success;
  final String? token;
  final String? fullName;
  final String? email;
  final String? role;
  final String message;

  const AuthResult({
    required this.success,
    this.token,
    this.fullName,
    this.email,
    this.role,
    required this.message,
  });
}


class AuthService {
  final Dio _dio = ApiClient.instance.dio;

  Future<AuthResult> signIn({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'emailOrPhone': emailOrPhone, 'password': password},
      );
      return AuthResult(
        success: true,
        token: response.data['token'],
        email: response.data['email'],
        fullName: response.data['fullName'],
        role: response.data['role'],
        message: 'Login successful',
      );
    } on DioException catch (e) {
      print('STATUS: ${e.response?.statusCode}');
      print('DATA: ${e.response?.data}');
      print('TYPE: ${e.type}');
      print('MESSAGE: ${e.message}');
      final msg = e.response?.data?['message'] ??
          'Login failed. Please try again.';
      return AuthResult(success: false, message: msg);
    } catch (e) {
      return AuthResult(success: false, message: 'Unexpected error: $e');
    }
  }

  Future<AuthResult> createAccount(RegisterRequestDTO dto) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: dto.toJson(),
      );
      return AuthResult(
        success: true,
        token: response.data['token'],
        email: response.data['email'],
        fullName: response.data['fullName'],
        role: response.data['role'],
        message: 'Account created successfully',
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Registration failed. Please try again.';
      return AuthResult(success: false, message: msg);
    } catch (e) {
      return AuthResult(success: false, message: 'Unexpected error: $e');
    }
  }


  //TODO: make this in the backend , is not done yet
  Future<AuthResult> recoverPassword({required String email}) async {
    try {
      await _dio.post(
        '/api/auth/forgot-password',
        data: {'email': email},
      );
      return AuthResult(success: true, message: 'Reset link sent to $email');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Could not send reset link.';
      return AuthResult(success: false, message: msg);
    } catch (e) {
      return AuthResult(success: false, message: 'Unexpected error: $e');
    }
  }
}
