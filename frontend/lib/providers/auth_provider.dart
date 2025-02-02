import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/env.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/navigation_service.dart';
import '../config/app_routes.dart';
import '../models/user.dart';
import '../models/toy.dart';

class AuthProvider with ChangeNotifier {
  String? _userId;
  User? _user;
  final NavigationService _navigationService = NavigationService();
  bool _isAuthenticated = false;
  List<Toy> allToys = [];
  String? _token;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: dotenv.get('GOOGLE_CLIENT_ID'),
    serverClientId: dotenv.get('GOOGLE_SERVER_CLIENT_ID'),
  );

  String? get userId => _userId;
  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;

  void updateUser(User newUser) {
    _user = newUser;
    notifyListeners();
  }

  void setToys(List<Toy> toys) {
    allToys = toys;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:5000/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _token = data['token'];
      _user = User.fromJson(data);
      _isAuthenticated = true;
      notifyListeners();
    } else {
      throw Exception('Erreur lors du login');
    }
  }

  void logout() {
    _userId = null;
    _user = null;
    _isAuthenticated = false;
    _token = null;
    notifyListeners();
  }

  Future<void> handleGoogleSignIn(BuildContext context) async {
    try {
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Erreur lors de la connexion Google: Utilisateur null');
      }

      final googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null) {
        throw Exception(
            'Erreur lors de la connexion Google: Token d\'accès null');
      }

      if (googleAuth.idToken == null) {
        throw Exception('Erreur d\'authentification: Token Google non reçu');
      }

      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'idToken': googleAuth.idToken,
        }),
      );

      print('Réponse du backend : ${response.body}'); // Nouveau log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['token'];
        updateUserFromJson(data);
        _isAuthenticated = true;
        notifyListeners();

        _triggerNavigation(context);
      } else {
        print('Erreur HTTP : ${response.statusCode}');
        throw Exception('Erreur lors de la connexion Google');
      }
    } catch (error) {
      print('Erreur complète : $error');
      _showErrorSnackbar(context, error);
    }
  }

  void _triggerNavigation(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  void _showErrorSnackbar(BuildContext context, dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Erreur de connexion Google: ${error.toString()}')),
    );
  }

  Future<void> toggleFavorite(String toyId) async {
    if (user == null) return;

    try {
      final response = await http.patch(
        Uri.parse('http://10.0.2.2:5000/api/users/${user!.id}/favorites'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'toyId': toyId}),
      );

      if (response.statusCode == 200) {
        final updatedFavorites = List<String>.from(jsonDecode(response.body));
        final updatedUser = user!.copyWith(favoriteToys: updatedFavorites);
        updateUser(updatedUser);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur favori: $e');
    }
  }

  Future<User?> signInWithGoogle(BuildContext context) async {
    await handleGoogleSignIn(context);
    return _user;
  }

  void updateToken(String newToken) {
    _token = newToken;
    notifyListeners();
  }

  void updateUserFromJson(Map<String, dynamic> json) {
    final userData = json.containsKey('user') ? json['user'] : json;
    print("Données utilisateur reçues : $userData");
    _user = User.fromJson(userData);
    print("ID utilisateur assigné : ${_user?.id}");
    notifyListeners();
  }

  Future<void> refreshUserData() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/auth/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        updateUserFromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Erreur rafraîchissement utilisateur: $e');
    }
  }
}
