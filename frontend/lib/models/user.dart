class User {
  final String id;
  final String username;
  final String? profileImageUrl;
  final double rating;
  final int responseTimeMinutes;
  final int totalListings;
  final int completedTransactions;
  final String memberSince;

  User({
    required this.id,
    required this.username,
    this.profileImageUrl,
    required this.rating,
    required this.responseTimeMinutes,
    required this.totalListings,
    required this.completedTransactions,
    required this.memberSince,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      responseTimeMinutes: json['responseTimeMinutes'] ?? 0,
      totalListings: json['totalListings'] ?? 0,
      completedTransactions: json['completedTransactions'] ?? 0,
      memberSince: json['memberSince'] ?? '',
    );
  }
}
