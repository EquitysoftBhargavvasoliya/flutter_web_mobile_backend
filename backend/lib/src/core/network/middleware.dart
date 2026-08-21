import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dotenv/dotenv.dart';

class ApiMiddleware {
  static Middleware corsMiddleware() {
    return (innerHandler) {
      return (request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok(
            '',
            headers: {
              'Access-Control-Allow-Origin': '*',
              'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
              'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
            },
          );
        }

        final response = await innerHandler(request);
        return response.change(headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
        });
      };
    };
  }

  static String get _jwtSecret {
    final env = DotEnv(includePlatformEnvironment: true)..load(['../.env']);
    return env['JWT_SECRET'] ?? 'orbit_super_secret_key';
  }

  static Middleware handleErrors() {
    return (innerHandler) {
      return (request) async {
        try {
          return await innerHandler(request);
        } catch (error) {
          print('Error processing request: \$error');
          return Response.internalServerError(
            body: jsonEncode({'error': error.toString()}),
            headers: {'content-type': 'application/json'},
          );
        }
      };
    };
  }

  static Middleware authMiddleware() {
    return (innerHandler) {
      return (request) async {
        final authHeader = request.headers['authorization'];
        if (authHeader == null || !authHeader.startsWith('Bearer ')) {
          return Response.forbidden(jsonEncode({'error': 'Missing or invalid token'}), headers: {'content-type': 'application/json'});
        }

        final token = authHeader.substring(7);
        try {
          final jwt = JWT.verify(token, SecretKey(_jwtSecret));
          final updatedRequest = request.change(context: {'user': jwt.payload});
          return await innerHandler(updatedRequest);
        } catch (e) {
          return Response.forbidden(jsonEncode({'error': 'Invalid token'}), headers: {'content-type': 'application/json'});
        }
      };
    };
  }

  static String generateToken(Map<String, dynamic> payload) {
    final jwt = JWT(payload);
    return jwt.sign(SecretKey(_jwtSecret), expiresIn: Duration(days: 7));
  }
}
