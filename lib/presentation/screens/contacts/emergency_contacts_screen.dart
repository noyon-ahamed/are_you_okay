import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../model/emergency_contact_model.dart';
import '../../../provider/contact_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/custom_button.dart';
import '../../routes/app_router.dart';

/// Emergency Contacts Screen
/// Manage emergency contacts
class EmergencyContactsScreen extends ConsumerWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('জরুরি যোগাযোগ'),
      ),
      body: contactsAsync.when(
        initial: () => const Center(child: CircularProgressIndicator()),
        loading: () => const Center(child: CircularProgressIndicator()),
        loaded: (contacts) {
          if (contacts.isEmpty) {
            return EmptyStateWidget(
              title: 'কোন জরুরি যোগাযোগ নেই',
              description: 'আপনার প্রিয়জনদের যোগ করুন যারা জরুরি অবস্থায় অবহিত হবেন।',
              icon: Icons.contact_phone_outlined,
              actionLabel: 'যোগাযোগ যোগ করুন',
              onAction: () {
                Navigator.pushNamed(context, '/add-contact');
              },
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return _ContactCard(
                      contact: contact,
                      onEdit: () {
                        // TODO: Navigate to edit contact
                      },
                      onDelete: () async {
                        final confirm = await _showDeleteDialog(context);
                        if (confirm && context.mounted) {
                          ref
                              .read(contactProvider.notifier)
                              .deleteContact(contact.id!);
                        }
                      },
                      onTest: () {
                        _showTestContactDialog(context, contact);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: CustomButton(
                  text: 'নতুন যোগাযোগ যোগ করুন',
                  onPressed: () {
                    Navigator.pushNamed(context, '/add-contact');
                  },
                  icon: Icons.person_add,
                ),
              ),
            ],
          );
        },
        error: (message) => Center(
          child: Text('ত্রুটি: $message'),
        ),
      ),
    );
  }

  Future<bool> _showDeleteDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('মুছে ফেলবেন?'),
            content: const Text('আপনি কি এই যোগাযোগটি মুছে ফেলতে চান?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('না'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
                child: const Text('হ্যাঁ'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showTestContactDialog(
    BuildContext context,
    EmergencyContactModel contact,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('টেস্ট বার্তা'),
        content: Text(
          'একটি টেস্ট বার্তা ${contact.name} কে পাঠানো হবে।'
          '\nফোন: ${contact.phoneNumber}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Send test message
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('টেস্ট বার্তা পাঠানো হয়েছে')),
              );
            },
            child: const Text('পাঠান'),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final EmergencyContactModel contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTest;

  const _ContactCard({
    required this.contact,
    required this.onEdit,
    required this.onDelete,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    contact.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contact.relationship,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(contact.priority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'অগ্রাধিকার ${contact.priority}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getPriorityColor(contact.priority),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.phone,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    contact.phoneNumber,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Notification methods
            Wrap(
              spacing: 8,
              children: [
                if (contact.notifyViaSMS)
                  Chip(
                    label: const Text('SMS'),
                    avatar: const Icon(Icons.sms, size: 16),
                    backgroundColor: AppColors.success.withOpacity(0.1),
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                    ),
                  ),
                if (contact.notifyViaApp)
                  Chip(
                    label: const Text('অ্যাপ'),
                    avatar: const Icon(Icons.notifications, size: 16),
                    backgroundColor: AppColors.info.withOpacity(0.1),
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      color: AppColors.info,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTest,
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('টেস্ট'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('সম্পাদনা'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.info,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('মুছুন'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return AppColors.danger;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }
}
