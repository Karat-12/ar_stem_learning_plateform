import 'package:dio/dio.dart';

import '../config/api_constants.dart';
import 'api_exception.dart';

/// HTTP client using Dio for API communication
class ApiClient {
  late final Dio _dio;
  final Future<String?> Function()? _getTokenFn;

  ApiClient({Future<String?> Function()? getToken}) : _getTokenFn = getToken {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: Duration(seconds: ApiConstants.connectionTimeout),
        receiveTimeout: Duration(seconds: ApiConstants.receiveTimeout),
        sendTimeout: Duration(seconds: ApiConstants.sendTimeout),
        headers: {ApiConstants.contentTypeHeader: ApiConstants.applicationJson},
      ),
    );

    // Authorization interceptor (async)
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest:
            (RequestOptions options, RequestInterceptorHandler handler) async {
              options.headers[ApiConstants.contentTypeHeader] =
                  ApiConstants.applicationJson;

              // Add authorization header if token exists
              try {
                final token = await _getTokenFn?.call();
                if (token != null && token.isNotEmpty) {
                  options.headers[ApiConstants.authorizationHeader] =
                      'Bearer $token';
                }
              } catch (e) {
                // Token retrieval failed, continue without token
              }

              return handler.next(options);
            },
      ),
    );

    // Logging interceptor for debugging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugLog(
            'API Request',
            'Method: ${options.method}, URL: ${options.uri}',
          );
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugLog(
            'API Response',
            'Status: ${response.statusCode}, URL: ${response.requestOptions.uri}',
          );
          return handler.next(response);
        },
        onError: (error, handler) {
          debugLog(
            'API Error',
            'Status: ${error.response?.statusCode}, Message: ${error.message}',
          );
          return handler.next(error);
        },
      ),
    );
  }

  /// Performs a GET request
  Future<T> get<T>({
    required String path,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);

      if (fromJson != null) {
        return fromJson(response.data);
      }

      return response.data as T;
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ApiException(
        message: 'Unexpected error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Performs a POST request
  Future<T> post<T>({
    required String path,
    required dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      if (fromJson != null) {
        return fromJson(response.data);
      }

      return response.data as T;
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ApiException(
        message: 'Unexpected error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Performs a PUT request
  Future<T> put<T>({
    required String path,
    required dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      if (fromJson != null) {
        return fromJson(response.data);
      }

      return response.data as T;
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ApiException(
        message: 'Unexpected error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Performs a DELETE request
  Future<T> delete<T>({
    required String path,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        queryParameters: queryParameters,
      );

      if (fromJson != null) {
        return fromJson(response.data);
      }

      return response.data as T;
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ApiException(
        message: 'Unexpected error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Handles Dio exceptions and converts them to ApiException
  ApiException _handleDioException(DioException error) {
    String message;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        break;
      case DioExceptionType.sendTimeout:
        message = 'Send timeout. Please try again.';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Receive timeout. Please try again.';
        break;
      case DioExceptionType.badResponse:
        message = _extractErrorMessage(error.response?.data);
        break;
      case DioExceptionType.cancel:
        message = 'Request cancelled.';
        break;
      case DioExceptionType.unknown:
        message = 'Network error: ${error.message}';
        break;
      case DioExceptionType.badCertificate:
        message = 'SSL certificate error.';
        break;
      case DioExceptionType.connectionError:
        message = 'Connection error. Please check your internet connection.';
        break;
    }

    return ApiException(
      message: message,
      statusCode: error.response?.statusCode,
      originalError: error,
    );
  }

  /// Extracts error message from response data
  String _extractErrorMessage(dynamic responseData) {
    if (responseData is Map) {
      if (responseData.containsKey('message')) {
        return responseData['message'];
      }
      if (responseData.containsKey('error')) {
        return responseData['error'];
      }
    }
    return 'An error occurred. Please try again.';
  }

  /// Simple debug logging
  void debugLog(String title, String message) {
    if (true) {
      // Set to false in production
      // ignore: avoid_print
      print('[$title] $message');
    }
  }
}
