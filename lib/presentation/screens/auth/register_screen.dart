import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/api/auth_api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthApiService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty 
            ? _phoneController.text.trim() 
            : null,
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('নিবন্ধন সফল! আপনার ইমেইল যাচাই করুন।'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('নিবন্ধন'),
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
                
                // Name field
                CustomTextField(
                  controller: _nameController,
                  label: 'নাম',
                  hint: 'আপনার নাম',
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'নাম দিন';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Email field
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
                
                const SizedBox(height: 16),
                
                // Phone field (optional)
                CustomTextField(
                  controller: _phoneController,
                  label: 'ফোন (ঐচ্ছিক)',
                  hint: '+880...',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                ),
                
                const SizedBox(height: 16),
                
                // Password field
                CustomTextField(
                  controller: _passwordController,
                  label: 'পাসওয়ার্ড',
                  hint: 'কমপক্ষে ৬ অক্ষর',
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'পাসওয়ার্ড দিন';
                    }
                    if (value.length < 6) {
                      return 'কমপক্ষে ৬ অক্ষর দিন';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Confirm password field
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'পাসওয়ার্ড নিশ্চিত করুন',
                  hint: '••••••••',
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'পাসওয়ার্ড নিশ্চিত করুন';
                    }
                    if (value != _passwordController.text) {
                      return 'পাসওয়ার্ড মিলছে না';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Register button
                CustomButton(
                  text: 'নিবন্ধন করুন',
                  onPressed: _isLoading ? null : _handleRegister,
                  isLoading: _isLoading,
                ),
                
                const SizedBox(height: 24),
                
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'ইতিমধ্যে অ্যাকাউন্ট আছে? ',
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