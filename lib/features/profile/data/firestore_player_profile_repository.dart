import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/player_profile.dart';
import '../domain/player_profile_repository.dart';
import '../domain/profile_failure.dart';

class FirestorePlayerProfileRepository implements PlayerProfileRepository {
  FirestorePlayerProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _document(String uid) =>
      _firestore.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> _publicDocument(String uid) =>
      _firestore.collection('publicProfiles').doc(uid);

  @override
  Stream<PlayerProfile?> watchProfile(String uid) =>
      _document(uid).snapshots().map(
        (snapshot) => snapshot.exists
            ? PlayerProfile.fromMap(snapshot.data()!, uid: snapshot.id)
            : null,
      );

  @override
  Stream<PlayerProfile?> watchPublicProfile(String uid) =>
      _publicDocument(uid).snapshots().map(
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
      final batch = _firestore.batch()
        ..set(_document(profile.uid), data)
        ..set(_publicDocument(profile.uid), _publicData(profile));
      await batch.commit();
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
      final batch = _firestore.batch()
        ..update(_document(profile.uid), data)
        ..set(
          _publicDocument(profile.uid),
          _publicData(profile),
          SetOptions(merge: true),
        );
      await batch.commit();
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

  static Map<String, Object?> _publicData(PlayerProfile profile) =>
      <String, Object?>{
        'uid': profile.uid,
        'fullName': profile.fullName,
        'photoUrl': profile.photoUrl,
        'bio': profile.bio,
        'city': profile.city,
        'skillLevel': profile.skillLevel,
        'preferredSide': profile.preferredSide,
        'playingHand': profile.playingHand,
        'playingStyle': profile.playingStyle,
        'preferredDays': profile.preferredDays,
        'preferredTimeRanges': profile.preferredTimeRanges,
        'preferredClubIds': profile.preferredClubIds,
        'favoriteClubIds': profile.favoriteClubIds,
        'verificationStatus': profile.hasTrustedVerification
            ? 'verified'
            : 'unverified',
        'createdAt': profile.createdAt,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
