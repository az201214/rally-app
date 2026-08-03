import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/auth_providers.dart';
import '../data/firestore_matchmaking_repositories.dart';
import '../domain/matchmaking_models.dart';
import '../domain/matchmaking_repositories.dart';

final availabilityRepositoryProvider = Provider<AvailabilityRepository>(
  (ref) => FirestoreAvailabilityRepository(FirebaseFirestore.instance),
);
final matchmakingRepositoryProvider = Provider<MatchmakingRepository>(
  (ref) => FirestoreMatchmakingRepository(FirebaseFirestore.instance),
);

enum MatchmakingPhase {
  idle,
  creating,
  searching,
  matchFound,
  accepting,
  confirmed,
  cancelled,
  expired,
  error,
}

class MatchmakingState {
  const MatchmakingState({
    this.phase = MatchmakingPhase.idle,
    this.availability,
    this.request,
    this.match,
    this.startedAt,
    this.message,
  });
  final MatchmakingPhase phase;
  final PlayerAvailability? availability;
  final MatchRequest? request;
  final RallyMatch? match;
  final DateTime? startedAt;
  final String? message;
  MatchmakingState copyWith({
    MatchmakingPhase? phase,
    PlayerAvailability? availability,
    MatchRequest? request,
    RallyMatch? match,
    DateTime? startedAt,
    String? message,
  }) => MatchmakingState(
    phase: phase ?? this.phase,
    availability: availability ?? this.availability,
    request: request ?? this.request,
    match: match ?? this.match,
    startedAt: startedAt ?? this.startedAt,
    message: message,
  );
}

final matchmakingControllerProvider =
    NotifierProvider<MatchmakingController, MatchmakingState>(
      MatchmakingController.new,
    );

class MatchmakingController extends Notifier<MatchmakingState> {
  StreamSubscription<MatchRequest?>? _requestSubscription;
  StreamSubscription<RallyMatch?>? _matchSubscription;
  Timer? _candidateTimer;
  Timer? _candidateKickoffTimer;
  Timer? _matchExpiryTimer;
  bool _mutationPending = false;
  bool _searchPassRunning = false;
  int _generation = 0;
  int _consecutiveSearchFailures = 0;
  String? _watchedRequestId;
  String? _watchedMatchId;

  @override
  MatchmakingState build() {
    ref.onDispose(_resetRuntime);
    ref.listen(authStateProvider, (previous, next) {
      if (next.isLoading) return;
      final user = next.value;
      if (user == null) {
        _resetRuntime();
        state = const MatchmakingState();
      } else if (previous?.value?.uid != user.uid &&
          !_mutationPending &&
          state.phase == MatchmakingPhase.idle) {
        unawaited(restore(user.uid));
      }
    });
    return const MatchmakingState();
  }

