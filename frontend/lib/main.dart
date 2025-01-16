// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/toy_list_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/add_toy_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/messages_screen.dart';
import 'providers/theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Troky - Troc de Jouets',
      theme: ThemeData(
        primaryColor: Color.fromARGB(255, 42, 149, 156),
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        // Thème clair
        colorScheme: ColorScheme.light(
          primary: Color.fromARGB(255, 42, 149, 156),
          secondary: Colors.blue,
        ),
      ),
      darkTheme: ThemeData(
        primaryColor: Color.fromARGB(255, 42, 149, 156),
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF121212), // Couleur de fond sombre
        // Thème sombre
        colorScheme: ColorScheme.dark(
          primary: Color.fromARGB(255, 42, 149, 156),
          secondary: Colors.blue,
          surface: Color(0xFF1E1E1E),
          background: Color(0xFF121212),
        ),
        // Personnalisation des composants en mode sombre
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
        ),
        inputDecorationTheme: InputDecorationTheme(
          fillColor: Color(0xFF2A2A2A),
          filled: true,
        ),
      ),
      themeMode: themeProvider.themeMode, // Utilisez le thème du provider
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    ToyListScreen(),
    FavoritesScreen(),
    AddToyScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
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
