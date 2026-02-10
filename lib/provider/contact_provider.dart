import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/emergency_contact_model.dart';
import '../repository/contact_repository.dart';

// Contact State
abstract class ContactState {
  const ContactState();
}

class ContactInitial extends ContactState {
  const ContactInitial();
}

class ContactLoading extends ContactState {
  const ContactLoading();
}

class ContactLoaded extends ContactState {
  final List<EmergencyContactModel> contacts;
  const ContactLoaded(this.contacts);
}

class ContactError extends ContactState {
  final String message;
  const ContactError(this.message);
}

// Contact Notifier
class ContactNotifier extends StateNotifier<ContactState> {
  final ContactRepository _repository;

  ContactNotifier(this._repository) : super(const ContactInitial()) {
    loadContacts();
  }

  Future<void> loadContacts() async {
    try {
      state = const ContactLoading();
      final contacts = _repository.getAllContacts();
      state = ContactLoaded(contacts);
    } catch (e) {
      state = ContactError(e.toString());
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
      state = const ContactLoading();
      
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
      state = ContactError(e.toString());
    }
  }

  Future<void> updateContact(EmergencyContactModel contact) async {
    try {
      state = const ContactLoading();
      await _repository.updateContact(contact);
      await loadContacts();
    } catch (e) {
      state = ContactError(e.toString());
    }
  }

  Future<void> deleteContact(String id) async {
    try {
      state = const ContactLoading();
      await _repository.deleteContact(id);
      await loadContacts();
    } catch (e) {
      state = ContactError(e.toString());
    }
  }

  Future<void> reorderContacts(List<String> orderedIds) async {
    try {
      state = const ContactLoading();
      await _repository.reorderContacts(orderedIds);
      await loadContacts();
    } catch (e) {
      state = ContactError(e.toString());
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
  if (state is ContactLoaded) {
    return state.contacts;
  }
  return [];
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