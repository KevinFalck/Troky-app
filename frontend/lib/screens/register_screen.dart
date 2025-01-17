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

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  int _selectedIndex = 0; // Pour gérer l'index de la barre de navigation

  Future<void> _register() async {
    final response = await http.post(
      Uri.parse(
          'http://10.0.2.2:5000/auth/register'), // Remplacez par l'URL de votre backend
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': _emailController.text,
        'password': _passwordController.text,
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      // Gérer l'inscription réussie
      print('Inscription réussie: ${data['message']}');
      // Afficher une notification de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Inscription réussie!')),
      );
      Navigator.of(context)
          .pushReplacementNamed('/login'); // Redirige vers la page de connexion
    } else {
      // Gérer les erreurs
      final data = json.decode(response.body);
      print('Erreur: ${data['message']}');
      // Afficher une notification d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${data['message']}')),
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
      appBar: AppBar(title: Text('Inscription')),
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
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pushNamed('/login'); // Redirige vers la page de connexion
              },
              child: Text('Déjà inscrit ? Connectez-vous'),
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
