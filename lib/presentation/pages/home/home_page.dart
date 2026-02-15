import 'package:flutter/material.dart';
import 'package:avrai/core/navigation/app_navigator.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/blocs/lists/lists_bloc.dart';
import 'package:avrai/presentation/blocs/spots/spots_bloc.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/tokens/theme_tokens.dart';
import 'package:avrai/presentation/pages/lists/list_details_page.dart';
import 'package:avrai/presentation/widgets/lists/spot_list_card.dart';
import 'package:avrai/presentation/widgets/map/map_view.dart';
import 'package:avrai/presentation/widgets/common/search_bar.dart';
import 'package:avrai/presentation/widgets/common/chat_message.dart';
import 'package:avrai/presentation/widgets/common/universal_ai_search.dart';
import 'package:avrai/presentation/widgets/common/ai_command_processor.dart';
import 'package:avrai/domain/repositories/lists_repository.dart';
import 'package:avrai/core/models/misc/list.dart';
import 'package:geolocator/geolocator.dart';
// Phase 1 Integration: Offline indicator
import 'package:avrai/presentation/widgets/common/offline_indicator_widget.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:avrai/presentation/pages/events/events_browse_page.dart';
import 'package:avrai/presentation/pages/communities/communities_discover_page.dart';
import 'package:avrai/presentation/widgets/chat/chat_button_with_badge.dart';
import 'package:go_router/go_router.dart';
import 'package:avrai/core/config/design_feature_flags.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';

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
    const MapTab(),
    const SpotsTab(),
    const ExploreTab(),
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
          context.showError(state.message);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return const AdaptivePlatformPageScaffold(
              title: 'avrai',
              showNavigationBar: false,
              constrainBody: false,
              body: Center(child: CircularProgressIndicator()),
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
      body: Column(
        children: [
          // Phase 7 Week 35: Full OfflineIndicatorWidget integration
          StreamBuilder<List<ConnectivityResult>>(
            stream: Connectivity().onConnectivityChanged,
            initialData: const [ConnectivityResult.none],
            builder: (context, snapshot) {
              final connectivityResults =
                  snapshot.data ?? [ConnectivityResult.none];
              final isOffline =
                  connectivityResults.contains(ConnectivityResult.none);

              if (!isOffline) return const SizedBox.shrink();

              return OfflineIndicatorWidget(
                isOffline: isOffline,
                onRetry: () async {
                  // Retry connectivity check
                  final connectivity = Connectivity();
                  final result = await connectivity.checkConnectivity();
                  final isNowOnline = !result.contains(ConnectivityResult.none);

                  if (isNowOnline && context.mounted) {
                    context.showSuccess('Connection restored!');
                  }
                },
                showDismiss: true,
              );
            },
          ),
          // Main content
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: AdaptivePlatformBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 3) {
            // Settings tab - navigate to profile/settings
            context.go('/profile');
          } else {
            setState(() => _currentIndex = index);
          }
        },
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppColors.textSecondary,
        destinations: const [
          AdaptiveBottomNavDestination(icon: Icon(Icons.map), label: 'Map'),
          AdaptiveBottomNavDestination(icon: Icon(Icons.place), label: 'Spots'),
          AdaptiveBottomNavDestination(
              icon: Icon(Icons.explore), label: 'Explore'),
          AdaptiveBottomNavDestination(
              icon: Icon(Icons.settings), label: 'Settings'),
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
              'Create lists of places and share them with others',
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
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;
    return AdaptivePlatformPageScaffold(
      title: 'My Lists',
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
                  style: textTheme.bodyMedium?.copyWith(
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
            hintText: 'Search lists...',
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
                    color: AppColors.grey100,
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
                              return const Center(
                                  child: CircularProgressIndicator());
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
                                      SizedBox(height: spacing.md),
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
                                      AppNavigator.pushBuilder(
                                        context,
                                        builder: (context) =>
                                            ListDetailsPage(list: list),
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
                                    SizedBox(height: spacing.md),
                                    Text('Error: ${state.message}'),
                                    SizedBox(height: spacing.md),
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
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            if (state is SpotsLoaded) {
                              if (state.respectedSpots.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.favorite_border,
                                          size: 64,
                                          color: AppColors.textSecondary),
                                      SizedBox(height: spacing.md),
                                      Text(
                                        'No respected lists yet',
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: spacing.xs),
                                      Text(
                                        'Respect some lists during onboarding to see them here',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
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
                                  return PortalSurface(
                                    margin: EdgeInsets.symmetric(
                                        horizontal: spacing.md,
                                        vertical: spacing.xs),
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
                                    SizedBox(height: spacing.md),
                                    Text('Error: ${state.message}'),
                                    SizedBox(height: spacing.md),
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
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      builder: (context) => BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            return Container(
              padding: EdgeInsets.all(spacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        state.user.displayName?.substring(0, 1).toUpperCase() ??
                            state.user.email.substring(0, 1).toUpperCase(),
                        style: textTheme.bodyMedium?.copyWith(
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
                    title: Text(
                      'Sign Out',
                      style: textTheme.bodyLarge,
                    ),
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

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Explore',
      constrainBody: false,
      leading: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final textTheme = Theme.of(context).textTheme;

          if (state is Authenticated) {
            return IconButton(
              icon: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  state.user.displayName?.substring(0, 1).toUpperCase() ??
                      state.user.email.substring(0, 1).toUpperCase(),
                  style: textTheme.bodyMedium?.copyWith(
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
      materialBottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.people), text: 'Users'),
          Tab(icon: Icon(Icons.smart_toy), text: 'AI'),
          Tab(icon: Icon(Icons.event), text: 'Events'),
          Tab(icon: Icon(Icons.groups), text: 'Communities'),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          UsersSubTab(),
          AISubTab(),
          EventsSubTab(),
          CommunitiesDiscoverPage(showAppBar: false),
        ],
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      builder: (context) => BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            return Container(
              padding: EdgeInsets.all(spacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        state.user.displayName?.substring(0, 1).toUpperCase() ??
                            state.user.email.substring(0, 1).toUpperCase(),
                        style: textTheme.bodyMedium?.copyWith(
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
                    title: Text(
                      'Sign Out',
                      style: textTheme.bodyLarge,
                    ),
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
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
            SizedBox(height: spacing.md),
            Text(
              'Error loading public lists',
              style: textTheme.titleLarge,
            ),
            SizedBox(height: spacing.xs),
            Text(
              _error!,
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing.md),
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
            SizedBox(height: spacing.md),
            Text(
              'Discover Public Lists',
              style: textTheme.titleLarge,
            ),
            SizedBox(height: spacing.xs),
            Text(
              'No public lists available yet.\nBe the first to create one!',
              style: textTheme.bodyMedium?.copyWith(
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
        padding: EdgeInsets.all(spacing.md),
        itemCount: _publicLists.length,
        itemBuilder: (context, index) {
          final list = _publicLists[index];
          return PortalSurface(
            margin: EdgeInsets.only(bottom: spacing.sm),
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
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                  SizedBox(height: spacing.xxs),
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: spacing.xxs),
                      Text(
                        '${list.respectCount} respects',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(width: spacing.md),
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: spacing.xxs),
                      Text(
                        '${list.spots.length} spots',
                        style: textTheme.bodySmall?.copyWith(
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
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        // AI Features Section
        PortalSurface(
          padding: EdgeInsets.all(spacing.md),
          color: AppColors.grey100,
          borderColor: AppColors.grey200,
          radius: 0,
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
              SizedBox(height: spacing.sm),
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
                  SizedBox(width: spacing.sm),
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
              SizedBox(height: spacing.xs),
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
              SizedBox(height: spacing.xs),
              Text(
                'Try: "Find coffee shops near me" or "Create a weekend list"',
                style: textTheme.bodySmall?.copyWith(
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
            padding: EdgeInsets.symmetric(
                horizontal: spacing.md, vertical: spacing.xs),
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
                SizedBox(width: spacing.xs),
                PortalSurface(
                  radius: 18,
                  padding: EdgeInsets.symmetric(
                      horizontal: spacing.md, vertical: spacing.sm),
                  color: Theme.of(context).brightness == Brightness.light
                      ? AppColors.grey200
                      : AppColors.grey700,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor),
                        ),
                      ),
                      SizedBox(width: spacing.xs),
                      Text(
                        'Processing your request...',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.grey600,
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
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;
    return PortalSurface(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.radius.sm),
        child: Padding(
          padding: EdgeInsets.all(spacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(icon, color: color),
              ),
              SizedBox(height: spacing.xs),
              Text(
                title,
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing.xxs / 2),
              Text(
                subtitle,
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.grey600,
                ),
                textAlign: TextAlign.center,
              ),
              if (onTap == null)
                Padding(
                  padding: EdgeInsets.only(top: spacing.xxs),
                  child: Chip(
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide.none,
                    backgroundColor: color.withValues(alpha: 0.1),
                    label: Text(
                      'ACTIVE',
                      style: textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
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
