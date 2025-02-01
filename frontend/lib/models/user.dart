class User {
  final String id;
  final String? username;
  final String? email;
  final String? profileImageUrl;
  final double? rating;
  final int? reviewsCount;
  final int? responseTimeMinutes;
  final int? totalListings;
  final int? completedTransactions;
  final String? memberSince;
  List<String> favoriteToys;

  User({
    required this.id,
    this.username = 'Utilisateur',
    this.email = '',
    this.profileImageUrl,
    this.rating,
    this.reviewsCount,
    this.responseTimeMinutes,
    this.totalListings,
    this.completedTransactions,
    this.memberSince,
    this.favoriteToys = const [],
  });

  factory User.fromJson(dynamic json) {
    if (json is List) {
      throw FormatException("Réponse serveur invalide");
    }
    final map = json as Map<String, dynamic>;
    return User(
      id: map['_id']?.toString() ?? map['userId']?.toString() ?? '',
      username: map['name'] ?? map['username'] ?? 'Utilisateur',
      email: map['email'] ?? '',
      profileImageUrl: map['profileImage'] ?? map['profileImageUrl'],
      rating: map['rating'] != null ? (map['rating'] as num).toDouble() : null,
      reviewsCount:
          map['reviewsCount'] != null ? map['reviewsCount'] as int : 0,
      responseTimeMinutes: map['responseTimeMinutes'],
      totalListings: map['totalListings'],
      completedTransactions: map['completedTransactions'],
      memberSince: map['memberSince'],
      favoriteToys: map['favoriteToys'] != null
          ? List<String>.from(map['favoriteToys'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': username,
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
      username: username,
      email: email,
      profileImageUrl: profileImageUrl,
      rating: rating,
      reviewsCount: reviewsCount,
      responseTimeMinutes: responseTimeMinutes,
      totalListings: totalListings,
      completedTransactions: completedTransactions,
      memberSince: memberSince,
      favoriteToys: favoriteToys ?? this.favoriteToys,
    );
  }
}
