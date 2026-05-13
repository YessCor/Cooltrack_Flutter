import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  String? _authToken;

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        if (kDebugMode) {
          print('API Request: ${options.method} ${options.uri}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          print('API Response: ${response.statusCode} ${response.requestOptions.uri}');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          print('API Error: ${error.message}');
        }
        handler.next(error);
      },
    ));
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  String? get authToken => _authToken;

  // Generic GET
  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? queryParams}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParams);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Generic POST
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Generic PUT
  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.put(path, data: data);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Generic PATCH
  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.patch(path, data: data);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Generic DELETE
  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Upload file (for photos, signatures)
  Future<Map<String, dynamic>> uploadFile(String path, String filePath, String fieldName) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post(path, data: formData);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Map<String, dynamic> _handleResponse(Response response) {
    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
      if (response.data is Map<String, dynamic>) {
        return response.data;
      }
      return {'data': response.data};
    }
    throw ApiException(
      response.data?['message'] ?? 'Error en la solicitud',
      statusCode: response.statusCode,
      data: response.data,
    );
  }

  ApiException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('Tiempo de conexión agotado', statusCode: 408);
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        String message = data?['message'] ?? data?['error'] ?? 'Error del servidor';
        return ApiException(message, statusCode: statusCode, data: data);
      case DioExceptionType.cancel:
        return ApiException('Solicitud cancelada');
      case DioExceptionType.connectionError:
        return ApiException('Sin conexión a internet');
      default:
        return ApiException(error.message ?? 'Error desconocido');
    }
  }
}