import 'package:api_client/api_client.dart';

class UserRepository {
  Future<List<dynamic>> getUsers() async {
    try {
      final response = await apiService.get('/users');
      return response.data as List<dynamic>;
    } catch (e) {
      logger.e('UserRepository.getUsers failed: $e');
      return [];
    }
  }

  Future<bool> deleteUser(String id) async {
    await apiService.delete('/users/$id');
    return true;
  }
}
