import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/api/auth_api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../../provider/language_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with RestorationMixin {
  final _formKey = GlobalKey<FormState>();
  final RestorableTextEditingController _emailController =
      RestorableTextEditingController();
  final RestorableTextEditingController _otpController =
      RestorableTextEditingController();
  final RestorableTextEditingController _newPasswordController =
      RestorableTextEditingController();
  final RestorableTextEditingController _confirmPasswordController =
      RestorableTextEditingController();
  final RestorableBool _obscurePassword = RestorableBool(true);
  final RestorableBool _obscureConfirm = RestorableBool(true);
  final RestorableInt _currentStep = RestorableInt(0);
  final RestorableStringN _resetToken = RestorableStringN(null);
  final RestorableDouble _scrollOffset = RestorableDouble(0);
  late final ScrollController _scrollController;
  final _authService = AuthApiService();

  bool _isLoading = false;

  @override
  String? get restorationId => 'forgot_password_screen';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        _scrollOffset.value = _scrollController.offset;
      });
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_emailController, 'email');
    registerForRestoration(_otpController, 'otp');
    registerForRestoration(_newPasswordController, 'new_password');
    registerForRestoration(_confirmPasswordController, 'confirm_password');
    registerForRestoration(_obscurePassword, 'obscure_password');
    registerForRestoration(_obscureConfirm, 'obscure_confirm');
    registerForRestoration(_currentStep, 'current_step');
    registerForRestoration(_resetToken, 'reset_token');
    registerForRestoration(_scrollOffset, 'scroll_offset');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollOffset.value);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _obscurePassword.dispose();
    _obscureConfirm.dispose();
    _currentStep.dispose();
    _resetToken.dispose();
    _scrollOffset.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.forgotPassword(_emailController.value.text.trim());

      if (mounted) {
        final s = ref.read(stringsProvider);
        _showSuccess(s.forgotOtpSent);
        setState(() => _currentStep.value = 1);
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
    if (_otpController.value.text.trim().length != 6) {
      final s = ref.read(stringsProvider);
      _showError(s.forgotOtpHint);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await _authService.verifyOtp(
        email: _emailController.value.text.trim(),
        otp: _otpController.value.text.trim(),
      );

      if (mounted) {
        final s = ref.read(stringsProvider);
        _showSuccess(s.forgotOtpVerified);
        setState(() {
          _resetToken.value = token;
          _currentStep.value = 2;
        });
      }
    } catch (e) {
      if (mounted) {
        final s = ref.read(stringsProvider);
        String msg = e.toString().replaceAll('Exception: ', '');
        if (msg.contains('Invalid') || msg.contains('expired')) {
          msg = s.forgotOtpInvalid;
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
    if (_resetToken.value == null) {
      final s = ref.read(stringsProvider);
      _showError(
          s.isBangla ? 'OTP যাচাই প্রয়োজন' : 'OTP verification required');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.resetPassword(
        token: _resetToken.value!,
        newPassword: _newPasswordController.value.text,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.forgotTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          key: const PageStorageKey('forgot_password_scroll'),
          controller: _scrollController,
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
                  _currentStep.value == 0
                      ? s.forgotTitle
                      : _currentStep.value == 1
                          ? s.forgotVerifyOTP
                          : s.forgotNewPassword,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  _currentStep.value == 0
                      ? s.forgotSubtitle
                      : _currentStep.value == 1
                          ? s.forgotOTPSubtitle
                          : s.forgotNewPassSubtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
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
                      width: index == _currentStep.value ? 32 : 12,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index <= _currentStep.value
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
                if (_currentStep.value == 0) ...[
                  CustomTextField(
                    controller: _emailController.value,
                    label: s.regEmail,
                    hint: 'your@email.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '${s.regEmail} ${s.validationRequired}';
                      }
                      if (!value.contains('@')) {
                        return s.validationEmailInvalid;
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
                if (_currentStep.value == 1) ...[
                  Text(
                    _emailController.value.text.trim(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _otpController.value,
                    label: s.forgotOtpCode,
                    hint: s.forgotOtpHint,
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
                            _otpController.value.clear();
                            _sendOtp();
                          },
                    child: Text(
                      s.forgotResendOtp,
                      style: const TextStyle(fontFamily: 'HindSiliguri'),
                    ),
                  ),
                ],

                // Step 2: New Password
                if (_currentStep.value == 2) ...[
                  CustomTextField(
                    controller: _newPasswordController.value,
                    label: s.forgotNewPassword,
                    hint: '••••••••',
                    obscureText: _obscurePassword.value,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword.value
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(() =>
                          _obscurePassword.value = !_obscurePassword.value),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '${s.forgotNewPassword} ${s.validationRequired}';
                      }
                      if (value.length < 6) {
                        return s.validationPassLength;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _confirmPasswordController.value,
                    label: s.regConfirmPass,
                    hint: '••••••••',
                    obscureText: _obscureConfirm.value,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm.value
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(
                          () => _obscureConfirm.value = !_obscureConfirm.value),
                    ),
                    validator: (value) {
                      if (value != _newPasswordController.value.text) {
                        return s.validationPassMatch;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: s.forgotResetButton,
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
                      s.forgotRemembered,
                      style: TextStyle(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
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
