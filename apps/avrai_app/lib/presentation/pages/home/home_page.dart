import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/blocs/lists/lists_bloc.dart';
import 'package:avrai/presentation/blocs/spots/spots_bloc.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/pages/lists/list_details_page.dart';
import 'package:avrai/presentation/widgets/lists/spot_list_card.dart';
import 'package:avrai/presentation/widgets/map/map_view.dart';
import 'package:avrai/presentation/widgets/common/search_bar.dart';
import 'package:avrai/presentation/widgets/common/chat_message.dart';
import 'package:avrai/presentation/widgets/common/universal_ai_search.dart';
import 'package:avrai/presentation/widgets/common/ai_command_processor.dart';
import 'package:avrai_runtime_os/domain/repositories/lists_repository.dart';
import 'package:avrai_core/models/misc/list.dart';
import 'package:geolocator/geolocator.dart';
// Phase 1 Integration: Offline indicator
import 'package:avrai/presentation/widgets/common/offline_indicator_widget.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:avrai/presentation/pages/events/events_browse_page.dart';
import 'package:avrai/presentation/widgets/chat/chat_button_with_badge.dart';
import 'package:go_router/go_router.dart';
import 'package:avrai_runtime_os/config/design_feature_flags.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/common/app_surface.dart';
import 'package:avrai/presentation/pages/feed/daily_serendipity_drop_feed.dart';
import 'package:avrai/presentation/models/daily_serendipity_drop.dart';
import 'package:avrai/presentation/pages/chat/world_model_ai_page.dart';
import 'package:avrai/presentation/pages/explore/explore_page.dart';
import 'package:avrai/presentation/widgets/portal/turbine_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DailySerendipityDropFeedWrapper extends StatefulWidget {
  const DailySerendipityDropFeedWrapper({super.key});

  @override
  State<DailySerendipityDropFeedWrapper> createState() =>
      _DailySerendipityDropFeedWrapperState();
}

class _DailySerendipityDropFeedWrapperState
    extends State<DailySerendipityDropFeedWrapper> {
  DailySerendipityDrop? _drop;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDrop();
  }

  Future<void> _loadDrop() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dropJson = prefs.getString('latest_daily_serendipity_drop');

      if (dropJson != null) {
        setState(() {
          _drop = DailySerendipityDrop.fromJson(jsonDecode(dropJson));
          _isLoading = false;
        });
      } else {
        // Create a realistic-looking empty state or default drop if none exists
        setState(() {
          _drop = DailySerendipityDrop(
            date: DateTime.now(),
            llmContextualInsight:
                "Your AI is still learning your resonance patterns. Walk around the city to gather more serendipitous encounters.",
            event: DropEvent(
              id: 'ev_0',
              title: "Discover the City",
              subtitle: "Start moving to find events",
              locationName: "Anywhere",
              time: DateTime.now().add(const Duration(hours: 2)),
              archetypeAffinity: 0.5,
            ),
            spot: DropSpot(
              id: 'sp_0',
              title: "Explore Hidden Gems",
              subtitle: "We'll suggest spots once we know your vibe",
              category: "Exploration",
              distanceMiles: 0.0,
              archetypeAffinity: 0.5,
            ),
            community: DropCommunity(
              id: 'co_0',
              title: "Local Groups",
              subtitle: "Connect to find communities",
              memberCount: 0,
              commonInterests: ["Discovery"],
              archetypeAffinity: 0.5,
            ),
            club: DropClub(
              id: 'cl_0',
              title: "Secret Clubs",
              subtitle: "Awaiting your first physical interaction",
              applicationStatus: "Locked",
              vibe: "Unknown",
              archetypeAffinity: 0.5,
            ),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: TurbineLoader());
    }

    if (_drop == null) {
      return const Center(
          child: Text("No daily drop available.",
              style: TextStyle(color: AppColors.white)));
    }

    return DailySerendipityDropFeed(drop: _drop!);
  }
}

class HomePage extends StatefulWidget {
  final int initialTabIndex;

