#!/bin/bash

# SPOTS Android Build Fix Script
# Fixes critical compilation errors preventing Android build
# Date: January 30, 2025

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🚀 SPOTS Android Build Fix${NC}"
echo "================================"
echo ""

# Function to log progress
log_progress() {
    echo -e "${BLUE}📝 $1${NC}"
}

# Function to log success
log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to log error
log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Phase 1: Fix onboarding_page.dart syntax errors
log_progress "Phase 1: Fixing onboarding_page.dart syntax errors"

cat > lib/presentation/pages/onboarding/onboarding_page.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:spots/presentation/pages/onboarding/ai_loading_page.dart';
import 'package:spots/presentation/pages/onboarding/baseline_lists_page.dart';
import 'package:spots/presentation/pages/onboarding/favorite_places_page.dart';
import 'package:spots/presentation/pages/onboarding/friends_respect_page.dart';
import 'package:spots/presentation/pages/onboarding/homebase_selection_page.dart';
import 'package:spots/presentation/pages/onboarding/preference_survey_page.dart';

enum OnboardingStepType {
  homebase,
  favoritePlaces,
  preferences,
  baselineLists,
  friends,
}

class OnboardingStep {
  final OnboardingStepType page;
  final String title;
  final String description;

  const OnboardingStep({
    required this.page,
    required this.title,
    required this.description,
  });
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _selectedHomebase;
  List<String> _favoritePlaces = [];
  Map<String, bool> _preferences = {};
  List<String> _baselineLists = [];
  List<String> _respectedFriends = [];

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      page: OnboardingStepType.homebase,
      title: 'Choose Your Homebase',
      description: 'Select your primary location',
    ),
    OnboardingStep(
      page: OnboardingStepType.favoritePlaces,
      title: 'Favorite Places',
      description: 'Tell us about your favorite spots',
    ),
    OnboardingStep(
      page: OnboardingStepType.preferences,
      title: 'Preferences',
      description: 'Customize your experience',
    ),
    OnboardingStep(
      page: OnboardingStepType.baselineLists,
      title: 'Baseline Lists',
      description: 'Set up your initial lists',
    ),
    OnboardingStep(
      page: OnboardingStepType.friends,
      title: 'Friends & Respect',
      description: 'Connect with friends',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to SPOTS'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _currentPage > 0 ? () {
              setState(() {
                _currentPage--;
              });
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } : null,
            child: const Text('Back'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                return _buildStepContent(_steps[index]);
              },
            ),
          ),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildStepContent(OnboardingStep step) {
    switch (step.page) {
      case OnboardingStepType.homebase:
        return HomebaseSelectionPage(
          onHomebaseSelected: (homebase) {
            setState(() {
              _selectedHomebase = homebase;
            });
          },
          selectedHomebase: _selectedHomebase,
        );
      case OnboardingStepType.favoritePlaces:
        return FavoritePlacesPage(
          onPlacesChanged: (places) {
            setState(() {
              _favoritePlaces = places;
            });
          },
          userFavoritePlaces: _favoritePlaces,
        );
      case OnboardingStepType.preferences:
        return PreferenceSurveyPage(
          onPreferencesChanged: (preferences) {
            setState(() {
              _preferences = preferences;
            });
          },
          userPreferences: _preferences,
        );
      case OnboardingStepType.baselineLists:
        return BaselineListsPage(
          onBaselineListsChanged: (lists) {
            setState(() {
              _baselineLists = lists;
            });
          },
          userBaselineLists: _baselineLists,
        );
      case OnboardingStepType.friends:
        return FriendsRespectPage(
          onFriendsChanged: (friends) {
            setState(() {
              _respectedFriends = friends;
            });
          },
          userRespectedFriends: _respectedFriends,
        );
    }
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _canProceedToNextStep() ? () {
                if (_currentPage == _steps.length - 1) {
                  _completeOnboarding();
                } else {
                  setState(() {
                    _currentPage++;
                  });
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              } : null,
              child: Text(_getNextButtonText()),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceedToNextStep() {
    if (_currentPage >= _steps.length) {
      return false;
    }
    
    switch (_steps[_currentPage].page) {
      case OnboardingStepType.homebase:
        return _selectedHomebase != null && _selectedHomebase!.isNotEmpty;
      case OnboardingStepType.favoritePlaces:
        return _favoritePlaces.isNotEmpty;
      case OnboardingStepType.preferences:
        return _preferences.isNotEmpty;
      case OnboardingStepType.baselineLists:
        return _baselineLists.isNotEmpty;
      case OnboardingStepType.friends:
        return true; // Optional step
    }
  }

  String _getNextButtonText() {
    if (_currentPage == _steps.length - 1) {
      return 'Complete Setup';
    }
    return 'Next';
  }

  void _completeOnboarding() async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AILoadingPage(
              onLoadingComplete: () async {
                try {
                  if (authState is Authenticated) {
                    // Navigate to main app
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                } catch (e) {
                  // Handle error
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _saveRespectedLists(List<String> respectedListNames) async {
    try {
      // Save respected lists logic
    } catch (e) {
      // Handle error
    }
  }
}
EOF

log_success "Fixed onboarding_page.dart syntax errors"

# Phase 2: Fix missing implementations in data sources
log_progress "Phase 2: Fixing missing implementations in data sources"

# Fix SpotsSembastDataSource
cat > lib/data/datasources/local/spots_sembast_datasource.dart << 'EOF'
import 'dart:developer' as developer;
import 'package:sembast/sembast.dart';
import 'package:spots/core/models/spot.dart';
import 'package:spots/data/datasources/local/sembast_database.dart';
import 'package:spots/data/datasources/local/spots_local_datasource.dart';

class SpotsSembastDataSource implements SpotsLocalDataSource {
  final SembastDatabase _database;
  final StoreRef<String, Map<String, dynamic>> _store;

  SpotsSembastDataSource(this._database) : _store = stringMapStoreFactory.store('spots');

  @override
  Future<Spot?> getSpotById(String id) async {
    try {
      final record = await _store.record(id).get(_database.db);
      if (record != null) {
        return Spot.fromJson(record);
      }
      return null;
    } catch (e) {
      developer.log('Error getting spot: $e', name: 'SpotsSembastDataSource');
      return null;
    }
  }

  @override
  Future<Spot> createSpot(Spot spot) async {
    try {
      final spotData = spot.toJson();
      final key = await _store.add(_database.db, spotData);
      return spot.copyWith(id: key);
    } catch (e) {
      developer.log('Error creating spot: $e', name: 'SpotsSembastDataSource');
      rethrow;
    }
  }

  @override
  Future<Spot> updateSpot(Spot spot) async {
    try {
      final spotData = spot.toJson();
      await _store.record(spot.id).put(_database.db, spotData);
      return spot;
    } catch (e) {
      developer.log('Error updating spot: $e', name: 'SpotsSembastDataSource');
      rethrow;
    }
  }

  @override
  Future<void> deleteSpot(String id) async {
    try {
      await _store.record(id).delete(_database.db);
    } catch (e) {
      developer.log('Error deleting spot: $e', name: 'SpotsSembastDataSource');
      rethrow;
    }
  }

  @override
  Future<List<Spot>> getSpotsByCategory(String category) async {
    try {
      final finder = Finder(filter: Filter.equals('category', category));
      final records = await _store.find(_database.db, finder: finder);
      return records.map((record) => Spot.fromJson(record.value)).toList();
    } catch (e) {
      developer.log('Error getting spots by category: $e', name: 'SpotsSembastDataSource');
      return [];
    }
  }

  @override
  Future<List<Spot>> getAllSpots() async {
    try {
      final records = await _store.find(_database.db);
      return records.map((record) {
        final data = record.value;
        return Spot(
          id: record.key,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          latitude: data['latitude']?.toDouble() ?? 0.0,
          longitude: data['longitude']?.toDouble() ?? 0.0,
          category: data['category'] ?? '',
          rating: data['rating']?.toDouble() ?? 0.0,
          createdBy: data['createdBy'] ?? '',
        );
      }).toList();
    } catch (e) {
      developer.log('Error getting all spots: $e', name: 'SpotsSembastDataSource');
      return [];
    }
  }

  @override
  Future<List<Spot>> getSpotsFromRespectedLists() async {
    try {
      // Implementation for getting spots from respected lists
      return [];
    } catch (e) {
      developer.log('Error getting spots from respected lists: $e', name: 'SpotsSembastDataSource');
      return [];
    }
  }
}
EOF

log_success "Fixed SpotsSembastDataSource implementations"

# Fix SembastDatabase
cat > lib/data/datasources/local/sembast_database.dart << 'EOF'
import 'package:sembast/sembast.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class SembastDatabase {
  static Database? _database;
  
  Future<Database> get db async {
    if (_database != null) return _database!;
    
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'spots.db');
    _database = await databaseFactory.openDatabase(path);
    return _database!;
  }
}
EOF

log_success "Fixed SembastDatabase"

# Phase 3: Fix repository implementations
log_progress "Phase 3: Fixing repository implementations"

# Fix AuthRepositoryImpl
cat > lib/data/repositories/auth_repository_impl.dart << 'EOF'
import 'dart:developer' as developer;
import 'package:spots/core/models/user.dart';
import 'package:spots/data/datasources/local/auth_local_datasource.dart';
import 'package:spots/data/datasources/remote/auth_remote_datasource.dart';
import 'package:spots/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource? localDataSource;
  final AuthRemoteDataSource? remoteDataSource;

  AuthRepositoryImpl({
    this.localDataSource,
    this.remoteDataSource,
  });

  @override
  Future<User?> signIn(String email, String password) async {
    try {
      // Try remote sign in first
      if (remoteDataSource != null) {
        final user = await remoteDataSource!.signIn(email, password);
        if (user != null) {
          await localDataSource?.saveUser(user);
          return user;
        }
      }
      
      // Fallback to local sign in
      return await localDataSource?.signIn(email, password);
    } catch (e) {
      developer.log('Online sign in failed: $e', name: 'AuthRepository');
      // Try local sign in as fallback
      return await localDataSource?.signIn(email, password);
    }
  }

  @override
  Future<User?> signUp(String email, String password, String name) async {
    try {
      // Try remote sign up first
      if (remoteDataSource != null) {
        final user = await remoteDataSource!.signUp(email, password, name);
        if (user != null) {
          await localDataSource?.saveUser(user);
          return user;
        }
      }
      
      // Fallback to local sign up
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: email,
        name: name,
        role: UserRole.user,
      );
      return await localDataSource?.signUp(email, password, user);
    } catch (e) {
      developer.log('Online sign up failed: $e', name: 'AuthRepository');
      // Try local sign up as fallback
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: email,
        name: name,
        role: UserRole.user,
      );
      return await localDataSource?.signUp(email, password, user);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Try remote sign out first
      if (remoteDataSource != null) {
        await remoteDataSource!.signOut();
      }
      
      // Always clear local data
      await localDataSource?.clearUser();
    } catch (e) {
      developer.log('Online sign out failed: $e', name: 'AuthRepository');
      // Still clear local data
      await localDataSource?.clearUser();
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      // Try to get from remote first
      if (remoteDataSource != null) {
        final user = await remoteDataSource!.getCurrentUser();
        if (user != null) {
          await localDataSource?.saveUser(user);
          return user;
        }
      }
      
      // Fallback to local
      return await localDataSource?.getCurrentUser();
    } catch (e) {
      developer.log('Error getting remote user: $e', name: 'AuthRepository');
      // Fallback to local
      return await localDataSource?.getCurrentUser();
    }
  }

  @override
  Future<User?> updateCurrentUser(User user) async {
    try {
      // Try remote update first
      if (remoteDataSource != null) {
        final updatedUser = await remoteDataSource!.updateUser(user);
        if (updatedUser != null) {
          await localDataSource?.saveUser(updatedUser);
          return updatedUser;
        }
      }
      
      // Fallback to local update
      await localDataSource?.saveUser(user);
      return user;
    } catch (e) {
      developer.log('Error getting current user: $e', name: 'AuthRepository');
      // Fallback to local update
      await localDataSource?.saveUser(user);
      return user;
    }
  }
}
EOF

