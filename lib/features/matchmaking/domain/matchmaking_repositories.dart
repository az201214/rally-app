import 'matchmaking_models.dart';

abstract interface class AvailabilityRepository {
  Future<PlayerAvailability> createAvailability(
    PlayerAvailability availability,
  );
  Stream<PlayerAvailability?> watchAvailability(String id);
  Future<void> cancelAvailability(String id, String userId);
  Future<void> expireAvailability(String id, String userId);
  Future<PlayerAvailability?> getActiveAvailabilityForUser(String userId);
}

abstract interface class MatchmakingRepository {
  Future<void> createSearch(
    PlayerAvailability availability,
    MatchRequest request,
  );
  Future<MatchRequest> createMatchRequest(MatchRequest request);
  Future<MatchRequest?> getActiveRequestForUser(String userId);
  Stream<MatchRequest?> watchMatchRequest(String id);
  Future<void> cancelMatchRequest(String id, String userId);
  Future<void> cancelSearch({
    required String requestId,
    required String availabilityId,
    required String userId,
    required bool expired,
  });
  Future<List<MatchRequest>> findCompatibleRequests(MatchRequest request);
  Future<RallyMatch?> createOrJoinMatch(
    MatchRequest own,
    MatchRequest candidate,
  );
  Stream<RallyMatch?> watchMatch(String id);
  Future<void> acceptMatch(String id, String userId);
  Future<void> declineMatch(String id, String userId);
  Future<void> cancelMatch(String id, String userId, String reason);
  Future<void> expireMatch(String id);
}
