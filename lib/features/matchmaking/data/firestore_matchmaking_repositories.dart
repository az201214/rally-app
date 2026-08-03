import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/compatibility_engine.dart';
import '../domain/matchmaking_models.dart';
import '../domain/matchmaking_repositories.dart';

class FirestoreAvailabilityRepository implements AvailabilityRepository {
  FirestoreAvailabilityRepository(this._firestore);
  final FirebaseFirestore _firestore;
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('availability');

  @override
  Future<PlayerAvailability> createAvailability(
    PlayerAvailability value,
  ) async {
    final existing = await getActiveAvailabilityForUser(value.userId);
    if (existing != null) {
      throw StateError('An active availability already exists.');
    }
    await _collection.doc(value.id).set(value.toMap());
    return value;
  }

  @override
  Stream<PlayerAvailability?> watchAvailability(String id) => _collection
      .doc(id)
      .snapshots()
      .map(
        (snapshot) => snapshot.exists
            ? PlayerAvailability.fromMap(snapshot.data()!, id: snapshot.id)
            : null,
      );

  @override
  Future<PlayerAvailability?> getActiveAvailabilityForUser(
    String userId,
  ) async {
    final result = await _collection
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();
    if (result.docs.isEmpty) return null;
    final value = PlayerAvailability.fromMap(
      result.docs.first.data(),
      id: result.docs.first.id,
    );
    if (value.expiresAt.isAfter(DateTime.now().toUtc())) return value;
    await expireAvailability(value.id, userId);
    return null;
  }

  @override
  Future<void> cancelAvailability(String id, String userId) =>
      _transition(id, userId, AvailabilityStatus.cancelled);
  @override
  Future<void> expireAvailability(String id, String userId) =>
      _transition(id, userId, AvailabilityStatus.expired);

