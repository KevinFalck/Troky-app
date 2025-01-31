import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/toy.dart';
import '../models/user.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ToyDetailScreen extends StatefulWidget {
  final Toy toy;

  const ToyDetailScreen({super.key, required this.toy});

  @override
  _ToyDetailScreenState createState() => _ToyDetailScreenState();
}

class _ToyDetailScreenState extends State<ToyDetailScreen> {
  late bool isFavorite;
  late User mockOwner;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    isFavorite = auth.user?.favoriteToys?.contains(widget.toy.id) ?? false;
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
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connectez-vous pour gérer les favoris')),
      );
      return;
    }

    try {
      setState(() => isFavorite = !isFavorite); // Feedback immédiat
      await auth.toggleFavorite(widget.toy.id!); // Utilisation du provider
    } catch (e) {
      setState(() => isFavorite = !isFavorite); // Annulation visuelle
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
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
        title: Text(widget.toy.name ?? 'Détails du jouet'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: (widget.toy.imageUrl?.isNotEmpty ?? false)
                      ? Image.network(widget.toy.imageUrl!)
                      : Placeholder(),
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
                    widget.toy.name ?? 'Nom inconnu',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.toy.description ?? 'Aucune description',
                    style: Theme.of(context).textTheme.bodyMedium,
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
                            mockOwner.username ?? 'Utilisateur inconnu',
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
                                mockOwner.rating?.toStringAsFixed(1) ?? '0.0',
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
