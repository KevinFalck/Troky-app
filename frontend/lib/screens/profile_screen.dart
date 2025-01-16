import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/user.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        // TODO: Uploader l'image vers le serveur
        _uploadImage(_imageFile!);
      }
    } catch (e) {
      print('Erreur lors de la sélection de l\'image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection de l\'image')),
      );
    }
  }

  Future<void> _showImageSourceDialog() async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choisir depuis la galerie'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1000,
                    maxHeight: 1000,
                    imageQuality: 85,
                  );
                  if (image != null) {
                    setState(() {
                      _imageFile = File(image.path);
                    });
                    _uploadImage(_imageFile!);
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Prendre une photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 1000,
                    maxHeight: 1000,
                    imageQuality: 85,
                  );
                  if (image != null) {
                    setState(() {
                      _imageFile = File(image.path);
                    });
                    _uploadImage(_imageFile!);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadImage(File imageFile) async {
    try {
      // TODO: Implémenter l'upload vers le serveur
      // Exemple de feedback utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo de profil mise à jour')),
      );
    } catch (e) {
      print('Erreur lors de l\'upload de l\'image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la mise à jour de la photo')),
      );
    }
  }

  // Données temporaires pour le prototype
  final User mockUser = User(
    id: '1',
    username: 'Kevin F.',
    profileImageUrl: null,
    rating: 4.9,
    responseTimeMinutes: 20,
    totalListings: 12,
    completedTransactions: 8,
    memberSince: '2024-01',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Row(
          children: [
            Image.asset(
              'assets/images/troky_logo.webp',
              height: 40,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 8),
            Text(
              'Mon Profil',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6,
                color: Theme.of(context).colorScheme.onPrimary),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
        ],
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // En-tête du profil
              Container(
                padding: EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  children: [
                    // Photo de profil
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (mockUser.profileImageUrl != null
                                  ? NetworkImage(mockUser.profileImageUrl!)
                                      as ImageProvider
                                  : null),
                          child: (_imageFile == null &&
                                  mockUser.profileImageUrl == null)
                              ? Icon(Icons.person, size: 50, color: Colors.grey)
                              : null,
                        ),
                        GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Color.fromARGB(255, 42, 149, 156),
                            child: Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Pseudo
                    Text(
                      mockUser.username,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 8),
                    // Note
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < mockUser.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 24,
                          );
                        }),
                        SizedBox(width: 8),
                        Text(
                          mockUser.rating.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              // Statistiques
              Container(
                padding: EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statistiques',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildStatItem(
                      icon: Icons.timer,
                      title: 'Temps de réponse moyen',
                      value: '${mockUser.responseTimeMinutes} minutes',
                    ),
                    _buildStatItem(
                      icon: Icons.list_alt,
                      title: 'Annonces publiées',
                      value: mockUser.totalListings.toString(),
                    ),
                    _buildStatItem(
                      icon: Icons.swap_horiz,
                      title: 'Échanges réalisés',
                      value: mockUser.completedTransactions.toString(),
                    ),
                    _buildStatItem(
                      icon: Icons.calendar_today,
                      title: 'Membre depuis',
                      value: mockUser.memberSince,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              // Menu d'actions
              Container(
                padding: EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildActionButton(
                      icon: Icons.edit,
                      title: 'Modifier le profil',
                      onTap: () {
                        // Navigation vers modification profil
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.history,
                      title: 'Historique des échanges',
                      onTap: () {
                        // Navigation vers historique
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.help_outline,
                      title: 'Aide et support',
                      onTap: () {
                        // Navigation vers aide
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Color.fromARGB(255, 42, 149, 156)),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Color.fromARGB(255, 42, 149, 156)),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