  Future<void> _transition(
    String id,
    String userId,
    AvailabilityStatus status,
  ) => _firestore.runTransaction((transaction) async {
    final reference = _collection.doc(id);
    final snapshot = await transaction.get(reference);
    if (!snapshot.exists || snapshot.data()?['userId'] != userId) {
      throw StateError('Availability is unavailable.');
    }
    transaction.update(reference, <String, Object?>{
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  });
}

class FirestoreMatchmakingRepository implements MatchmakingRepository {
  FirestoreMatchmakingRepository(this._firestore);
  final FirebaseFirestore _firestore;
  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('matchRequests');
  CollectionReference<Map<String, dynamic>> get _matches =>
      _firestore.collection('matches');

  @override
  Future<void> createSearch(
    PlayerAvailability availability,
    MatchRequest request,
  ) => _firestore.runTransaction((transaction) async {
    final availabilityRef = _firestore
        .collection('availability')
        .doc(availability.id);
    final requestRef = _requests.doc(request.id);
    final availabilitySnapshot = await transaction.get(availabilityRef);
    final requestSnapshot = await transaction.get(requestRef);
    final now = DateTime.now().toUtc();
    if (requestSnapshot.exists) {
      final existing = MatchRequest.fromMap(
        requestSnapshot.data()!,
        id: requestSnapshot.id,
      );
      if ((existing.status == MatchRequestStatus.searching ||
              existing.status == MatchRequestStatus.matched) &&
          existing.expiresAt.isAfter(now)) {
        throw StateError('A search is already active.');
      }
    }
    if (availabilitySnapshot.exists) {
      final existing = PlayerAvailability.fromMap(
        availabilitySnapshot.data()!,
        id: availabilitySnapshot.id,
      );
      if ((existing.status == AvailabilityStatus.active ||
              existing.status == AvailabilityStatus.matched) &&
          existing.expiresAt.isAfter(now)) {
        throw StateError('An availability window is already active.');
      }
    }
    transaction.set(availabilityRef, availability.toMap());
    transaction.set(requestRef, request.toMap());
  });

  @override
  Future<MatchRequest> createMatchRequest(MatchRequest request) async {
    final duplicate = await _requests
        .where('userId', isEqualTo: request.userId)
        .where('status', isEqualTo: 'searching')
        .limit(1)
        .get();
    if (duplicate.docs.isNotEmpty) {
      throw StateError('A search is already active.');
    }
    await _requests.doc(request.id).set(request.toMap());
    return request;
  }

  @override
  Future<MatchRequest?> getActiveRequestForUser(String userId) async {
    for (final status in const <String>['searching', 'matched']) {
      final result = await _requests
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: status)
          .limit(1)
          .get();
      if (result.docs.isNotEmpty) {
        final value = MatchRequest.fromMap(
          result.docs.first.data(),
          id: result.docs.first.id,
        );
        if (value.expiresAt.isAfter(DateTime.now().toUtc())) return value;
      }
    }
    return null;
  }

  @override
  Stream<MatchRequest?> watchMatchRequest(String id) => _requests
      .doc(id)
      .snapshots()
      .map(
        (snapshot) => snapshot.exists
            ? MatchRequest.fromMap(snapshot.data()!, id: snapshot.id)
            : null,
      );

  @override
  Future<List<MatchRequest>> findCompatibleRequests(MatchRequest own) async {
    final result = await _requests
        .where('city', isEqualTo: own.city)
        .where('status', isEqualTo: 'searching')
        .limit(30)
        .get();
    final candidates = result.docs
        .map((doc) => MatchRequest.fromMap(doc.data(), id: doc.id))
        .where((candidate) => CompatibilityEngine.isCompatible(own, candidate))
        .toList();
    candidates.sort(
      (a, b) => CompatibilityEngine.score(
        own,
        b,
      ).score.compareTo(CompatibilityEngine.score(own, a).score),
    );
    return candidates;
  }

  @override
  Future<RallyMatch?> createOrJoinMatch(
    MatchRequest own,
    MatchRequest candidate,
  ) async {
    final pair = <String>[own.id, candidate.id]..sort();
    final matchId = 'pair_${pair.join('_')}';
    return _firestore.runTransaction<RallyMatch?>((transaction) async {
      final ownRef = _requests.doc(own.id);
      final candidateRef = _requests.doc(candidate.id);
      final matchRef = _matches.doc(matchId);
      final ownSnapshot = await transaction.get(ownRef);
      final candidateSnapshot = await transaction.get(candidateRef);
      final existingMatch = await transaction.get(matchRef);
      if (existingMatch.exists) {
        return RallyMatch.fromMap(existingMatch.data()!, id: matchId);
      }
      if (!ownSnapshot.exists || !candidateSnapshot.exists) return null;
      final currentOwn = MatchRequest.fromMap(ownSnapshot.data()!, id: own.id);
      final currentCandidate = MatchRequest.fromMap(
        candidateSnapshot.data()!,
        id: candidate.id,
      );
      if (!CompatibilityEngine.isCompatible(currentOwn, currentCandidate)) {
        return null;
      }
      final now = DateTime.now().toUtc();
      final result = CompatibilityEngine.score(currentOwn, currentCandidate);
      MatchParticipant participant(MatchRequest request) => MatchParticipant(
        userId: request.userId,
        displayName: request.displayName.isEmpty
            ? 'Rally player'
            : request.displayName,
        photoUrl: request.photoUrl,
        skillLevel: request.skillLevel,
        preferredSide: request.preferredSide,
        reliabilityScore: request.reliabilityScore,
        acceptanceStatus: AcceptanceStatus.pending,
        joinedAt: now,
      );
      final commonClubs = currentOwn.preferredClubIds.toSet().intersection(
        currentCandidate.preferredClubIds.toSet(),
      );
      final match = RallyMatch(
        id: matchId,
        participantIds: <String>[own.userId, candidate.userId],
        participants: <MatchParticipant>[
          participant(currentOwn),
          participant(currentCandidate),
        ],
        city: own.city,
        clubId: commonClubs.firstOrNull ?? '',
        clubName: commonClubs.isEmpty
            ? 'Club to be confirmed'
            : 'Preferred Rally club',
        scheduledStart:
            currentOwn.availableFrom.isAfter(currentCandidate.availableFrom)
            ? currentOwn.availableFrom
            : currentCandidate.availableFrom,
        scheduledEnd:
            currentOwn.availableUntil.isBefore(currentCandidate.availableUntil)
            ? currentOwn.availableUntil
            : currentCandidate.availableUntil,
        status: RallyMatchStatus.awaitingAcceptance,
        compatibilityScore: result.score,
        compatibilityReasons: result.reasons,
        createdBy: own.userId,
        createdAt: now,
        updatedAt: now,
        expiresAt: now.add(const Duration(minutes: 10)),
        cancellationReason: '',
      );
      transaction.set(matchRef, match.toMap());
      for (final requestRef in <DocumentReference>[ownRef, candidateRef]) {
        transaction.update(requestRef, <String, Object?>{
          'status': 'matched',
          'matchedMatchId': matchId,
          'expiresAt': match.expiresAt,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      transaction.set(matchRef.collection('events').doc(), <String, Object?>{
        'type': 'matchCreated',
        'actorId': own.userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return match;
    });
  }

  @override
  Stream<RallyMatch?> watchMatch(String id) => _matches
      .doc(id)
      .snapshots()
      .map(
        (snapshot) => snapshot.exists
            ? RallyMatch.fromMap(snapshot.data()!, id: snapshot.id)
            : null,
      );

  @override
  Future<void> acceptMatch(String id, String userId) =>
      _firestore.runTransaction((transaction) async {
        final reference = _matches.doc(id);
        final snapshot = await transaction.get(reference);
        if (!snapshot.exists) throw StateError('Match is unavailable.');
        final match = RallyMatch.fromMap(snapshot.data()!, id: id);
        final now = DateTime.now().toUtc();
        if (!match.participantIds.contains(userId) ||
            match.expiresAt.isBefore(now) ||
            match.status != RallyMatchStatus.awaitingAcceptance) {
          throw StateError('This match can no longer be accepted.');
        }
        final existingParticipant = match.participants
            .where((participant) => participant.userId == userId)
            .firstOrNull;
        if (existingParticipant?.acceptanceStatus ==
            AcceptanceStatus.accepted) {
          return;
        }
        final participants = match.participants
            .map(
              (participant) => participant.userId == userId
                  ? MatchParticipant(
                      userId: participant.userId,
                      displayName: participant.displayName,
                      photoUrl: participant.photoUrl,
                      skillLevel: participant.skillLevel,
                      preferredSide: participant.preferredSide,
                      reliabilityScore: participant.reliabilityScore,
                      acceptanceStatus: AcceptanceStatus.accepted,
                      joinedAt: participant.joinedAt,
                      acceptedAt: now,
                    )
                  : participant,
            )
            .toList();
        final confirmed = participants.every(
          (item) => item.acceptanceStatus == AcceptanceStatus.accepted,
        );
        transaction.update(reference, <String, Object?>{
          'participants': participants.map((item) => item.toMap()).toList(),
          'status': confirmed ? 'confirmed' : 'awaitingAcceptance',
          'updatedAt': FieldValue.serverTimestamp(),
          if (confirmed) 'confirmedAt': FieldValue.serverTimestamp(),
        });
        transaction.set(reference.collection('events').doc(), <String, Object?>{
          'type': 'participantAccepted',
          'actorId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

  @override
  Future<void> declineMatch(String id, String userId) =>
      _finish(id, userId, RallyMatchStatus.declined, 'Participant declined');
  @override
  Future<void> cancelMatch(String id, String userId, String reason) =>
      _finish(id, userId, RallyMatchStatus.cancelled, reason);
  @override
  Future<void> expireMatch(String id) => _finish(
    id,
    '',
    RallyMatchStatus.expired,
    'Acceptance window expired',
    allowSystem: true,
  );

  Future<void> _finish(
    String id,
    String userId,
    RallyMatchStatus status,
    String reason, {
    bool allowSystem = false,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final reference = _matches.doc(id);
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) return;
      final match = RallyMatch.fromMap(snapshot.data()!, id: id);
      if (!allowSystem && !match.participantIds.contains(userId)) {
        throw StateError('You cannot update this match.');
      }
      if (match.status == RallyMatchStatus.confirmed ||
          match.status == RallyMatchStatus.completed) {
        throw StateError('This match can no longer be changed.');
      }
      transaction.update(reference, <String, Object?>{
        'status': status.name,
        'cancellationReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    final linked = await _requests.where('matchedMatchId', isEqualTo: id).get();
    if (linked.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final document in linked.docs) {
      batch.update(document.reference, <String, Object?>{
        'status': status == RallyMatchStatus.expired ? 'expired' : 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final availabilityId = document.data()['availabilityId'];
      if (availabilityId is String && availabilityId.isNotEmpty) {
        batch.update(
          _firestore.collection('availability').doc(availabilityId),
          <String, Object?>{
            'status': status == RallyMatchStatus.expired
                ? 'expired'
                : 'cancelled',
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      }
    }
    await batch.commit();
  }

  @override
  Future<void> cancelMatchRequest(String id, String userId) =>
      _firestore.runTransaction((transaction) async {
        final reference = _requests.doc(id);
        final snapshot = await transaction.get(reference);
        if (!snapshot.exists || snapshot.data()?['userId'] != userId) {
          throw StateError('Search is unavailable.');
        }
        if (snapshot.data()?['status'] == 'matched') {
          throw StateError('A match has already been found.');
        }
        transaction.update(reference, <String, Object?>{
          'status': 'cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

  @override
  Future<void> cancelSearch({
    required String requestId,
    required String availabilityId,
    required String userId,
    required bool expired,
  }) => _firestore.runTransaction((transaction) async {
    final requestRef = _requests.doc(requestId);
    final availabilityRef = _firestore
        .collection('availability')
        .doc(availabilityId);
    final requestSnapshot = await transaction.get(requestRef);
    final availabilitySnapshot = await transaction.get(availabilityRef);
    if (!requestSnapshot.exists ||
        requestSnapshot.data()?['userId'] != userId) {
      throw StateError('Search is unavailable.');
    }
    if (requestSnapshot.data()?['status'] == 'matched') {
      throw StateError('A match has already been found.');
    }
    final status = expired ? 'expired' : 'cancelled';
    transaction.update(requestRef, <String, Object?>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (availabilitySnapshot.exists &&
        availabilitySnapshot.data()?['userId'] == userId) {
      transaction.update(availabilityRef, <String, Object?>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  });
}
