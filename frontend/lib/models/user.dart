class User {
  final String id;
  final String email;
  final String name;
  final String? profileImage;
  final double? rating;
  final int reviewsCount;
  final int totalListings;
  final int? responseTimeMinutes;
  final int? completedTransactions;
  final String? memberSince;
  final List<String> favoriteToys;
  final String? profileImageUrl;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.profileImage,
    this.rating,
    this.reviewsCount = 0,
    this.totalListings = 0,
    this.responseTimeMinutes,
    this.completedTransactions,
    this.memberSince,
    this.favoriteToys = const [],
    this.profileImageUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['userId'],
      email: json['email'],
      name: json['name'],
      profileImage: json['profileImage'],
      rating: _safeToDouble(json['rating']),
      reviewsCount: _safeToInt(json['reviewsCount']) ?? 0,
      totalListings: _safeToInt(json['totalListings']) ?? 0,
      responseTimeMinutes: json['responseTimeMinutes'],
      completedTransactions: json['completedTransactions'],
      memberSince: json['memberSince'],
      favoriteToys: List<String>.from(json['favoriteToys'] ?? []),
      profileImageUrl: json['profileImageUrl'],
    );
  }

  static double? _safeToDouble(dynamic value) {
    if (value == null) return null;
    return (value is num) ? value.toDouble() : null;
  }

  static int _safeToInt(dynamic value) {
    if (value == null) return 0;
    return (value is num) ? value.toInt() : int.tryParse(value.toString()) ?? 0;
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'profileImage': profileImageUrl,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'responseTimeMinutes': responseTimeMinutes,
      'totalListings': totalListings,
      'completedTransactions': completedTransactions,
      'memberSince': memberSince,
      'favoriteToys': favoriteToys,
    };
  }

  User copyWith({List<String>? favoriteToys}) {
    return User(
      id: id,
      email: email,
      name: name,
      profileImage: profileImage,
      rating: rating,
      reviewsCount: reviewsCount,
      totalListings: totalListings,
      responseTimeMinutes: responseTimeMinutes,
      completedTransactions: completedTransactions,
      memberSince: memberSince,
      favoriteToys: favoriteToys ?? this.favoriteToys,
      profileImageUrl: profileImageUrl,
    );
  }
}
