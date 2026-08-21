import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final AuthController ctrl = Get.put(AuthController());
  final TextEditingController otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late String email;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    email = args['email'] ?? '';
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_read, size: 80, color: Colors.pink),
              const SizedBox(height: 16),
              Text('Enter the 6-digit code sent for $email', textAlign: TextAlign.center),
              const SizedBox(height: 32),
              TextFormField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(labelText: 'OTP', border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.trim().length != 6) {
                    return 'Enter the 6-digit code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Obx(() => ctrl.isLoading.value
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          ctrl.verifyPasswordResetOtp(email, otpController.text.trim());
                        }
                      },
                      child: const Text('Verify'),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}
