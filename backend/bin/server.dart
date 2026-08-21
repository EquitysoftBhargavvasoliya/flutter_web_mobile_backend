import 'dart:convert';
import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:backend/src/core/network/database.dart';
import 'package:backend/src/core/network/middleware.dart';
import 'package:backend/src/presentation/controllers/api_controller.dart';
import 'package:dotenv/dotenv.dart';

void main(List<String> args) async {
  // 1. Load env and init Database
  final env = DotEnv(includePlatformEnvironment: true)..load(['../.env']);
  try {
    await Database.initialize();
  } catch (e) {
    print('Failed to connect to database: \$e');
  }

  // 2. Setup Router
  final app = Router();

  // Health checks — unauthenticated, used by the hosting platform to verify
  // the process is alive (/health) and can reach Postgres (/health/db).
  final appEnv = env['APP_ENV'] ?? Platform.environment['APP_ENV'] ?? 'development';
  app.get('/health', (Request req) {
    return Response.ok(jsonEncode({'status': 'ok', 'env': appEnv}), headers: {'content-type': 'application/json'});
  });
  app.get('/health/db', (Request req) async {
    try {
      await Database.pool.execute(Sql('SELECT 1'));
      return Response.ok(jsonEncode({'status': 'ok'}), headers: {'content-type': 'application/json'});
    } catch (_) {
      return Response.internalServerError(
        body: jsonEncode({'status': 'error'}),
        headers: {'content-type': 'application/json'},
      );
    }
  });

  app.mount('/api/v1', ApiController().router.call);

  // 3. Setup Pipeline with Middleware
  final handler = Pipeline()
      .addMiddleware(ApiMiddleware.corsMiddleware())
      .addMiddleware(logRequests())
      .addMiddleware(ApiMiddleware.handleErrors())
      .addHandler(app.call);

  // 4. Start Server
  final port = int.parse(env['PORT'] ?? Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, InternetAddress.anyIPv4, port);
  print('Server listening on port ${server.port}');

  // 5. Initialize Cron Jobs
  // Cron temporarily disabled — uncomment to re-enable.
  // final cron = Cron();
  // final fcmService = FcmService();
  // final repo = BackendRepository();
  //
  // cron.schedule(Schedule.parse('*/2 * * * *'), () async {
  //   print('Cron triggered: Sending 50% off discount notification to all users.');
  //   try {
  //     final tokens = await repo.getAllFcmTokens();
  //     if (tokens.isNotEmpty) {
  //       await fcmService.sendDiscountNotification(tokens);
  //     } else {
  //       print('Cron Info: No FCM tokens found in the database.');
  //     }
  //   } catch (e) {
  //     print('Cron Error: \$e');
  //   }
  // });
}
