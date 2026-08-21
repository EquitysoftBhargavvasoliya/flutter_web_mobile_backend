import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';

class Database {
  static late Pool _pool;

  static Future<void> initialize() async {
    final env = DotEnv(includePlatformEnvironment: true)..load(['../.env']);
    
    // Parse DATABASE_URL: postgres://orbit_admin:orbit_password@localhost:5432/orbit_db
    final dbUrl = env['DATABASE_URL'] ?? Platform.environment['DATABASE_URL'];
    
    if (dbUrl == null) {
      throw Exception('DATABASE_URL is not set in the environment.');
    }
    
    final uri = Uri.parse(dbUrl);

    // Uri.port returns 0 (not 5432) when the URL omits an explicit port,
    // which Render's Internal Database URL does — Dart only knows default
    // ports for schemes like http/https, not postgres/postgresql.
    final port = uri.hasPort ? uri.port : 5432;

    final endpoint = Endpoint(
      host: uri.host,
      port: port,
      database: uri.pathSegments.first,
      username: uri.userInfo.split(':').first,
      password: uri.userInfo.split(':').length > 1 ? uri.userInfo.split(':')[1] : null,
    );

    final sslMode = (env['DB_SSL_MODE'] ?? Platform.environment['DB_SSL_MODE']) == 'require'
        ? SslMode.require
        : SslMode.disable;

    _pool = Pool.withEndpoints([endpoint], settings: PoolSettings(
      maxConnectionCount: 10,
      sslMode: sslMode,
    ));
    
    print('Connected to PostgreSQL at ${endpoint.host}:${endpoint.port}');
  }

  static Pool get pool => _pool;
}
