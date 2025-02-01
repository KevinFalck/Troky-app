class User {
  final String id;
  final String email;
  final String name;
  final String? profileImage;
  final double? rating;
  final int? reviewsCount;
  final int? responseTimeMinutes;
  final int? totalListings;
  final int? completedTransactions;
  final String? memberSince;
  final List<String>? favoriteToys;
  final String? profileImageUrl;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.profileImage,
    this.rating,
    this.reviewsCount,
    this.responseTimeMinutes,
    this.totalListings,
    this.completedTransactions,
    this.memberSince,
    this.favoriteToys,
    this.profileImageUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? json['userId'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      profileImage: json['profileImage'],
      rating: json['rating'],
      reviewsCount: json['reviewsCount'] ?? 0,
      responseTimeMinutes: json['responseTimeMinutes'],
      totalListings: json['totalListings'],
      completedTransactions: json['completedTransactions'],
      memberSince: json['memberSince'],
      favoriteToys: List<String>.from(json['favoriteToys'] ?? []),
      profileImageUrl: json['profileImageUrl'],
    );
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
      responseTimeMinutes: responseTimeMinutes,
      totalListings: totalListings,
      completedTransactions: completedTransactions,
      memberSince: memberSince,
      favoriteToys: favoriteToys ?? this.favoriteToys,
      profileImageUrl: profileImageUrl,
    );
  }
}
