// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:avrai/presentation/pages/auth/auth_wrapper.dart';
import 'package:avrai/presentation/pages/auth/login_page.dart';
import 'package:avrai/presentation/pages/auth/signup_page.dart';
import 'package:avrai/presentation/pages/home/home_page.dart';
import 'package:avrai/presentation/pages/spots/spots_page.dart';
import 'package:avrai/presentation/pages/lists/lists_page.dart';
import 'package:avrai/presentation/pages/map/map_page.dart';
import 'package:avrai/presentation/pages/profile/profile_page.dart';
import 'package:avrai/presentation/pages/profile/beta_feedback_page.dart';
import 'package:avrai/presentation/pages/profile/data_center_page.dart';
import 'package:avrai/apps/consumer_app/ui/pages/profile/ai_personality_status_page.dart';
import 'package:avrai/presentation/pages/chat/unified_chat_page.dart';
import 'package:avrai/presentation/pages/chat/agent_chat_view.dart';
import 'package:avrai/presentation/pages/chat/admin_support_chat_view.dart';
import 'package:avrai/presentation/pages/chat/event_chat_view.dart';
import 'package:avrai/presentation/pages/chat/friend_chat_view.dart';
import 'package:avrai/presentation/pages/chat/community_chat_view.dart';
import 'package:avrai/presentation/pages/expertise/expertise_dashboard_page.dart';
import 'package:avrai/presentation/pages/onboarding/onboarding_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:avrai/presentation/pages/onboarding/ai_loading_page.dart';
import 'package:avrai/presentation/pages/onboarding/bham_walkthrough_page.dart';
import 'package:avrai/presentation/pages/onboarding/knot_birth_page.dart';
import 'package:avrai/presentation/pages/onboarding/knot_discovery_page.dart';
import 'package:avrai/presentation/pages/world_planes/world_planes_page.dart';
import 'package:avrai/presentation/pages/supabase_test_page.dart';
import 'package:avrai/presentation/pages/search/hybrid_search_page.dart';
// Phase 19.18: Quantum Group Matching System
import 'package:avrai/presentation/pages/group/group_formation_page.dart';
import 'package:avrai/presentation/pages/group/group_results_page.dart';
import 'package:avrai/presentation/blocs/group_matching_bloc.dart';
import 'package:avrai/presentation/pages/business/business_signup_page.dart';
import 'package:avrai/presentation/pages/business/business_login_page.dart';
import 'package:avrai/presentation/pages/business/business_dashboard_page.dart';
import 'package:avrai/presentation/blocs/lists/lists_bloc.dart';
import 'package:avrai/presentation/blocs/spots/spots_bloc.dart';
import 'package:avrai/presentation/blocs/search/hybrid_search_bloc.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai_runtime_os/data/datasources/local/onboarding_completion_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
// Phase 1 Integration: Device Discovery & AI2AI Connections
import 'package:avrai/presentation/pages/network/device_discovery_page.dart';
import 'package:avrai/presentation/pages/network/ai2ai_connections_page.dart';
import 'package:avrai/presentation/pages/settings/discovery_settings_page.dart';
// Phase 2.1: Federated Learning
import 'package:avrai/presentation/pages/settings/federated_learning_page.dart';
import 'package:avrai/presentation/pages/settings/on_device_ai_settings_page.dart';
// Phase 7, Week 37: AI Self-Improvement Visibility
import 'package:avrai/presentation/pages/settings/ai_improvement_page.dart';
// Phase 7, Week 38: AI2AI Learning Methods UI
import 'package:avrai/presentation/pages/settings/ai2ai_learning_methods_page.dart';
// Phase 7, Section 39: Continuous Learning UI
import 'package:avrai/presentation/pages/settings/continuous_learning_page.dart';
// Phase 4.5: Partnerships Page
import 'package:avrai/presentation/pages/profile/partnerships_page.dart';
import 'package:avrai/presentation/pages/debug/geo_area_evolution_debug_page.dart';
import 'package:avrai/presentation/pages/debug/proof_run_page.dart';
import 'package:avrai/presentation/pages/receipts/receipt_detail_page.dart';
import 'package:avrai/presentation/pages/receipts/receipts_page.dart';
// Phase 10: Social Media Integration - Friend Discovery
import 'package:avrai/presentation/pages/social/friend_discovery_page.dart';
import 'package:avrai/presentation/pages/social/add_friend_qr_page.dart';
import 'package:avrai/presentation/pages/social/scan_friend_qr_page.dart';
// Phase 10: Social Media Integration - Public Handles
import 'package:avrai/presentation/pages/settings/public_handles_page.dart';
import 'package:avrai/presentation/pages/admin/admin_desktop_handoff_page.dart';
// Phase 6, Week 29: Communities & Clubs
import 'package:avrai/presentation/pages/communities/community_page.dart';
import 'package:avrai/presentation/pages/communities/create_community_page.dart';
import 'package:avrai/presentation/pages/communities/communities_discover_page.dart';
import 'package:avrai/presentation/pages/clubs/club_page.dart';
import 'package:avrai/presentation/pages/clubs/create_club_page.dart';
// Detail Pages
import 'package:avrai/presentation/pages/events/create_event_page.dart';
import 'package:avrai/presentation/pages/events/event_details_page.dart';
import 'package:avrai/presentation/pages/lists/list_details_page.dart';
import 'package:avrai/presentation/pages/spots/spot_details_page.dart';
import 'package:avrai/presentation/pages/spots/create_spot_page.dart';
import 'package:avrai/presentation/pages/spots/edit_spot_page.dart';
import 'package:avrai/presentation/pages/lists/create_list_page.dart';
import 'package:avrai/presentation/pages/lists/edit_list_page.dart';
import 'package:avrai_core/models/misc/list.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_runtime_os/domain/repositories/lists_repository.dart';
import 'package:avrai_runtime_os/domain/repositories/spots_repository.dart';
import 'package:avrai_runtime_os/data/repositories/spots_repository_impl.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai_core/models/user/user.dart';
// Phase 15: Reservations
import 'package:avrai/presentation/pages/reservations/my_reservations_page.dart';
import 'package:avrai/presentation/pages/reservations/create_reservation_page.dart';
import 'package:avrai/presentation/pages/reservations/reservation_detail_page.dart';
import 'package:avrai/presentation/pages/reservations/user_reservation_analytics_page.dart';
import 'package:avrai/presentation/pages/business/reservations/business_reservation_analytics_page.dart';
import 'package:avrai_core/models/misc/reservation.dart';
import 'package:avrai_runtime_os/config/bham_beta_defaults.dart';
import 'package:avrai_runtime_os/config/design_feature_flags.dart';
import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';

