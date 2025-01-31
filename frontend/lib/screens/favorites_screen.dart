import 'package:flutter/material.dart';
import 'package:frontend/models/user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/toy.dart';
import 'toy_detail_screen.dart';
import 'add_toy_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'favorites_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Toy> favoriteToys = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFavoritesFromProvider();
  }

  Future<void> _loadFavoritesFromProvider() async {
    final auth = Provider.of<AuthProvider>(context, listen: true);
    final favoriteIds = auth.user?.favoriteToys ?? [];
    final toys = Provider.of<AuthProvider>(context).allToys;
    var favoriteToys = toys.where((t) => favoriteIds.contains(t.id)).toList();

    if (favoriteToys.isEmpty) {
      if (mounted) setState(() => favoriteToys = []);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/toys/by-ids'),
        body: jsonEncode({'ids': favoriteIds}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          favoriteToys = (jsonDecode(response.body) as List)
              .map<Toy>((item) => Toy.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final favoriteIds = auth.user?.favoriteToys ?? [];
    final toys = Provider.of<AuthProvider>(context).allToys;
    final favoriteToys = toys.where((t) => favoriteIds.contains(t.id)).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 42, 149, 156),
        title: Row(
          children: [
            Image.asset(
              'assets/images/troky_logo.webp',
              height: 40,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 8),
            Text(
              'Mes Favoris',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      body: favoriteToys.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Aucun favori pour le moment',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent: 320,
              ),
              itemCount: favoriteToys.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ToyDetailScreen(toy: favoriteToys[index]),
                      ),
                    );
                    if (result == true) {
                      await _loadFavoritesFromProvider();
                    }
                  },
                  child: SizedBox(
                    height: 320,
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              SizedBox(
                                height: 180,
                                width: double.infinity,
                                child:
                                    (favoriteToys[index].imageUrl?.isNotEmpty ??
                                            false)
                                        ? Image.network(
                                            favoriteToys[index].imageUrl!,
                                            fit: BoxFit.cover)
                                        : Placeholder(),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  height: 36,
                                  width: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: Icon(
                                      auth.user?.favoriteToys?.contains(
                                                  favoriteToys[index].id) ??
                                              false
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => Provider.of<AuthProvider>(
                                            context,
                                            listen: false)
                                        .toggleFavorite(favoriteToys[index].id),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    favoriteToys[index].name ??
                                        'Nom non disponible',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 6),
                                  Expanded(
                                    child: Text(
                                      favoriteToys[index].description ??
                                          'Description non disponible',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
