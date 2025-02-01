// lib/models/toy.dart
import 'user.dart';

class Toy {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String location;
  final double latitude;
  final double longitude;
  final String owner;
  final double? price;
  final bool? isAvailable;
  bool isFavorite = false;
  final Map<String, dynamic>? coordinates;

  Toy({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.owner,
    this.price,
    this.isAvailable,
    this.coordinates,
  });

  Toy copyWith() {
    return Toy(
      id: id,
      name: name,
      description: description,
      imageUrl: imageUrl,
      location: location,
      latitude: latitude,
      longitude: longitude,
      owner: owner,
      price: price,
      isAvailable: isAvailable,
      coordinates: coordinates,
    );
  }

  factory Toy.fromJson(Map<String, dynamic> json) {
    final ownerValue = json['owner'];
    String ownerId = '';
    if (ownerValue is Map<String, dynamic>) {
      ownerId = ownerValue['_id'] ?? '';
    } else if (ownerValue is String) {
      ownerId = ownerValue;
    }

    return Toy(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      location: json['location'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      owner: ownerId,
      price: json['price']?.toDouble(),
      isAvailable: json['isAvailable'],
      coordinates: json['coordinates'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['coordinates'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'location': location,
    };
  }
}
