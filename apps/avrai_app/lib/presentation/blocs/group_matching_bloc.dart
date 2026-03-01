// Group Matching BLoC
//
// State management for group matching UI
// Part of Phase 19.18: Quantum Group Matching System
// Section GM.4: Group Matching BLoC
//
// **Workflow:**
// 1. Start group formation (discover nearby users, load friends)
// 2. Add/remove group members
// 3. Form group session
// 4. Search for spots
// 5. Match group against spots
// 6. Display results

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:developer' as developer;

import 'package:avrai_runtime_os/controllers/group_matching_controller.dart';
import 'package:avrai_runtime_os/services/matching/group_formation_service.dart';
import 'package:avrai_core/models/quantum/group_session.dart';
import 'package:avrai_core/models/quantum/group_matching_result.dart';
import 'package:avrai_core/models/quantum/group_matching_input.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_runtime_os/data/repositories/hybrid_search_repository.dart';

// ===== EVENTS =====

/// Base class for group matching events
abstract class GroupMatchingEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Start group formation process
class StartGroupFormation extends GroupMatchingEvent {
  final String currentUserId;

  StartGroupFormation({required this.currentUserId});

  @override
  List<Object?> get props => [currentUserId];
}

/// Discover nearby users
class DiscoverNearbyUsers extends GroupMatchingEvent {
  final String currentUserId;
  final double minCompatibility;
  final int maxResults;

  DiscoverNearbyUsers({
    required this.currentUserId,
    this.minCompatibility = 0.3,
    this.maxResults = 10,
  });

  @override
  List<Object?> get props => [currentUserId, minCompatibility, maxResults];
}

/// Load friends list
class LoadFriendsList extends GroupMatchingEvent {
  final String currentUserId;

  LoadFriendsList({required this.currentUserId});

  @override
  List<Object?> get props => [currentUserId];
}

/// Add nearby user to group
class AddNearbyUser extends GroupMatchingEvent {
  final DiscoveredUser user;