  const HomePage({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _currentIndex;

  final List<Widget> _pages = [
    const DailySerendipityDropFeedWrapper(),
    const ExplorePage(),
    const SpotsTab(),
    const AITab(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
    // Load lists when the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListsBloc>().add(LoadLists());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          Navigator.pushReplacementNamed(context, '/');
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return const AdaptivePlatformPageScaffold(
              title: 'avrai',
              showNavigationBar: false,
              constrainBody: false,
              body: Center(child: TurbineLoader()),
            );
          }

          if (state is Authenticated) {
            return _buildAuthenticatedContent(context, state);
          }

          return _buildUnauthenticatedContent(context);
        },
      ),
    );
  }

  Widget _buildAuthenticatedContent(BuildContext context, Authenticated state) {
    return AdaptivePlatformPageScaffold(
      title: 'avrai',
      showNavigationBar: false,
      constrainBody: false,
      body: Stack(
        children: [
          // Main content
          Positioned.fill(
            child: Builder(
              builder: (context) {
                return AdaptivePaneLayout(
                  primary: IndexedStack(
                    index: _currentIndex,
                    children: _pages,
                  ),
                  secondary: null,
                );
              },
            ),
          ),
          // Phase 7 Week 35: Full OfflineIndicatorWidget integration
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: StreamBuilder<List<ConnectivityResult>>(
                stream: Connectivity().onConnectivityChanged,
                initialData: const [ConnectivityResult.none],
                builder: (context, snapshot) {
                  final connectivityResults =
                      snapshot.data ?? [ConnectivityResult.none];
                  final isOffline =
                      connectivityResults.contains(ConnectivityResult.none);

                  return AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: isOffline
                        ? OfflineIndicatorWidget(
                            isOffline: isOffline,
                            onRetry: () async {
                              // Retry connectivity check
                              final connectivity = Connectivity();
                              final result =
                                  await connectivity.checkConnectivity();
                              final isNowOnline =
                                  !result.contains(ConnectivityResult.none);

                              if (isNowOnline && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Connection restored!'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            },
                            showDismiss: true,
                          )
                        : const SizedBox.shrink(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bolt), label: 'Daily Drop'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.place), label: 'Spots'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'AI'),
        ],
      ),
      floatingActionButton: DesignFeatureFlags.enableWorldPlanesRoute
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/world-planes'),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('World Planes'),
            )
          : null,
      // Remove the invasive offline FAB - offline status is now shown in profile page
    );
  }

  Widget _buildUnauthenticatedContent(BuildContext context) {
    final spacing = context.spacing;

    return AdaptivePlatformPageScaffold(
      title: 'avrai',
      automaticallyImplyLeading: false,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on,
              size: 80,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: spacing.md),
            Text(
              'Welcome to avrai',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: spacing.xs),
            Text(
              'Explore places, events, and communities with guidance from your AI.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing.xl),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Sign In'),
            ),
            SizedBox(height: spacing.md),
            TextButton(
              onPressed: () => context.go('/signup'),
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}

// Tab Widgets
class MapTab extends StatelessWidget {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const MapView(
      showAppBar: true,
      appBarTitle: 'Map',
    );
  }
}

class SpotsTab extends StatefulWidget {
  const SpotsTab({super.key});

  @override
  State<SpotsTab> createState() => _SpotsTabState();
}

