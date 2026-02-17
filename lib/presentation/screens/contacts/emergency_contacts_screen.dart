import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../model/emergency_contact_model.dart';
import '../../../provider/contact_provider.dart';
import '../../../routes/app_router.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/empty_state.dart';

class EmergencyContactsScreen extends ConsumerWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactState = ref.watch(contactProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('জরুরি যোগাযোগ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddContactSheet(context, ref),
        icon: const Icon(Icons.person_add),
        label: Text('যোগ করুন',
            style: TextStyle(fontFamily: 'HindSiliguri', fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(context, ref, contactState, isDark),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ContactState state, bool isDark) {
    if (state is ContactLoading) {
      return const ShimmerList(itemCount: 4);
    }

    if (state is ContactError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('ত্রুটি হয়েছে',
                style: TextStyle(fontFamily: 'HindSiliguri', fontSize: 16)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  ref.read(contactProvider.notifier).loadContacts(),
              child: Text('আবার চেষ্টা',
                  style: TextStyle(fontFamily: 'HindSiliguri')),
            ),
          ],
        ),
      );
    }

    if (state is ContactLoaded && state.contacts.isEmpty) {
      return EmptyState(
        icon: Icons.contacts_outlined,
        title: 'কোনো জরুরি যোগাযোগ নেই',
        description: 'আপনার প্রিয়জনদের জরুরি যোগাযোগ\nহিসেবে যোগ করুন',
        buttonText: 'যোগ করুন',
        onButtonPressed: () => _showAddContactSheet(context, ref),
      );
    }

    final contacts =
        state is ContactLoaded ? state.contacts : <EmergencyContactModel>[];

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: contacts.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        final ids =
            contacts.map((c) => c.id).toList();
        final movedId = ids.removeAt(oldIndex);
        ids.insert(newIndex, movedId);
        ref.read(contactProvider.notifier).reorderContacts(ids);
      },
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return _buildContactCard(context, ref, contact, index, isDark);
      },
    );
  }



  Widget _buildContactCard(BuildContext context, WidgetRef ref,
      EmergencyContactModel contact, int index, bool isDark) {
    final colors = [
      const Color(0xFF6C63FF),
      const Color(0xFF00BCD4),
      const Color(0xFFFF9800),
      const Color(0xFF4CAF50),
      AppColors.primary,
    ];
    final color = colors[index % colors.length];

    return Dismissible(
      key: Key(contact.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => _showDeleteConfirm(context),
      onDismissed: (_) {
        ref.read(contactProvider.notifier).deleteContact(contact.id);
      },
      child: Container(
        key: ValueKey(contact.id),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: AppDecorations.cardDecoration(context: context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    contact.name.isNotEmpty
                        ? contact.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: TextStyle(
                        fontFamily: 'HindSiliguri',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contact.phoneNumber,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (contact.relationship.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          contact.relationship,
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontFamily: 'HindSiliguri',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Priority badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#${contact.priority}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Drag handle
              Icon(
                Icons.drag_handle,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text('মুছে ফেলুন', style: TextStyle(fontFamily: 'HindSiliguri')),
        content: Text('এই যোগাযোগ মুছে ফেলতে চান?',
            style: TextStyle(fontFamily: 'HindSiliguri')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('বাতিল', style: TextStyle(fontFamily: 'HindSiliguri')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('মুছুন',
                style: TextStyle(
                    fontFamily: 'HindSiliguri', color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showAddContactSheet(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'নতুন যোগাযোগ',
              style: TextStyle(
                fontFamily: 'HindSiliguri',
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'নাম',
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'ফোন নম্বর',
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: relationController,
              decoration: InputDecoration(
                labelText: 'সম্পর্ক (যেমন: মা, বাবা, বন্ধু)',
                prefixIcon: const Icon(Icons.family_restroom_outlined),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty &&
                      phoneController.text.isNotEmpty) {
                    ref.read(contactProvider.notifier).addContact(
                          name: nameController.text.trim(),
                          phoneNumber: phoneController.text.trim(),
                          relationship: relationController.text.trim(),
                        );
                    Navigator.pop(context);
                  }
                },
                child: Text('যোগ করুন',
                    style: TextStyle(fontFamily: 'HindSiliguri')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('জরুরি যোগাযোগ',
            style: TextStyle(fontFamily: 'HindSiliguri')),
        content: Text(
          'জরুরি সময়ে এই যোগাযোগকারীদের SMS ও নোটিফিকেশন পাঠানো হবে। '
          'ড্র্যাগ করে অগ্রাধিকার পরিবর্তন করুন।\n\n'
          'বামে সোয়াইপ করে মুছুন।',
          style: TextStyle(fontFamily: 'HindSiliguri'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('বুঝেছি', style: TextStyle(fontFamily: 'HindSiliguri')),
          ),
        ],
      ),
    );
  }
}