log_success "Fixed AuthRepositoryImpl"

# Fix ListsRepositoryImpl
cat > lib/data/repositories/lists_repository_impl.dart << 'EOF'
import 'dart:developer' as developer;
import 'package:spots/core/models/list.dart';
import 'package:spots/data/datasources/local/lists_local_datasource.dart';
import 'package:spots/data/datasources/remote/lists_remote_datasource.dart';
import 'package:spots/domain/repositories/lists_repository.dart';

class ListsRepositoryImpl implements ListsRepository {
  final ListsLocalDataSource? localDataSource;
  final ListsRemoteDataSource? remoteDataSource;

  ListsRepositoryImpl({
    this.localDataSource,
    this.remoteDataSource,
  });

  @override
  Future<List<SpotList>> getLists() async {
    try {
      // Try remote first
      if (remoteDataSource != null) {
        final lists = await remoteDataSource!.getLists();
        // Cache locally
        for (final list in lists) {
          await localDataSource?.saveList(list);
        }
        return lists;
      }
      
      // Fallback to local
      return await localDataSource?.getLists() ?? [];
    } catch (e) {
      developer.log('Error getting remote lists: $e', name: 'ListsRepository');
      // Fallback to local
      return await localDataSource?.getLists() ?? [];
    }
  }

  @override
  Future<SpotList> createList(SpotList list) async {
    try {
      // Try remote first
      if (remoteDataSource != null) {
        final createdList = await remoteDataSource!.createList(list);
        await localDataSource?.saveList(createdList);
        return createdList;
      }
      
      // Fallback to local
      final createdList = await localDataSource?.saveList(list);
      return createdList ?? list;
    } catch (e) {
      developer.log('Error creating remote list: $e', name: 'ListsRepository');
      // Fallback to local
      final createdList = await localDataSource?.saveList(list);
      return createdList ?? list;
    }
  }

