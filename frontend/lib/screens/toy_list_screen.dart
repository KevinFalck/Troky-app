// lib/screens/toy_list_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:math';
import '../models/toy.dart';
import 'add_toy_screen.dart';
import 'toy_detail_screen.dart';
import './favorites_screen.dart';

class ToyListScreen extends StatefulWidget {
  @override
  _ToyListScreenState createState() => _ToyListScreenState();
}

class _ToyListScreenState extends State<ToyListScreen> {
  List<Toy> toys = [];
  List<Toy> filteredToys = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  bool _isLoading = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadToys();
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Les services de localisation sont désactivés. Veuillez les activer.'),
          action: SnackBarAction(
            label: 'PARAMÈTRES',
            onPressed: () => Geolocator.openLocationSettings(),
          ),
        ),
      );
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Les permissions de localisation sont refusées')),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Les permissions de localisation sont refusées de manière permanente'),
          action: SnackBarAction(
            label: 'PARAMÈTRES',
            onPressed: () => Geolocator.openAppSettings(),
          ),
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final hasPermission = await _handleLocationPermission();

      if (!hasPermission) {
        throw Exception('Permission non accordée');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      _filterToys();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Position mise à jour ! Affichage des jouets à proximité.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de localisation: ${e.toString()}'),
          action: SnackBarAction(
            label: 'RÉESSAYER',
            onPressed: _getCurrentLocation,
          ),
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _filterToys() {
    setState(() {
      String searchQuery = _searchController.text.toLowerCase();
      String locationQuery = _locationController.text.toLowerCase();

      filteredToys = toys.where((toy) {
        bool matchesSearch = searchQuery.isEmpty ||
            toy.name.toLowerCase().contains(searchQuery) ||
            toy.description.toLowerCase().contains(searchQuery);

        bool matchesLocation = true;

        if (locationQuery.isNotEmpty) {
          matchesLocation = toy.location.toLowerCase().contains(locationQuery);
        } else if (_currentPosition != null) {
          if (toy.coordinates != null &&
              toy.coordinates['coordinates'] != null &&
              toy.coordinates['coordinates'].length == 2) {
            double distance = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              toy.latitude,
              toy.longitude,
            );

            // Convertir en kilomètres
            distance = distance / 1000;
            matchesLocation = distance <= 20; // 20km maximum
          } else {
            // Si pas de coordonnées valides, ne pas inclure dans les résultats
            matchesLocation = false;
          }
        }

        return matchesSearch && matchesLocation;
      }).toList();

      // Trier par distance si on a une position
      if (_currentPosition != null) {
        filteredToys.sort((a, b) {
          // Ne trier que les jouets avec des coordonnées valides
          if (a.coordinates == null || a.coordinates['coordinates'] == null)
            return 1;
          if (b.coordinates == null || b.coordinates['coordinates'] == null)
            return -1;

          double distanceA = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            a.latitude,
            a.longitude,
          );
          double distanceB = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            b.latitude,
            b.longitude,
          );
          return distanceA.compareTo(distanceB);
        });
      }
    });
  }

  Future<void> _loadToys() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response =
          await http.get(Uri.parse('http://10.0.2.2:5000/api/toys'));
      if (response.statusCode == 200) {
        final List<dynamic> toysJson = json.decode(response.body);
        setState(() {
          toys = toysJson.map((json) => Toy.fromJson(json)).toList();
          filteredToys = List.from(toys);
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des jouets: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> toggleFavorite(String id, bool currentState) async {
    try {
      final response = await http.patch(
        Uri.parse('http://10.0.2.2:5000/api/toys/$id/favorites'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'favorites': !currentState}),
      );

      if (response.statusCode == 200) {
        // Rafraîchir la liste des jouets
        await _loadToys();
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

  void _onItemTapped(int index) {
    if (index == 2) {
      // Navigation vers la page d'ajout
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddToyScreen()),
      ).then((_) => _loadToys()); // Rafraîchir la liste au retour
    } else {
      setState(() {
        _selectedIndex = index;
      });
      // Ajouter ici la navigation vers les autres pages
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.surface,
                  child: Column(
                    children: [
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _searchController,
                                textAlignVertical: TextAlignVertical.center,
                                decoration: InputDecoration(
                                  hintText: 'Rechercher un jouet',
                                  hintStyle: TextStyle(color: Colors.grey[600]),
                                  prefixIcon: Icon(Icons.search,
                                      color: Colors.grey[600]),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context)
                                      .inputDecorationTheme
                                      .fillColor,
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 16),
                                ),
                                onChanged: (value) => _filterToys(),
                              ),
                            ),
                            VerticalDivider(
                              color: Colors.grey[300],
                              thickness: 1,
                              width: 1,
                            ),
                            Expanded(
                              flex: 2,
                              child: Stack(
                                alignment: Alignment.centerRight,
                                children: [
                                  TextField(
                                    controller: _locationController,
                                    textAlign: TextAlign.center,
                                    textAlignVertical: TextAlignVertical.center,
                                    decoration: InputDecoration(
                                      hintText: _isLoadingLocation
                                          ? 'Localisation...'
                                          : 'Ville',
                                      hintStyle:
                                          TextStyle(color: Colors.grey[600]),
                                      prefixIcon: Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: Icon(
                                            _currentPosition != null
                                                ? Icons.my_location
                                                : Icons.location_on,
                                            color: Colors.grey[600]),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                    onChanged: (value) => _filterToys(),
                                  ),
                                  if (_isLoadingLocation)
                                    Positioned(
                                      right: 8,
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Color.fromARGB(255, 42, 149, 156),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadToys,
                    child: GridView.builder(
                      padding: EdgeInsets.all(8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        mainAxisExtent: 320,
                      ),
                      itemCount: filteredToys.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ToyDetailScreen(toy: filteredToys[index]),
                              ),
                            );
                            if (result == true) {
                              await _loadToys();
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
                                        child: filteredToys[index]
                                                .imageUrl
                                                .isNotEmpty
                                            ? Image.network(
                                                filteredToys[index].imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return Container(
                                                    color: Colors.grey[200],
                                                    child: Icon(
                                                      Icons.error_outline,
                                                      color: Colors.grey[400],
                                                      size: 40,
                                                    ),
                                                  );
                                                },
                                              )
                                            : Container(
                                                color: Colors.grey[200],
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.grey[400],
                                                  size: 40,
                                                ),
                                              ),
                                      ),
                                      Positioned(
                                        bottom: 8,
                                        right: 8,
                                        child: Container(
                                          height: 36,
                                          width: 36,
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.8),
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: Icon(
                                              filteredToys[index].favorites
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              toggleFavorite(
                                                  filteredToys[index].id,
                                                  filteredToys[index]
                                                      .favorites);
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            filteredToys[index].name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                size: 16,
                                                color: Colors.grey[600],
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                filteredToys[index].location,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          Expanded(
                                            child: Text(
                                              filteredToys[index].description,
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
                  ),
                ),
              ],
            ),
    );
  }
}
