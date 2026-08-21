import 'dart:io';
import 'package:dotenv/dotenv.dart';

void main() {
  final env = DotEnv(includePlatformEnvironment: true)..load(['../.env']);
  print('DATABASE_URL from env: ${env['DATABASE_URL']}');
  print('Platform.environment[DATABASE_URL]: ${Platform.environment['DATABASE_URL']}');
}
