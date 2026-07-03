import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single shared Dio instance for the whole app.
///
/// To point the app at a different server (e.g. a new LAN IP, a deployed
/// backend, etc.), change [_lanHost] here — every service shares this client.
class ApiClient {
  ApiClient._internal()
      : dio = Dio(
          BaseOptions(
            baseUrl: _resolveBaseUrl(),
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final isAuthEndpoint = options.path.contains('/login') ||
              options.path.contains('/register');
          if (!isAuthEndpoint) {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('jwt_token');
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();

  final Dio dio;

  // Flip this single flag when switching between testing on an emulator/simulator
  // and testing on a physical device. Everything else resolves automatically.
  static const bool _useEmulator = false;

  // Physical device on the same WiFi as the dev machine running the backend.
  // Update this if your PC's LAN IP changes.
  static const String _lanHost = 'http://192.168.0.67:8080';

  static String _resolveBaseUrl() {
    if (kIsWeb) return 'http://localhost:8080';

    if (_useEmulator) {
      // 10.0.2.2 is a special alias the Android emulator uses to reach the
      // host machine's localhost. iOS simulators share the host's network,
      // so plain localhost works there.
      // return defaultTargetPlatform == TargetPlatform.android
      //     ? 'http://10.0.2.2:8080'
      //     : 'http://localhost:8080';

      return defaultTargetPlatform == TargetPlatform.android
          ? 'http://10.0.2.2:8080'
          : 'http://localhost:8080';
    }

    return _lanHost;
  }
}
