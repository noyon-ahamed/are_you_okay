import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../model/emergency_contact_model.dart';
import '../../../provider/contact_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'package:are_you_okay/routes/app_router.dart';

/// Add Contact Screen
/// Allows user to add a new emergency contact
class AddContactScreen extends ConsumerStatefulWidget {
  const AddContactScreen({super.key});

  @override
  ConsumerState<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends ConsumerState<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationshipController = TextEditingController();
  int _selectedPriority = 1;
  bool _notifyViaSMS = true;
  bool _notifyViaApp = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('নতুন কন্টাক্ট'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _nameController,
                label: 'নাম',
                hint: 'ব্যক্তির নাম লিখুন',
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
                controller: _phoneController,
                label: 'ফোন নম্বর',
                hint: '01XXXXXXXXX',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'ফোন নম্বর প্রয়োজন';
                  }
                  if (value.length < 11) {
                    return 'সঠিক ফোন নম্বর লিখুন';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _relationshipController,
                label: 'সম্পর্ক',
                hint: 'যেমন: বাবা, মা, ভাই, বন্ধু',
                prefixIcon: Icons.people_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'সম্পর্ক উল্লেখ করুন';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Priority
              const Text(
                'অগ্রাধিকার লেভেল',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [1, 2, 3, 4, 5].map((p) {
                  final isSelected = _selectedPriority == p;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPriority = p),
                    child: Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.divider,
                        ),
                      ),
                      child: Text(
                        p.toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              const Text(
                '১ নং অগ্রাধিকার সবচেয়ে বেশি গুরুত্বপূর্ণ।',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Notification Methods
              const Text(
                'বিজ্ঞপ্তির ধরণ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('SMS এর মাধ্যমে জানান'),
                value: _notifyViaSMS,
                onChanged: (value) => setState(() => _notifyViaSMS = value),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text('অ্যাপ বিজ্ঞপ্তির মাধ্যমে জানান'),
                value: _notifyViaApp,
                onChanged: (value) => setState(() => _notifyViaApp = value),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 40),

              CustomButton(
                text: 'কন্টাক্ট যোগ করুন',
                onPressed: _saveContact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveContact() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(contactProvider.notifier).addContact(
            name: _nameController.text,
            phoneNumber: _phoneController.text,
            relationship: _relationshipController.text,
            priority: _selectedPriority,
            notifyViaSMS: _notifyViaSMS,
            notifyViaApp: _notifyViaApp,
          );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('নতুন কন্টাক্ট যোগ করা হয়েছে।')),
        );
      }
    }
  }
}
