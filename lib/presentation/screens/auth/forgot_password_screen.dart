import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/api/auth_api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../../core/localization/app_strings.dart';
import '../../../provider/language_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthApiService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // 0 = enter email, 1 = enter OTP, 2 = enter new password
  int _currentStep = 0;
  String? _resetToken;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.forgotPassword(_emailController.text.trim());

      if (mounted) {
        final s = ref.read(stringsProvider);
        _showSuccess(s.isBangla
            ? 'আপনার ইমেইলে ৬ সংখ্যার OTP কোড পাঠানো হয়েছে'
            : 'A 6-digit OTP code has been sent to your email');
        setState(() => _currentStep = 1);
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().length != 6) {
      final s = ref.read(stringsProvider);
      _showError(s.isBangla
          ? 'অনুগ্রহ করে ৬ সংখ্যার OTP কোড দিন'
          : 'Please enter 6-digit OTP code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await _authService.verifyOtp(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
      );

      if (mounted) {
        final s = ref.read(stringsProvider);
        _showSuccess(s.isBangla
            ? 'OTP সঠিক! এখন নতুন পাসওয়ার্ড দিন।'
            : 'OTP verified! Now enter your new password.');
        setState(() {
          _resetToken = token;
          _currentStep = 2;
        });
      }
    } catch (e) {
      if (mounted) {
        final s = ref.read(stringsProvider);
        String msg = e.toString().replaceAll('Exception: ', '');
        if (msg.contains('Invalid') || msg.contains('expired')) {
          msg = s.isBangla
              ? 'ভুল বা মেয়াদোত্তীর্ণ OTP কোড। আবার চেষ্টা করুন।'
              : 'Invalid or expired OTP code. Please try again.';
        }
        _showError(msg);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_resetToken == null) {
      final s = ref.read(stringsProvider);
      _showError(
          s.isBangla ? 'OTP ভেরিফিকেশন প্রয়োজন' : 'OTP verification required');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.resetPassword(
        token: _resetToken!,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        final s = ref.read(stringsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              s.forgotResetSuccess,
              style: const TextStyle(fontFamily: 'HindSiliguri'),
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );

        // Go back to login
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: const TextStyle(fontFamily: 'HindSiliguri')),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: const TextStyle(fontFamily: 'HindSiliguri')),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.forgotTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                const Icon(
                  Icons.lock_reset,
                  size: 80,
                  color: AppColors.primary,
                ),

                const SizedBox(height: 24),

                Text(
                  _currentStep == 0
                      ? s.forgotTitle
                      : _currentStep == 1
                          ? s.forgotVerifyOTP
                          : (s.isBangla ? 'নতুন পাসওয়ার্ড' : 'New Password'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  _currentStep == 0
                      ? s.forgotSubtitle
                      : _currentStep == 1
                          ? s.forgotOTPSubtitle
                          : s.forgotNewPassSubtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontFamily: 'HindSiliguri',
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Step indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Container(
                      width: index == _currentStep ? 32 : 12,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index <= _currentStep
                            ? AppColors.primary
                            // ignore: deprecated_member_use
                            : AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 32),

                // Step 0: Email
                if (_currentStep == 0) ...[
                  CustomTextField(
                    controller: _emailController,
                    label: s.regEmail,
                    hint: 'your@email.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return s.regEmail +
                            ' ' +
                            (s.isBangla ? 'দিন' : 'required');
                      }
                      if (!value.contains('@')) {
                        return s.contactsPhoneInvalid;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: s.forgotSendOTP,
                    onPressed: _isLoading
                        ? null
                        : () {
                            _sendOtp();
                          },
                    isLoading: _isLoading,
                  ),
                ],

                // Step 1: OTP
                if (_currentStep == 1) ...[
                  Text(
                    _emailController.text.trim(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _otpController,
                    label: 'OTP ' + (s.isBangla ? 'কোড' : 'Code'),
                    hint: s.isBangla ? '৬ সংখ্যার কোড' : '6-digit code',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.pin,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: s.forgotVerifyOTP,
                    onPressed: _isLoading
                        ? null
                        : () {
                            _verifyOtp();
                          },
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            _otpController.clear();
                            _sendOtp();
                          },
                    child: Text(
                      s.isBangla ? 'আবার OTP পাঠান' : 'Resend OTP',
                      style: const TextStyle(fontFamily: 'HindSiliguri'),
                    ),
                  ),
                ],

                // Step 2: New Password
                if (_currentStep == 2) ...[
                  CustomTextField(
                    controller: _newPasswordController,
                    label: s.isBangla ? 'নতুন পাসওয়ার্ড' : 'New Password',
                    hint: '••••••••',
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return (s.isBangla
                                ? 'নতুন পাসওয়ার্ড'
                                : 'New Password') +
                            ' ' +
                            (s.isBangla ? 'দিন' : 'required');
                      }
                      if (value.length < 6) {
                        return s.isBangla
                            ? 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে'
                            : 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: s.regConfirmPass,
                    hint: '••••••••',
                    obscureText: _obscureConfirm,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    validator: (value) {
                      if (value != _newPasswordController.text) {
                        return s.isBangla
                            ? 'পাসওয়ার্ড মিলছে না'
                            : 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text:
                        s.isBangla ? 'পাসওয়ার্ড রিসেট করুন' : 'Reset Password',
                    onPressed: _isLoading
                        ? null
                        : () {
                            _resetPassword();
                          },
                    isLoading: _isLoading,
                  ),
                ],

                const SizedBox(height: 24),

                // Back to login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      (s.isBangla ? 'মনে পড়েছে? ' : 'Remembered? '),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(
                        s.loginButton,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
