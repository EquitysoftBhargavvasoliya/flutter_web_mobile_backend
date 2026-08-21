import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiClient extends GetConnect {
  final storage = const FlutterSecureStorage();

  @override
  void onInit() {
    httpClient.baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080/api/v1';
    
    httpClient.addRequestModifier<dynamic>((request) async {
      final token = await storage.read(key: 'jwt_token');
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      return request;
    });

    httpClient.addResponseModifier((request, response) {
      if (response.status.hasError) {
        if (response.statusCode == 401) {
          // Token expired or invalid, trigger logout
          Get.offAllNamed('/login');
          Get.snackbar('Session Expired', 'Please login again.');
        } else if (response.statusCode == 500) {
          Get.snackbar('Server Error', 'An unexpected error occurred on the server.');
        }
      }
      return response;
    });
    
    super.onInit();
  }

  Future<Response<T>> _runWithLogging<T>(
    String method,
    String url, {
    dynamic body,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    required Future<Response<T>> Function() requestFn,
  }) async {
    final fullUrl = httpClient.createUri(url, query).toString();

    print('╔══[API REQUEST]════════════════════════════════════════');
    print('║ Method: ${method.toUpperCase()}');
    print('║ URL: $fullUrl');
    if (query != null && query.isNotEmpty) {
      print('║ Query: $query');
    }
    if (headers != null && headers.isNotEmpty) {
      print('║ Headers (initial): $headers');
    }
    if (body != null) {
      print('║ Request Body: $body');
    }
    print('╚═══════════════════════════════════════════════════════');

    try {
      final response = await requestFn();
      
      print('╔══[API RESPONSE]═══════════════════════════════════════');
      print('║ URL: $fullUrl');
      print('║ Status Code: ${response.statusCode}');
      if (response.request?.headers != null && response.request!.headers.isNotEmpty) {
        print('║ Actual Headers: ${response.request!.headers}');
      }
      print('║ Response Body: ${response.bodyString ?? response.body}');
      print('╚═══════════════════════════════════════════════════════');
      
      return response;
    } catch (e) {
      print('╔══[API ERROR]══════════════════════════════════════════');
      print('║ URL: $fullUrl');
      print('║ Error: $e');
      print('╚═══════════════════════════════════════════════════════');
      rethrow;
    }
  }

  @override
  Future<Response<T>> get<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  }) {
    return _runWithLogging<T>(
      'get',
      url,
      headers: headers,
      query: query,
      requestFn: () => super.get<T>(
        url,
        headers: headers,
        contentType: contentType,
        query: query,
        decoder: decoder,
      ),
    );
  }

  @override
  Future<Response<T>> post<T>(
    String? url,
    dynamic body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) {
    return _runWithLogging<T>(
      'post',
      url ?? '',
      body: body,
      headers: headers,
      query: query,
      requestFn: () => super.post<T>(
        url,
        body,
        contentType: contentType,
        headers: headers,
        query: query,
        decoder: decoder,
        uploadProgress: uploadProgress,
      ),
    );
  }

  @override
  Future<Response<T>> put<T>(
    String url,
    dynamic body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) {
    return _runWithLogging<T>(
      'put',
      url,
      body: body,
      headers: headers,
      query: query,
      requestFn: () => super.put<T>(
        url,
        body,
        contentType: contentType,
        headers: headers,
        query: query,
        decoder: decoder,
        uploadProgress: uploadProgress,
      ),
    );
  }

  @override
  Future<Response<T>> patch<T>(
    String url,
    dynamic body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) {
    return _runWithLogging<T>(
      'patch',
      url,
      body: body,
      headers: headers,
      query: query,
      requestFn: () => super.patch<T>(
        url,
        body,
        contentType: contentType,
        headers: headers,
        query: query,
        decoder: decoder,
        uploadProgress: uploadProgress,
      ),
    );
  }

  @override
  Future<Response<T>> delete<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  }) {
    return _runWithLogging<T>(
      'delete',
      url,
      headers: headers,
      query: query,
      requestFn: () => super.delete<T>(
        url,
        headers: headers,
        contentType: contentType,
        query: query,
        decoder: decoder,
      ),
    );
  }

  @override
  Future<Response<T>> request<T>(
    String url,
    String method, {
    dynamic body,
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) {
    return _runWithLogging<T>(
      method,
      url,
      body: body,
      headers: headers,
      query: query,
      requestFn: () => super.request<T>(
        url,
        method,
        body: body,
        contentType: contentType,
        headers: headers,
        query: query,
        decoder: decoder,
        uploadProgress: uploadProgress,
      ),
    );
  }
}
