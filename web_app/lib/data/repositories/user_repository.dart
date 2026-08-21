import '../../core/network/api_service.dart';
import '../../core/network/logger.dart';

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
