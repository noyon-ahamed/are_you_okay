import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../provider/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../../provider/language_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with RestorationMixin {
  final _formKey = GlobalKey<FormState>();
  final RestorableTextEditingController _emailController =
      RestorableTextEditingController();
  final RestorableTextEditingController _passwordController =
      RestorableTextEditingController();
  final RestorableBool _obscurePassword = RestorableBool(true);
  final RestorableDouble _scrollOffset = RestorableDouble(0);
  late final ScrollController _scrollController;

  bool _isLoading = false;

  @override
  String? get restorationId => 'login_screen';

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
    registerForRestoration(_passwordController, 'password');
    registerForRestoration(_obscurePassword, 'obscure_password');
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
    _passwordController.dispose();
    _obscurePassword.dispose();
    _scrollOffset.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      if (mounted) {
        _showError(ref.read(stringsProvider).noInternet);
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).login(
            email: _emailController.value.text.trim(),
            password: _passwordController.value.text,
          );
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        // Extract message from DioException or common Exception
        if (e is DioException) {
          msg = e.response?.data['errorCode'] ??
              e.response?.data['error'] ??
              e.message ??
              'Network error';
        } else {
          msg = msg.replaceAll('Exception: ', '');
        }
        _showError(msg);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String rawMessage) {
    String message = rawMessage.replaceAll('Exception: ', '');

    final s = ref.read(stringsProvider);
    // Map common error messages to localized strings
    if (message == 'INVALID_CREDENTIALS' ||
        message.contains('Invalid email or password') ||
        (message.toLowerCase().contains('invalid') &&
            message.toLowerCase().contains('password')) ||
        message.contains('INVALID_CREDENTIALS')) {
      message = s.loginWrongPassword;
    } else if (message == 'USER_NOT_FOUND' ||
        message.contains('USER_NOT_FOUND')) {
      message = s.loginUserNotFound;
    } else if (message.contains('ACCOUNT_BLOCKED') ||
        message.toLowerCase().contains('blocked by an administrator')) {
      message = 'Your account has been blocked. Please contact support.';
    } else if (message.contains('ACCOUNT_DELETED') ||
        message.toLowerCase().contains('account has been deleted')) {
      message = 'This account is no longer available.';
    } else if (message.contains('SocketException') ||
        message.contains('Failed host lookup') ||
        message.contains('No Internet') ||
        message.contains('connection')) {
      message = s.noInternet;
    } else if (message.contains('Network error')) {
      message = s.networkError;
    } else if (message.contains('Login failed')) {
      message = '${s.loginTitle} ${s.error.toLowerCase()}';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'HindSiliguri'),
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: s.ok,
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!mounted) return;

      if (_isLoading && next is! AuthLoading) {
        setState(() => _isLoading = false);
      }

      if (next is AuthAuthenticated && previous is! AuthAuthenticated) {
        context.go('/home');
      } else if (next is AuthError &&
          (previous is! AuthError || previous.message != next.message)) {
        _showError(next.message);
      }
    });

    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          key: const PageStorageKey('login_scroll'),
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Logo
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  s.appName,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  s.loginSubtitle,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Email field
                CustomTextField(
                  controller: _emailController.value,
                  label: s.loginEmail,
                  hint: 'your@email.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '${s.loginEmail} ${s.validationRequired}';
                    }
                    if (!value.contains('@')) {
                      return s.validationEmailInvalid;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password field
                CustomTextField(
                  controller: _passwordController.value,
                  label: s.loginPassword,
                  hint: '••••••••',
                  obscureText: _obscurePassword.value,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() =>
                          _obscurePassword.value = !_obscurePassword.value);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '${s.loginPassword} ${s.validationRequired}';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 8),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: Text(s.loginForgotPass),
                  ),
                ),

                const SizedBox(height: 24),

                // Login button
                CustomButton(
                  text: s.loginButton,
                  onPressed: _isLoading
                      ? null
                      : () {
                          _handleLogin();
                        },
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 24),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      s.loginNoAccountText,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: Text(
                        s.regButton,
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
