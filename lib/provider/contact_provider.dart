import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../model/emergency_contact_model.dart';
import '../repository/contact_repository.dart';

part 'contact_provider.freezed.dart';

// Contact State
@freezed
class ContactState with _$ContactState {
  const factory ContactState.initial() = _Initial;
  const factory ContactState.loading() = _Loading;
  const factory ContactState.loaded(List<EmergencyContactModel> contacts) =
      _Loaded;
  const factory ContactState.error(String message) = _Error;
}

// Contact Notifier
class ContactNotifier extends StateNotifier<ContactState> {
  final ContactRepository _repository;

  ContactNotifier(this._repository) : super(const ContactState.initial()) {
    loadContacts();
  }

  Future<void> loadContacts() async {
    try {
      state = const ContactState.loading();
      final contacts = _repository.getAllContacts();
      state = ContactState.loaded(contacts);
    } catch (e) {
      state = ContactState.error(e.toString());
    }
  }

  Future<void> addContact({
    required String name,
    required String phoneNumber,
    required String relationship,
    int priority = 1,
    bool notifyViaSMS = true,
    bool notifyViaCall = false,
    bool notifyViaApp = true,
  }) async {
    try {
      state = const ContactState.loading();
      
      await _repository.addContact(
        name: name,
        phoneNumber: phoneNumber,
        relationship: relationship,
        priority: priority,
        notifyViaSMS: notifyViaSMS,
        notifyViaCall: notifyViaCall,
        notifyViaApp: notifyViaApp,
      );
      
      await loadContacts();
    } catch (e) {
      state = ContactState.error(e.toString());
    }
  }

  Future<void> updateContact(EmergencyContactModel contact) async {
    try {
      state = const ContactState.loading();
      await _repository.updateContact(contact);
      await loadContacts();
    } catch (e) {
      state = ContactState.error(e.toString());
    }
  }

  Future<void> deleteContact(String id) async {
    try {
      state = const ContactState.loading();
      await _repository.deleteContact(id);
      await loadContacts();
    } catch (e) {
      state = ContactState.error(e.toString());
    }
  }

  Future<void> reorderContacts(List<String> orderedIds) async {
    try {
      state = const ContactState.loading();
      await _repository.reorderContacts(orderedIds);
      await loadContacts();
    } catch (e) {
      state = ContactState.error(e.toString());
    }
  }

  bool canAddMoreContacts() {
    return _repository.canAddMoreContacts();
  }

  int getContactCount() {
    return _repository.getContactCount();
  }
}

// Providers
final contactProvider =
    StateNotifierProvider<ContactNotifier, ContactState>((ref) {
  return ContactNotifier(ref.watch(contactRepositoryProvider));
});

// Provider for contact list
final contactListProvider = Provider<List<EmergencyContactModel>>((ref) {
  final state = ref.watch(contactProvider);
  return state.maybeWhen(
    loaded: (contacts) => contacts,
    orElse: () => [],
  );
});

// Provider for single contact
final singleContactProvider =
    Provider.family<EmergencyContactModel?, String>((ref, id) {
  final contacts = ref.watch(contactListProvider);
  try {
    return contacts.firstWhere((c) => c.id == id);
  } catch (e) {
    return null;
  }
});

// Provider for notification contacts
final notificationContactsProvider =
    Provider<List<EmergencyContactModel>>((ref) {
  final repository = ref.watch(contactRepositoryProvider);
  return repository.getNotificationContacts();
});