import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dotenv/dotenv.dart';

class ApiMiddleware {
  /// CORS_ORIGINS is a comma-separated allow-list, e.g.
  /// "https://example.com,https://admin.example.com". When unset (local dev),
  /// any http://localhost:*  or http://127.0.0.1:* origin is allowed instead
  /// of falling back to a wildcard.
  static List<String>? get _configuredOrigins {
    final env = DotEnv(includePlatformEnvironment: true)..load(['../.env']);
    final raw = env['CORS_ORIGINS'] ?? Platform.environment['CORS_ORIGINS'];
    if (raw == null || raw.trim().isEmpty) return null;
    return raw.split(',').map((o) => o.trim()).where((o) => o.isNotEmpty).toList();
  }

  static bool _isLocalhostOrigin(String origin) {
    final uri = Uri.tryParse(origin);
    return uri != null && (uri.host == 'localhost' || uri.host == '127.0.0.1');
  }

  /// Supports exact origins ("https://example.com") and wildcard suffix
  /// patterns ("*.vercel.app") in CORS_ORIGINS, since Vercel assigns a new
  /// random preview URL on every deploy that a fixed allow-list can't track.
  static bool _matchesPattern(String origin, String pattern) {
    if (!pattern.startsWith('*.')) return origin == pattern;
    final host = Uri.tryParse(origin)?.host;
    if (host == null) return false;
    final suffix = pattern.substring(1); // ".vercel.app"
    return host.endsWith(suffix);
  }

  static String? _allowedOriginFor(String? requestOrigin) {
    if (requestOrigin == null) return null;
    final configured = _configuredOrigins;
    if (configured != null) {
      return configured.any((p) => _matchesPattern(requestOrigin, p)) ? requestOrigin : null;
    }
    return _isLocalhostOrigin(requestOrigin) ? requestOrigin : null;
  }

  static Middleware corsMiddleware() {
    return (innerHandler) {
      return (request) async {
        final allowOrigin = _allowedOriginFor(request.headers['origin']);
        final corsHeaders = {
          if (allowOrigin != null) 'Access-Control-Allow-Origin': allowOrigin,
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
          'Vary': 'Origin',
        };

        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: corsHeaders);
        }

        final response = await innerHandler(request);
        return response.change(headers: corsHeaders);
      };
    };
  }

  static String get _jwtSecret {
    final env = DotEnv(includePlatformEnvironment: true)..load(['../.env']);
    return env['JWT_SECRET'] ?? Platform.environment['JWT_SECRET'] ?? 'orbit_super_secret_key';
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
