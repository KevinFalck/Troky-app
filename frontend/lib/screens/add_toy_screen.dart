import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../screens/toy_list_screen.dart';
import '../main.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';

class AddToyScreen extends StatefulWidget {
  const AddToyScreen({super.key});

  @override
  _AddToyScreenState createState() => _AddToyScreenState();
}

class _AddToyScreenState extends State<AddToyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  bool _isLoading = false;
  Position? _currentPosition;
  final bool _isLocationLoading = false;
  List<String> _suggestions = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      print('Erreur de géolocalisation: $e');
    }
  }

  Future<(double, double)?> _getCoordinatesFromCity(String cityName) async {
    try {
      String cleanedCityName = cityName.trim();
      List<Location> locations =
          await locationFromAddress("$cleanedCityName, France");

      if (locations.isEmpty) {
        locations = await locationFromAddress(cleanedCityName);
      }

      if (locations.isNotEmpty) {
        return (locations.first.latitude, locations.first.longitude);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la géolocalisation de la ville: $e');
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veuillez ajouter une photo')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final cityCoordinates =
            await _getCoordinatesFromCity(_locationController.text);

        if (cityCoordinates == null) {
          throw Exception('Ville non trouvée');
        }

        final String imageUrl = await _uploadImage(_imageFile!);

        final response = await http.post(
          Uri.parse('http://10.0.2.2:5000/api/toys'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'name': _nameController.text,
            'description': _descriptionController.text,
            'imageUrl': imageUrl,
            'location': _locationController.text.trim(),
            'latitude': cityCoordinates.$1,
            'longitude': cityCoordinates.$2,
            'owner': null
          }),
        );

        if (response.statusCode == 201) {
          if (!mounted) return;

          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        } else {
          if (!mounted) return;
          final errorBody = json.decode(response.body);
          throw Exception(
              'Erreur création: ${errorBody['message'] ?? 'Erreur inconnue'}');
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            duration: Duration(seconds: 3),
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
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
        if (mounted) {
          setState(() {
            _imageFile = pickedFile;
          });
        }
      }
    } catch (e) {
      print('Erreur lors de la sélection de l\'image: $e');
    }
  }

  Future<String> _uploadImage(XFile imageFile) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Début de l\'upload...')),
      );

      // Créer la requête multipart avec la route correcte
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'http://10.0.2.2:5000/api/upload'), // Retour à la route originale
      );

      // Ajouter le fichier
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
        SnackBar(content: Text('Envoi de l\'image vers S3...')),
      );

      // Envoyer la requête
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Réponse upload - Status: ${response.statusCode}')),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['imageUrl'];
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur upload - Body: ${response.body}')),
        );
        throw Exception('Échec de l\'upload: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur détaillée upload: $e')),
      );
      throw Exception('Erreur lors de l\'upload de l\'image: $e');
    }
  }

  Future<void> _searchCities(String query) async {
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://geo.api.gouv.fr/communes?nom=$query&limit=5&boost=population'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _suggestions =
              data.map<String>((city) => city['nom'] as String).toList();
          _isSearching = false;
        });
      }
    } catch (e) {
      print('Erreur lors de la recherche des villes: $e');
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
    }
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: 'Ville',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Theme.of(context).inputDecorationTheme.fillColor,
            prefixIcon: Icon(Icons.location_on),
            suffixIcon: _isSearching
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
          onChanged: (value) => _searchCities(value),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer une ville';
            }
            return null;
          },
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: _suggestions
                  .map((city) => ListTile(
                        title: Text(city),
                        onTap: () {
                          setState(() {
                            _locationController.text = city;
                            _suggestions = [];
                          });
                        },
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (!auth.isAuthenticated) {
      Future.microtask(
          () => Navigator.of(context).pushReplacementNamed('/login'));
      return Container();
    }

    return WillPopScope(
      onWillPop: () async {
        // Redirige vers MainScreen au lieu de revenir à la page précédente
        Navigator.of(context).pushReplacementNamed('/');
        return false; // Ne pas bloquer la navigation
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          title: Text(
            'Ajouter un jouet',
            style: TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: Theme.of(context).colorScheme.onPrimary),
            onPressed: () {
              // Vérifiez s'il y a un écran précédent
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                // Si aucun écran précédent, redirigez vers MainScreen
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      child: _imageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_imageFile!.path),
                                fit: BoxFit.cover,
                              ),
                            )
                          : Center(
                              child: Text(
                                'Ajouter une photo',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nom du jouet',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor:
                          Theme.of(context).inputDecorationTheme.fillColor,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un nom';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor:
                          Theme.of(context).inputDecorationTheme.fillColor,
                    ),
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer une description';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  _buildLocationField(),
                  SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isLoading ? null : _submitForm,
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Publier',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