  AddNearbyUser({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Add friend to group
class AddFriend extends GroupMatchingEvent {
  final String friendAgentId;

  AddFriend({required this.friendAgentId});

  @override
  List<Object?> get props => [friendAgentId];
}

/// Remove member from group
class RemoveMember extends GroupMatchingEvent {
  final String agentId;

  RemoveMember({required this.agentId});

  @override
  List<Object?> get props => [agentId];
}

/// Form group from selected members
class FormGroup extends GroupMatchingEvent {
  final String currentUserId;
  final List<DiscoveredUser>? nearbyUsers;
  final List<String>? friendAgentIds;

  FormGroup({
    required this.currentUserId,
    this.nearbyUsers,
    this.friendAgentIds,
  });

  @override
  List<Object?> get props => [currentUserId, nearbyUsers, friendAgentIds];
}

/// Start group search (match group against spots)
class StartGroupSearch extends GroupMatchingEvent {
  final UnifiedUser currentUser;
  final GroupSession session;
  final String? searchQuery;
  final double? latitude;
  final double? longitude;
  final int? radius;

  StartGroupSearch({
    required this.currentUser,
    required this.session,
    this.searchQuery,
    this.latitude,
    this.longitude,
    this.radius,
  });

  @override
  List<Object?> get props => [
        currentUser,
        session,
        searchQuery,
        latitude,
        longitude,
        radius,
      ];
}

/// Retry search with same parameters
class RetrySearch extends GroupMatchingEvent {}

/// Clear group and start over
class ClearGroup extends GroupMatchingEvent {}

// ===== STATES =====

/// Base class for group matching states
abstract class GroupMatchingState extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Initial state
class GroupMatchingInitial extends GroupMatchingState {}

/// Loading state
class GroupMatchingLoading extends GroupMatchingState {}

/// Group formation in progress
class GroupFormationInProgress extends GroupMatchingState {
  final List<DiscoveredUser> nearbyUsers;
  final List<String> friendAgentIds;
  final List<String> selectedMemberAgentIds;
  final String currentUserId;

  GroupFormationInProgress({
    required this.nearbyUsers,
    required this.friendAgentIds,
    required this.selectedMemberAgentIds,
    required this.currentUserId,
  });

  @override
  List<Object?> get props => [
        nearbyUsers,
        friendAgentIds,
        selectedMemberAgentIds,
        currentUserId,
      ];

  /// Get total number of selected members (including current user)
  int get totalSelectedMembers => selectedMemberAgentIds.length + 1;

  /// Check if group can be formed (at least 2 members)
  bool get canFormGroup => totalSelectedMembers >= 2;
}

/// Group formed successfully
class GroupFormed extends GroupMatchingState {
  final GroupSession session;

  GroupFormed({required this.session});

  @override
  List<Object?> get props => [session];
}

/// Group matching results ready
class GroupMatchingResults extends GroupMatchingState {
  final GroupMatchingResult matchingResult;
  final List<GroupMatchedSpot> matchedSpots;
  final Map<String, double> compatibilityScores;

  GroupMatchingResults({
    required this.matchingResult,
    required this.matchedSpots,
    required this.compatibilityScores,
  });

  @override
  List<Object?> get props => [
        matchingResult,
        matchedSpots,
        compatibilityScores,
      ];
}

/// Error state
class GroupMatchingError extends GroupMatchingState {
  final String message;
  final String? errorCode;

  GroupMatchingError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}

// ===== BLoC =====

/// Group Matching BLoC
///
/// Manages state for group matching workflow:
/// - Group formation (proximity + manual)
/// - Group matching against spots
/// - Results display
class GroupMatchingBloc extends Bloc<GroupMatchingEvent, GroupMatchingState> {
  static const String _logName = 'GroupMatchingBloc';

  final GroupMatchingController _controller;
  final GroupFormationService _formationService;
  final HybridSearchRepository? _searchRepository;

  // Temporary state for group formation
  List<DiscoveredUser> _nearbyUsers = [];
  List<String> _friendAgentIds = [];
  final List<String> _selectedMemberAgentIds = [];
  // ignore: unused_field
  String? _currentUserId;

  GroupMatchingBloc({
    required GroupMatchingController controller,
    required GroupFormationService formationService,
    HybridSearchRepository? searchRepository,
  })  : _controller = controller,
        _formationService = formationService,
        _searchRepository = searchRepository,
        super(GroupMatchingInitial()) {
    on<StartGroupFormation>(_onStartGroupFormation);
    on<DiscoverNearbyUsers>(_onDiscoverNearbyUsers);
    on<LoadFriendsList>(_onLoadFriendsList);
    on<AddNearbyUser>(_onAddNearbyUser);
    on<AddFriend>(_onAddFriend);
    on<RemoveMember>(_onRemoveMember);
    on<FormGroup>(_onFormGroup);
    on<StartGroupSearch>(_onStartGroupSearch);
    on<RetrySearch>(_onRetrySearch);
    on<ClearGroup>(_onClearGroup);
  }

  /// Start group formation
  Future<void> _onStartGroupFormation(
    StartGroupFormation event,
    Emitter<GroupMatchingState> emit,
  ) async {
    try {
      emit(GroupMatchingLoading());
      _currentUserId = event.currentUserId;

      // Discover nearby users and load friends in parallel
      final nearbyUsersFuture = _formationService.discoverNearbyUsers(
        currentUserId: event.currentUserId,
      );
      final friendsFuture =
          _formationService.getFriendsList(event.currentUserId);

      final results = await Future.wait([nearbyUsersFuture, friendsFuture]);
      _nearbyUsers = results[0] as List<DiscoveredUser>;
      _friendAgentIds = results[1] as List<String>;

      emit(GroupFormationInProgress(
        nearbyUsers: _nearbyUsers,
        friendAgentIds: _friendAgentIds,
        selectedMemberAgentIds: _selectedMemberAgentIds,
        currentUserId: event.currentUserId,
      ));
    } catch (e, stackTrace) {
      developer.log(
        'Error starting group formation: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      emit(GroupMatchingError(
        message: 'Failed to start group formation: ${e.toString()}',
        errorCode: 'GROUP_FORMATION_START_ERROR',
      ));
    }
  }

  /// Discover nearby users
  Future<void> _onDiscoverNearbyUsers(
    DiscoverNearbyUsers event,
    Emitter<GroupMatchingState> emit,
  ) async {
    try {
      emit(GroupMatchingLoading());

      _nearbyUsers = await _formationService.discoverNearbyUsers(
        currentUserId: event.currentUserId,
        minCompatibility: event.minCompatibility,
        maxResults: event.maxResults,
      );

      if (state is GroupFormationInProgress) {
        final currentState = state as GroupFormationInProgress;
        emit(GroupFormationInProgress(
          nearbyUsers: _nearbyUsers,
          friendAgentIds: currentState.friendAgentIds,
          selectedMemberAgentIds: currentState.selectedMemberAgentIds,
          currentUserId: currentState.currentUserId,
        ));
      } else {
        emit(GroupFormationInProgress(
          nearbyUsers: _nearbyUsers,
          friendAgentIds: _friendAgentIds,
          selectedMemberAgentIds: _selectedMemberAgentIds,
          currentUserId: event.currentUserId,
        ));
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error discovering nearby users: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      emit(GroupMatchingError(
        message: 'Failed to discover nearby users: ${e.toString()}',
        errorCode: 'DISCOVERY_ERROR',
      ));
    }
  }

  /// Load friends list
  Future<void> _onLoadFriendsList(
    LoadFriendsList event,
    Emitter<GroupMatchingState> emit,
  ) async {
    try {
      emit(GroupMatchingLoading());

      _friendAgentIds =
          await _formationService.getFriendsList(event.currentUserId);

      if (state is GroupFormationInProgress) {
        final currentState = state as GroupFormationInProgress;
        emit(GroupFormationInProgress(
          nearbyUsers: currentState.nearbyUsers,
          friendAgentIds: _friendAgentIds,
          selectedMemberAgentIds: currentState.selectedMemberAgentIds,
          currentUserId: currentState.currentUserId,
        ));
      } else {
        emit(GroupFormationInProgress(
          nearbyUsers: _nearbyUsers,
          friendAgentIds: _friendAgentIds,
          selectedMemberAgentIds: _selectedMemberAgentIds,
          currentUserId: event.currentUserId,
        ));
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error loading friends list: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      emit(GroupMatchingError(
        message: 'Failed to load friends: ${e.toString()}',
        errorCode: 'FRIENDS_LOAD_ERROR',
      ));
    }
  }

  /// Add nearby user to group
  void _onAddNearbyUser(
    AddNearbyUser event,
    Emitter<GroupMatchingState> emit,
  ) {
    if (state is! GroupFormationInProgress) {
      emit(GroupMatchingError(
        message: 'Cannot add user: group formation not in progress',
        errorCode: 'INVALID_STATE',
      ));
      return;
    }

    final currentState = state as GroupFormationInProgress;

    // Check if already selected
    if (_selectedMemberAgentIds.contains(event.user.agentId)) {
      return; // Already selected, no state change
    }

    _selectedMemberAgentIds.add(event.user.agentId);

    emit(GroupFormationInProgress(
      nearbyUsers: currentState.nearbyUsers,
      friendAgentIds: currentState.friendAgentIds,
      selectedMemberAgentIds: _selectedMemberAgentIds,
      currentUserId: currentState.currentUserId,
    ));
  }

  /// Add friend to group
  void _onAddFriend(
    AddFriend event,
    Emitter<GroupMatchingState> emit,
  ) {
    if (state is! GroupFormationInProgress) {
      emit(GroupMatchingError(
        message: 'Cannot add friend: group formation not in progress',
        errorCode: 'INVALID_STATE',
      ));
      return;
    }

    final currentState = state as GroupFormationInProgress;

    // Check if already selected
    if (_selectedMemberAgentIds.contains(event.friendAgentId)) {
      return; // Already selected, no state change
    }

    _selectedMemberAgentIds.add(event.friendAgentId);

    emit(GroupFormationInProgress(
      nearbyUsers: currentState.nearbyUsers,
      friendAgentIds: currentState.friendAgentIds,
      selectedMemberAgentIds: _selectedMemberAgentIds,
      currentUserId: currentState.currentUserId,
    ));
  }

  /// Remove member from group
  void _onRemoveMember(
    RemoveMember event,
    Emitter<GroupMatchingState> emit,
  ) {
    if (state is! GroupFormationInProgress) {
      emit(GroupMatchingError(
        message: 'Cannot remove member: group formation not in progress',
        errorCode: 'INVALID_STATE',
      ));
      return;
    }

    final currentState = state as GroupFormationInProgress;

    _selectedMemberAgentIds.remove(event.agentId);

    emit(GroupFormationInProgress(
      nearbyUsers: currentState.nearbyUsers,
      friendAgentIds: currentState.friendAgentIds,
      selectedMemberAgentIds: _selectedMemberAgentIds,
      currentUserId: currentState.currentUserId,
    ));
  }

  /// Form group from selected members
  Future<void> _onFormGroup(
    FormGroup event,
    Emitter<GroupMatchingState> emit,
  ) async {
    try {
      if (_selectedMemberAgentIds.isEmpty &&
          event.nearbyUsers == null &&
          event.friendAgentIds == null) {
        emit(GroupMatchingError(
          message: 'Cannot form group: no members selected',
          errorCode: 'NO_MEMBERS',
        ));
        return;
      }

      emit(GroupMatchingLoading());

      GroupSession session;

      // Determine formation method and create session
      if (event.nearbyUsers != null && event.friendAgentIds != null) {
        // Hybrid approach
        session = await _formationService.formGroupHybrid(
          currentUserId: event.currentUserId,
          discoveredUsers: event.nearbyUsers,
          friendAgentIds: event.friendAgentIds,
        );
      } else if (event.nearbyUsers != null && event.nearbyUsers!.isNotEmpty) {
        // Proximity-based
        session = await _formationService.formGroupFromNearbyUsers(
          currentUserId: event.currentUserId,
          discoveredUsers: event.nearbyUsers!,
        );
      } else if (event.friendAgentIds != null &&
          event.friendAgentIds!.isNotEmpty) {
        // Manual friend selection
        session = await _formationService.formGroupFromFriends(
          currentUserId: event.currentUserId,
          friendAgentIds: event.friendAgentIds!,
        );
      } else {
        // Use selected members from state
        if (_selectedMemberAgentIds.isEmpty) {
          emit(GroupMatchingError(
            message: 'Cannot form group: no members selected',
            errorCode: 'NO_MEMBERS',
          ));
          return;
        }

        // Convert selected members to discovered users or friends
        // For simplicity, treat as friends
        session = await _formationService.formGroupFromFriends(
          currentUserId: event.currentUserId,
          friendAgentIds: _selectedMemberAgentIds,
        );
      }

      emit(GroupFormed(session: session));
    } catch (e, stackTrace) {
      developer.log(
        'Error forming group: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      emit(GroupMatchingError(
        message: 'Failed to form group: ${e.toString()}',
        errorCode: 'GROUP_FORMATION_ERROR',
      ));
    }
  }

  /// Start group search (match group against spots)
  Future<void> _onStartGroupSearch(
    StartGroupSearch event,
    Emitter<GroupMatchingState> emit,
  ) async {
    try {
      emit(GroupMatchingLoading());

      // Get candidate spots
      List<Spot> candidateSpots = [];

      if (_searchRepository != null) {
        if (event.searchQuery != null && event.searchQuery!.isNotEmpty) {
          // Search by query
          final searchResult = await _searchRepository.searchSpots(
            query: event.searchQuery!,
            latitude: event.latitude,
            longitude: event.longitude,
            maxResults: 50,
          );
          candidateSpots = searchResult.spots;
        } else if (event.latitude != null && event.longitude != null) {
          // Search nearby
          final searchResult = await _searchRepository.searchNearbySpots(
            latitude: event.latitude!,
            longitude: event.longitude!,
            radius: event.radius ?? 5000,
            maxResults: 50,
          );
          candidateSpots = searchResult.spots;
        } else {
          // Default: get all spots (limited)
          final searchResult = await _searchRepository.searchSpots(
            query: '',
            maxResults: 50,
          );
          candidateSpots = searchResult.spots;
        }
      }

      if (candidateSpots.isEmpty) {
        emit(GroupMatchingError(
          message: 'No spots found to match against',
          errorCode: 'NO_SPOTS',
        ));
        return;
      }

      // Create input for controller
      final input = GroupMatchingInput(
        currentUser: event.currentUser,
        session: event.session,
        candidateSpots: candidateSpots,
        searchQuery: event.searchQuery,
        latitude: event.latitude,
        longitude: event.longitude,
        radius: event.radius,
      );

      // Execute matching via controller
      final result = await _controller.execute(input);

      if (!result.success) {
        emit(GroupMatchingError(
          message: result.error ?? 'Group matching failed',
          errorCode: result.errorCode,
        ));
        return;
      }

      if (result.matchingResult == null) {
        emit(GroupMatchingError(
          message: 'No matching result returned',
          errorCode: 'NO_RESULT',
        ));
        return;
      }

      // Extract compatibility scores from matched spots
      final compatibilityScores = <String, double>{};
      for (final matchedSpot in result.matchingResult!.matchedSpots) {
        compatibilityScores[matchedSpot.spot.id] =
            matchedSpot.groupCompatibility;
      }

      emit(GroupMatchingResults(
        matchingResult: result.matchingResult!,
        matchedSpots: result.matchingResult!.matchedSpots,
        compatibilityScores: compatibilityScores,
      ));
    } catch (e, stackTrace) {
      developer.log(
        'Error starting group search: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      emit(GroupMatchingError(
        message: 'Failed to search for spots: ${e.toString()}',
        errorCode: 'SEARCH_ERROR',
      ));
    }
  }

  /// Retry search with same parameters
  Future<void> _onRetrySearch(
    RetrySearch event,
    Emitter<GroupMatchingState> emit,
  ) async {
    // Get last search parameters from state
    if (state is GroupMatchingResults || state is GroupFormed) {
      // Retry with same session (would need to store search params)
      // For now, just emit error
      emit(GroupMatchingError(
        message: 'Retry not yet implemented. Please start a new search.',
        errorCode: 'RETRY_NOT_IMPLEMENTED',
      ));
    } else {
      emit(GroupMatchingError(
        message: 'Cannot retry: no previous search to retry',
        errorCode: 'NO_PREVIOUS_SEARCH',
      ));
    }
  }

  /// Clear group and start over
  void _onClearGroup(
    ClearGroup event,
    Emitter<GroupMatchingState> emit,
  ) {
    _nearbyUsers.clear();
    _friendAgentIds.clear();
    _selectedMemberAgentIds.clear();
    _currentUserId = null;

    emit(GroupMatchingInitial());
  }
}
