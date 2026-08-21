import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UiUtils {
  static void showToast(String message) {
    Get.rawSnackbar(
      messageText: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ),
      backgroundColor: Colors.black87,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      borderRadius: 30,
    );
  }
}
