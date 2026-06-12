import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';

const String _baseUrl = 'https://neovlm.neophyte.live/rel-icr-api';

/// Low-level HTTP client mirroring OkHttp with:
/// - Unlimited timeouts (connectTimeout=0 in Kotlin)
/// - Up to 3 retry attempts on 502/503/504
/// - SSE (server-sent events) streaming support
class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(minutes: 10),
      receiveTimeout: const Duration(minutes: 30),
      sendTimeout: const Duration(minutes: 10),
    ));
  }

  /// POST multipart - returns response data as Map
  Future<Map<String, dynamic>> postMultipart(
    String path,
    FormData formData, {
    int maxAttempts = 3,
  }) async {
    int attempt = 0;
    while (attempt < maxAttempts) {
      attempt++;
      try {
        final response = await _dio.post<Map<String, dynamic>>(path, data: formData);
        if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
          return response.data ?? {};
        }
        if ([502, 503, 504].contains(response.statusCode) && attempt < maxAttempts) {
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'HTTP ${response.statusCode}',
        );
      } on DioException catch (e) {
        if (attempt >= maxAttempts) rethrow;
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    throw Exception('Failed after $maxAttempts attempts');
  }

  /// POST JSON body - returns response data as Map
  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: body,
      options: Options(contentType: 'application/json'),
    );
    return response.data ?? {};
  }

  /// POST multipart with SSE streaming response.
  /// Each yielded event is a parsed JSON map from a `data:` line.
  Stream<Map<String, dynamic>> postMultipartStream(
    String path,
    FormData formData, {
    int maxAttempts = 3,
  }) async* {
    int attempt = 0;
    while (attempt < maxAttempts) {
      attempt++;
      try {
        final response = await _dio.post<ResponseBody>(
          path,
          data: formData,
          options: Options(
            responseType: ResponseType.stream,
            headers: {'Accept': 'text/event-stream'},
          ),
        );

        final stream = response.data!.stream;
        final buffer = StringBuffer();

        await for (final chunk in stream) {
          buffer.write(utf8.decode(chunk));
          final text = buffer.toString();
          final lines = text.split('\n');

          // Keep incomplete last line in buffer
          buffer.clear();
          buffer.write(lines.last);

          for (int i = 0; i < lines.length - 1; i++) {
            final line = lines[i].trim();
            if (line.startsWith('data:')) {
              final data = line.substring(5).trim();
              if (data.isEmpty) continue;
              try {
                final json = jsonDecode(data) as Map<String, dynamic>;
                yield json;
              } catch (_) {
                // skip malformed SSE lines
              }
            }
          }
        }
        return; // success
      } on DioException catch (_) {
        if (attempt >= maxAttempts) rethrow;
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }
}
