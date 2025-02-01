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

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: dotenv.get('GOOGLE_CLIENT_ID'),
    serverClientId: dotenv.get('GOOGLE_SERVER_CLIENT_ID'),
  );

  String? get userId => _userId;
  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;

  void updateUser(User newUser) {
    _user = newUser;
    notifyListeners();
  }

  void setToys(List<Toy> toys) {
    allToys = toys;
    notifyListeners();
  }

  Future<void> login(String userId) async {
    _isAuthenticated = true;
    notifyListeners();
  }

  void logout() {
    _userId = null;
    _user = null;
    _isAuthenticated = false;
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
        Uri.parse('${Env.backendUrl}/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'idToken': googleAuth.idToken,
          'email': googleUser.email,
          'name': googleUser.displayName,
          'photoUrl': googleUser.photoUrl,
        }),
      );

      print('Réponse du backend : ${response.body}'); // Nouveau log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = User.fromJson(data);
        updateUser(user);
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
}
