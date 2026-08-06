import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/club.dart';
import '../domain/club_repository.dart';

class FirestoreClubRepository implements ClubRepository {
  FirestoreClubRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<Club>> watchClubs() => _firestore
      .collection('clubs')
      .where('active', isEqualTo: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Club.fromMap(doc.id, doc.data()))
            .where((club) => club.name.isNotEmpty)
            .toList(growable: false),
      );

  @override
  Future<Club?> getClub(String id) async {
    final snapshot = await _firestore.collection('clubs').doc(id).get();
    final data = snapshot.data();
    return data == null ? null : Club.fromMap(snapshot.id, data);
  }
}
