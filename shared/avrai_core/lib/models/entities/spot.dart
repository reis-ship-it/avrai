import 'package:equatable/equatable.dart';

class Spot extends Equatable {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String category;
  final String? listId;
  final String userId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Spot({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.listId,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        latitude,
        longitude,
        category,
        listId,
        userId,
        createdAt,
        updatedAt
      ];

  Spot copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    String? category,
    String? listId,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Spot(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      listId: listId ?? this.listId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
