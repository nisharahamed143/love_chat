import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/login_model.dart';
import '../services/firebase_auth_service.dart';

enum AuthStatus { initial, loading, otpSent, success, error }

class LoginViewModel extends ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();

  AuthStatus _status = AuthStatus.initial;
  String _errorMessage = '';
  String _verificationId = '';
  LoginModel? _currentUserModel;

  AuthStatus get status => _status;
  String get errorMessage => _errorMessage;
  String get verificationId => _verificationId;
  LoginModel? get currentUserModel => _currentUserModel;

  void resetStatus() {
    _status = AuthStatus.initial;
    _errorMessage = '';
    notifyListeners();
  }

  // ১. ফোন নাম্বারে OTP রিকোয়েস্ট পাঠানো
  Future<void> requestOTP(String mobileNumber) async {
    _setStatus(AuthStatus.loading);

    await _authService.sendOTP(
      phoneNumber: mobileNumber,
      onCodeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        _setStatus(AuthStatus.otpSent); // এটি Listeners-কে নোটিফাই করবে UI আপডেট করার জন্য
      },
      onError: (e) {
        _errorMessage = e.message ?? "Phone verification failed";
        _setStatus(AuthStatus.error);
      },
      onAutoVerification: (credential) async {
        try {
          final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (userCredential.user != null) {
            _currentUserModel = LoginModel(
              uid: userCredential.user!.uid,
              mobileNo: userCredential.user!.phoneNumber ?? '',
            );
            _setStatus(AuthStatus.success);
          }
        } catch (e) {
          _errorMessage = e.toString();
          _setStatus(AuthStatus.error);
        }
      },
    );
  }

  // ২. OTP Submit এবং Authentication সম্পন্ন করা
  Future<bool> verifyOTP(String smsCode) async {
    _setStatus(AuthStatus.loading);

    try {
      final loginModel = await _authService.verifyOTPAndSignIn(
        verificationId: _verificationId,
        smsCode: smsCode,
      );

      if (loginModel != null) {
        _currentUserModel = loginModel;
        _setStatus(AuthStatus.success);
        return true;
      } else {
        _errorMessage = "Authentication failed. User is null.";
        _setStatus(AuthStatus.error);
        return false;
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? "Invalid OTP entered";
      _setStatus(AuthStatus.error);
      return false;
    } catch (e) {
      _errorMessage = "Something went wrong: ${e.toString()}";
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }
}