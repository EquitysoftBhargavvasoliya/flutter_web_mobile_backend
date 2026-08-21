import 'package:dio/dio.dart';

/// Pulls the backend's own {"error": "..."} message out of a failed
/// response so exceptions show the real reason instead of a generic string.
String? _backendError(Response? response) {
  final data = response?.data;
  if (data is Map && data['error'] != null) return data['error'].toString();
  return null;
}

class ConnectionTimeOutException extends DioException {
  ConnectionTimeOutException(RequestOptions r) : super(requestOptions: r);
  @override
  String toString() => 'Connection timed out. Please try again.';
}

class SendTimeOutException extends DioException {
  SendTimeOutException(RequestOptions r) : super(requestOptions: r);
  @override
  String toString() => 'Sending request timed out. Please try again.';
}

class ReceiveTimeOutException extends DioException {
  ReceiveTimeOutException(RequestOptions r) : super(requestOptions: r);
  @override
  String toString() => 'Server took too long to respond. Please try again.';
}

class NoInternetConnectionException extends DioException {
  NoInternetConnectionException(RequestOptions r) : super(requestOptions: r);
  @override
  String toString() => 'No internet connection. Please check your network.';
}

class CancelledRequestException extends DioException {
  CancelledRequestException(RequestOptions r) : super(requestOptions: r);
  @override
  String toString() => 'Request was cancelled.';
}

class BadRequestException extends DioException {
  BadRequestException(RequestOptions r, {super.response})
      : super(requestOptions: r, type: DioExceptionType.badResponse);
  @override
  String toString() => _backendError(response) ?? 'Invalid request.';
}

class UnauthorizedException extends DioException {
  UnauthorizedException(RequestOptions r, {super.response})
      : super(requestOptions: r, type: DioExceptionType.badResponse);
  @override
  String toString() => _backendError(response) ?? 'Invalid credentials or session expired.';
}

class NotFoundException extends DioException {
  NotFoundException(RequestOptions r, {super.response})
      : super(requestOptions: r, type: DioExceptionType.badResponse);
  @override
  String toString() => _backendError(response) ?? 'Requested resource was not found.';
}

class ConflictException extends DioException {
  ConflictException(RequestOptions r, {super.response})
      : super(requestOptions: r, type: DioExceptionType.badResponse);
  @override
  String toString() => _backendError(response) ?? 'This already exists.';
}

class InternalServerErrorException extends DioException {
  InternalServerErrorException(RequestOptions r, {super.response})
      : super(requestOptions: r, type: DioExceptionType.badResponse);
  @override
  String toString() => _backendError(response) ?? 'Something went wrong on the server. Please try again later.';
}

class UnknownException extends DioException {
  UnknownException(RequestOptions r, {super.response})
      : super(requestOptions: r);
  @override
  String toString() => _backendError(response) ?? 'Something went wrong. Please try again.';
}
