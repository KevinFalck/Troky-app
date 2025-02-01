import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart'; // Importez la page d'inscription
import 'toy_list_screen.dart'; // Importez les autres écrans nécessaires
import 'favorites_screen.dart';
import 'add_toy_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  int _selectedIndex = 0; // Pour gérer l'index de la barre de navigation

  Future<void> _login() async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:5000/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': _emailController.text,
        'password': _passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Connexion réussie: ${data['message']}');
      // Mettez à jour l'état d'authentification avec le userId et le token
      Provider.of<AuthProvider>(context, listen: false)
          .login(data['userId'], data['token']);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connexion réussie!')),
      );
      Navigator.of(context).pushReplacementNamed('/');
    } else {
      final data = json.decode(response.body);
      print('Erreur: ${data['message']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${data['message']}')),
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    try {
      // Appel en passant bien le contexte
      final user = await Provider.of<AuthProvider>(context, listen: false)
          .signInWithGoogle(context);

      if (user != null && (user.email?.isNotEmpty ?? false)) {
        // Notification de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connecté avec ${user.email}')),
        );
        // Redirection ou autres actions après connexion réussie…
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du login : utilisateur inconnu')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du login : ${e.toString()}')),
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
        Navigator.of(context).pushReplacementNamed(
            '/favorites'); // Redirige vers la page des favoris
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed(
            '/add-toy'); // Redirige vers la page d'ajout de jouet
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed(
            '/messages'); // Redirige vers la page des messages
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed(
            '/profile'); // Redirige vers la page de profil
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Connexion')),
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
              onPressed: _login,
              child: Text('Se connecter'),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(
                    '/register'); // Redirige vers la page d'inscription
              },
              child: Text('Pas encore inscrit ? Créez un compte'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.grey),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: _loginWithGoogle,
              icon: Image.asset(
                'assets/images/google_logo.webp',
                height: 24.0,
              ),
              label: Text(
                'Connexion avec Google',
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
