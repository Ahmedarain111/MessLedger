import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../storage/local_storage.dart';
import 'api_exception.dart';

/// Reusable HTTP client. The UI never calls this directly; services do.
/// When the Django backend is ready, the mock services are swapped for
/// services built on this client.
class ApiClient {
  ApiClient({Dio? dio, LocalStorage? storage})
      : _dio = dio ?? Dio(),
        _storage = storage ?? LocalStorage() {
    _dio.options = BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: AppConstants.requestTimeoutSeconds),
      receiveTimeout: const Duration(seconds: AppConstants.requestTimeoutSeconds),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    );
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
      final token = await _storage.readToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    }));
  }

  final Dio _dio;
  final LocalStorage _storage;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _execute(() => _dio.get(path, queryParameters: query));

  Future<dynamic> post(String path, {dynamic data}) => _execute(() => _dio.post(path, data: data));

  Future<dynamic> put(String path, {dynamic data}) => _execute(() => _dio.put(path, data: data));

  Future<dynamic> patch(String path, {dynamic data}) => _execute(() => _dio.patch(path, data: data));

  Future<dynamic> delete(String path, {dynamic data}) => _execute(() => _dio.delete(path, data: data));

  Future<dynamic> _execute(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      return response.data;
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data['detail'] ?? e.message).toString()
          : e.message ?? 'Network error';
      throw ApiException(msg, statusCode: e.response?.statusCode);
    }
  }
}
