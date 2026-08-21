import 'package:get/get.dart';
import '../../data/repositories/user_repository.dart';

class UserController extends GetxController {
  final UserRepository repo = Get.put(UserRepository());
  
  var isLoading = false.obs;
  var users = [].obs;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    isLoading.value = true;
    try {
      users.value = await repo.getUsers();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteUser(String id) async {
    isLoading.value = true;
    try {
      final success = await repo.deleteUser(id);
      if (success) {
        Get.snackbar('Success', 'User deleted successfully');
        await fetchUsers();
      }
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      isLoading.value = false;
    }
  }
}
