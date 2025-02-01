import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart'; // Importez la page de connexion
import 'toy_list_screen.dart'; // Importez les autres écrans nécessaires
import 'favorites_screen.dart';
import 'add_toy_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import '../config/app_routes.dart';
import '../widgets/custom_app_bar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  int _selectedIndex = 0; // Pour gérer l'index de la barre de navigation

  Future<void> _register() async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        Provider.of<AuthProvider>(context, listen: false).login(data['userId']);
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      } else {
        final errorBody = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorBody['message'] ?? 'Erreur inconnue')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion: $e')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Navigation vers les différentes pages
    switch (index) {
      case 0:
        Navigator.of(context)
            .pushReplacementNamed('/'); // Redirige vers la page d'accueil
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/favorites'); // Favoris
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/add-toy'); // Publier
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/messages'); // Messages
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed('/profile'); // Profil
        break;
    }
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Déconnexion'),
          content: Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Provider.of<AuthProvider>(context, listen: false).logout();
                Navigator.of(context).pushReplacementNamed(AppRoutes.login);
              },
              child: Text('Déconnexion', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Pas de redirection ici
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: Text('Inscription'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              child: Text('S\'inscrire'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed(AppRoutes.login);
              },
              child: Text('Déjà un compte ? Connectez-vous'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.grey),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () async {
                try {
                  final user =
                      await Provider.of<AuthProvider>(context, listen: false)
                          .signInWithGoogle(context);
                  if (user != null && (user.email?.isNotEmpty ?? false)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Connecté avec ${user.email}')),
                    );
                    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Erreur lors du login : utilisateur inconnu')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Erreur lors du login : ${e.toString()}')),
                  );
                }
              },
              icon: Image.asset(
                'assets/images/google_logo.webp',
                height: 24.0,
              ),
              label: Text(
                'Continuer avec Google',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Rechercher',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoris',
          ),
          BottomNavigationBarItem(
            icon: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.fromARGB(255, 42, 149, 156),
              ),
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: 30,
              ),
            ),
            label: 'Publier',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color.fromARGB(255, 42, 149, 156),
        onTap: _onItemTapped,
      ),
    );
  }
}
