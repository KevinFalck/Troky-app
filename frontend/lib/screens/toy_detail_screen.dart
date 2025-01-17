import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/toy.dart';
import '../models/user.dart';
import 'dart:convert' as json;
import 'dart:convert';

class ToyDetailScreen extends StatefulWidget {
  final Toy toy;

  ToyDetailScreen({required this.toy});

  @override
  _ToyDetailScreenState createState() => _ToyDetailScreenState();
}

class _ToyDetailScreenState extends State<ToyDetailScreen> {
  late bool isFavorite;
  late User mockOwner;

  @override
  void initState() {
    super.initState();
    isFavorite = widget.toy.favorites;
    mockOwner = User(
      id: '1',
      username: 'Kevin F.',
      email: 'kevinthelol@gmail.com',
      profileImageUrl: null,
      rating: 4.9,
      responseTimeMinutes: 20,
      totalListings: 12,
      completedTransactions: 8,
      memberSince: '2024-01',
    );
  }

  Future<void> toggleFavorite() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mise à jour des favoris en cours...')),
      );

      final response = await http.patch(
        Uri.parse('http://10.0.2.2:5000/api/toys/${widget.toy.id}/favorites'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'favorites': !isFavorite}),
      );

      if (response.statusCode == 200) {
        setState(() {
          isFavorite = !isFavorite;
          widget.toy.favorites = isFavorite;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Favori mis à jour avec succès')),
        );
      } else {
        print(
            'Erreur lors de la mise à jour des favoris: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour des favoris')),
        );
      }
    } catch (e) {
      print('Erreur de connexion: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 42, 149, 156),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        title: Text(widget.toy.name, style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 300,
                  width: double.infinity,
                  child: widget.toy.imageUrl.isNotEmpty
                      ? Image.network(
                          widget.toy.imageUrl,
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Icon(Icons.image_not_supported, size: 50),
                        ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: Colors.red,
                        size: 30,
                      ),
                      onPressed: toggleFavorite,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.toy.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.toy.description,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            InkWell(
              onTap: () {
                // TODO: Navigation vers le profil complet du vendeur
              },
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[200],
                      child: Icon(Icons.person, size: 30, color: Colors.grey),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mockOwner.username,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 20),
                              SizedBox(width: 4),
                              Text(
                                mockOwner.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(width: 16),
                              Icon(Icons.timer,
                                  color: Color.fromARGB(255, 42, 149, 156),
                                  size: 20),
                              SizedBox(width: 4),
                              Text(
                                'Rép. ~${mockOwner.responseTimeMinutes} min',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            Divider(height: 1),
            Padding(
              padding: EdgeInsets.all(16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 42, 149, 156),
                  minimumSize: Size(double.infinity, 48),
                ),
                onPressed: () {
                  // TODO: Implémenter la fonction de contact
                },
                child: Text(
                  'Contacter l\'annonceur',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
