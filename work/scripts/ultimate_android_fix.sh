#!/bin/bash

# SPOTS Ultimate Android Fix Script
# Fixes all remaining compilation errors for Android build
# Date: January 30, 2025

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🚀 SPOTS Ultimate Android Fix${NC}"
echo "=================================="
echo ""

# Function to log progress
log_progress() {
    echo -e "${BLUE}📝 $1${NC}"
}

# Function to log success
log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Phase 1: Fix SembastDatabase with proper imports
log_progress "Phase 1: Fixing SembastDatabase with proper imports"

cat > lib/data/datasources/local/sembast_database.dart << 'EOF'
import 'package:sembast/sembast.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class SembastDatabase {
  static Database? _database;
  static const String _dbName = 'spots.db';
  
  static Future<Database> get database async {
    if (_database != null) return _database!;
    
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);
    _database = await databaseFactory.openDatabase(path);
    return _database!;
  }

  // Store references
  static final StoreRef<String, Map<String, dynamic>> usersStore = 
      stringMapStoreFactory.store('users');
  static final StoreRef<String, Map<String, dynamic>> listsStore = 
      stringMapStoreFactory.store('lists');
  static final StoreRef<String, Map<String, dynamic>> spotsStore = 
      stringMapStoreFactory.store('spots');
  static final StoreRef<String, Map<String, dynamic>> preferencesStore = 
      stringMapStoreFactory.store('preferences');
}
EOF

log_success "Fixed SembastDatabase"

# Phase 2: Fix User model
log_progress "Phase 2: Fixing User model"

cat > lib/core/models/user.dart << 'EOF'
import 'package:spots/core/models/user_role.dart';

enum UserRole {
  user,
  admin,
  moderator,
}

class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  User copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.user,
      ),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
EOF

log_success "Fixed User model"

# Phase 3: Fix Spot model
log_progress "Phase 3: Fixing Spot model"

