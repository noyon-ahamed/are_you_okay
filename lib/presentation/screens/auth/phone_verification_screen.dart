import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:are_you_okay/routes/app_router.dart';

class PhoneVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const PhoneVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  ConsumerState<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState
    extends ConsumerState<PhoneVerificationScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _canResend = false;
  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendCountdown = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  String _getOtpCode() {
    return _otpControllers.map((c) => c.text).join();
  }

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        _otpFocusNodes[index].unfocus();
        _verifyOtp();
      }
    }
  }

  void _onOtpBackspace(int index) {
    if (index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _getOtpCode();
    if (otp.length != 6) {
      _showError('Please enter complete OTP');
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);

      // Navigate to home
      context.go(Routes.home);
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    // Clear OTP fields
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _otpFocusNodes[0].requestFocus();

    // TODO: Resend OTP API call
    _showSuccess('OTP sent successfully');

    // Restart timer
    _startResendTimer();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_read_outlined,
                  size: 50,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                'auth.verify_otp'.tr(),
                style: AppTextStyles.displaySmall(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Subtitle
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTextStyles.bodyMedium(
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    const TextSpan(text: 'We sent a code to\n'),
                    TextSpan(
                      text: '+880 ${widget.phoneNumber}',
                      style: AppTextStyles.bodyMedium(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 50,
                    child: TextFormField(
                      controller: _otpControllers[index],
                      focusNode: _otpFocusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: AppTextStyles.headlineLarge(
                        fontWeight: FontWeight.bold,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.border,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) => _onOtpChanged(index, value),
                      onTap: () {
                        _otpControllers[index].selection = TextSelection(
                          baseOffset: 0,
                          extentOffset:
                              _otpControllers[index].value.text.length,
                        );
                      },
                    ),
                  );
                }),
              ),

              const SizedBox(height: 32),

              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'auth.verify_otp'.tr(),
                          style: AppTextStyles.buttonLarge,
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Resend OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive code? ",
                    style: AppTextStyles.bodyMedium(),
                  ),
                  if (_canResend)
                    TextButton(
                      onPressed: _resendOtp,
                      child: Text(
                        'auth.resend_otp'.tr(),
                        style: AppTextStyles.labelLarge(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Text(
                      'Resend in ${_resendCountdown}s',
                      style: AppTextStyles.labelLarge(
                        color: AppColors.textTertiary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}