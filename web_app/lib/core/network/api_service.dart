import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart' hide Response;

import 'logger.dart';
import 'api_exceptions.dart';

final _ApiService apiService = _ApiService();

class _ApiService {
  static final _ApiService _instance = _ApiService._internal();

  factory _ApiService() => _instance;

  _ApiService._internal();

  static Dio dio = _createDio();

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080/api/v1',
        connectTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        contentType: 'application/json',
      ),
    );
    dio.interceptors.add(ApiInterceptor());
    return dio;
  }

  Future<Response> post(String url, Map<String, dynamic> body) async {
    return dio.post(url, data: body);
  }

  Future<Response> put(String url, Map<String, dynamic> body) async {
    return dio.put(url, data: body);
  }

  Future<Response> delete(String url) async {
    return dio.delete(url);
  }

  Future<Response> get(String url, {Map<String, dynamic>? query}) async {
    return dio.get(url, queryParameters: query);
  }
}

class ApiInterceptor extends Interceptor {
  static const _storage = FlutterSecureStorage();

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    logger.i('\n${options.method} ${options.uri}\nBody: ${options.data}');
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    DioException e = err;
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        e = ConnectionTimeOutException(err.requestOptions);
        break;
      case DioExceptionType.sendTimeout:
        e = SendTimeOutException(err.requestOptions);
        break;
      case DioExceptionType.receiveTimeout:
        e = ReceiveTimeOutException(err.requestOptions);
        break;
      case DioExceptionType.connectionError:
        e = NoInternetConnectionException(err.requestOptions);
        break;
      case DioExceptionType.cancel:
        e = CancelledRequestException(err.requestOptions);
        break;
      case DioExceptionType.badResponse:
        switch (err.response?.statusCode) {
          case 400:
            e = BadRequestException(err.requestOptions, response: err.response);
            break;
          case 401:
            e = UnauthorizedException(err.requestOptions, response: err.response);
            _forceLogout();
            break;
          case 403:
            // This backend also uses 403 for ordinary authorization denials
            // (e.g. "Buyers are not allowed to sell products", failed
            // logins, invalid OTP) not just expired sessions, so it must
            // NOT force a logout here the way 401 does.
            e = UnauthorizedException(err.requestOptions, response: err.response);
            break;
          case 404:
            e = NotFoundException(err.requestOptions, response: err.response);
            break;
          case 409:
            e = ConflictException(err.requestOptions, response: err.response);
            break;
          case 500:
            e = InternalServerErrorException(err.requestOptions, response: err.response);
            break;
          default:
            e = UnknownException(err.requestOptions, response: err.response);
        }
        break;
      default:
        e = UnknownException(err.requestOptions, response: err.response);
    }
    logger.e('${err.requestOptions.method} ${err.requestOptions.uri}\nAPI Error: $e');
    return handler.next(e);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logger.d(
      '${response.requestOptions.method} ${response.requestOptions.uri}\n'
      'Response: ${response.data}',
    );
    return handler.next(response);
  }

  Future<void> _forceLogout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_role');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'user_name');
    Get.offAllNamed('/login');
    Get.snackbar('Session Expired', 'Please login again.');
  }
}
