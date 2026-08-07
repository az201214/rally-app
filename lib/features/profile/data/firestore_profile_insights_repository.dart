import 'package:cloud_firestore/cloud_firestore.dart';

import '../../matchmaking/domain/matchmaking_models.dart';
import '../domain/profile_insights.dart';

class FirestoreProfileInsightsRepository implements ProfileInsightsRepository {
  FirestoreProfileInsightsRepository(this._firestore);
  final FirebaseFirestore _firestore;

  @override
  Stream<List<ProfileMatchHistoryItem>> watchMatchHistory(
    String uid, {
    int limit = 25,
  }) => _firestore
      .collection('matches')
      .where('participantIds', arrayContains: uid)
      .orderBy('scheduledStart', descending: true)
      .limit(limit.clamp(1, 50))
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) {
              final match = RallyMatch.fromMap(doc.data(), id: doc.id);
              final other = match.participants
                  .where((p) => p.userId != uid)
                  .firstOrNull;
              return ProfileMatchHistoryItem(
                match: match,
                otherPlayerName: other?.displayName ?? 'Rally player',
              );
            })
            .toList(growable: false),
      );
}
