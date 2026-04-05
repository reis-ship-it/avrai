import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String? location;
  final List<String> tags;
  final Map<String, String> expertise; // category -> level
  final List<String> friends;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    this.location,
    this.tags = const [],
    this.expertise = const {},
    this.friends = const [],
    required this.createdAt,
  });

  @override
  List<Object?> get props =>
      [id, name, location, tags, expertise, friends, createdAt];

  User copyWith({
    String? id,
    String? name,
    String? location,
    List<String>? tags,
    Map<String, String>? expertise,
    List<String>? friends,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      expertise: expertise ?? this.expertise,
      friends: friends ?? this.friends,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
