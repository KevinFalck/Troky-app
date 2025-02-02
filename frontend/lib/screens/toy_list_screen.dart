// lib/screens/toy_list_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:math';
import '../models/toy.dart';
import 'add_toy_screen.dart';
import 'toy_detail_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';

class ToyListScreen extends StatefulWidget {
  const ToyListScreen({Key? key}) : super(key: key);

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
  late Future<List<Toy>> _futureToys;

  @override
  void initState() {
    super.initState();
    _futureToys = fetchToys();
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
    // Ajouter un timeout pour les services de localisation
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return false;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Localisation requise'),
          content: Text('Activez la localisation pour voir les jouets proches'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                await Geolocator.openLocationSettings();
                Navigator.pop(ctx);
              },
              child: Text('Paramètres'),
            ),
          ],
        ),
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
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
        bool matchesSearch =
            _matchesSearchQuery(toy, searchQuery, locationQuery);

        bool matchesLocation = true;

        if (locationQuery.isNotEmpty) {
          matchesLocation =
              (toy.location ?? '').toLowerCase().contains(locationQuery);
        } else if (_currentPosition != null) {
          if (toy.coordinates?['coordinates'] != null &&
              (toy.coordinates?['coordinates'] as List).length == 2) {
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
          if (a.coordinates?['coordinates'] == null) {
            return 1;
          }
          if (b.coordinates?['coordinates'] == null) {
            return -1;
          }

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

  bool _matchesSearchQuery(Toy toy, String searchQuery, String locationQuery) {
    final name = toy.name ?? '';
    final description = toy.description ?? '';
    final location = toy.location ?? '';

    return name.toLowerCase().contains(searchQuery) ||
        description.toLowerCase().contains(searchQuery) &&
            (locationQuery.isEmpty ||
                location.toLowerCase().contains(locationQuery));
  }

  Future<List<Toy>> fetchToys() async {
    try {
      final response =
          await http.get(Uri.parse('http://10.0.2.2:5000/api/toys'));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        print("Body décodé (type ${body.runtimeType}) : $body");

        if (body is List) {
          for (var item in body) {
            print("Type d'un item: ${item.runtimeType}");
          }
          return body.map((json) => Toy.fromJson(json)).toList();
        } else {
          throw Exception("Format de réponse inattendu: $body");
        }
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print("Erreur lors de la récupération des jouets: $e");
      throw e;
    }
  }

  bool isFavorite(Toy toy) {
    final auth = Provider.of<AuthProvider>(context, listen: true);
    return auth.user?.favoriteToys?.contains(toy.id) ?? false;
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (!auth.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connectez-vous pour ajouter un jouet')),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddToyScreen()),
      ).then((_) => _futureToys = fetchToys());
    } else {
      setState(() {
        _selectedIndex = index;
      });
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
    // Détection du mode sombre
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[800] : Colors.grey[200];
    final borderColor =
        isDark ? Colors.blueGrey.shade600 : Colors.blueGrey.shade200;
    final iconColor = isDark ? Colors.white70 : Colors.grey;
    final hintStyle =
        TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey);

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
            const SizedBox(width: 8),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche et localisation avec support du mode sombre
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Barre "Rechercher"
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: borderColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: iconColor, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(fontSize: 12),
                            // On force la transparence de la zone de saisie afin d'hériter du bgColor du container
                            decoration: InputDecoration(
                              hintText: "Rechercher",
                              hintStyle: hintStyle,
                              border: InputBorder.none,
                              isDense: true,
                              filled: true,
                              fillColor: Colors.transparent,
                            ),
                            onChanged: (text) => setState(() {}),
                          ),
                        ),
                        _searchController.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _searchController.clear();
                                  });
                                },
                                child: Icon(Icons.clear,
                                    color: iconColor, size: 16),
                              )
                            : const SizedBox(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                // Barre "Localisation"
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: borderColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: iconColor, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _locationController,
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: "Localisation",
                              hintStyle: hintStyle,
                              border: InputBorder.none,
                              isDense: true,
                              filled: true,
                              // Force la transparence pour que la couleur du container soit respectée
                              fillColor: Colors.transparent,
                            ),
                            onChanged: (text) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                // Bouton de géolocalisation positionné à droite, à l'extérieur de la barre "Localisation"
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 42, 149, 156),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _isLoadingLocation
                      ? const Padding(
                          padding: EdgeInsets.all(6),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.my_location,
                              color: Colors.white, size: 16),
                          onPressed: _getCurrentLocation,
                        ),
                ),
              ],
            ),
          ),
          // La liste ou grille des jouets
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final toys = await fetchToys();
                setState(() {
                  _futureToys = Future.value(toys);
                });
              },
              child: FutureBuilder<List<Toy>>(
                future: _futureToys,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Erreur: ${snapshot.error}"));
                  } else if (!snapshot.hasData ||
                      (snapshot.data?.isEmpty ?? true)) {
                    return const Center(child: Text("Aucun jouet trouvé."));
                  } else {
                    final toys = snapshot.data!;
                    // Appliquer le filtre dès qu'on reçoit les données
                    final localFilteredToys = _getFilteredToys(toys);
                    return Expanded(
                      child: GridView.builder(
                        padding: EdgeInsets.all(8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          mainAxisExtent: 320,
                        ),
                        itemCount: localFilteredToys.length,
                        itemBuilder: (context, index) {
                          final toy = localFilteredToys[index];
                          return GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ToyDetailScreen(toy: toy),
                                ),
                              );
                              if (result == true) {
                                setState(() {
                                  _futureToys = fetchToys();
                                });
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
                                          child: toy.imageUrl != null
                                              ? Image.network(
                                                  toy.imageUrl!,
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
                                                isFavorite(toy)
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color: Colors.red,
                                              ),
                                              onPressed: () async {
                                                final auth =
                                                    Provider.of<AuthProvider>(
                                                        context,
                                                        listen: false);
                                                if (!auth.isAuthenticated) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content: Text(
                                                            'Connectez-vous pour gérer les favoris')),
                                                  );
                                                  return;
                                                }
                                                try {
                                                  await auth
                                                      .toggleFavorite(toy.id);
                                                } catch (e) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content: Text(
                                                            'Erreur: ${e.toString()}')),
                                                  );
                                                }
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
                                              toy.name ?? 'Nom inconnu',
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
                                                  toy.location ??
                                                      'Location non disponible',
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
                                                toy.description ??
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
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Toy> _getFilteredToys(List<Toy> toyList) {
    String searchQuery = _searchController.text.toLowerCase();
    String locationQuery = _locationController.text.toLowerCase();

    List<Toy> localFiltered = toyList.where((toy) {
      bool matchesSearch = toy.name.toLowerCase().contains(searchQuery) ||
          toy.description.toLowerCase().contains(searchQuery);
      bool matchesLocation = true;

      if (locationQuery.isNotEmpty) {
        matchesLocation = toy.location.toLowerCase().contains(locationQuery);
      } else if (_currentPosition != null) {
        if (toy.coordinates?['coordinates'] != null &&
            (toy.coordinates?['coordinates'] as List).length == 2) {
          double distance = Geolocator.distanceBetween(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                  toy.latitude,
                  toy.longitude) /
              1000; // conversion en km
          matchesLocation = distance <= 20; // 20 km maximum
        } else {
          matchesLocation = false;
        }
      }
      return matchesSearch && matchesLocation;
    }).toList();

    // Tri par distance si position disponible
    if (_currentPosition != null) {
      localFiltered.sort((a, b) {
        if (a.coordinates?['coordinates'] == null) return 1;
        if (b.coordinates?['coordinates'] == null) return -1;
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
    return localFiltered;
  }
}
