import 'package:dio/dio.dart';
import 'package:i_dhara/app/core/utils/snackbars/error_snackbar.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class NetworkManager {
  final _baseUrl = "https://dev-api-idhara.peepul.farm/v1.0";
  final Dio _dio;
  NetworkManager() : _dio = Dio() {
    _dio.options.baseUrl = _baseUrl;
    _dio.interceptors.add(PrettyDioLogger());
    _dio.interceptors.add(InterceptorsWrapper(
        onRequest: _onRequest, onError: _onError, onResponse: _onResponse));
  }
  void _onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = SharedPreference.getAccessToken();
    options.headers["Authorization"] = "Bearer $token";

    handler.next(options);
  }

  Future<Response<T>> get<T>(String path,
      {Map<String, dynamic>? queryParameters, int timeoutSeconds = 20}) async {
    try {
      final response = await _dio.get<T>(path,
          queryParameters: queryParameters,
          options: _getRequestOptions(timeoutSeconds));
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> post<T>(String path, Map<String, dynamic> queryParameters,
      {dynamic data, int timeoutSeconds = 20}) async {
    try {
      final response = await _dio.post<T>(path,
          queryParameters: queryParameters,
          data: data,
          options: _getRequestOptions(timeoutSeconds));
      return response;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Response<T>> put<T>(String path,
      {dynamic data, int timeoutSeconds = 10}) async {
    try {
      final response = await _dio.put<T>(path,
          data: data, options: _getRequestOptions(timeoutSeconds));
      return response;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Response<T>> patch<T>(String path,
      {dynamic data, int timeoutSeconds = 20}) async {
    try {
      final response = await _dio.patch<T>(path,
          data: data, options: _getRequestOptions(timeoutSeconds));
      return response;
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Response<T>> delete<T>(String path,
      {Map<String, dynamic>? queryParameters, int timeoutSeconds = 20}) async {
    try {
      final response = await _dio.delete<T>(path,
          queryParameters: queryParameters,
          options: _getRequestOptions(timeoutSeconds));
      return response;
    } catch (e) {
      return _handleError(e);
    }
  }

  Options _getRequestOptions(int timeoutSeconds) {
    return Options(
      receiveTimeout: Duration(milliseconds: timeoutSeconds * 1000),
      sendTimeout: Duration(milliseconds: timeoutSeconds * 1000),
    );
  }

  dynamic _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.receiveTimeout:
          geterrorSnackBar(errorsMap['timeout_error']);
          break;
        case DioExceptionType.connectionTimeout:
          throw UnimplementedError();
        case DioExceptionType.sendTimeout:
          throw UnimplementedError();
        case DioExceptionType.badCertificate:
          throw UnimplementedError();
        case DioExceptionType.badResponse:
          if (error.response != null) {
            final statusCode = error.response!.statusCode;
            final responseData = error.response!.data;
            switch (statusCode) {
              case 400:
                geterrorSnackBar(responseData['message']);
                return error.response;
              case 401:
                geterrorSnackBar(errorsMap["unauthorized_error"]);
                return error.response;
              case 404:
                geterrorSnackBar(responseData['message']);
                return error.response;
              case 403:
                geterrorSnackBar(errorsMap["bad_request_error"]);
                return error.response;
              case 409:
                geterrorSnackBar(responseData['message']);
                return error.response;
              case 422:
                return error.response;
              case 500:
                geterrorSnackBar("Internal Server Error");
                return error.response;
              case 555:
                geterrorSnackBar(errorsMap["internal_server_error"]);
                return error.response;
            }
          } else {
            throw NetworkException("No response from server.");
          }

          throw UnimplementedError();
        case DioExceptionType.cancel:
          throw UnimplementedError();
        case DioExceptionType.connectionError:
          throw UnimplementedError();
        case DioExceptionType.unknown:
          throw UnimplementedError();
      }
    }
    throw error;
  }

  void _onError(DioException e, ErrorInterceptorHandler handler) {
    handler.next(e);
  }

  void _onResponse(Response e, ResponseInterceptorHandler handler) {
    handler.next(e);
  }
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  @override
  String toString() {
    return 'NetworkException: $message';
  }
}

Map errorsMap = {
  "success": "success",
  "bad_request_error": "bad request. try again later",
  "no_content": "success with not content",
  "forbidden_error": "forbidden request. try again later",
  "unauthorized_error": "User unauthorized,please try again later",
  "not_found_error": "url not found, try again later",
  "conflict_error": "conflict found, try again later",
  "internal_server_error": "some thing went wrong, try again later",
  "unknown_error": "some thing went wrong, try again later",
  "timeout_error": "time out, try again later",
  "default_error": "some thing went wrong, try again later",
  "cache_error": "cache error, try again later",
  "no_internet_error": "Please check your internet connection"
};
