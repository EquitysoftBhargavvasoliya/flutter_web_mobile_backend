import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final AuthController ctrl = Get.put(AuthController());
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late String email;
  late String otp;
  final _obscurePassword = true.obs;
  final _obscureConfirm = true.obs;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    email = args['email'] ?? '';
    otp = args['otp'] ?? '';
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.password, size: 80, color: Colors.pink),
                  const SizedBox(height: 32),
                  Obx(() => TextFormField(
                    controller: passwordController,
                    obscureText: _obscurePassword.value,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword.value ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => _obscurePassword.value = !_obscurePassword.value,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a new password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  )),
                  const SizedBox(height: 16),
                  Obx(() => TextFormField(
                    controller: confirmController,
                    obscureText: _obscureConfirm.value,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm.value ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => _obscureConfirm.value = !_obscureConfirm.value,
                      ),
                    ),
                    validator: (value) {
                      if (value != passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  )),
                  const SizedBox(height: 24),
                  Obx(() => ctrl.isLoading.value
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              ctrl.resetPassword(email, otp, passwordController.text);
                            }
                          },
                          child: const Text('Reset Password'),
                        )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
