import 'package:equatable/equatable.dart';

class SpotList extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category;
  final String userId;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int respectCount;
  final List<String> spotIds;

  const SpotList({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.userId,
    this.isPublic = true,
    required this.createdAt,
    this.updatedAt,
    this.respectCount = 0,
    this.spotIds = const [],
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        userId,
        isPublic,
        createdAt,
        updatedAt,
        respectCount,
        spotIds
      ];

  SpotList copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? userId,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? respectCount,
    List<String>? spotIds,
  }) {
    return SpotList(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      userId: userId ?? this.userId,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      respectCount: respectCount ?? this.respectCount,
      spotIds: spotIds ?? this.spotIds,
    );
  }
}
