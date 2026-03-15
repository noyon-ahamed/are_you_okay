import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/api/auth_api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../../provider/language_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with RestorationMixin {
  final _formKey = GlobalKey<FormState>();
  final RestorableTextEditingController _nameController =
      RestorableTextEditingController();
  final RestorableTextEditingController _emailController =
      RestorableTextEditingController();
  final RestorableTextEditingController _phoneController =
      RestorableTextEditingController();
  final RestorableTextEditingController _passwordController =
      RestorableTextEditingController();
  final RestorableTextEditingController _confirmPasswordController =
      RestorableTextEditingController();
  final RestorableBool _obscurePassword = RestorableBool(true);
  final RestorableBool _obscureConfirmPassword = RestorableBool(true);
  final RestorableDouble _scrollOffset = RestorableDouble(0);
  late final ScrollController _scrollController;
  final _authService = AuthApiService();

  bool _isLoading = false;

  @override
  String? get restorationId => 'register_screen';

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
    registerForRestoration(_nameController, 'name');
    registerForRestoration(_emailController, 'email');
    registerForRestoration(_phoneController, 'phone');
    registerForRestoration(_passwordController, 'password');
    registerForRestoration(_confirmPasswordController, 'confirm_password');
    registerForRestoration(_obscurePassword, 'obscure_password');
    registerForRestoration(_obscureConfirmPassword, 'obscure_confirm_password');
    registerForRestoration(_scrollOffset, 'scroll_offset');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollOffset.value);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _obscurePassword.dispose();
    _obscureConfirmPassword.dispose();
    _scrollOffset.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.register(
        email: _emailController.value.text.trim(),
        password: _passwordController.value.text,
        name: _nameController.value.text.trim(),
        phone: _phoneController.value.text.trim().isNotEmpty
            ? _phoneController.value.text.trim()
            : null,
      );

      if (mounted) {
        final s = ref.read(stringsProvider);
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.regSuccess),
            backgroundColor: AppColors.success,
          ),
        );

        // Navigate to home
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.regTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          key: const PageStorageKey('register_scroll'),
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                // Name field
                CustomTextField(
                  controller: _nameController.value,
                  label: s.regName,
                  hint: s.regNameHint,
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '${s.regName} ${s.validationRequired}';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Email field
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

                const SizedBox(height: 16),

                // Phone field (optional)
                CustomTextField(
                  controller: _phoneController.value,
                  label:
                      '${s.regPhone} (${s.commonOptional})',
                  hint: '01XXXXXXXXX',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                ),

                const SizedBox(height: 16),

                // Password field
                CustomTextField(
                  controller: _passwordController.value,
                  label: s.regPassword,
                  hint:
                      s.regPassHint,
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
                      return '${s.regPassword} ${s.validationRequired}';
                    }
                    if (value.length < 6) {
                      return s.validationPassLength;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Confirm password field
                CustomTextField(
                  controller: _confirmPasswordController.value,
                  label: s.regConfirmPass,
                  hint: '••••••••',
                  obscureText: _obscureConfirmPassword.value,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscureConfirmPassword.value =
                          !_obscureConfirmPassword.value);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '${s.regConfirmPass} ${s.validationRequired}';
                    }
                    if (value != _passwordController.value.text) {
                      return s.validationPassMatch;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Register button
                CustomButton(
                  text: s.regButton,
                  onPressed: _isLoading
                      ? null
                      : () {
                          _handleRegister();
                        },
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 24),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      s.regHaveAccountText,
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
