import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../../provider/auth_provider.dart';
import '../../../provider/language_provider.dart';

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

  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-'
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
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.profileEdit),
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
                          : (_existingImageUrl != null &&
                                  _existingImageUrl!.isNotEmpty
                              ? (_existingImageUrl!.startsWith('data:image')
                                  ? MemoryImage(base64Decode(
                                          _existingImageUrl!.split(',').last))
                                      as ImageProvider
                                  : NetworkImage(_existingImageUrl!))
                              : null),
                      child: (_selectedImage == null &&
                              (_existingImageUrl == null ||
                                  _existingImageUrl!.isEmpty))
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
                      label: Text(s.profileChangePic),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              CustomTextField(
                controller: _nameController,
                label: s.profileFullName,
                hint: s.profileNameHint,
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return s.profileNameReq;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _emailController,
                label: s.profileEmailOpt,
                hint: s.profileEmailHint,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _addressController,
                label: s.profileAddress,
                hint: s.profileAddressHint,
                prefixIcon: Icons.location_on_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Blood Group
              Text(
                s.profileBloodGroup,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedBloodGroup,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon:
                      const Icon(Icons.bloodtype, color: AppColors.primary),
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
                text: s.profileSaveInfo,
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
    final s = ref.read(stringsProvider);
    if (_formKey.currentState!.validate()) {
      // Check connectivity first
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.profileOfflineWarning,
                      style: const TextStyle(fontFamily: 'HindSiliguri'),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.warning,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      setState(() => _isSaving = true);
      try {
        String? base64Image;
        if (_selectedImage != null) {
          final bytes = await _selectedImage!.readAsBytes();
          base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
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
            SnackBar(
              content: Text(s.profileUpdateSuccess),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${s.profileUpdateFail} $e'),
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
