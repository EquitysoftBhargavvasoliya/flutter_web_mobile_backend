import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../core/constants/fcm_constants.dart';
import '../../core/utils/ui_utils.dart';
import '../../data/repositories/auth_repository.dart';

class AuthController extends GetxController {
  final AuthRepository repo = Get.put(AuthRepository());
  
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var userRole = 'Buyer'.obs;
  var userId = ''.obs;
  var userName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final role = await repo.storage.read(key: 'user_role');
    final id = await repo.storage.read(key: 'user_id');
    final name = await repo.storage.read(key: 'user_name');
    userRole.value = role ?? 'Buyer';
    userId.value = id ?? '';
    userName.value = name ?? '';
  }

  Future<void> login(String email, String password, {String? fcmToken}) async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      String? tokenToPass = fcmToken;
      // FCM web push disabled for now: requires a VAPID key from the Firebase
      // Console (Cloud Messaging > Web configuration) that isn't available yet.
      // Uncomment once kFcmVapidKey in fcm_constants.dart is set to a real key.
      // try {
      //   if (tokenToPass == null) {
      //     // Request permission first (required for iOS, Web, and Android 13+)
      //     NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      //       alert: true,
      //       badge: true,
      //       sound: true,
      //     );
      //
      //     if (settings.authorizationStatus == AuthorizationStatus.authorized ||
      //         settings.authorizationStatus == AuthorizationStatus.provisional) {
      //       tokenToPass = await FirebaseMessaging.instance.getToken(
      //         vapidKey: kFcmVapidKey,
      //       );
      //     } else {
      //       print("FCM permission denied by user.");
      //     }
      //   }
      // } catch (e) {
      //   print("Failed to get FCM token: $e");
      // }
      // No fallback placeholder here: an unavailable token means the backend
      // should simply not store one for this session, not a fake string.

      final success = await repo.login(email, password, fcmToken: tokenToPass);
      if (success) {
        await _loadUserInfo();
        Get.offAllNamed('/home');
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      errorMessage.value = msg;
      UiUtils.showToast(errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register(String email, String password, String name, String role) async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      final success = await repo.register(email, password, name, role);
      if (success) {
        UiUtils.showToast('Account created! Please log in.');
        Get.offAllNamed('/login');
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      errorMessage.value = msg;
      UiUtils.showToast(errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> requestPasswordResetOtp(String email) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final otp = await repo.requestPasswordResetOtp(email);
      // Dev mode: the backend has no email/SMS provider configured yet, so it
      // returns the OTP directly instead of sending it. Surface it here so
      // testers can proceed without reading network logs.
      UiUtils.showToast('Dev mode OTP: $otp');
      Get.toNamed('/verify-otp', arguments: {'email': email});
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      errorMessage.value = msg;
      UiUtils.showToast(errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyPasswordResetOtp(String email, String otp) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      await repo.verifyPasswordResetOtp(email, otp);
      Get.toNamed('/reset-password', arguments: {'email': email, 'otp': otp});
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      errorMessage.value = msg;
      UiUtils.showToast(errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword(String email, String otp, String newPassword) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      await repo.resetPassword(email, otp, newPassword);
      UiUtils.showToast('Password reset! Please log in.');
      Get.offAllNamed('/login');
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      errorMessage.value = msg;
      UiUtils.showToast(errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  void logout() {
    repo.logout();
  }
}
