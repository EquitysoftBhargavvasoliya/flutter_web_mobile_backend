import 'dart:io';
import 'package:cron/cron.dart';
import 'package:backend/src/services/fcm_service.dart';
import 'package:backend/src/data/repositories/repository.dart';
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
  app.mount('/api/v1', ApiController().router.call);

  // 3. Setup Pipeline with Middleware
  final handler = Pipeline()
      .addMiddleware(ApiMiddleware.corsMiddleware())
      .addMiddleware(logRequests())
      .addMiddleware(ApiMiddleware.handleErrors())
      .addHandler(app.call);

  // 4. Start Server
  final port = int.parse(env['PORT'] ?? '8080');
  final server = await serve(handler, InternetAddress.anyIPv4, port);
  print('Server listening on port \${server.port}');

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
