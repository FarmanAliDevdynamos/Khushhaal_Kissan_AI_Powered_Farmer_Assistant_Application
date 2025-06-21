import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:khushhal_kisan_app/pages/farmer/farmerhomescreen.dart';
import 'package:khushhal_kisan_app/pages/seller/sellerhomescreen.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class VerifyOtp extends StatefulWidget {
  final String verificationId;
  final int? resendToken;
  final String role;
  final String phone;

  const VerifyOtp({
    required this.verificationId,
    required this.resendToken,
    required this.role,
    required this.phone,
    super.key,
  });

  @override
  // ignore: library_private_types_in_public_api
  _VerifyOtpState createState() => _VerifyOtpState();
}

class _VerifyOtpState extends State<VerifyOtp> {
  late TextEditingController otpController;
  late String verificationId;
  int countdown = 58;
  Timer? _timer;
  bool canResend = false;
  bool _isDisposed = false; // Track disposal

  @override
  void initState() {
    super.initState();
    otpController = TextEditingController();
    verificationId = widget.verificationId;
    startCountdown();
  }

  /// Starts the countdown timer
  void startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isDisposed) {
        timer.cancel();
        return;
      }
      if (mounted) {
        setState(() {
          if (countdown > 0) {
            countdown--;
          } else {
            canResend = true;
            timer.cancel();
          }
        });
      }
    });
  }

  /// Resends OTP
  void resendCode() async {
    if (!mounted || _isDisposed) return;

    setState(() {
      countdown = 28;
      canResend = false;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (!mounted || _isDisposed) return;
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted || _isDisposed) return;
          showSnackBar('Failed to resend OTP: ${e.message}');
        },
        codeSent: (String newVerificationId, int? newResendToken) {
          if (!mounted || _isDisposed) return;
          showSnackBar('OTP resent successfully!');
          if (mounted) {
            setState(() {
              verificationId = newVerificationId;
            });
          }
        },
        forceResendingToken: widget.resendToken,
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      if (!mounted || _isDisposed) return;
      showSnackBar('An error occurred while resending OTP');
    }

    startCountdown();
  }

  /// Verifies OTP
  void verifyOTP() async {
    if (!mounted || _isDisposed) return;

    if (!_isDisposed && otpController.text.isNotEmpty) {
      String otp = otpController.text.trim();
      if (otp.length < 6) {
        showSnackBar('Please enter a valid 6-digit OTP');
        return;
      }

      try {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: otp,
        );

        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);

        if (!mounted || _isDisposed) return;

        if (userCredential.user != null) {
          Get.offAll(() => widget.role == 'Farmer'
              ? const Farmerhomescreen()
              : const Sellerhomescreen());
        }
      } on FirebaseAuthException catch (ex) {
        if (!mounted || _isDisposed) return;
        String errorMessage = 'Something went wrong. Please try again.';
        if (ex.code == 'invalid-verification-code') {
          errorMessage = 'Invalid OTP, please try again.';
        } else if (ex.code == 'session-expired') {
          errorMessage = 'OTP has expired. Please request a new one.';
        }
        showSnackBar(errorMessage);
      }
    }
  }

  /// Shows a snack bar message
  void showSnackBar(String message) {
    if (!mounted || _isDisposed) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();

    // ✅ Delay disposal slightly to prevent UI crashes
    Future.delayed(Duration(milliseconds: 200), () {
      if (mounted) {
        otpController.dispose();
      }
    });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Please type the verification code sent to',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              widget.phone,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 30),

            /// OTP Input Field
            PinCodeTextField(
              appContext: context,
              length: 6,
              controller:
                  _isDisposed ? null : otpController, // ✅ Use null if disposed
              keyboardType: TextInputType.number,
              animationType: AnimationType.fade,
              cursorColor: Colors.green,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(8),
                fieldHeight: 50,
                fieldWidth: 45,
                activeFillColor: Colors.white,
                inactiveFillColor: Colors.white,
                selectedFillColor: Colors.white,
                activeColor: Colors.green,
                inactiveColor: Colors.green,
                selectedColor: Colors.green,
              ),
              enableActiveFill: true,
              onChanged: (value) {},
            ),

            const SizedBox(height: 10),

            /// Resend OTP Countdown
            Text(
              "Didn't receive the code? Resend in 00:${countdown.toString().padLeft(2, '0')}",
              style: TextStyle(color: Colors.grey[700]),
            ),
            TextButton(
              onPressed: canResend ? resendCode : null,
              child: Text(
                'Resend Code',
                style: TextStyle(
                  color: canResend ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),

            /// Next Button
            ElevatedButton(
              onPressed: verifyOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: const Text(
                'Next >',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
