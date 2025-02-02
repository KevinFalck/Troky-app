import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../config/app_routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).refreshUserData();
    });
  }

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
          _imageFile = pickedFile;
        });
        await _uploadAndUpdateProfile(pickedFile);
      }
    } catch (e) {
      print('Erreur lors de la sélection de l\'image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la sélection de l\'image'),
        ),
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
                      _imageFile = image;
                    });
                    _uploadAndUpdateProfile(image);
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
                      _imageFile = image;
                    });
                    _uploadAndUpdateProfile(image);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String> _uploadImage(XFile imageFile) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Début de l\'upload...')),
      );
      // Requête multipart vers l'endpoint /api/upload
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:5000/api/upload'),
      );
      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();
      var multipartFile = http.MultipartFile(
        'image',
        stream,
        length,
        filename: imageFile.name,
      );
      request.files.add(multipartFile);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Envoi de l\'image vers S3...')),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['imageUrl'];
      } else {
        throw Exception('Échec de l\'upload: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'upload de l\'image: $e'),
        ),
      );
      rethrow;
    }
  }

  Future<void> _uploadAndUpdateProfile(XFile imageFile) async {
    try {
      // 1. Upload de l'image vers S3
      final String imageUrl = await _uploadImage(imageFile);
      print("URL d'image récupérée : $imageUrl");

      // 2. Mise à jour du profil via PATCH /auth/profile/image
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;
      final token = authProvider.token; // Vérifiez que token n'est pas null
      print("Token utilisé pour la mise à jour: $token");
      print("ID de l'utilisateur : ${currentUser?.id}");

      final updateUri = Uri.parse('http://10.0.2.2:5000/auth/profile/image');
      final updateResponse = await http.patch(
        updateUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        // Le backend utilise req.user.id pour identifier l'utilisateur, inutile de passer "userId"
        body: json.encode({
          'profileImage': imageUrl,
        }),
      );
      print("Reponse PATCH: ${updateResponse.statusCode}");
      print("Body PATCH: ${updateResponse.body}");

      if (updateResponse.statusCode == 200) {
        final updateData = json.decode(updateResponse.body);
        authProvider.updateUser(User.fromJson(updateData));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo de profil mise à jour')),
        );
      } else {
        throw Exception('Erreur lors de la mise à jour de la photo de profil');
      }
    } catch (e) {
      print("Erreur dans _uploadAndUpdateProfile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 42, 149, 156),
        title: Row(
          children: [
            Image.asset('assets/images/troky_logo.webp', height: 40),
            SizedBox(width: 10),
            Text(
              'Profil',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: user == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Connectez-vous pour accéder à votre profil'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.login);
                    },
                    child: Text('Se connecter'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // En-tête du profil
                  Container(
                    padding: EdgeInsets.all(16),
                    color: Theme.of(context).colorScheme.surface,
                    child: Column(
                      children: [
                        // Photo de profil avec possibilité de modification
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: _imageFile != null
                                  ? FileImage(File(_imageFile!.path))
                                  : (user.profileImage != null
                                      ? NetworkImage(user.profileImage!)
                                      : null),
                              child: (_imageFile == null &&
                                      user.profileImage == null)
                                  ? Icon(Icons.person,
                                      size: 50, color: Colors.white)
                                  : null,
                            ),
                            GestureDetector(
                              onTap: _showImageSourceDialog,
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    Color.fromARGB(255, 42, 149, 156),
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
                        Text(
                          user.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        // Affichage de la note et avis
                        ReviewIndicator(
                          rating: user.rating,
                          reviewsCount: user.reviewsCount,
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
                          value: user.responseTimeMinutes != null
                              ? '${user.responseTimeMinutes} minutes'
                              : 'Non disponible',
                        ),
                        _buildStatItem(
                          icon: Icons.list_alt,
                          title: 'Annonces publiées',
                          value: user.totalListings != null 
                              ? '${user.totalListings}' 
                              : '${_calculateUserListings()}',
                        ),
                        _buildStatItem(
                          icon: Icons.swap_horiz,
                          title: 'Échanges réalisés',
                          value: user.completedTransactions?.toString() ?? '0',
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
                            // Navigation vers la page de modification du profil
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.history,
                          title: 'Historique des échanges',
                          onTap: () {
                            // Navigation vers l'historique
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.help_outline,
                          title: 'Aide et support',
                          onTap: () {
                            // Navigation vers l'aide
                          },
                        ),
                        // Bouton pour changer de thème
                        _buildActionButton(
                          icon: Icons.brightness_6,
                          title:
                              Provider.of<ThemeProvider>(context).themeMode ==
                                      ThemeMode.dark
                                  ? 'Passer en mode clair'
                                  : 'Passer en mode sombre',
                          onTap: () {
                            final themeProvider = Provider.of<ThemeProvider>(
                                context,
                                listen: false);
                            if (themeProvider.themeMode == ThemeMode.dark) {
                              themeProvider.toggleTheme(ThemeMode.light);
                            } else {
                              themeProvider.toggleTheme(ThemeMode.dark);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
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
              child: Text('Déconnexion',
                  style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  int _calculateUserListings() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.allToys.where((toy) => toy.owner == authProvider.user?.id).length;
  }
}

// Widget dédié à l'affichage de la note sous forme d'étoiles avec le nombre d'avis
class ReviewIndicator extends StatelessWidget {
  final double? rating;
  final int reviewsCount;

  const ReviewIndicator(
      {Key? key, required this.rating, required this.reviewsCount})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Si aucun avis n'est disponible, on affiche "aucun avis"
    if (reviewsCount == null || reviewsCount == 0 || rating == null) {
      return const Text(
        'aucun avis',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      );
    }

    int fullStars = rating!.floor();
    bool hasHalfStar = (rating! - fullStars) >= 0.5;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(5, (index) {
          if (index < fullStars) {
            return const Icon(Icons.star, color: Colors.amber, size: 24);
          } else if (index == fullStars && hasHalfStar) {
            return const Icon(Icons.star_half, color: Colors.amber, size: 24);
          } else {
            return const Icon(Icons.star_border, color: Colors.amber, size: 24);
          }
        }),
        const SizedBox(width: 8),
        Text(
          '${rating!.toStringAsFixed(2).replaceAll('.', ',')}/5 (${reviewsCount!} avis)',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface),
        ),
      ],
    );
  }
}
