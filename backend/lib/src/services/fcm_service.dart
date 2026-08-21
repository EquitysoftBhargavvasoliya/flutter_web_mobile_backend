import 'dart:convert';
import 'dart:io';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class FcmService {
  static const _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
  
  // Send notification to multiple tokens
  Future<void> sendDiscountNotification(List<String> tokens) async {
    if (tokens.isEmpty) return;

    final file = File('service-account.json');
    if (!await file.exists()) {
      print('FCM Warning: service-account.json not found. Notifications will not be sent.');
      return;
    }

    try {
      final jsonKey = jsonDecode(await file.readAsString());
      final projectId = jsonKey['project_id'];
      
      final credentials = ServiceAccountCredentials.fromJson(jsonKey);
      final client = await clientViaServiceAccount(credentials, _scopes);

      for (var token in tokens) {
        await _sendToToken(client, projectId, token);
      }
      
      client.close();
      print('FCM: Sent notification to ${tokens.length} devices.');
    } catch (e) {
      print('FCM Error: Failed to send notifications - $e');
    }
  }

  Future<void> _sendToToken(AuthClient client, String projectId, String token) async {
    final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send');
    final payload = {
      'message': {
        'token': token,
        'notification': {
          'title': 'Sale Started!',
          'body': '50% off all products. Shop now!',
        }
      }
    };

    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      print('FCM Error for token $token: ${response.body}');
    }
  }
}
