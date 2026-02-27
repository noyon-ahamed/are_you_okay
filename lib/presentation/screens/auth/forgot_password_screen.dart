import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/api/auth_api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
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
        _showSuccess('আপনার ইমেইলে ৬ সংখ্যার OTP কোড পাঠানো হয়েছে');
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
      _showError('অনুগ্রহ করে ৬ সংখ্যার OTP কোড দিন');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await _authService.verifyOtp(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
      );

      if (mounted) {
        _showSuccess('OTP সঠিক! এখন নতুন পাসওয়ার্ড দিন।');
        setState(() {
          _resetToken = token;
          _currentStep = 2;
        });
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceAll('Exception: ', '');
        if (msg.contains('Invalid') || msg.contains('expired')) {
          msg = 'ভুল বা মেয়াদোত্তীর্ণ OTP কোড। আবার চেষ্টা করুন।';
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
      _showError('OTP ভেরিফিকেশন প্রয়োজন');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.resetPassword(
        token: _resetToken!,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'পাসওয়ার্ড সফলভাবে রিসেট হয়েছে! এখন লগইন করুন।',
              style: TextStyle(fontFamily: 'HindSiliguri'),
            ),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
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
        content: Text(message, style: const TextStyle(fontFamily: 'HindSiliguri')),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'HindSiliguri')),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('পাসওয়ার্ড রিসেট'),
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
                      ? 'পাসওয়ার্ড রিসেট'
                      : _currentStep == 1
                          ? 'OTP যাচাই'
                          : 'নতুন পাসওয়ার্ড',
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
                      ? 'আপনার ইমেইল দিন। আমরা আপনাকে OTP কোড পাঠাব।'
                      : _currentStep == 1
                          ? 'আপনার ইমেইলে পাঠানো ৬ সংখ্যার কোড দিন।'
                          : 'আপনার নতুন পাসওয়ার্ড দিন।',
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
                    label: 'ইমেইল',
                    hint: 'your@email.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'ইমেইল দিন';
                      }
                      if (!value.contains('@')) {
                        return 'সঠিক ইমেইল দিন';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'OTP পাঠান',
                    onPressed: _isLoading ? null : () { _sendOtp(); },
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
                    label: 'OTP কোড',
                    hint: '৬ সংখ্যার কোড',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.pin,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'OTP যাচাই করুন',
                    onPressed: _isLoading ? null : () { _verifyOtp(); },
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isLoading ? null : () {
                      _otpController.clear();
                      _sendOtp();
                    },
                    child: const Text(
                      'আবার OTP পাঠান',
                      style: TextStyle(fontFamily: 'HindSiliguri'),
                    ),
                  ),
                ],

                // Step 2: New Password
                if (_currentStep == 2) ...[
                  CustomTextField(
                    controller: _newPasswordController,
                    label: 'নতুন পাসওয়ার্ড',
                    hint: '••••••••',
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'নতুন পাসওয়ার্ড দিন';
                      }
                      if (value.length < 6) {
                        return 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: 'পাসওয়ার্ড নিশ্চিত করুন',
                    hint: '••••••••',
                    obscureText: _obscureConfirm,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    validator: (value) {
                      if (value != _newPasswordController.text) {
                        return 'পাসওয়ার্ড মিলছে না';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'পাসওয়ার্ড রিসেট করুন',
                    onPressed: _isLoading ? null : () { _resetPassword(); },
                    isLoading: _isLoading,
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Back to login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'মনে পড়েছে? ',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text(
                        'লগইন করুন',
                        style: TextStyle(fontWeight: FontWeight.bold),
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
