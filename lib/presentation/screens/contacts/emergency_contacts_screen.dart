import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../model/emergency_contact_model.dart';
import '../../../provider/contact_provider.dart';
import '../../../provider/language_provider.dart';
import '../../../core/localization/app_strings.dart';
import '../../../routes/app_router.dart';

import '../../widgets/shimmer_loading.dart';
import '../../widgets/empty_state.dart';

class EmergencyContactsScreen extends ConsumerStatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  ConsumerState<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState
    extends ConsumerState<EmergencyContactsScreen> with RestorationMixin {
  final RestorableDouble _scrollOffset = RestorableDouble(0);
  late final ScrollController _scrollController;

  @override
  String? get restorationId => 'emergency_contacts_screen';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        _scrollOffset.value = _scrollController.offset;
      });
    // Silently refresh contacts in background to check for multi-device sync
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(contactProvider.notifier).loadContacts(silent: true);
    });
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_scrollOffset, 'scroll_offset');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollOffset.value);
      }
    });
  }

  @override
  void dispose() {
    _scrollOffset.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactState = ref.watch(contactProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.contactsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context, s),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddContact(context, s),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: _buildBody(context, contactState, isDark, s),
    );
  }

  Widget _buildBody(
      BuildContext context, ContactState state, bool isDark, AppStrings s) {
    if (state is ContactLoading) {
      return const ShimmerList(itemCount: 4);
    }

    if (state is ContactError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(s.error, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  ref.read(contactProvider.notifier).loadContacts(),
              child: Text(s.retry),
            ),
          ],
        ),
      );
    }

    if (state is ContactLoaded && state.contacts.isEmpty) {
      return EmptyState(
        icon: Icons.contacts_outlined,
        title: s.contactsEmpty,
        description: s.contactsEmptyDesc,
        buttonText: s.contactsAdd,
        onButtonPressed: () => _openAddContact(context, s),
      );
    }

    final contacts =
        state is ContactLoaded ? state.contacts : <EmergencyContactModel>[];

    return ReorderableListView.builder(
      key: const PageStorageKey('contacts_scroll'),
      scrollController: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: contacts.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        final ids = contacts.map((c) => c.id).toList();
        final movedId = ids.removeAt(oldIndex);
        ids.insert(newIndex, movedId);
        ref
            .read(contactProvider.notifier)
            .reorderContacts(ids)
            .catchError((_) {});
      },
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return _buildContactCard(context, contact, index, isDark, s);
      },
    );
  }

  Widget _buildContactCard(BuildContext context, EmergencyContactModel contact,
      int index, bool isDark, AppStrings s) {
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
      confirmDismiss: (_) => _showDeleteConfirm(context, s),
      onDismissed: (_) {
        ref
            .read(contactProvider.notifier)
            .deleteContact(contact.id)
            .catchError((_) {});
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
                    // ignore: deprecated_member_use
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
                      style: const TextStyle(
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
                          // ignore: deprecated_member_use
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
                  // ignore: deprecated_member_use
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

  Future<bool?> _showDeleteConfirm(BuildContext context, AppStrings s) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.contactsDeleteConfirm),
        content: Text(s.contactsDeleteAsk),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.contactsDeleteBtn,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddContact(BuildContext context, AppStrings s) async {
    final notifier = ref.read(contactProvider.notifier);
    final maxContacts = await notifier.getMaxEmergencyContacts();
    if (!context.mounted) return;
    final canAddMore = await notifier.canAddMoreContacts();
    if (!context.mounted) return;
    if (!canAddMore) {
      await _showContactLimitDialog(context, s, maxContacts);
      return;
    }

    if (!context.mounted) return;
    context.push(Routes.addContact);
  }

  Future<void> _showContactLimitDialog(
      BuildContext context, AppStrings s, int maxContacts) {
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

  void _showInfoDialog(BuildContext context, AppStrings s) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.contactsTitle),
        content: Text(s.contactsInfoDesc),
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
