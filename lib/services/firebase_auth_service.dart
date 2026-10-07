import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/login_model.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // HELPER: Dynamic Phone Number & UID Firestore-e Auto Save/Update Kora
  // ---------------------------------------------------------------------------
  Future<void> _saveOrUpdateUserToFirestore(User user, {String? name}) async {
    final userDocRef = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDocRef.get();

    // Phone number format normalize kora
    String rawPhone = user.phoneNumber ?? '';
    if (rawPhone.isNotEmpty && !rawPhone.startsWith('+')) {
      rawPhone = '+91$rawPhone';
    }

    // Default fallback name
    String defaultName = rawPhone.length >= 10
        ? 'User ${rawPhone.substring(rawPhone.length - 4)}'
        : 'User ${user.uid.substring(0, 4)}';

    if (!docSnapshot.exists) {
      // Notun user hole Document toiri hobe (Document ID ebong 'id' field duto'i UID hobe)
      await userDocRef.set({
        'id': user.uid,
        'uid': user.uid,
        'name': (name != null && name.trim().isNotEmpty) ? name : defaultName,
        'phoneNumber': rawPhone,
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Purono user hole Status & Details update hobe
      Map<String, dynamic> updateData = {
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      };
      if (name != null && name.trim().isNotEmpty) {
        updateData['name'] = name;
      }
      if (rawPhone.isNotEmpty) {
        updateData['phoneNumber'] = rawPhone;
      }
      await userDocRef.update(updateData);
    }
  }

  // ---------------------------------------------------------------------------
  // OTP Verification Request
  // ---------------------------------------------------------------------------
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onError,
    required Function(PhoneAuthCredential credential) onAutoVerification,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        onAutoVerification(credential);
      },
      verificationFailed: onError,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  // ---------------------------------------------------------------------------
  // OTP Sign In + Auto Sync
  // ---------------------------------------------------------------------------
  Future<LoginModel?> verifyOTPAndSignIn({
    required String verificationId,
    required String smsCode,
    String? name,
  }) async {
    try {
      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      final User? user = userCredential.user;

      if (user != null) {
        await _saveOrUpdateUserToFirestore(user, name: name);

        return LoginModel(
          uid: user.uid,
          mobileNo: user.phoneNumber ?? '',
        );
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Auto Verification Credential Sign In + Auto Sync
  // ---------------------------------------------------------------------------
  Future<LoginModel?> signInWithCredential(
      PhoneAuthCredential credential, {
        String? name,
      }) async {
    try {
      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        await _saveOrUpdateUserToFirestore(user, name: name);

        return LoginModel(
          uid: user.uid,
          mobileNo: user.phoneNumber ?? '',
        );
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  User? get currentUser => _auth.currentUser;

  // ---------------------------------------------------------------------------
  // Sign Out (isOnline Status False Set Kora)
  // ---------------------------------------------------------------------------
  Future<void> signOut() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
    await _auth.signOut();
  }
}