  Future<bool> startSearch({
    required DateTime availableFrom,
    required DateTime availableUntil,
  }) async {
    if (_mutationPending ||
        state.phase == MatchmakingPhase.searching ||
        state.phase == MatchmakingPhase.creating) {
      return false;
    }
    final user =
        ref.read(authStateProvider).value ??
        ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      return _error('Complete your player profile before searching.');
    }
    _mutationPending = true;
    final generation = ++_generation;
    _disposeListeners();
    state = state.copyWith(phase: MatchmakingPhase.creating, message: null);
    try {
      final profile = await ref
          .read(playerProfileRepositoryProvider)
          .loadProfile(user.uid);
      if (generation != _generation) return false;
      if (profile == null) {
        return _error('Complete your player profile before searching.');
      }
      final existing = await ref
          .read(matchmakingRepositoryProvider)
          .getActiveRequestForUser(user.uid);
      if (generation != _generation) return false;
      if (existing != null) {
        state = state.copyWith(
          phase: MatchmakingPhase.searching,
          request: existing,
          startedAt: existing.createdAt,
        );
        _watchRequest(existing, generation);
        if (existing.matchedMatchId.isNotEmpty) {
          _watchMatch(existing.matchedMatchId, generation);
        } else {
          _beginCandidateSearch(generation);
        }
        return true;
      }
      final orphanedAvailability = await ref
          .read(availabilityRepositoryProvider)
          .getActiveAvailabilityForUser(user.uid);
      if (generation != _generation) return false;
      if (orphanedAvailability != null) {
        await ref
            .read(availabilityRepositoryProvider)
            .cancelAvailability(orphanedAvailability.id, user.uid);
        if (generation != _generation) return false;
      }
      final now = DateTime.now().toUtc();
      final id = 'availability_${user.uid}';
      final coordinates = _coordinates(profile.city);
      final availability = PlayerAvailability(
        id: id,
        userId: user.uid,
        city: _canonicalCity(profile.city),
        latitude: coordinates.$1,
        longitude: coordinates.$2,
        searchRadiusKm: profile.searchRadiusKm.toDouble(),
        availableFrom: availableFrom.toUtc(),
        availableUntil: availableUntil.toUtc(),
        skillLevel: profile.skillLevel,
        preferredSide: profile.preferredSide,
        preferredClubIds: profile.homeClubId.isEmpty
            ? const []
            : <String>[profile.homeClubId],
        reliabilityScore: profile.reliabilityScore,
        status: AvailabilityStatus.active,
        createdAt: now,
        updatedAt: now,
        expiresAt: availableUntil.toUtc(),
      );
      await ref
          .read(availabilityRepositoryProvider)
          .createAvailability(availability);
      final request = MatchRequest(
        id: 'request_${user.uid}',
        userId: user.uid,
        availabilityId: id,
        city: availability.city,
        latitude: availability.latitude,
        longitude: availability.longitude,
        searchRadiusKm: availability.searchRadiusKm,
        availableFrom: availability.availableFrom,
        availableUntil: availability.availableUntil,
        skillLevel: availability.skillLevel,
        preferredSide: availability.preferredSide,
        preferredClubIds: availability.preferredClubIds,
        reliabilityScore: availability.reliabilityScore,
        status: MatchRequestStatus.searching,
        matchedMatchId: '',
        createdAt: now,
        updatedAt: now,
        expiresAt: availability.expiresAt,
        displayName: profile.fullName,
        photoUrl: profile.photoUrl,
      );
      await ref
          .read(matchmakingRepositoryProvider)
          .createSearch(availability, request);
      if (generation != _generation) return false;
      state = MatchmakingState(
        phase: MatchmakingPhase.searching,
        availability: availability,
        request: request,
        startedAt: now,
      );
      _watchRequest(request, generation);
      _beginCandidateSearch(generation);
      return true;
    } catch (_) {
      return _error('We could not start matchmaking. Please try again.');
    } finally {
      _mutationPending = false;
    }
  }

  Future<void> restore(String userId) async {
    final generation = ++_generation;
    _disposeListeners();
    try {
      final availability = await ref
          .read(availabilityRepositoryProvider)
          .getActiveAvailabilityForUser(userId);
      if (generation != _generation) return;
      final request = await ref
          .read(matchmakingRepositoryProvider)
          .getActiveRequestForUser(userId);
      if (generation != _generation || request == null) return;
      state = MatchmakingState(
        phase: MatchmakingPhase.searching,
        availability: availability,
        request: request,
        startedAt: request.createdAt,
      );
      _watchRequest(request, generation);
      if (request.matchedMatchId.isNotEmpty) {
        _watchMatch(request.matchedMatchId, generation);
      } else {
        _beginCandidateSearch(generation);
      }
    } catch (_) {
      if (generation != _generation) return;
      state = const MatchmakingState(
        phase: MatchmakingPhase.error,
        message: 'Your previous search could not be restored.',
      );
    }
  }

  void _watchRequest(MatchRequest request, int generation) {
    if (_watchedRequestId == request.id && _requestSubscription != null) return;
    unawaited(_requestSubscription?.cancel());
    _watchedRequestId = request.id;
    _requestSubscription = ref
        .read(matchmakingRepositoryProvider)
        .watchMatchRequest(request.id)
        .listen((value) {
          if (generation != _generation || value == null) return;
          state = state.copyWith(request: value);
          if (value.status == MatchRequestStatus.matched &&
              value.matchedMatchId.isNotEmpty) {
            _candidateTimer?.cancel();
            _watchMatch(value.matchedMatchId, generation);
          } else if (value.status == MatchRequestStatus.cancelled) {
            _candidateTimer?.cancel();
            _candidateTimer = null;
            state = state.copyWith(phase: MatchmakingPhase.cancelled);
          } else if (value.status == MatchRequestStatus.expired) {
            _candidateTimer?.cancel();
            _candidateTimer = null;
            state = state.copyWith(phase: MatchmakingPhase.expired);
          }
        }, onError: (_) => _failLiveSearch(generation));
  }

  void _watchMatch(String id, int generation) {
    if (_watchedMatchId == id && _matchSubscription != null) return;
    unawaited(_matchSubscription?.cancel());
    _watchedMatchId = id;
    _matchSubscription = ref
        .read(matchmakingRepositoryProvider)
        .watchMatch(id)
        .listen((match) {
          if (generation != _generation || match == null) return;
          final phase = switch (match.status) {
            RallyMatchStatus.confirmed => MatchmakingPhase.confirmed,
            RallyMatchStatus.cancelled ||
            RallyMatchStatus.declined => MatchmakingPhase.cancelled,
            RallyMatchStatus.expired => MatchmakingPhase.expired,
            _ => MatchmakingPhase.matchFound,
          };
          state = state.copyWith(phase: phase, match: match);
          _scheduleMatchExpiry(match, generation);
        }, onError: (_) => _failLiveSearch(generation));
  }

  void _beginCandidateSearch(int generation) {
    _candidateTimer?.cancel();
    _consecutiveSearchFailures = 0;
    _candidateTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => unawaited(_findCandidate(generation)),
    );
    _candidateKickoffTimer = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(_findCandidate(generation)),
    );
  }

  Future<void> _findCandidate(int generation) async {
    if (_searchPassRunning || generation != _generation) return;
    final request = state.request;
    if (request == null || request.status != MatchRequestStatus.searching) {
      return;
    }
    if (request.expiresAt.isBefore(DateTime.now().toUtc())) {
      await cancelSearch(expired: true);
      return;
    }
    _searchPassRunning = true;
    try {
      final candidates = await ref
          .read(matchmakingRepositoryProvider)
          .findCompatibleRequests(request);
      if (generation != _generation) return;
      for (final candidate in candidates) {
        final match = await ref
            .read(matchmakingRepositoryProvider)
            .createOrJoinMatch(request, candidate);
        if (generation != _generation) return;
        if (match != null) {
          _candidateTimer?.cancel();
          _watchMatch(match.id, generation);
          return;
        }
      }
      _consecutiveSearchFailures = 0;
    } catch (_) {
      _consecutiveSearchFailures++;
      if (_consecutiveSearchFailures >= 3) {
        _failLiveSearch(generation);
      }
    } finally {
      _searchPassRunning = false;
    }
  }

  Future<bool> accept() async {
    final match = state.match;
    final user =
        ref.read(authStateProvider).value ??
        ref.read(authRepositoryProvider).currentUser;
    if (_mutationPending || match == null || user == null) return false;
    _mutationPending = true;
    state = state.copyWith(phase: MatchmakingPhase.accepting);
    try {
      await ref
          .read(matchmakingRepositoryProvider)
          .acceptMatch(match.id, user.uid);
      return true;
    } catch (_) {
      return _error('This match could not be accepted. It may have expired.');
    } finally {
      _mutationPending = false;
    }
  }

  Future<bool> decline() async {
    final match = state.match;
    final user =
        ref.read(authStateProvider).value ??
        ref.read(authRepositoryProvider).currentUser;
    if (_mutationPending || match == null || user == null) return false;
    _mutationPending = true;
    try {
      await ref
          .read(matchmakingRepositoryProvider)
          .declineMatch(match.id, user.uid);
      state = state.copyWith(phase: MatchmakingPhase.cancelled);
      return true;
    } catch (_) {
      return _error('This match could not be declined.');
    } finally {
      _mutationPending = false;
    }
  }

  Future<bool> cancelSearch({bool expired = false}) async {
    final request = state.request;
    final user =
        ref.read(authStateProvider).value ??
        ref.read(authRepositoryProvider).currentUser;
    if (_mutationPending || request == null || user == null) return false;
    _mutationPending = true;
    try {
      await ref
          .read(matchmakingRepositoryProvider)
          .cancelSearch(
            requestId: request.id,
            availabilityId: request.availabilityId,
            userId: user.uid,
            expired: expired,
          );
      _resetRuntime();
      state = MatchmakingState(
        phase: expired ? MatchmakingPhase.expired : MatchmakingPhase.cancelled,
      );
      return true;
    } catch (_) {
      final current = await ref
          .read(matchmakingRepositoryProvider)
          .getActiveRequestForUser(user.uid);
      if (current?.matchedMatchId.isNotEmpty == true) {
        final generation = _generation;
        state = state.copyWith(
          phase: MatchmakingPhase.searching,
          request: current,
        );
        _watchRequest(current!, generation);
        _watchMatch(current.matchedMatchId, generation);
        return false;
      }
      return _error('Your search could not be cancelled.');
    } finally {
      _mutationPending = false;
    }
  }

  bool _error(String message) {
    state = state.copyWith(phase: MatchmakingPhase.error, message: message);
    return false;
  }

  (double, double) _coordinates(String city) => switch (city.toLowerCase()) {
    'lahore' => (31.5204, 74.3587),
    'islamabad' => (33.6844, 73.0479),
    _ => (24.8607, 67.0011),
  };
  String _canonicalCity(String city) {
    final trimmed = city.trim();
    if (trimmed.isEmpty) return 'Karachi';
    return trimmed
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  void _scheduleMatchExpiry(RallyMatch match, int generation) {
    _matchExpiryTimer?.cancel();
    if (match.status != RallyMatchStatus.awaitingAcceptance) return;
    final delay = match.expiresAt.difference(DateTime.now().toUtc());
    if (delay <= Duration.zero) {
      unawaited(_expireMatch(match.id, generation));
      return;
    }
    _matchExpiryTimer = Timer(
      delay,
      () => unawaited(_expireMatch(match.id, generation)),
    );
  }

  Future<void> _expireMatch(String id, int generation) async {
    if (generation != _generation) return;
    try {
      await ref.read(matchmakingRepositoryProvider).expireMatch(id);
    } catch (_) {
      if (generation == _generation) {
        state = state.copyWith(
          phase: MatchmakingPhase.error,
          message: 'The match status could not be refreshed.',
        );
      }
    }
  }

  void _failLiveSearch(int generation) {
    if (generation != _generation) return;
    _candidateTimer?.cancel();
    _candidateKickoffTimer?.cancel();
    state = state.copyWith(
      phase: MatchmakingPhase.error,
      message: 'Live matchmaking was interrupted. Cancel and try again.',
    );
  }

  void _resetRuntime() {
    _generation++;
    _disposeListeners();
  }

  void _disposeListeners() {
    _candidateTimer?.cancel();
    _matchExpiryTimer?.cancel();
    unawaited(_requestSubscription?.cancel());
    unawaited(_matchSubscription?.cancel());
    _candidateTimer = null;
    _candidateKickoffTimer = null;
    _matchExpiryTimer = null;
    _requestSubscription = null;
    _matchSubscription = null;
    _watchedRequestId = null;
    _watchedMatchId = null;
    _searchPassRunning = false;
  }
}
