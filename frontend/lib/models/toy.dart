// lib/models/toy.dart
import 'user.dart';

class Toy {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String location;
  bool _favorites;
  final User? owner;

  bool get favorites => _favorites;
  set favorites(bool value) {
    _favorites = value;
  }

  double get latitude {
    if (coordinates == null ||
        coordinates['coordinates'] == null ||
        coordinates['coordinates'].length < 2) {
      return 0.0;
    }
    return coordinates['coordinates'][1];
  }

  double get longitude {
    if (coordinates == null ||
        coordinates['coordinates'] == null ||
        coordinates['coordinates'].isEmpty) {
      return 0.0;
    }
    return coordinates['coordinates'][0];
  }

  final Map<String, dynamic> coordinates;

  Toy({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.location,
    required bool favorites,
    this.owner,
    required this.coordinates,
  }) : _favorites = favorites;

  factory Toy.fromJson(Map<String, dynamic> json) {
    return Toy(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      location: json['location'] ?? '',
      favorites: json['favorites'] ?? false,
      owner: json['owner'] != null ? User.fromJson(json['owner']) : null,
      coordinates: json['coordinates'] ??
          {
            'type': 'Point',
            'coordinates': [0.0, 0.0]
          },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'location': location,
      'favorites': favorites,
    };
  }
}
