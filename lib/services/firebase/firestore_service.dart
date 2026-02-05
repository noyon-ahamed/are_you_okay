import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/firebase_config.dart';

/// Firestore Service
/// Handles all Firestore database operations
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersRef =>
      _firestore.collection(FirebaseConfig.usersCollection);
  CollectionReference get _alertsRef =>
      _firestore.collection(FirebaseConfig.alertsCollection);
  CollectionReference get _appSettingsRef =>
      _firestore.collection(FirebaseConfig.appSettingsCollection);

  /// User Operations

  /// Get user document reference
  DocumentReference getUserDoc(String userId) => _usersRef.doc(userId);

  /// Create user document
  Future<void> createUser(String userId, Map<String, dynamic> data) async {
    try {
      await _usersRef.doc(userId).set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  /// Get user data
  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error getting user: $e');
      rethrow;
    }
  }

  /// Update user data
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _usersRef.doc(userId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  /// Delete user
  Future<void> deleteUser(String userId) async {
    try {
      await _usersRef.doc(userId).delete();
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    }
  }

  /// Stream user data
  Stream<DocumentSnapshot> streamUser(String userId) {
    return _usersRef.doc(userId).snapshots();
  }

  /// Emergency Contacts Operations

  /// Get emergency contacts collection reference
  CollectionReference _getEmergencyContactsRef(String userId) {
    return _usersRef
        .doc(userId)
        .collection(FirebaseConfig.emergencyContactsCollection);
  }

  /// Add emergency contact
  Future<String> addEmergencyContact(
    String userId,
    Map<String, dynamic> contactData,
  ) async {
    try {
      final docRef = await _getEmergencyContactsRef(userId).add({
        ...contactData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding emergency contact: $e');
      rethrow;
    }
  }

  /// Update emergency contact
  Future<void> updateEmergencyContact(
    String userId,
    String contactId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _getEmergencyContactsRef(userId).doc(contactId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating emergency contact: $e');
      rethrow;
    }
  }

  /// Delete emergency contact
  Future<void> deleteEmergencyContact(
    String userId,
    String contactId,
  ) async {
    try {
      await _getEmergencyContactsRef(userId).doc(contactId).delete();
    } catch (e) {
      debugPrint('Error deleting emergency contact: $e');
      rethrow;
    }
  }

  /// Get all emergency contacts
  Future<List<Map<String, dynamic>>> getEmergencyContacts(
    String userId,
  ) async {
    try {
      final snapshot = await _getEmergencyContactsRef(userId)
          .orderBy('priority')
          .get();
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      debugPrint('Error getting emergency contacts: $e');
      rethrow;
    }
  }

  /// Stream emergency contacts
  Stream<QuerySnapshot> streamEmergencyContacts(String userId) {
    return _getEmergencyContactsRef(userId)
        .orderBy('priority')
        .snapshots();
  }

  /// Check-in Operations

  /// Get check-ins collection reference
  CollectionReference _getCheckinsRef(String userId) {
    return _usersRef
        .doc(userId)
        .collection(FirebaseConfig.checkinsCollection);
  }

  /// Create check-in
  Future<String> createCheckin(
    String userId,
    Map<String, dynamic> checkinData,
  ) async {
    try {
      // Add check-in to sub-collection
      final docRef = await _getCheckinsRef(userId).add({
        ...checkinData,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update user's last check-in time
      await _usersRef.doc(userId).update({
        'lastCheckIn': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      debugPrint('Error creating check-in: $e');
      rethrow;
    }
  }

  /// Get check-in history
  Future<List<Map<String, dynamic>>> getCheckins(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _getCheckinsRef(userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      debugPrint('Error getting check-ins: $e');
      rethrow;
    }
  }

  /// Stream check-ins
  Stream<QuerySnapshot> streamCheckins(String userId, {int limit = 50}) {
    return _getCheckinsRef(userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Alert Operations

  /// Create alert
  Future<String> createAlert(Map<String, dynamic> alertData) async {
    try {
      final docRef = await _alertsRef.add({
        ...alertData,
        'triggeredAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating alert: $e');
      rethrow;
    }
  }

  /// Update alert status
  Future<void> updateAlertStatus(
    String alertId,
    String status, {
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == 'acknowledged') {
        updateData['acknowledgedAt'] = FieldValue.serverTimestamp();
      } else if (status == 'resolved') {
        updateData['resolvedAt'] = FieldValue.serverTimestamp();
      }

      if (notes != null) {
        updateData['notes'] = notes;
      }

      await _alertsRef.doc(alertId).update(updateData);
    } catch (e) {
      debugPrint('Error updating alert: $e');
      rethrow;
    }
  }

  /// Get user alerts
  Future<List<Map<String, dynamic>>> getUserAlerts(
    String userId, {
    String? status,
    int limit = 20,
  }) async {
    try {
      Query query = _alertsRef
          .where('userId', isEqualTo: userId)
          .orderBy('triggeredAt', descending: true)
          .limit(limit);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      debugPrint('Error getting alerts: $e');
      rethrow;
    }
  }

  /// Stream user alerts
  Stream<QuerySnapshot> streamUserAlerts(String userId) {
    return _alertsRef
        .where('userId', isEqualTo: userId)
        .orderBy('triggeredAt', descending: true)
        .limit(20)
        .snapshots();
  }

  /// App Settings Operations

  /// Get app settings
  Future<Map<String, dynamic>?> getAppSettings() async {
    try {
      final doc = await _appSettingsRef.doc('config').get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error getting app settings: $e');
      return null;
    }
  }

  /// Stream app settings
  Stream<DocumentSnapshot> streamAppSettings() {
    return _appSettingsRef.doc('config').snapshots();
  }

  /// Batch Operations

  /// Batch write
  Future<void> batchWrite(
    Future<void> Function(WriteBatch batch) operations,
  ) async {
    try {
      final batch = _firestore.batch();
      await operations(batch);
      await batch.commit();
    } catch (e) {
      debugPrint('Error in batch write: $e');
      rethrow;
    }
  }

  /// Transaction
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) operations,
  ) async {
    try {
      return await _firestore.runTransaction(operations);
    } catch (e) {
      debugPrint('Error in transaction: $e');
      rethrow;
    }
  }
}