class AppRouter {
  // Route path helpers for legacy Navigator.pushNamed usages
  static const String home = '/home';
  static const String signup = '/signup';
  // Phase 19.18: Quantum Group Matching System
  static const String groupFormation = '/group/formation';
  static const String groupResults = '/group/results';

  static GoRouter build({required AuthBloc authBloc}) {
    const bool goToSupabaseTest = bool.fromEnvironment('GO_TO_SUPABASE_TEST');
    const bool autoDriveSupabase =
        bool.fromEnvironment('AUTO_DRIVE_SUPABASE_TEST');
    const bool isIntegrationTest = bool.fromEnvironment('FLUTTER_TEST');
    const bool enableProofRun = bool.fromEnvironment('ENABLE_PROOF_RUN');

    // Safely get Firebase Analytics - may be null if Firebase isn't initialized
    FirebaseAnalytics? analytics;
    try {
      analytics = FirebaseAnalytics.instance;
    } catch (e) {
      developer.log('Firebase Analytics not available: $e', name: 'AppRouter');
      analytics = null;
    }

    return GoRouter(
      initialLocation: goToSupabaseTest
          ? (autoDriveSupabase ? '/supabase-test?auto=1' : '/supabase-test')
          : '/',
      refreshListenable: _GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) async {
        final isLoggingIn = state.matchedLocation == '/login' ||
            state.matchedLocation == '/signup';
        final isOnboarding = state.matchedLocation == '/onboarding';
        final isRoot = state.matchedLocation == '/';
        final isSupabaseTest =
            state.matchedLocation.startsWith('/supabase-test');

        // When test flag is enabled, always allow and prefer the Supabase test page
        if (goToSupabaseTest) {
          if (!isSupabaseTest) {
            return autoDriveSupabase
                ? '/supabase-test?auto=1'
                : '/supabase-test';
          }
          return null;
        }

        final authState = authBloc.state;

        if (authState is Authenticated) {
          // Integration tests: skip onboarding/permission redirects to keep navigation deterministic.
          if (isIntegrationTest) {
            if (isLoggingIn || isRoot) return '/home';
            return null;
          }

          // Allow onboarding journey pages to proceed without redirect
          if (state.matchedLocation == '/ai-loading' ||
              state.matchedLocation == '/knot-birth' ||
              state.matchedLocation == '/knot-discovery') {
            return null;
          }

          // If authenticated, ensure onboarding completed for this specific user
          // OnboardingCompletionService uses in-memory cache to prevent race conditions
          // No delay needed - cache is checked first and is immediately available
          // Check onboarding completion status
          // Note: Logging is done in OnboardingCompletionService
          final onboardingDone =
              await OnboardingCompletionService.isOnboardingCompleted(
                  authState.user.id);

          if (!onboardingDone) {
            // If already on onboarding or ai-loading page, allow navigation within onboarding flow
            if (isOnboarding ||
                state.matchedLocation == '/ai-loading' ||
                state.matchedLocation == '/knot-birth' ||
                state.matchedLocation == '/knot-discovery') {
              return null; // Allow navigation within onboarding flow
            }
            // If trying to access other pages (including root), redirect to onboarding
            return '/onboarding';
          } else {
            // Onboarding is completed - allow user to proceed to home
            // Don't redirect back to onboarding just because permissions aren't granted
            // Permissions can be requested later or user can proceed without them

            // If on root, login, or signup pages, redirect to home
            if (isRoot || isLoggingIn || state.matchedLocation == '/signup') {
              return '/home';
            }

            // If on onboarding page but onboarding is done, redirect to home
            if (isOnboarding) {
              return '/home';
            }
          }

          // Allow navigation to other pages (home, spots, lists, etc.)
          return null;
        }

        // Unauthenticated: allow login/signup/onboarding/root; also allow supabase-test when running in test mode
        if (!(isLoggingIn || isOnboarding || isRoot || isSupabaseTest)) {
          return '/login';
        }
        return null;
      },
      observers: analytics != null
          ? [
              FirebaseAnalyticsObserver(analytics: analytics),
            ]
          : [],
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const AuthWrapper(),
          routes: [
            GoRoute(path: 'login', builder: (c, s) => const LoginPage()),
            GoRoute(path: 'signup', builder: (c, s) => const SignupPage()),
            GoRoute(path: 'home', builder: (c, s) => const HomePage()),
            GoRoute(path: 'spots', builder: (c, s) => const SpotsPage()),
            GoRoute(path: 'lists', builder: (c, s) => const ListsPage()),
            // Detail Pages
            GoRoute(
              path: 'list/:id',
              builder: (c, s) {
                final id = s.pathParameters['id']!;
                return FutureBuilder<SpotList?>(
                  future: _loadListById(id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const AppFlowScaffold(
                        title: '',
                        showNavigationBar: false,
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasData && snapshot.data != null) {
                      return ListDetailsPage(list: snapshot.data!);
                    }
                    return const AppFlowScaffold(
                      title: 'List Not Found',
                      body: Center(
                        child: Text('The requested list could not be found.'),
                      ),
                    );
                  },
                );
              },
            ),
            GoRoute(
              path: 'spot/:id',
              builder: (c, s) {
                final id = s.pathParameters['id']!;
                return FutureBuilder<Spot?>(
                  future: _loadSpotById(id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const AppFlowScaffold(
                        title: '',
                        showNavigationBar: false,
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasData && snapshot.data != null) {
                      return SpotDetailsPage(spot: snapshot.data!);
                    }
                    return const AppFlowScaffold(
                      title: 'Spot Not Found',
                      body: Center(
                        child: Text('The requested spot could not be found.'),
                      ),
                    );
                  },
                );
              },
            ),
            GoRoute(
              path: 'spot/create',
              builder: (c, s) => const CreateSpotPage(),
            ),
            GoRoute(
              path: 'spot/:id/edit',
              builder: (c, s) {
                final id = s.pathParameters['id']!;
                return FutureBuilder<Spot?>(
                  future: _loadSpotById(id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const AppFlowScaffold(
                        title: '',
                        showNavigationBar: false,
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasData && snapshot.data != null) {
                      return EditSpotPage(spot: snapshot.data!);
                    }
                    return const AppFlowScaffold(
                      title: 'Spot Not Found',
                      body: Center(
                        child: Text('The requested spot could not be found.'),
                      ),
                    );
                  },
                );
              },
            ),
            GoRoute(
              path: 'event/create',
              builder: (c, s) => const CreateEventPage(),
            ),
            GoRoute(
              path: 'event/:id',
              builder: (c, s) {
                final id = s.pathParameters['id']!;
                return FutureBuilder(
                  future: _loadEventById(id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const AppFlowScaffold(
                        title: '',
                        showNavigationBar: false,
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasData && snapshot.data != null) {
                      return EventDetailsPage(event: snapshot.data!);
                    }
                    return const AppFlowScaffold(
                      title: 'Event Not Found',
                      body: Center(
                        child: Text('The requested event could not be found.'),
                      ),
                    );
                  },
                );
              },
            ),
            GoRoute(
              path: 'list/create',
              builder: (c, s) => const CreateListPage(),
            ),
            GoRoute(
              path: 'list/:id/edit',
              builder: (c, s) {
                final id = s.pathParameters['id']!;
                return FutureBuilder<SpotList?>(
                  future: _loadListById(id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const AppFlowScaffold(
                        title: '',
                        showNavigationBar: false,
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasData && snapshot.data != null) {
                      return EditListPage(list: snapshot.data!);
                    }
                    return const AppFlowScaffold(
                      title: 'List Not Found',
                      body: Center(
                        child: Text('The requested list could not be found.'),
                      ),
                    );
                  },
                );
              },
            ),
            GoRoute(
              path: 'map',
              redirect: (context, state) async {
                // Skip permission check on web
                if (kIsWeb) {
                  return null;
                }
                try {
                  final locWhenInUse =
                      await Permission.locationWhenInUse.status;
                  if (!locWhenInUse.isGranted && !locWhenInUse.isLimited) {
                    return '/onboarding?reason=location_required';
                  }
                } catch (e) {
                  // If permission check fails, allow access
                }
                return null;
              },
              builder: (context, state) => MultiBlocProvider(
                providers: [
                  BlocProvider.value(
                      value: BlocProvider.of<ListsBloc>(context)),
                  BlocProvider.value(
                      value: BlocProvider.of<SpotsBloc>(context)),
                ],
                child: const MapPage(),
              ),
            ),
            GoRoute(path: 'profile', builder: (c, s) => const ProfilePage()),
            GoRoute(
              path: 'settings',
              builder: (c, s) =>
                  const ProfilePage(), // Settings is part of ProfilePage
            ),
            // Phase 15: Reservations
            GoRoute(
              path: 'reservations',
              builder: (c, s) => const MyReservationsPage(),
            ),
            GoRoute(
              path: 'reservations/create',
              builder: (c, s) {
                final extra = s.extra as Map<String, dynamic>?;
                return CreateReservationPage(
                  type: extra?['type'] as ReservationType?,
                  targetId: extra?['targetId'] as String?,
                  targetTitle: extra?['targetTitle'] as String?,
                );
              },
            ),
            GoRoute(
              path: 'reservations/:id',
              builder: (c, s) {
                final id = s.pathParameters['id']!;
                return ReservationDetailPage(reservationId: id);
              },
            ),
            GoRoute(
              path: 'reservations/analytics',
              builder: (c, s) => const UserReservationAnalyticsPage(),
            ),
            GoRoute(
              path: 'profile/beta-feedback',
              builder: (c, s) => const BetaFeedbackPage(),
            ),
            GoRoute(
              path: 'profile/ai-status',
              builder: (c, s) => const AIPersonalityStatusPage(),
            ),
            GoRoute(
              path: 'profile/data-center',
              builder: (c, s) => DataCenterPage(
                focusEnvelopeId:
                    s.uri.queryParameters[DataCenterPage.focusRecordQueryParam],
                focusEntityTitle:
                    s.uri.queryParameters[DataCenterPage.focusEntityQueryParam],
              ),
            ),
            GoRoute(
              path: 'profile/receipts',
              builder: (c, s) => const ReceiptsPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (c, s) {
                    final id = s.pathParameters['id']!;
                    return ReceiptDetailPage(ledgerRowId: id);
                  },
                ),
              ],
            ),
            // Phase 3: Unified Chat
            GoRoute(
              path: 'chat',
              builder: (c, s) => const UnifiedChatPage(),
              routes: [
                GoRoute(
                  path: 'agent',
                  builder: (c, s) => const AgentChatView(),
                ),
                GoRoute(
                  path: 'admin',
                  builder: (c, s) => const AdminSupportChatView(),
                ),
                GoRoute(
                  path: 'friend/:friendId',
                  builder: (c, s) {
                    final friendId = s.pathParameters['friendId']!;
                    return FriendChatView(friendId: friendId);
                  },
                ),
                GoRoute(
                  path: 'community/:communityId',
                  builder: (c, s) {
                    final communityId = s.pathParameters['communityId']!;
                    return CommunityChatView(communityId: communityId);
                  },
                ),
                GoRoute(
                  path: 'event/:eventId',
                  builder: (c, s) {
                    final eventId = s.pathParameters['eventId']!;
                    final title =
                        s.uri.queryParameters['title'] ?? 'Event Chat';
                    return EventChatView(
                      threadId: 'event:$eventId',
                      title: title,
                    );
                  },
                ),
                GoRoute(
                  path: 'announcement/:scope/:scopeId',
                  builder: (c, s) {
                    final scope = s.pathParameters['scope']!;
                    final scopeId = s.pathParameters['scopeId']!;
                    final title =
                        s.uri.queryParameters['title'] ?? 'Announcements';
                    return EventChatView(
                      threadId: 'announcement:$scope:$scopeId',
                      title: title,
                      readOnly: true,
                    );
                  },
                ),
              ],
            ),
            GoRoute(
              path: 'profile/expertise-dashboard',
              builder: (c, s) => const ExpertiseDashboardPage(),
            ),
            // Phase 4.5: Partnerships Page
            GoRoute(
              path: 'profile/partnerships',
              redirect: (context, state) {
                if (!BhamBetaDefaults.enablePartnershipSurfaces) {
                  return '/profile';
                }
                return null;
              },
              builder: (c, s) => const PartnershipsPage(),
            ),
            // Phase 10: Social Media Integration - Friend Discovery
            GoRoute(
              path: 'friends/discover',
              builder: (c, s) => const FriendDiscoveryPage(),
            ),
            // QR Code Friending
            GoRoute(
              path: 'friends/qr/add',
              builder: (c, s) => const AddFriendQRPage(),
            ),
            GoRoute(
              path: 'friends/qr/scan',
              builder: (c, s) => const ScanFriendQRPage(),
            ),
            // Phase 10: Social Media Integration - Public Handles
            GoRoute(
              path: 'settings/public-handles',
              builder: (c, s) => const PublicHandlesPage(),
            ),
            // Phase 6, Week 29: Communities & Clubs
            GoRoute(
              path: 'community/:id',
              builder: (c, s) {
                final id = s.pathParameters['id']!;
                return CommunityPage(communityId: id);
              },
            ),
            GoRoute(
              path: 'community/create',
              builder: (c, s) => const CreateCommunityPage(),
            ),
            GoRoute(
              path: 'communities/discover',
              builder: (c, s) => const CommunitiesDiscoverPage(),
            ),
            GoRoute(
              path: 'club/:id',
              builder: (c, s) {
                final id = s.pathParameters['id']!;
                return ClubPage(clubId: id);
              },
            ),
            GoRoute(
              path: 'club/create',
              builder: (c, s) => const CreateClubPage(),
            ),
            GoRoute(
              path: 'admin/fraud-review/:eventId',
              redirect: (context, state) async {
                final authState = authBloc.state;

                // Check authentication
                if (authState is! Authenticated) {
                  return '/login';
                }

                // Check admin role
                if (authState.user.role != UserRole.admin) {
                  return '/home';
                }

                return null;
              },
              builder: (c, s) {
                final eventId = s.pathParameters['eventId']!;
                return AdminDesktopHandoffPage(
                  requestedSurfaceTitle: 'Fraud Review',
                  requestedPath: '/admin/fraud-review/$eventId',
                );
              },
            ),
            GoRoute(
              path: 'admin/fraud-review/:eventId/review',
              redirect: (context, state) async {
                final authState = authBloc.state;

                // Check authentication
                if (authState is! Authenticated) {
                  return '/login';
                }

                // Check admin role
                if (authState.user.role != UserRole.admin) {
                  return '/home';
                }

                return null;
              },
              builder: (c, s) {
                final eventId = s.pathParameters['eventId']!;
                return AdminDesktopHandoffPage(
                  requestedSurfaceTitle: 'Fraud Review',
                  requestedPath: '/admin/fraud-review/$eventId/review',
                );
              },
            ),
            GoRoute(
              path: 'admin/user/:id',
              redirect: (context, state) async {
                final authState = authBloc.state;

                // Check authentication
                if (authState is! Authenticated) {
                  return '/login';
                }

                // Check admin role
                if (authState.user.role != UserRole.admin) {
                  return '/home';
                }

                return null;
              },
              builder: (c, s) {
                final userId = s.pathParameters['id']!;
                return AdminDesktopHandoffPage(
                  requestedSurfaceTitle: 'User Detail',
                  requestedPath: '/admin/user/$userId',
                );
              },
            ),
            GoRoute(
              path: 'admin/communication/:id',
              redirect: (context, state) async {
                final authState = authBloc.state;

                // Check authentication
                if (authState is! Authenticated) {
                  return '/login';
                }

                // Check admin role
                if (authState.user.role != UserRole.admin) {
                  return '/home';
                }

                return null;
              },
              builder: (c, s) {
                final connectionId = s.pathParameters['id']!;
                return AdminDesktopHandoffPage(
                  requestedSurfaceTitle: 'Communication Detail',
                  requestedPath: '/admin/communication/$connectionId',
                );
              },
            ),
            GoRoute(
              path: 'admin/club/:id',
              redirect: (context, state) async {
                final authState = authBloc.state;

                // Check authentication
                if (authState is! Authenticated) {
                  return '/login';
                }

                // Check admin role
                if (authState.user.role != UserRole.admin) {
                  return '/home';
                }

                return null;
              },
              builder: (c, s) {
                final clubId = s.pathParameters['id']!;
                return AdminDesktopHandoffPage(
                  requestedSurfaceTitle: 'Club Detail',
                  requestedPath: '/admin/club/$clubId',
                );
              },
            ),
            // Phase 11 Section 8: Learning Quality Monitoring
            GoRoute(
              path: 'admin/learning-analytics',
              redirect: (context, state) async {
                final authState = authBloc.state;

                // Check authentication
                if (authState is! Authenticated) {
                  return '/login';
                }

                // Check admin role (optional - can be removed if all users should access)
                // if (authState.user.role != UserRole.admin) {
                //   return '/home';
                // }

                return null;
              },
              builder: (c, s) => const AdminDesktopHandoffPage(
                requestedSurfaceTitle: 'Learning Analytics',
                requestedPath: '/admin/learning-analytics',
              ),
            ),
            // Business Routes
            GoRoute(
              path: 'business/signup',
              redirect: (context, state) {
                if (!BhamBetaDefaults.enableBusinessAccountSurfaces) {
                  return '/home';
                }
                return null;
              },
              builder: (c, s) => const BusinessSignupPage(),
            ),
            GoRoute(
              path: 'business/login',
              redirect: (context, state) {
                if (!BhamBetaDefaults.enableBusinessAccountSurfaces) {
                  return '/home';
                }
                return null;
              },
              builder: (c, s) => const BusinessLoginPage(),
            ),
            GoRoute(
              path: 'business/dashboard',
              redirect: (context, state) {
                if (!BhamBetaDefaults.enableBusinessAccountSurfaces) {
                  return '/home';
                }
                return null;
              },
              builder: (c, s) => const BusinessDashboardPage(),
            ),
            GoRoute(
              path: 'business/reservations/analytics',
              redirect: (context, state) {
                if (!BhamBetaDefaults.enableBusinessAccountSurfaces) {
                  return '/home';
                }
                return null;
              },
              builder: (c, s) {
                final extra = s.extra as Map<String, dynamic>?;
                return BusinessReservationAnalyticsPage(
                  businessId: extra?['businessId'] as String? ?? '',
                  type: extra?['type'] as ReservationType? ??
                      ReservationType.business,
                );
              },
            ),
            // Phase 1 Integration: Device Discovery & AI2AI Routes
            GoRoute(
              path: 'device-discovery',
              builder: (c, s) => const DeviceDiscoveryPage(),
            ),
            GoRoute(
              path: 'ai2ai-connections',
              builder: (c, s) => const AI2AIConnectionsPage(),
            ),
            GoRoute(
              path: 'discovery-settings',
              builder: (c, s) => const DiscoverySettingsPage(),
            ),
            // Phase 2.1: Federated Learning
            GoRoute(
              path: 'federated-learning',
              builder: (c, s) => const FederatedLearningPage(),
            ),
            GoRoute(
              path: 'on-device-ai',
              builder: (c, s) => const OnDeviceAiSettingsPage(),
            ),
            GoRoute(
              path: 'proof-run',
              redirect: (context, state) {
                if (kDebugMode || enableProofRun) return null;
                return '/home';
              },
              builder: (c, s) => const ProofRunPage(),
            ),
            GoRoute(
              path: 'geo-area-debug',
              redirect: (context, state) {
                if (kDebugMode) return null;
                return '/home';
              },
              builder: (c, s) => const GeoAreaEvolutionDebugPage(),
            ),
            // Phase 7, Week 37: AI Self-Improvement Visibility
            GoRoute(
              path: 'ai-improvement',
              builder: (c, s) => const AIImprovementPage(),
            ),
            // Phase 7, Week 38: AI2AI Learning Methods UI
            GoRoute(
              path: 'ai2ai-learning-methods',
              builder: (c, s) => const AI2AILearningMethodsPage(),
            ),
            // Phase 7, Section 39: Continuous Learning UI
            GoRoute(
              path: 'continuous-learning',
              builder: (c, s) => const ContinuousLearningPage(),
            ),
            GoRoute(
              path: 'supabase-test',
              builder: (c, s) {
                final auto = s.uri.queryParameters['auto'] == '1';
                return SupabaseTestPage(auto: auto);
              },
            ),
            GoRoute(
              path: 'onboarding',
              builder: (context, state) {
                final reason = state.uri.queryParameters['reason'];
                if (reason != null && reason.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final text = switch (reason) {
                      'permissions_required' =>
                        'Permissions required for ai2ai connectivity. Please enable to continue.',
                      'location_required' =>
                        'Location permission required to use the map.',
                      _ => 'Additional permissions are required.'
                    };
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(text)),
                    );
                  });
                }
                return const OnboardingPage();
              },
            ),
            GoRoute(
              path: 'ai-loading',
              builder: (c, s) {
                // Extract onboarding data from query parameters or state
                final extra = s.extra as Map<String, dynamic>?;
                // Parse birthday if provided
                DateTime? birthday;
                if (extra?['birthday'] != null) {
                  try {
                    birthday = DateTime.parse(extra!['birthday'] as String);
                  } catch (e) {
                    // Invalid date, ignore
                  }
                }
                final age = extra?['age'] as int?;

                return AILoadingPage(
                  userName: extra?['userName'] as String? ?? 'User',
                  birthday: birthday,
                  age: age,
                  homebase: extra?['homebase'] as String?,
                  openResponses:
                      (extra?['openResponses'] as Map<String, dynamic>?)
                              ?.map((k, v) => MapEntry(k, v.toString())) ??
                          const {},
                  // Note: respectedFriends and socialMediaConnected are passed via extras
                  // but AILoadingPage loads data from OnboardingDataService, so these are
                  // primarily for fallback/verification. The page will use saved onboarding data.
                  onLoadingComplete: () {
                    try {
                      c.go('/onboarding/walkthrough');
                    } catch (e) {
                      c.go('/home');
                    }
                  },
                );
              },
            ),
            GoRoute(
              path: 'onboarding/walkthrough',
              builder: (c, s) => const BhamWalkthroughPage(),
            ),
            // Phase 3: Knot Discovery Page (optional onboarding step)
            GoRoute(
              path: 'knot-birth',
              builder: (c, s) {
                final extra = s.extra as Map<String, dynamic>?;
                final userId = extra?['userId'] as String?;

                if (!DesignFeatureFlags.enableKnotBirthExperience) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    c.go('/knot-discovery', extra: {'userId': userId});
                  });
                  return const AppFlowScaffold(
                    title: '',
                    showNavigationBar: false,
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                return KnotBirthPage(userId: userId);
              },
            ),
            // Phase 3: Knot Discovery Page (optional onboarding step)
            GoRoute(
              path: 'knot-discovery',
              builder: (c, s) {
                final extra = s.extra as Map<String, dynamic>?;
                final userId = extra?['userId'] as String?;
                final knotBirthOutcome = extra?['knotBirthOutcome'] as String?;
                final knotBirthReason = extra?['knotBirthReason'] as String?;

                // Try to get personality profile from AgentInitializationController result
                // For now, pass null - page will load it from storage
                return KnotDiscoveryPage(
                  userId: userId,
                  personalityProfile: null, // Will be loaded from storage
                  knotBirthOutcome: knotBirthOutcome,
                  knotBirthReason: knotBirthReason,
                );
              },
            ),
            GoRoute(
              path: 'world-planes',
              builder: (c, s) {
                if (!DesignFeatureFlags.enableWorldPlanesRoute) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    c.go('/home');
                  });
                  return const AppFlowScaffold(
                    title: '',
                    showNavigationBar: false,
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                return const WorldPlanesPage();
              },
            ),
            GoRoute(
              path: 'hybrid-search',
              builder: (context, state) => BlocProvider(
                create: (context) => di.sl<HybridSearchBloc>(),
                child: const HybridSearchPage(),
              ),
            ),
            // Phase 19.18: Quantum Group Matching System
            GoRoute(
              path: 'group/formation',
              builder: (context, state) => BlocProvider(
                create: (context) => di.sl<GroupMatchingBloc>(),
                child: const GroupFormationPage(),
              ),
            ),
            GoRoute(
              path: 'group/results/:sessionId',
              builder: (context, state) {
                final sessionId = state.pathParameters['sessionId'];
                return BlocProvider(
                  create: (context) => di.sl<GroupMatchingBloc>(),
                  child: GroupResultsPage(sessionId: sessionId),
                );
              },
            ),
            GoRoute(
              path: 'group/results',
              builder: (context, state) => BlocProvider(
                create: (context) => di.sl<GroupMatchingBloc>(),
                child: const GroupResultsPage(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper functions to load data by ID
  static Future<SpotList?> _loadListById(String id) async {
    try {
      // Get all lists and find by ID (since getById might not be available)
      final repository = di.sl<ListsRepository>();
      final lists = await repository.getLists();
      try {
        return lists.firstWhere((list) => list.id == id);
      } catch (e) {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<Spot?> _loadSpotById(String id) async {
    try {
      // Try to get from repository if getById method exists
      final repository = di.sl<SpotsRepository>();
      // Check if repository has getById method (might need to cast)
      if (repository is SpotsRepositoryImpl) {
        // Use the convenience method
        return await repository.getSpotById(id);
      }
      // Fallback: get all spots and find by ID
      final spots = await repository.getSpots();
      try {
        return spots.firstWhere((spot) => spot.id == id);
      } catch (e) {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<dynamic> _loadEventById(String id) async {
    try {
      final eventService = di.sl<ExpertiseEventService>();
      return await eventService.getEventById(id);
    } catch (e) {
      return null;
    }
  }
}

// Simple adapter to notify GoRouter when the auth bloc emits a new state
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// Removed _hasCriticalPermissions - no longer needed during onboarding redirect
// Permission checks are handled within the onboarding flow itself
// Once onboarding is complete, users can proceed regardless of permission status
