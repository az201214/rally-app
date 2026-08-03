import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/player_profile.dart';
import '../domain/player_profile_repository.dart';
import '../domain/profile_failure.dart';

class FirestorePlayerProfileRepository implements PlayerProfileRepository {
  FirestorePlayerProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _document(String uid) =>
      _firestore.collection('users').doc(uid);

  @override
  Stream<PlayerProfile?> watchProfile(String uid) =>
      _document(uid).snapshots().map(
        (snapshot) => snapshot.exists
            ? PlayerProfile.fromMap(snapshot.data()!, uid: snapshot.id)
            : null,
      );

  @override
  Future<PlayerProfile?> loadProfile(String uid) async {
    try {
      final snapshot = await _document(uid).get();
      final data = snapshot.data();
      return data == null ? null : PlayerProfile.fromMap(data, uid: uid);
    } on FirebaseException catch (error) {
      throw ProfileFailure(_message(error));
    }
  }

  @override
  Future<void> createProfile(PlayerProfile profile) async {
    try {
      final data = profile.toMap()
        ..['createdAt'] = FieldValue.serverTimestamp()
        ..['updatedAt'] = FieldValue.serverTimestamp();
      await _document(profile.uid).set(data);
    } on FirebaseException catch (error) {
      throw ProfileFailure(_message(error));
    }
  }

  @override
  Future<void> updateProfile(PlayerProfile profile) async {
    try {
      final data = profile.toMap()
        ..remove('uid')
        ..remove('email')
        ..remove('createdAt')
        ..['updatedAt'] = FieldValue.serverTimestamp();
      await _document(profile.uid).update(data);
    } on FirebaseException catch (error) {
      throw ProfileFailure(_message(error));
    }
  }

  static String _message(FirebaseException error) => switch (error.code) {
    'unavailable' =>
      'You appear to be offline. Your profile could not be updated.',
    'permission-denied' => 'Your session expired. Please log in again.',
    'not-found' => 'Your player profile could not be found.',
    _ => 'Your profile could not be saved. Please try again.',
  };
}