class _SpotsTabState extends State<SpotsTab> {
  @override
  void initState() {
    super.initState();
    // Load lists when this tab is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ListsBloc>().add(LoadLists());
      // Also load spots from respected lists
      context.read<SpotsBloc>().add(LoadSpotsWithRespected());
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Spots',
      constrainBody: false,
      leading: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            return IconButton(
              icon: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  (state.user.displayName ?? state.user.name)
                      .substring(0, 1)
                      .toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onPressed: () {
                _showProfileMenu(context);
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
      actions: const [
        ChatButtonWithBadge(),
      ],
      body: Column(
        children: [
          // Search bar below app bar
          CustomSearchBar(
            hintText: 'Search saved spots and lists...',
            onChanged: (value) {
              context.read<ListsBloc>().add(SearchLists(value));
            },
          ),
          // Content with tabs
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  // Tab bar
                  Container(
                    color: AppColors.transparent,
                    child: const TabBar(
                      labelColor: AppTheme.primaryColor,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppTheme.primaryColor,
                      tabs: [
                        Tab(text: 'My Lists'),
                        Tab(text: 'Respected Lists'),
                      ],
                    ),
                  ),
                  // Tab content
                  Expanded(
                    child: TabBarView(
                      children: [
                        // My Lists Tab
                        BlocBuilder<ListsBloc, ListsState>(
                          builder: (context, state) {
                            if (state is ListsLoading) {
                              return const Center(child: TurbineLoader());
                            }

                            if (state is ListsLoaded) {
                              if (state.filteredLists.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.list,
                                        size: 64,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No lists yet. Create your first list!',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return ListView.builder(
                                itemCount: state.filteredLists.length,
                                itemBuilder: (context, index) {
                                  final list = state.filteredLists[index];
                                  return SpotListCard(
                                    list: list,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ListDetailsPage(list: list),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            }

                            if (state is ListsError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error,
                                        size: 64, color: AppTheme.errorColor),
                                    const SizedBox(height: 16),
                                    Text('Error: ${state.message}'),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        context
                                            .read<ListsBloc>()
                                            .add(LoadLists());
                                      },
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return const Center(child: Text('No lists loaded'));
                          },
                        ),
                        // Respected Lists Tab
                        BlocBuilder<SpotsBloc, SpotsState>(
                          builder: (context, state) {
                            if (state is SpotsLoading) {
                              return const Center(child: TurbineLoader());
                            }

                            if (state is SpotsLoaded) {
                              if (state.respectedSpots.isEmpty) {
                                return const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.favorite_border,
                                          size: 64,
                                          color: AppColors.textSecondary),
                                      SizedBox(height: 16),
                                      Text(
                                        'No respected lists yet',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Respect some lists during onboarding to see them here',
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: AppColors.textSecondary),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return ListView.builder(
                                itemCount: state.respectedSpots.length,
                                itemBuilder: (context, index) {
                                  final spot = state.respectedSpots[index];
                                  return AppSurface(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    padding: EdgeInsets.zero,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: AppTheme.primaryColor
                                            .withValues(alpha: 0.1),
                                        child: Icon(
                                          _getCategoryIcon(spot.category),
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      title: Text(spot.name),
                                      subtitle: Text(spot.description),
                                      trailing: const Icon(Icons.favorite,
                                          color: AppTheme.errorColor),
                                    ),
                                  );
                                },
                              );
                            }

                            if (state is SpotsError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error,
                                        size: 64, color: AppTheme.errorColor),
                                    const SizedBox(height: 16),
                                    Text('Error: ${state.message}'),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        context
                                            .read<SpotsBloc>()
                                            .add(LoadSpotsWithRespected());
                                      },
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return const Center(
                                child: Text('No respected spots loaded'));
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        state.user.displayName?.substring(0, 1).toUpperCase() ??
                            state.user.email.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(state.user.displayName ?? 'User'),
                    subtitle: Text(state.user.email),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Sign Out'),
                    onTap: () {
                      Navigator.pop(context);
                      context.read<AuthBloc>().add(SignOutRequested());
                    },
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food & drink':
        return Icons.restaurant;
      case 'activities':
        return Icons.sports_soccer;
      case 'outdoor & nature':
        return Icons.nature;
      case 'culture & arts':
        return Icons.museum;
      case 'entertainment':
        return Icons.movie;
      default:
        return Icons.place;
    }
  }
}

class AITab extends StatelessWidget {
  const AITab({super.key});

  @override
  Widget build(BuildContext context) {
    return const WorldModelAiPage();
  }
}

class UsersSubTab extends StatefulWidget {
  const UsersSubTab({super.key});

  @override
  State<UsersSubTab> createState() => _UsersSubTabState();
}

class _UsersSubTabState extends State<UsersSubTab> {
  List<SpotList> _publicLists = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPublicLists();
  }

  Future<void> _loadPublicLists() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = GetIt.instance<ListsRepository>();
      final publicLists = await repository.getPublicLists();
      setState(() {
        _publicLists = publicLists;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: TurbineLoader());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading public lists',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPublicLists,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_publicLists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.explore,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Discover Public Lists',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'No public lists available yet.\nBe the first to create one!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPublicLists,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _publicLists.length,
        itemBuilder: (context, index) {
          final list = _publicLists[index];
          return AppSurface(
            margin: const EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.list,
                  color: AppTheme.primaryColor,
                ),
              ),
              title: Text(
                list.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (list.description.isNotEmpty)
                    Text(
                      list.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${list.respectCount} respects',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${list.spots.length} spots',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
              onTap: () {
                context.go('/list/${list.id}');
              },
            ),
          );
        },
      ),
    );
  }
}

class AISubTab extends StatefulWidget {
  const AISubTab({super.key});

  @override
  State<AISubTab> createState() => _AISubTabState();
}

class _AISubTabState extends State<AISubTab> {
  final List<Map<String, dynamic>> _messages = [];
  bool _isProcessingCommand = false;

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add({
      'message':
          "Hi! I'm your avrai AI assistant. I can help you create lists, add spots, find places, discover events, connect with users, and much more! Just tell me what you'd like to do.",
      'isUser': false,
      'timestamp': DateTime.now(),
    });
  }

  void _handleAICommand(String command) async {
    if (command.trim().isEmpty) return;

    // Add user command
    setState(() {
      _messages.add({
        'message': command,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
      _isProcessingCommand = true;
    });

    // Get userId from AuthBloc
    String? userId;
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      userId = authState.user.id;
    }

    // Get current location (optional, for spot creation)
    Position? currentLocation;
    try {
      final hasPermission = await Geolocator.checkPermission();
      if (hasPermission == LocationPermission.always ||
          hasPermission == LocationPermission.whileInUse) {
        currentLocation = await Geolocator.getCurrentPosition();
      }
    } catch (e) {
      // Location not available, continue without it
    }

    // Process command and get response
    if (!mounted) return;
    final response = await AICommandProcessor.processCommand(
      command,
      context,
      userId: userId,
      currentLocation: currentLocation,
    );

    if (!mounted) return;
    if (mounted) {
      setState(() {
        _isProcessingCommand = false;
        _messages.add({
          'message': response,
          'isUser': false,
          'timestamp': DateTime.now(),
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // AI Features Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.grey100,
            border: Border(
              bottom: BorderSide(color: AppColors.grey200),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI-Powered Features',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 12),
              // Feature Cards
              Row(
                children: [
                  Expanded(
                    child: _buildFeatureCard(
                      context,
                      icon: Icons.search,
                      title: 'Hybrid Search',
                      subtitle: 'Community + External Data',
                      color: AppTheme.successColor,
                      onTap: () {
                        context.go('/hybrid-search');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFeatureCard(
                      context,
                      icon: Icons.smart_toy,
                      title: 'AI Assistant',
                      subtitle: 'Chat & Commands',
                      color: AppColors.grey600,
                      onTap: null, // Current tab
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildFeatureCard(
                      context,
                      icon: Icons.group,
                      title: 'Group Matching',
                      subtitle: 'Find spots with friends',
                      color: AppTheme.primaryColor,
                      onTap: () {
                        context.go('/group/formation');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Try: "Find coffee shops near me" or "Create a weekend list"',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        // Chat messages
        Expanded(
          child: ListView.builder(
            reverse: true,
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[_messages.length - 1 - index];
              return ChatMessage(
                message: message['message'],
                isUser: message['isUser'],
                timestamp: message['timestamp'],
              );
            },
          ),
        ),
        // Loading indicator
        if (_isProcessingCommand)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryColor,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.light
                        ? AppColors.grey200
                        : AppColors.grey700,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: TurbineLoader(size: 16),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Processing your request...',
                        style: TextStyle(
                          color: AppColors.grey600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        // Universal AI Search
        UniversalAISearch(
          hintText: 'Ask me anything... (create lists, find spots, etc.)',
          onCommand: _handleAICommand,
          isLoading: _isProcessingCommand,
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return AppSurface(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: onTap == null
                ? Border.all(color: color.withValues(alpha: 0.3))
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.grey600,
                ),
                textAlign: TextAlign.center,
              ),
              if (onTap == null)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: TextStyle(
                      fontSize: 8,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class EventsSubTab extends StatelessWidget {
  const EventsSubTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Replace "Coming Soon" placeholder with Events Browse Page
    // Agent 2: Event Discovery & Hosting UI (Phase 1, Section 1)
    return const EventsBrowsePage();
  }
}
