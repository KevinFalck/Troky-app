import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/toy.dart';
import '../models/user.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ToyDetailScreen extends StatefulWidget {
  final Toy toy;

  const ToyDetailScreen({Key? key, required this.toy}) : super(key: key);

  @override
  _ToyDetailScreenState createState() => _ToyDetailScreenState();
}

class _ToyDetailScreenState extends State<ToyDetailScreen> {
  late bool isFavorite;
  User? owner;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    isFavorite = auth.user?.favoriteToys?.contains(widget.toy.id) ?? false;
    _loadOwner(widget.toy.owner);
  }

  Future<void> _loadOwner(String ownerId) async {
    try {
      final response =
          await http.get(Uri.parse('http://10.0.2.2:5000/api/users/$ownerId'));
      if (response.statusCode == 200) {
        setState(() {
          owner = User.fromJson(json.decode(response.body));
        });
      } else {
        print('Erreur chargement owner: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors du chargement du propriétaire: $e');
    }
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

  Widget _buildOwnerInfo() {
    // Si les infos du propriétaire ne sont pas encore chargées, on affiche un placeholder.
    if (owner == null) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[200],
              child: Icon(Icons.person, size: 30, color: Colors.grey),
            ),
            SizedBox(width: 16),
            Text('Chargement des infos du vendeur...',
                style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    // Affichage détaillé des infos du propriétaire.
    return InkWell(
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
              backgroundImage: owner!.profileImage != null &&
                      owner!.profileImage!.isNotEmpty
                  ? NetworkImage(owner!.profileImage!)
                  : null,
              child: owner!.profileImage == null || owner!.profileImage!.isEmpty
                  ? Icon(Icons.person, size: 30, color: Colors.grey)
                  : null,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    owner!.name ?? 'Utilisateur inconnu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  owner!.rating != null
                      ? Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            SizedBox(width: 4),
                            Text(
                              owner!.rating!.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(width: 16),
                            Icon(Icons.timer,
                                color:
                                    Color.fromARGB(255, 42, 149, 156),
                                size: 20),
                            SizedBox(width: 4),
                            Text(
                              'Rép. ~${owner!.responseTimeMinutes ?? '?'} min',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        )
                      : Container(),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
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
            _buildOwnerInfo(),
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
