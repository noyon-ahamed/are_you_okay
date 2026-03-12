import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../provider/contact_provider.dart';
import '../../../provider/language_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

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
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.contactsNewContact),
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
                label: s.contactsName,
                hint: s.contactsNameHint,
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return s.contactsNameReq;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _phoneController,
                label: s.contactsPhone,
                hint: s.contactsPhoneHint,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return s.contactsPhoneReq;
                  }
                  if (value.length < 11) {
                    return s.contactsPhoneInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _relationshipController,
                label: s.contactsRelation,
                hint: s.contactsRelationHint,
                prefixIcon: Icons.people_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return s.contactsRelationReq;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Priority
              Text(
                s.contactsPriorityLevel,
                style: const TextStyle(
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
                        color:
                            isSelected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.divider,
                        ),
                      ),
                      child: Text(
                        p.toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                s.contactsPriorityDesc,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Notification Methods
              Text(
                s.contactsNotifType,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: Text(s.contactsNotifySMS),
                value: _notifyViaSMS,
                onChanged: (value) => setState(() => _notifyViaSMS = value),
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: Text(s.contactsNotifyApp),
                value: _notifyViaApp,
                onChanged: (value) => setState(() => _notifyViaApp = value),
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 40),

              CustomButton(
                text: s.contactsAdd,
                onPressed: _saveContact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveContact() async {
    final s = ref.read(stringsProvider);
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
          SnackBar(content: Text(s.contactsAddedToast)),
        );
      }
    }
  }
}
