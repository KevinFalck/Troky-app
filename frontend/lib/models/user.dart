class User {
  final String id;
  final String? username;
  final String? email;
  final String? profileImageUrl;
  final double? rating;
  final int? responseTimeMinutes;
  final int? totalListings;
  final int? completedTransactions;
  final String? memberSince;
  List<String> favoriteToys = [];

  User({
    required this.id,
    this.username = 'Utilisateur',
    this.email = '',
    this.profileImageUrl,
    this.rating,
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
      id: map['_id']?.toString() ?? '',
      username: map['username'] ?? 'Utilisateur',
      email: map['email'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      rating: map['rating']?.toDouble(),
      responseTimeMinutes: map['responseTimeMinutes'],
      totalListings: map['totalListings'],
      completedTransactions: map['completedTransactions'],
      memberSince: map['memberSince'],
      favoriteToys: (map['favoriteToys'] as List<dynamic>?)
              ?.map<String>((item) => item['\$oid']?.toString() ?? '')
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'rating': rating,
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
      responseTimeMinutes: responseTimeMinutes,
      totalListings: totalListings,
      completedTransactions: completedTransactions,
      memberSince: memberSince,
      favoriteToys: favoriteToys ?? this.favoriteToys,
    );
  }
}
