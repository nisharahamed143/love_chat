import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../screens/navigation_screen.dart';
import '../../view_models/login_view_model.dart';

class LoginScreenBody extends StatefulWidget {
  final VoidCallback? onSignUpTap;

  const LoginScreenBody({
    super.key,
    this.onSignUpTap,
  });

  @override
  State<LoginScreenBody> createState() => _LoginScreenBodyState();
}

class _LoginScreenBodyState extends State<LoginScreenBody> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // OTP পাঠানো
  Future<void> _handleSendOTP(LoginViewModel viewModel) async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus(); // Keyboard hide
      final String fullMobileNumber = "+91${_phoneController.text.trim()}";
      await viewModel.requestOTP(fullMobileNumber);
    }
  }

  // OTP যাচাই ও নেভিগেশন
  Future<void> _handleVerifyOTP(LoginViewModel viewModel) async {
    if (_formKey.currentState!.validate()) {
      final otp = _otpController.text.trim();
      if (otp.length == 6) {
        FocusScope.of(context).unfocus();
        bool isSuccess = await viewModel.verifyOTP(otp);

        if (!mounted) return;

        if (isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login Successful!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const NavigationScreen(),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Enter a valid 6-digit OTP"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.status == AuthStatus.error && viewModel.errorMessage.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(viewModel.errorMessage),
                backgroundColor: Colors.redAccent,
              ),
            );
            viewModel.resetStatus();
          });
        }

        final bool isOtpSent = viewModel.status == AuthStatus.otpSent ||
            (viewModel.status == AuthStatus.loading && _otpController.text.isNotEmpty);
        final bool isLoading = viewModel.status == AuthStatus.loading;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Mobile Input Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.teal.withOpacity(0.15),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF18ECB0),
                              Color(0xFF00B4DB),
                              Color(0xFF0083B0),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.phone_iphone_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "+91",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          enabled: !isOtpSent,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: Colors.black87,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter phone number';
                            }
                            if (value.trim().length < 10) {
                              return 'Enter a valid 10-digit number';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: "00000 00000",
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 15,
                              fontWeight: FontWeight.normal,
                              letterSpacing: 1.0,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Custom OTP Field (Without Pinput)
                if (isOtpSent) ...[
                  const SizedBox(height: 24),
                  Text(
                    "Enter 6-digit OTP code sent to +91 ${_phoneController.text}",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF0083B0),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 16,
                        color: Colors.black87,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter OTP';
                        }
                        if (value.trim().length < 6) {
                          return 'OTP must be 6 digits';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: "******",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 22,
                          letterSpacing: 12,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Button (Continue / Verify & Login)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF00B4DB),
                        Color(0xFF0083B0),
                      ],
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                      if (!isOtpSent) {
                        _handleSendOTP(viewModel);
                      } else {
                        _handleVerifyOTP(viewModel);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      !isOtpSent ? "Continue" : "Verify & Login",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}