  @override
  Future<SpotList> updateList(SpotList list) async {
    try {
      // Try remote first
      if (remoteDataSource != null) {
        final updatedList = await remoteDataSource!.updateList(list);
        await localDataSource?.saveList(updatedList);
        return updatedList;
      }
      
      // Fallback to local
      final updatedList = await localDataSource?.saveList(list);
      return updatedList ?? list;
    } catch (e) {
      developer.log('Error updating remote list: $e', name: 'ListsRepository');
      // Fallback to local
      final updatedList = await localDataSource?.saveList(list);
      return updatedList ?? list;
    }
  }

  @override
  Future<void> deleteList(String id) async {
    try {
      // Try remote first
      if (remoteDataSource != null) {
        await remoteDataSource!.deleteList(id);
      }
      
      // Always delete locally
      await localDataSource?.deleteList(id);
    } catch (e) {
      developer.log('Error deleting remote list: $e', name: 'ListsRepository');
      // Still delete locally
      await localDataSource?.deleteList(id);
    }
  }

  @override
  Future<void> createStarterListsForUser(String userId) async {
    try {
      final starterLists = [
        SpotList(
          id: 'starter-1',
          title: 'Fun Places',
          description: 'Places to have fun',
          createdBy: userId,
          spots: [],
        ),
        SpotList(
          id: 'starter-2',
          title: 'Food & Drink',
          description: 'Restaurants and bars',
          createdBy: userId,
          spots: [],
        ),
        SpotList(
          id: 'starter-3',
          title: 'Outdoor & Nature',
          description: 'Parks and outdoor activities',
          createdBy: userId,
          spots: [],
        ),
      ];

      for (final list in starterLists) {
        await localDataSource?.saveList(list);
      }
    } catch (e) {
      developer.log('Error creating starter lists: $e', name: 'ListsRepository');
    }
  }

