import 'package:get/get.dart';
import '../../core/network/api_client.dart';

class UserRepository {
  final ApiClient apiClient = Get.find<ApiClient>();

  Future<List<dynamic>> getUsers() async {
    final response = await apiClient.get('/users');
    if (response.isOk) {
      return response.body as List<dynamic>;
    }
    return [];
  }

  Future<bool> deleteUser(String id) async {
    final response = await apiClient.delete('/users/$id');
    if (!response.isOk) throw Exception(_extractError(response, 'Failed to delete user'));
    return response.isOk;
  }

  String _extractError(Response response, String fallback) {
    return response.body != null && response.body is Map && response.body['error'] != null
        ? response.body['error'].toString()
        : fallback;
  }
}
