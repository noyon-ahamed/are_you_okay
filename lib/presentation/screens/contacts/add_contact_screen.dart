import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
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

class _AddContactScreenState extends ConsumerState<AddContactScreen>
    with RestorationMixin {
  final _formKey = GlobalKey<FormState>();
  final RestorableTextEditingController _nameController =
      RestorableTextEditingController();
  final RestorableTextEditingController _phoneController =
      RestorableTextEditingController();
  final RestorableTextEditingController _relationshipController =
      RestorableTextEditingController();
  final RestorableTextEditingController _emailController =
      RestorableTextEditingController();
  final RestorableInt _selectedPriority = RestorableInt(1);
  final RestorableBool _notifyViaSMS = RestorableBool(true);
  final RestorableBool _notifyViaEmail = RestorableBool(true);
  final RestorableDouble _scrollOffset = RestorableDouble(0);
  late final ScrollController _scrollController;

  @override
  String? get restorationId => 'add_contact_screen';

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
    registerForRestoration(_phoneController, 'phone');
    registerForRestoration(_relationshipController, 'relationship');
    registerForRestoration(_emailController, 'email');
    registerForRestoration(_selectedPriority, 'priority');
    registerForRestoration(_notifyViaSMS, 'notify_sms');
    registerForRestoration(_notifyViaEmail, 'notify_email');
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
    _phoneController.dispose();
    _relationshipController.dispose();
    _emailController.dispose();
    _selectedPriority.dispose();
    _notifyViaSMS.dispose();
    _notifyViaEmail.dispose();
    _scrollOffset.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contactCount = ref.watch(contactListProvider).length;
    final maxContactsAsync = ref.watch(maxEmergencyContactsProvider);
    final maxContacts =
        maxContactsAsync.value ?? AppConstants.maxEmergencyContacts;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.contactsNewContact),
      ),
      body: SingleChildScrollView(
        key: const PageStorageKey('add_contact_scroll'),
        controller: _scrollController,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceVariantDark
                      : AppColors.primaryLight.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.primary,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.contactsFormIntro,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.contactsCounterLabel(contactCount, maxContacts),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _nameController.value,
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
                controller: _phoneController.value,
                label: s.contactsPhone,
                hint: s.contactsPhoneHint,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(
                    AppConstants.phoneNumberLength,
                  ),
                ],
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final normalized = value?.trim() ?? '';
                  if (normalized.isEmpty) {
                    return s.contactsPhoneReq;
                  }
                  if (!_isValidPhoneNumber(normalized)) {
                    return s.contactsPhoneInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _relationshipController.value,
                label: s.contactsRelation,
                hint: s.contactsRelationHint,
                prefixIcon: Icons.people_outline,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return s.contactsRelationReq;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _emailController.value,
                label: s.contactsEmailMissedAlert,
                hint: s.contactsEmailOptional,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  final normalized = value?.trim() ?? '';
                  if (normalized.isEmpty) {
                    return null;
                  }
                  if (!_isValidEmail(normalized)) {
                    return s.validationEmailInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Priority
              Text(
                s.contactsPriorityLevel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [1, 2, 3, 4, 5].map((p) {
                  final isSelected = _selectedPriority.value == p;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPriority.value = p),
                    child: Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.surfaceVariantDark
                                : AppColors.surface),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.borderDark
                                  : AppColors.divider),
                        ),
                      ),
                      child: Text(
                        p.toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                s.contactsPriorityDesc,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Notification Methods
              Text(
                s.contactsNotifType,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: Text(s.contactsNotifySMS),
                value: _notifyViaSMS.value,
                onChanged: (value) =>
                    setState(() => _notifyViaSMS.value = value),
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: Text(s.contactsNotifyEmail),
                value: _notifyViaEmail.value,
                onChanged: (value) =>
                    setState(() => _notifyViaEmail.value = value),
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
    final notifier = ref.read(contactProvider.notifier);
    final maxContacts = await notifier.getMaxEmergencyContacts();
    if (!await notifier.canAddMoreContacts()) {
      await _showContactLimitDialog(s, maxContacts);
      return;
    }

    if (_formKey.currentState!.validate()) {
      final name = _nameController.value.text.trim();
      final phone = _phoneController.value.text.trim();
      final relation = _relationshipController.value.text.trim();
      final email = _emailController.value.text.trim();

      try {
        await ref.read(contactProvider.notifier).addContact(
              name: name,
              phoneNumber: phone,
              email: email.isEmpty ? null : email,
              relationship: relation,
              priority: _selectedPriority.value,
              notifyViaSMS: _notifyViaSMS.value,
              notifyViaEmail: _notifyViaEmail.value && email.isNotEmpty,
              notifyViaApp: false,
            );

        if (mounted) {
          final messenger = ScaffoldMessenger.of(context);
          Navigator.pop(context);
          messenger.showSnackBar(
            SnackBar(content: Text(s.contactsAddedToast)),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  bool _isValidPhoneNumber(String phone) {
    return phone.length == AppConstants.phoneNumberLength &&
        phone.startsWith(AppConstants.phoneNumberPrefix);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  Future<void> _showContactLimitDialog(dynamic s, int maxContacts) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.contactsLimitTitle),
        content: Text(s.contactsLimitMessage(maxContacts)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.ok),
          ),
        ],
      ),
    );
  }
}
