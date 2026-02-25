import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
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
  File? _selectedImage;
  String? _existingImageUrl;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _selectedBloodGroup = user?.bloodGroup;
    _selectedInterval = user?.checkinInterval ?? 24;
    _existingImageUrl = user?.profilePicture;
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
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty
                              ? (_existingImageUrl!.startsWith('data:image') 
                                  ? MemoryImage(base64Decode(_existingImageUrl!.split(',').last)) as ImageProvider
                                  : NetworkImage(_existingImageUrl!))
                              : null),
                      child: (_selectedImage == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty))
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: AppColors.primary,
                            )
                          : null,
                    ),
                    TextButton.icon(
                      onPressed: _pickImage,
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

              // // Check-in Interval
              // const Text(
              //   'চেক-ইন ইন্টারভাল (ঘণ্টা)',
              //   style: TextStyle(
              //     fontSize: 14,
              //     fontWeight: FontWeight.w600,
              //     color: AppColors.textPrimary,
              //   ),
              // ),
              // const SizedBox(height: 8),
              // Slider(
              //   value: _selectedInterval.toDouble(),
              //   min: 1,
              //   max: 72,
              //   divisions: 71,
              //   label: '$_selectedInterval ঘণ্টা',
              //   onChanged: (value) {
              //     setState(() {
              //       _selectedInterval = value.round();
              //     });
              //   },
              // ),
              // Center(
              //   child: Text(
              //     'প্রতি $_selectedInterval ঘণ্টা পর পর অ্যাপে চেক-ইন করতে হবে।',
              //     style: const TextStyle(
              //       fontSize: 12,
              //       color: AppColors.textSecondary,
              //     ),
              //   ),
              // ),
              const SizedBox(height: 40),

              CustomButton(
                text: 'তথ্য সংরক্ষণ করুন',
                isLoading: _isSaving,
                onPressed: _saveProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSaving = false;

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        String? base64Image;
        if (_selectedImage != null) {
          final bytes = await _selectedImage!.readAsBytes();
          base64Image = 'data:image/jpeg;base64,' + base64Encode(bytes);
        }

        // Update profile on backend
        await ref.read(authProvider.notifier).updateProfile(
          name: _nameController.text.trim(),
          phone: null, // phone is read-only on this screen
          address: _addressController.text.trim(),
          bloodGroup: _selectedBloodGroup,
          profilePicture: base64Image,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('আপনার প্রোফাইল সফলভাবে আপডেট করা হয়েছে।'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('প্রোফাইল আপডেট ব্যর্থ: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }
}
