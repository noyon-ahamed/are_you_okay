import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase Authentication Service
/// Handles all authentication operations
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Phone verification variables
  String? _verificationId;
  int? _resendToken;

  /// Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Register with email and password
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Send verification code to phone number
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
    required Function(String error) verificationFailed,
    required Function(PhoneAuthCredential credential) verificationCompleted,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: timeout,
      verificationCompleted: verificationCompleted,
      verificationFailed: (FirebaseAuthException e) {
        verificationFailed(_handleAuthException(e));
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        codeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
      forceResendingToken: _resendToken,
    );
  }

  /// Verify OTP code
  Future<UserCredential> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with phone credential (auto-verification)
  Future<UserCredential> signInWithPhoneCredential(
    PhoneAuthCredential credential,
  ) async {
    try {
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Link phone number to existing account
  Future<void> linkPhoneNumber(PhoneAuthCredential credential) async {
    try {
      await _auth.currentUser?.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Update email
  Future<void> updateEmail(String newEmail) async {
    try {
      await _auth.currentUser?.verifyBeforeUpdateEmail(newEmail);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Reload user data
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Delete account
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');

    switch (e.code) {
      case 'user-not-found':
        return 'কোন ব্যবহারকারী পাওয়া যায়নি।';
      case 'wrong-password':
        return 'ভুল পাসওয়ার্ড।';
      case 'email-already-in-use':
        return 'এই ইমেইল ইতিমধ্যে ব্যবহৃত হয়েছে।';
      case 'invalid-email':
        return 'অকার্যকর ইমেইল।';
      case 'weak-password':
        return 'পাসওয়ার্ড খুবই দুর্বল।';
      case 'too-many-requests':
        return 'অনেক বেশি চেষ্টা। পরে আবার চেষ্টা করুন।';
      case 'invalid-verification-code':
        return 'ভুল যাচাইকরণ কোড।';
      case 'invalid-verification-id':
        return 'যাচাইকরণ আইডি সময়োত্তীর্ণ।';
      case 'session-expired':
        return 'সেশন সময়োত্তীর্ণ। আবার চেষ্টা করুন।';
      case 'invalid-phone-number':
        return 'অকার্যকর ফোন নম্বর।';
      case 'quota-exceeded':
        return 'এসএমএস কোটা শেষ। পরে আবার চেষ্টা করুন।';
      default:
        return e.message ?? 'কিছু ভুল হয়েছে।';
    }
  }
}