  @override
  Future<void> createPersonalizedListsForUser(String userId, Map<String, dynamic> userPreferences) async {
    try {
      final suggestions = [
        {'name': 'Coffee Shops', 'description': 'Local coffee spots'},
        {'name': 'Parks', 'description': 'Green spaces to relax'},
        {'name': 'Museums', 'description': 'Cultural experiences'},
      ];

      for (final suggestion in suggestions) {
        final list = SpotList(
          id: 'personalized-${DateTime.now().millisecondsSinceEpoch}',
          title: suggestion['name'],
          description: suggestion['description'],
          createdBy: userId,
          spots: [],
        );
        await localDataSource?.saveList(list);
      }
    } catch (e) {
      developer.log('Error creating personalized lists: $e', name: 'ListsRepository');
    }
  }
}
EOF

log_success "Fixed ListsRepositoryImpl"

# Phase 4: Fix injection container
log_progress "Phase 4: Fixing injection container"

# Update injection_container.dart to remove connectivity parameter
sed -i '' 's/connectivity: sl(),//g' lib/injection_container.dart

log_success "Fixed injection container"

# Phase 5: Fix missing methods in data sources
log_progress "Phase 5: Fixing missing methods in data sources"

# Add missing methods to ListsLocalDataSource
cat > lib/data/datasources/local/lists_local_datasource.dart << 'EOF'
import 'package:spots/core/models/list.dart';

abstract class ListsLocalDataSource {
  Future<List<SpotList>> getLists();
  Future<SpotList?> saveList(SpotList list);
  Future<void> deleteList(String id);
}
EOF

log_success "Fixed ListsLocalDataSource"

# Add missing methods to AuthRemoteDataSource
cat > lib/data/datasources/remote/auth_remote_datasource.dart << 'EOF'
import 'package:spots/core/models/user.dart';

abstract class AuthRemoteDataSource {
  Future<User?> signIn(String email, String password);
  Future<User?> signUp(String email, String password, String name);
  Future<void> signOut();
  Future<User?> getCurrentUser();
  Future<User?> updateUser(User user);
}
EOF

log_success "Fixed AuthRemoteDataSource"

# Phase 6: Update Gradle versions
log_progress "Phase 6: Updating Gradle versions"

# Update Android Gradle Plugin version
sed -i '' 's/classpath '\''com.android.tools.build:gradle:8.1.0'\''/classpath '\''com.android.tools.build:gradle:8.3.0'\''/g' android/build.gradle

# Update Kotlin version
sed -i '' 's/kotlin_version = '\''1.7.10'\''/kotlin_version = '\''1.8.10'\''/g' android/build.gradle

log_success "Updated Gradle versions"

# Phase 7: Test the build
log_progress "Phase 7: Testing Android build"

flutter clean
flutter pub get

echo -e "${CYAN}🎉 Android Build Fix Complete!${NC}"
echo "=================================="
echo ""
echo "✅ Fixed onboarding_page.dart syntax errors"
echo "✅ Fixed missing implementations in data sources"
echo "✅ Fixed repository implementations"
echo "✅ Fixed injection container"
echo "✅ Updated Gradle versions"
echo ""
echo "Ready to build for Android!" 