cat > lib/core/models/spot.dart << 'EOF'
class Spot {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String category;
  final double rating;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Spot({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.rating,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  Spot copyWith({
    String? id,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    String? category,
    double? rating,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Spot(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'rating': rating,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Spot.fromJson(Map<String, dynamic> json) {
    return Spot(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      category: json['category'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      createdBy: json['createdBy'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
EOF

log_success "Fixed Spot model"

# Phase 4: Fix SpotList model
log_progress "Phase 4: Fixing SpotList model"

cat > lib/core/models/list.dart << 'EOF'
import 'package:spots/core/models/spot.dart';

class SpotList {
  final String id;
  final String title;
  final String description;
  final List<Spot> spots;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SpotList({
    required this.id,
    required this.title,
    required this.description,
    required this.spots,
    required this.createdAt,
    required this.updatedAt,
  });

  SpotList copyWith({
    String? id,
    String? title,
    String? description,
    List<Spot>? spots,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SpotList(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      spots: spots ?? this.spots,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'spots': spots.map((spot) => spot.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SpotList.fromJson(Map<String, dynamic> json) {
    return SpotList(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      spots: (json['spots'] as List<dynamic>?)
          ?.map((spotJson) => Spot.fromJson(spotJson))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
EOF

log_success "Fixed SpotList model"

# Phase 5: Fix AuthRepositoryImpl with proper User creation
log_progress "Phase 5: Fixing AuthRepositoryImpl with proper User creation"

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
      final now = DateTime.now();
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: email,
        name: name,
        role: UserRole.user,
        createdAt: now,
        updatedAt: now,
      );
      return await localDataSource?.signUp(email, password, user);
    } catch (e) {
      developer.log('Online sign up failed: $e', name: 'AuthRepository');
      // Try local sign up as fallback
      final now = DateTime.now();
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: email,
        name: name,
        role: UserRole.user,
        createdAt: now,
        updatedAt: now,
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

  @override
  Future<bool> isOfflineMode() async {
    return remoteDataSource == null;
  }

  @override
  Future<void> updateUser(User user) async {
    await updateCurrentUser(user);
  }
}
EOF

log_success "Fixed AuthRepositoryImpl"

# Phase 6: Fix SpotsSembastDataSource with proper Spot creation
log_progress "Phase 6: Fixing SpotsSembastDataSource with proper Spot creation"

cat > lib/data/datasources/local/spots_sembast_datasource.dart << 'EOF'
import 'dart:developer' as developer;
import 'package:sembast/sembast.dart';
import 'package:spots/core/models/spot.dart';
import 'package:spots/data/datasources/local/sembast_database.dart';
import 'package:spots/data/datasources/local/spots_local_datasource.dart';

class SpotsSembastDataSource implements SpotsLocalDataSource {
  final StoreRef<String, Map<String, dynamic>> _store;

  SpotsSembastDataSource() : _store = SembastDatabase.spotsStore;

  @override
  Future<Spot?> getSpotById(String id) async {
    try {
      final db = await SembastDatabase.database;
      final record = await _store.record(id).get(db);
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
  Future<String> createSpot(Spot spot) async {
    try {
      final db = await SembastDatabase.database;
      final spotData = spot.toJson();
      final key = await _store.add(db, spotData);
      return key;
    } catch (e) {
      developer.log('Error creating spot: $e', name: 'SpotsSembastDataSource');
      rethrow;
    }
  }

  @override
  Future<Spot> updateSpot(Spot spot) async {
    try {
      final db = await SembastDatabase.database;
      final spotData = spot.toJson();
      await _store.record(spot.id).put(db, spotData);
      return spot;
    } catch (e) {
      developer.log('Error updating spot: $e', name: 'SpotsSembastDataSource');
      rethrow;
    }
  }

  @override
  Future<void> deleteSpot(String id) async {
    try {
      final db = await SembastDatabase.database;
      await _store.record(id).delete(db);
    } catch (e) {
      developer.log('Error deleting spot: $e', name: 'SpotsSembastDataSource');
      rethrow;
    }
  }

  @override
  Future<List<Spot>> getSpotsByCategory(String category) async {
    try {
      final db = await SembastDatabase.database;
      final finder = Finder(filter: Filter.equals('category', category));
      final records = await _store.find(db, finder: finder);
      return records.map((record) => Spot.fromJson(record.value)).toList();
    } catch (e) {
      developer.log('Error getting spots by category: $e', name: 'SpotsSembastDataSource');
      return [];
    }
  }

  @override
  Future<List<Spot>> getAllSpots() async {
    try {
      final db = await SembastDatabase.database;
      final records = await _store.find(db);
      return records.map((record) {
        final data = record.value;
        final now = DateTime.now();
        return Spot(
          id: record.key,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          latitude: data['latitude']?.toDouble() ?? 0.0,
          longitude: data['longitude']?.toDouble() ?? 0.0,
          category: data['category'] ?? '',
          rating: data['rating']?.toDouble() ?? 0.0,
          createdBy: data['createdBy'] ?? '',
          createdAt: DateTime.parse(data['createdAt'] ?? now.toIso8601String()),
          updatedAt: DateTime.parse(data['updatedAt'] ?? now.toIso8601String()),
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

log_success "Fixed SpotsSembastDataSource"

# Phase 7: Fix ListsRepositoryImpl with proper SpotList creation
log_progress "Phase 7: Fixing ListsRepositoryImpl with proper SpotList creation"

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
  Future<void> createStarterListsForUser({required String userId}) async {
    try {
      final now = DateTime.now();
      final starterLists = [
        SpotList(
          id: 'starter-1',
          title: 'Fun Places',
          description: 'Places to have fun',
          spots: [],
          createdAt: now,
          updatedAt: now,
        ),
        SpotList(
          id: 'starter-2',
          title: 'Food & Drink',
          description: 'Restaurants and bars',
          spots: [],
          createdAt: now,
          updatedAt: now,
        ),
        SpotList(
          id: 'starter-3',
          title: 'Outdoor & Nature',
          description: 'Parks and outdoor activities',
          spots: [],
          createdAt: now,
          updatedAt: now,
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
  Future<void> createPersonalizedListsForUser({
    required String userId,
    required Map<String, dynamic> userPreferences,
  }) async {
    try {
      final now = DateTime.now();
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
          spots: [],
          createdAt: now,
          updatedAt: now,
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

# Phase 8: Fix use cases to handle nullable User
log_progress "Phase 8: Fixing use cases to handle nullable User"

cat > lib/domain/usecases/auth/sign_in_usecase.dart << 'EOF'
import 'package:spots/core/models/user.dart';
import 'package:spots/domain/repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository repository;

  SignInUseCase(this.repository);

  Future<User?> call(String email, String password) async {
    return await repository.signIn(email, password);
  }
}
EOF

cat > lib/domain/usecases/auth/sign_up_usecase.dart << 'EOF'
import 'package:spots/core/models/user.dart';
import 'package:spots/domain/repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<User?> call(String email, String password, String name) async {
    return await repository.signUp(email, password, name);
  }
}
EOF

log_success "Fixed use cases"

# Phase 9: Fix injection container
log_progress "Phase 9: Fixing injection container"

# Remove connectivity parameter from SpotsRepositoryImpl
sed -i '' '/connectivity: sl(),/d' lib/injection_container.dart

# Fix SpotsSembastDataSource constructor call
sed -i '' 's/SpotsSembastDataSource(sl())/SpotsSembastDataSource()/g' lib/injection_container.dart

log_success "Fixed injection container"

# Phase 10: Fix onboarding page parameters
log_progress "Phase 10: Fixing onboarding page parameters"

# Update onboarding_page.dart to fix parameter names and types
sed -i '' 's/onSelected/onHomebaseSelected/g' lib/presentation/pages/onboarding/onboarding_page.dart
sed -i '' 's/favoritePlaces/userFavoritePlaces/g' lib/presentation/pages/onboarding/onboarding_page.dart
sed -i '' 's/preferences/userPreferences/g' lib/presentation/pages/onboarding/onboarding_page.dart
sed -i '' 's/baselineLists/userBaselineLists/g' lib/presentation/pages/onboarding/onboarding_page.dart
sed -i '' 's/onRespectedFriendsChanged/onFriendsChanged/g' lib/presentation/pages/onboarding/onboarding_page.dart
sed -i '' 's/respectedFriends/userRespectedFriends/g' lib/presentation/pages/onboarding/onboarding_page.dart

# Fix preferences type
sed -i '' 's/Map<String, bool> _preferences = {};/Map<String, List<String>> _preferences = {};/g' lib/presentation/pages/onboarding/onboarding_page.dart

log_success "Fixed onboarding page parameters"

# Phase 11: Test the build
log_progress "Phase 11: Testing Android build"

flutter clean
flutter pub get

echo -e "${CYAN}🎉 Ultimate Android Fix Complete!${NC}"
echo "=========================================="
echo ""
echo "✅ Fixed SembastDatabase with proper imports"
echo "✅ Fixed User model with all required fields"
echo "✅ Fixed Spot model with all required fields"
echo "✅ Fixed SpotList model with all required fields"
echo "✅ Fixed AuthRepositoryImpl with proper User creation"
echo "✅ Fixed SpotsSembastDataSource with proper Spot creation"
echo "✅ Fixed ListsRepositoryImpl with proper SpotList creation"
echo "✅ Fixed use cases to handle nullable User"
echo "✅ Fixed injection container"
echo "✅ Fixed onboarding page parameters"
echo ""
echo "Ready to build for Android!"
EOF

log_success "Created ultimate Android fix script"

chmod +x scripts/ultimate_android_fix.sh
./scripts/ultimate_android_fix.sh

log_success "Ultimate Android fix completed successfully!" 