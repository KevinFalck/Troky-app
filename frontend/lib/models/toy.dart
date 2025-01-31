// lib/models/toy.dart
import 'user.dart';

class Toy {
  final String id;
  final String? name;
  final String? description;
  final String? imageUrl;
  final String? location;
  final double? price;
  final bool? isAvailable;
  final User? owner;
  bool isFavorite = false;

  double get latitude {
    if (coordinates['coordinates'] == null ||
        coordinates['coordinates'].length < 2) {
      return 0.0;
    }
    return coordinates['coordinates'][1];
  }

  double get longitude {
    if (coordinates['coordinates'] == null ||
        coordinates['coordinates'].isEmpty) {
      return 0.0;
    }
    return coordinates['coordinates'][0];
  }

  final Map<String, dynamic> coordinates;

  Toy({
    required this.id,
    this.name,
    this.description,
    this.imageUrl,
    this.location,
    this.price,
    this.isAvailable,
    this.owner,
    required this.coordinates,
  });

  Toy copyWith() {
    return Toy(
      id: id,
      name: name,
      description: description,
      imageUrl: imageUrl,
      location: location,
      price: price,
      isAvailable: isAvailable,
      owner: owner,
      coordinates: coordinates,
    );
  }

  factory Toy.fromJson(Map<String, dynamic> json) {
    return Toy(
      id: json['_id']?.toString() ?? '',
      name: json['name'] ?? 'Jouet sans nom',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      location: json['location'] ?? 'Localisation inconnue',
      price: json['price']?.toDouble(),
      isAvailable: json['isAvailable'],
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
    };
  }
}
