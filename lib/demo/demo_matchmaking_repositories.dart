import 'dart:async';

import '../features/matchmaking/domain/compatibility_engine.dart';
import '../features/matchmaking/domain/matchmaking_models.dart';
import '../features/matchmaking/domain/matchmaking_repositories.dart';

class DemoAvailabilityRepository implements AvailabilityRepository {
  PlayerAvailability? _value;
  final _changes = StreamController<PlayerAvailability?>.broadcast();
  @override
  Future<PlayerAvailability> createAvailability(
    PlayerAvailability value,
  ) async {
    _value = value;
    _changes.add(value);
    return value;
  }

  @override
  Future<PlayerAvailability?> getActiveAvailabilityForUser(
    String userId,
  ) async =>
      _value?.userId == userId && _value?.status == AvailabilityStatus.active
      ? _value
      : null;
  @override
  Stream<PlayerAvailability?> watchAvailability(String id) =>
      Stream<PlayerAvailability?>.multi((listener) {
        listener.add(_value);
        final subscription = _changes.stream.listen(listener.add);
        listener.onCancel = subscription.cancel;
      });
  @override
  Future<void> cancelAvailability(String id, String userId) async {
    _value = null;
    _changes.add(null);
  }

  @override
  Future<void> expireAvailability(String id, String userId) =>
      cancelAvailability(id, userId);
}

class DemoMatchmakingRepository implements MatchmakingRepository {
  MatchRequest? _request;
  RallyMatch? _match;
  final _requests = StreamController<MatchRequest?>.broadcast();
  final _matches = StreamController<RallyMatch?>.broadcast();

  @override
  Future<void> createSearch(
    PlayerAvailability availability,
    MatchRequest request,
  ) async {
    await createMatchRequest(request);
  }

  @override
  Future<MatchRequest> createMatchRequest(MatchRequest request) async {
    if (_request?.status == MatchRequestStatus.searching) {
      throw StateError('A search is already active.');
    }
    _request = request;
    _requests.add(request);
    return request;
  }

  @override
  Future<MatchRequest?> getActiveRequestForUser(String userId) async =>
      _request?.userId == userId ? _request : null;
  @override
  Stream<MatchRequest?> watchMatchRequest(String id) =>
      Stream<MatchRequest?>.multi((listener) {
        listener.add(_request);
        final subscription = _requests.stream.listen(listener.add);
        listener.onCancel = subscription.cancel;
      });
  @override
  Stream<RallyMatch?> watchMatch(String id) =>
      Stream<RallyMatch?>.multi((listener) {
        listener.add(_match);
        final subscription = _matches.stream.listen(listener.add);
        listener.onCancel = subscription.cancel;
      });
  @override
  Future<List<MatchRequest>> findCompatibleRequests(
    MatchRequest request,
  ) async {
    final now = DateTime.now().toUtc();
    return <MatchRequest>[
      MatchRequest(
        id: 'demo-opponent-request',
        userId: 'demo-opponent',
        availabilityId: 'demo-opponent-availability',
        city: request.city,
        latitude: request.latitude + .012,
        longitude: request.longitude,
        searchRadiusKm: 10,
        availableFrom: request.availableFrom,
        availableUntil: request.availableUntil,
        skillLevel: request.skillLevel,
        preferredSide: request.preferredSide.toLowerCase() == 'right'
            ? 'Left'
            : 'Right',
        preferredClubIds: request.preferredClubIds,
        reliabilityScore: 96,
        status: MatchRequestStatus.searching,
        matchedMatchId: '',
        createdAt: now,
        updatedAt: now,
        expiresAt: request.expiresAt,
      ),
    ];
  }

  @override
  Future<RallyMatch?> createOrJoinMatch(
    MatchRequest own,
    MatchRequest candidate,
  ) async {
    if (_match != null) return _match;
    final now = DateTime.now().toUtc();
    final result = CompatibilityEngine.score(own, candidate);
    _match = RallyMatch(
      id: 'demo-rally-match',
      participantIds: <String>[own.userId, candidate.userId],
      participants: <MatchParticipant>[
        MatchParticipant(
          userId: own.userId,
          displayName: 'You',
          photoUrl: '',
          skillLevel: own.skillLevel,
          preferredSide: own.preferredSide,
          reliabilityScore: own.reliabilityScore,
          acceptanceStatus: AcceptanceStatus.pending,
          joinedAt: now,
        ),
        MatchParticipant(
          userId: candidate.userId,
          displayName: 'Ayesha Malik',
          photoUrl: '',
          skillLevel: candidate.skillLevel,
          preferredSide: candidate.preferredSide,
          reliabilityScore: candidate.reliabilityScore,
          acceptanceStatus: AcceptanceStatus.accepted,
          joinedAt: now,
          acceptedAt: now,
        ),
      ],
      city: own.city,
      clubId: own.preferredClubIds.firstOrNull ?? 'padelverse-clifton',
      clubName: 'Padelverse Clifton',
      scheduledStart: own.availableFrom,
      scheduledEnd: own.availableUntil,
      status: RallyMatchStatus.awaitingAcceptance,
      compatibilityScore: result.score,
      compatibilityReasons: result.reasons,
      createdBy: own.userId,
      createdAt: now,
      updatedAt: now,
      expiresAt: now.add(const Duration(minutes: 10)),
      cancellationReason: '',
    );
    _request = MatchRequest.fromMap(<String, Object?>{
      ...own.toMap(),
      'status': 'matched',
      'matchedMatchId': _match!.id,
    }, id: own.id);
    _requests.add(_request);
    _matches.add(_match);
    return _match;
  }

  @override
  Future<void> acceptMatch(String id, String userId) async {
    final value = _match;
    if (value == null) return;
    final now = DateTime.now().toUtc();
    final participants = value.participants
        .map(
          (item) => item.userId == userId
              ? MatchParticipant(
                  userId: item.userId,
                  displayName: item.displayName,
                  photoUrl: item.photoUrl,
                  skillLevel: item.skillLevel,
                  preferredSide: item.preferredSide,
                  reliabilityScore: item.reliabilityScore,
                  acceptanceStatus: AcceptanceStatus.accepted,
                  joinedAt: item.joinedAt,
                  acceptedAt: now,
                )
              : item,
        )
        .toList();
    _match = RallyMatch.fromMap(<String, Object?>{
      ...value.toMap(),
      'participants': participants.map((e) => e.toMap()).toList(),
      'status': 'confirmed',
      'confirmedAt': now,
    }, id: value.id);
    _matches.add(_match);
  }

  @override
  Future<void> declineMatch(String id, String userId) async =>
      _setStatus(RallyMatchStatus.declined);
  @override
  Future<void> cancelMatch(String id, String userId, String reason) async =>
      _setStatus(RallyMatchStatus.cancelled);
  @override
  Future<void> expireMatch(String id) async =>
      _setStatus(RallyMatchStatus.expired);
  void _setStatus(RallyMatchStatus status) {
    final value = _match;
    if (value == null) return;
    _match = RallyMatch.fromMap(<String, Object?>{
      ...value.toMap(),
      'status': status.name,
    }, id: value.id);
    _matches.add(_match);
  }

  @override
  Future<void> cancelMatchRequest(String id, String userId) async {
    _request = null;
    _requests.add(null);
  }

  @override
  Future<void> cancelSearch({
    required String requestId,
    required String availabilityId,
    required String userId,
    required bool expired,
  }) => cancelMatchRequest(requestId, userId);
}
