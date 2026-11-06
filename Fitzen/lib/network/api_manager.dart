import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';

class ApiManager {
  static final ApiManager _instance = ApiManager._internal();

  factory ApiManager() => _instance;

  late final Dio dio;
  late final ApiClient client;

  ApiManager._internal() {
    dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),

        // Google Apps Script may return 302.
        followRedirects: false,
        maxRedirects: 0,

        contentType: 'text/plain',
        responseType: ResponseType.json,

        headers: {
          Headers.acceptHeader: Headers.jsonContentType,
          // 🚨 CHANGE THIS: Force plain text header
          Headers.contentTypeHeader: 'text/plain',
        },

        // IMPORTANT:
        // Allow 302 to reach our interceptor.
        validateStatus: (status) {
          return status != null && status >= 200 && status < 400;
        },

        receiveDataWhenStatusError: true,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(

        // ==========================================================
        // REQUEST
        // ==========================================================

        // ==========================================================
        // REQUEST
        // ==========================================================

        onRequest: (options, handler) {
          // 🚨 ADD THIS FIX:
          // Manually convert the data to a JSON string before sending it
          // so Apps Script can parse it correctly while keeping text/plain format.
          if (options.data is Map) {
            options.data = jsonEncode(options.data);
          }

          if (kDebugMode) {
            debugPrint('');
            debugPrint('========== FITZEN API REQUEST ==========');
            debugPrint('${options.method} ${options.uri}');
            debugPrint('PAYLOAD: ${options.data}'); // Added this so you can see it in logs!
            debugPrint('========================================');
          }

          handler.next(options);
        },

        // ==========================================================
        // RESPONSE
        // ==========================================================

        onResponse: (response, handler) async {
          if (kDebugMode) {
            debugPrint('');
            debugPrint('========== FITZEN API RESPONSE ==========');
            debugPrint('STATUS: ${response.statusCode}');
            debugPrint('URL: ${response.requestOptions.uri}');
            debugPrint('=========================================');
          }

          // ========================================================
          // GOOGLE APPS SCRIPT 302
          // ========================================================

          if (response.statusCode == 302) {
            final location =
            response.headers.value('location');

            if (kDebugMode) {
              debugPrint('');
              debugPrint('====== APPS SCRIPT 302 REDIRECT ======');
              debugPrint('LOCATION: $location');
              debugPrint('======================================');
            }

            if (location == null || location.isEmpty) {
              return handler.reject(
                DioException(
                  requestOptions: response.requestOptions,
                  response: response,
                  type: DioExceptionType.badResponse,
                  error:
                  'Apps Script returned 302 without Location header.',
                ),
              );
            }

            try {
              // Use a separate Dio instance for the redirected GET.
              // This prevents the 302 interceptor from triggering itself.
              final redirectDio = Dio(
                BaseOptions(
                  connectTimeout:
                  const Duration(seconds: 20),
                  receiveTimeout:
                  const Duration(seconds: 20),

                  followRedirects: true,
                  maxRedirects: 5,

                  responseType: ResponseType.json,

                  headers: {
                    Headers.acceptHeader:
                    Headers.jsonContentType,
                  },

                  validateStatus: (status) {
                    return status != null &&
                        status >= 200 &&
                        status < 400;
                  },
                ),
              );

              final redirectedResponse =
              await redirectDio.get(location);

              if (kDebugMode) {
                debugPrint('');
                debugPrint('====== REDIRECT RESPONSE ======');
                debugPrint(
                  'STATUS: ${redirectedResponse.statusCode}',
                );
                debugPrint(
                  'DATA: ${redirectedResponse.data}',
                );
                debugPrint('================================');
              }

              // Sometimes Apps Script returns JSON as String.
              if (redirectedResponse.data is String) {
                final raw =
                redirectedResponse.data as String;

                if (raw.trim().isNotEmpty) {
                  try {
                    redirectedResponse.data =
                        jsonDecode(raw);
                  } catch (_) {
                    // Keep original response.
                  }
                }
              }

              // Give final response back to Retrofit.
              return handler.resolve(
                redirectedResponse,
              );
            } catch (e) {
              if (kDebugMode) {
                debugPrint('');
                debugPrint('====== REDIRECT FAILED ======');
                debugPrint('$e');
                debugPrint('==============================');
              }

              return handler.reject(
                DioException(
                  requestOptions:
                  response.requestOptions,
                  response: response,
                  type: DioExceptionType.badResponse,
                  error:
                  'Failed to read Apps Script redirect: $e',
                ),
              );
            }
          }

          // ========================================================
          // NORMAL RESPONSE
          // ========================================================

          if (response.data is String) {
            final raw = response.data as String;

            if (raw.trim().isNotEmpty) {
              try {
                response.data = jsonDecode(raw);
              } catch (_) {
                // Keep original response.
              }
            }
          }

          handler.next(response);
        },

        // ==========================================================
        // ERROR
        // ==========================================================

        onError: (error, handler) {
          if (kDebugMode) {
            debugPrint('');
            debugPrint('========== FITZEN API ERROR ==========');
            debugPrint('TYPE: ${error.type}');
            debugPrint('MESSAGE: ${error.message}');
            debugPrint(
              'STATUS: ${error.response?.statusCode}',
            );
            debugPrint(
              'URL: ${error.requestOptions.uri}',
            );
            debugPrint('======================================');
          }

          handler.next(error);
        },
      ),
    );

    // Retrofit client
    client = ApiClient(dio);
  }
}