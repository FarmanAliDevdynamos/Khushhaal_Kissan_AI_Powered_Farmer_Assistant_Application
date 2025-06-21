// ignore_for_file: library_private_types_in_public_api

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khushhal_kisan_app/pages/farmer/farmerhomescreen.dart';
import 'package:khushhal_kisan_app/pages/farmer/phone_auth/verify_otp.dart';
import 'package:khushhal_kisan_app/pages/seller/sellerhomescreen.dart';

class LoginPage extends StatefulWidget {
  final String role;
  const LoginPage({required this.role, super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isChecked = false;
  final TextEditingController phoneController = TextEditingController();

  bool isValidPhoneNumber(String phone) {
    RegExp regex = RegExp(r'^\+?92[0-9]{10}$');
    return regex.hasMatch("+92${phoneController.text}");
  }

  void sendOTP() async {
    String phone = "+92${phoneController.text.trim()}";

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (widget.role == 'Farmer') {
          Get.offAll(() => Farmerhomescreen());
        } else {
          Get.offAll(() => Sellerhomescreen());
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        Get.snackbar(
          'Error',
          e.message!,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => VerifyOtp(
              verificationId: verificationId,
              resendToken: resendToken,
              role: widget.role,
              phone: phone,
            ),
          ),
          (route) => false, // Removes all previous routes
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
      timeout: const Duration(seconds: 60),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.green[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: screenHeight * 0.22,
                child: Image.asset(
                  'assets/images/logo1.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'خوشحال ',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.green,
                      ),
                    ),
                    TextSpan(
                      text: 'کسان',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.red[400],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Please enter correct phone number',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                onChanged: (value) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  prefixText: '+92 ',
                  prefixStyle:
                      const TextStyle(color: Colors.black, fontSize: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(
                    value: isChecked,
                    checkColor: Colors.white,
                    fillColor: WidgetStateProperty.all(Colors.green),
                    onChanged: (value) {
                      setState(() {
                        isChecked = value!;
                      });
                    },
                  ),
                  const Text('I agree to the '),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 55),
              ElevatedButton(
                onPressed: () {
                  if (isValidPhoneNumber(phoneController.text)) {
                    sendOTP();
                  } else {
                    Get.snackbar(
                      'Invalid Phone Number',
                      'Please enter a valid phone number',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                  sendOTP();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.green,
                  disabledForegroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
