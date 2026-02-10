import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_widget.dart';
import '../../../provider/auth_provider.dart';
import 'package:are_you_okay/routes/app_router.dart';

/// Edit Profile Screen
/// Allows user to update their profile information
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  String? _selectedBloodGroup;
  int _selectedInterval = 24;

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).maybeWhen(
      authenticated: (u) => u,
      orElse: () => null,
    );
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _selectedBloodGroup = user?.bloodGroup;
    _selectedInterval = user?.checkinInterval ?? 24;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('প্রোফাইল সম্পাদন'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: AppColors.primary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Change image
                      },
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('ছবি পরিবর্তন করুন'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              CustomTextField(
                controller: _nameController,
                label: 'সম্পূর্ণ নাম',
                hint: 'আপনার নাম লিখুন',
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'নাম প্রয়োজন';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _emailController,
                label: 'ইমেইল (ঐচ্ছিক)',
                hint: 'আপনার ইমেইল লিখুন',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _addressController,
                label: 'ঠিকানা',
                hint: 'আপনার বর্তমান ঠিকানা লিখুন',
                prefixIcon: Icons.location_on_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Blood Group
              const Text(
                'রক্তের গ্রুপ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedBloodGroup,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.bloodtype, color: AppColors.primary),
                ),
                items: _bloodGroups.map((group) {
                  return DropdownMenuItem(
                    value: group,
                    child: Text(group),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBloodGroup = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Check-in Interval
              const Text(
                'চেক-ইন ইন্টারভাল (ঘণ্টা)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Slider(
                value: _selectedInterval.toDouble(),
                min: 1,
                max: 72,
                divisions: 71,
                label: '$_selectedInterval ঘণ্টা',
                onChanged: (value) {
                  setState(() {
                    _selectedInterval = value.round();
                  });
                },
              ),
              Center(
                child: Text(
                  'প্রতি $_selectedInterval ঘণ্টা পর পর অ্যাপে চেক-ইন করতে হবে।',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              CustomButton(
                text: 'তথ্য সংরক্ষণ করুন',
                onPressed: _saveProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement actual save logic via authProvider or userRepository
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('আপনার প্রোফাইল সফলভাবে আপডেট করা হয়েছে।')),
      );
      Navigator.pop(context);
    }
  }
}
