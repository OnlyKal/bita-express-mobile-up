import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'colors.dart';
import 'api.dart';
import 'session.dart';
import 'pages/ride_tracking_page.dart';

class NavigationMapPage extends StatefulWidget {
  final double destinationLatitude;
  final double destinationLongitude;
  final String destinationTitle;
  final String destinationSubtitle;
  final String? vehicleTypeFilter;
  final double? departLatitude;
  final double? departLongitude;
  final double? distanceMeters;
  final double? durationSeconds;

  const NavigationMapPage({
    super.key,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.destinationTitle,
    required this.destinationSubtitle,
    this.vehicleTypeFilter,
    this.departLatitude,
    this.departLongitude,
    this.distanceMeters,
    this.durationSeconds,
  });

  @override
  State<NavigationMapPage> createState() => _NavigationMapPageState();
}

class _NavigationMapPageState extends State<NavigationMapPage> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  bool _isLoadingLocation = true;
  String? _locationError;
  double _currentZoom = 12.0;
  List<VehicleModel> _vehicles = [];
  bool _isLoadingVehicles = true;

  // Timer pour le rafraîchissement automatique des véhicules
  Timer? _vehicleRefreshTimer;
  bool _isAutoRefreshing = false;

  // Variables pour le routing OSRM
  List<LatLng> _routePoints = [];
  double _routeDistance = 0.0;
  double _routeDuration = 0.0;
  String _routeSummary = '';
  bool _isLoadingRoute = false;

  // Variables pour la tarification
  final Map<String, PricingModel?> _vehiclePricing = {};
  final Map<String, bool> _loadingPricing = {};

  // Flag pour suivre si le véhicule le plus proche a déjà été affiché
  bool _closestVehicleShown = false;

  @override
  void initState() {
    super.initState();
    print('NavigationMapPage - Destination reçue:');
    print('  Titre: ${widget.destinationTitle}');
    print('  Sous-titre: ${widget.destinationSubtitle}');
    print('  Latitude: ${widget.destinationLatitude}');
    print('  Longitude: ${widget.destinationLongitude}');

    // Vérification des coordonnées
    if (widget.destinationLatitude == 0.0 &&
        widget.destinationLongitude == 0.0) {
      print('ERREUR: Les coordonnées sont nulles (0,0) - Océan Atlantique!');
    } else if (widget.destinationLatitude.abs() > 90 ||
        widget.destinationLongitude.abs() > 180) {
      print('ERREUR: Coordonnées invalides (hors limites)!');
    } else {
      print('Coordonnées valides reçues');
    }

    _getCurrentLocation();
    _loadVehicles().then((_) {
      // Lancer automatiquement la navigation avec le premier véhicule
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _vehicles.isNotEmpty) {
          _autoStartNavigation();
        }
      });
    });
    _startVehicleRefreshTimer();
  }

  /// Lance automatiquement la navigation avec le premier véhicule disponible
  Future<void> _autoStartNavigation() async {
    if (_vehicles.isEmpty) return;

    try {
      final vehicle = _vehicles.first;
      print(
        'Navigation automatique avec le véhicule: ${vehicle.marque} ${vehicle.modele}',
      );

      // Récupérer les données utilisateur
      final userData = await SessionManager.getUserData();
      final token = await SessionManager.getToken();

      if (userData == null || token == null) {
        print('Erreur: Authentification non disponible');
        return;
      }

      if (_currentLocation == null) {
        print('Erreur: Position actuelle non disponible');
        return;
      }

      if (_routeDistance == 0 || _routeDuration == 0) {
        print('Erreur: Route non calculée');
        return;
      }

      // Récupérer la tarification
      String vehicleKey = '${vehicle.id}';
      PricingModel? pricing = _vehiclePricing[vehicleKey];

      if (pricing == null) {
        print('Erreur: Tarification non disponible');
        return;
      }

      // Afficher un dialogue de chargement
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Text(
                  'Création de la course...',
                  style: TextStyle(color: Colors.grey[800]),
                ),
              ],
            ),
          ),
        );
      }

      // Créer la demande de course sans confirmation
      final response = await ApiService.createRide(
        token: token,
        passagerId: userData['id'] ?? 0,
        departLatitude: _currentLocation!.latitude,
        departLongitude: _currentLocation!.longitude,
        destinationLatitude: widget.destinationLatitude,
        destinationLongitude: widget.destinationLongitude,
        distance: _routeDistance,
        dureeEstimee: _routeDuration,
        prixEstime: pricing.prixCdf,
      );

      if (response.success) {
        print('Course créée automatiquement: ${response.data}');

        // Extraire l'ID de la course créée
        int? rideId;
        if (response.data is Map<String, dynamic>) {
          rideId = response.data['id'] ?? response.data['course_id'];
        } else if (response.data is int) {
          rideId = response.data as int;
        }

        if (rideId != null && mounted) {
          // Fermer le loading dialog
          Navigator.pop(context);

          // Naviguer vers RideTrackingPage avec le vrai rideId
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => RideTrackingPage(rideId: rideId!),
            ),
          );
        }
      } else {
        if (mounted) {
          Navigator.pop(context); // Fermer le loading dialog
          _showErrorSnackBar('Erreur: ${response.message}');
        }
      }
    } catch (e) {
      print('Erreur lors du lancement de la navigation automatique: $e');
      if (mounted) {
        Navigator.pop(context); // S'assurer de fermer le loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Démarre le timer de rafraîchissement automatique des véhicules
  void _startVehicleRefreshTimer() {
    setState(() {
      _isAutoRefreshing = true;
    });

    _vehicleRefreshTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (mounted) {
        _loadVehicles(showLoading: false);
      }
    });
  }

  /// Arrête le timer de rafraîchissement
  void _stopVehicleRefreshTimer() {
    _vehicleRefreshTimer?.cancel();
    _vehicleRefreshTimer = null;

    if (mounted) {
      setState(() {
        _isAutoRefreshing = false;
      });
    }
  }

  @override
  void dispose() {
    _stopVehicleRefreshTimer();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Vérifier si les services de localisation sont activés
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Les services de localisation sont désactivés';
          _isLoadingLocation = false;
        });
        return;
      }

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Permission de localisation refusée';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Permission de localisation définitivement refusée';
          _isLoadingLocation = false;
        });
        return;
      }

      // Obtenir la position actuelle
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      // Ajuster la vue de la carte pour inclure les deux points
      _adjustMapView();

      // Calculer la route avec OSRM pour les passagers
      final userData = await SessionManager.getUserData();
      if (userData != null && userData['type_utilisateur'] == 'passager') {
        _calculateRouteWithOSRM();
      }
    } catch (e) {
      setState(() {
        _locationError = 'Erreur lors de l\'obtention de la position: $e';
        _isLoadingLocation = false;
      });
      print('Erreur géolocalisation: $e');
    }
  }

  /// Charge les véhicules selon le type d'utilisateur
  Future<void> _loadVehicles({bool showLoading = true}) async {
    try {
      if (showLoading) {
        setState(() {
          _isLoadingVehicles = true;
        });
      }

      final token = await SessionManager.getToken();
      final userData = await SessionManager.getUserData();

      if (token == null || userData == null) {
        setState(() {
          _isLoadingVehicles = false;
        });
        return;
      }

      final String userType = userData['type_utilisateur'] ?? '';

      if (userType == 'chauffeur') {
        // Chauffeur : récupérer son propre véhicule uniquement
        final response = await ApiService.getVehicle(token);

        if (response.success && response.data != null) {
          setState(() {
            if (response.data is Map<String, dynamic>) {
              _vehicles = [VehicleModel.fromJson(response.data)];
            } else if (response.data is List && response.data.isNotEmpty) {
              // Prendre seulement le premier véhicule (son véhicule)
              _vehicles = [VehicleModel.fromJson(response.data[0])];
            } else {
              _vehicles = [];
            }
            _isLoadingVehicles = false;
          });
          if (showLoading) {
            print('Véhicule du chauffeur chargé: ${_vehicles.length}');
          }
        } else {
          setState(() {
            _vehicles = [];
            _isLoadingVehicles = false;
          });
          if (showLoading) {
            print('Erreur chargement véhicule chauffeur: ${response.message}');
          }
        }
      } else {
        // Passager : récupérer tous les véhicules disponibles
        final response = await ApiService.getVehiclesList(token);

        if (response.success && response.data != null) {
          setState(() {
            List<VehicleModel> allVehicles = [];
            if (response.data is List) {
              allVehicles = (response.data as List)
                  .map((json) => VehicleModel.fromJson(json))
                  .toList();
            } else if (response.data is Map<String, dynamic>) {
              allVehicles = [VehicleModel.fromJson(response.data)];
            }

            // Appliquer le filtrage par type de véhicule si fourni
            if (widget.vehicleTypeFilter != null &&
                widget.vehicleTypeFilter!.isNotEmpty) {
              _vehicles = allVehicles
                  .where(
                    (vehicle) =>
                        vehicle.typeVehicule.toLowerCase() ==
                        widget.vehicleTypeFilter!.toLowerCase(),
                  )
                  .toList();
              print(
                'Véhicules filtrés par type "${widget.vehicleTypeFilter}": ${_vehicles.length}',
              );
            } else {
              _vehicles = allVehicles;
              print('Pas de filtrage - tous les véhicules affichés');
            }

            _isLoadingVehicles = false;
          });
          if (showLoading) {
            print('Véhicules pour passager chargés: ${_vehicles.length}');
          }
        } else {
          setState(() {
            _vehicles = [];
            _isLoadingVehicles = false;
          });
          if (showLoading) {
            print('Erreur chargement véhicules passager: ${response.message}');
          }
        }
      }
    } catch (e) {
      setState(() {
        _vehicles = [];
        _isLoadingVehicles = false;
      });
      if (showLoading) {
        print('Erreur lors du chargement des véhicules: $e');
      }
    }
  }

  /// Obtient l'icône du véhicule selon son type
  String _getVehicleIcon(String typeVehicule) {
    switch (typeVehicule.toLowerCase()) {
      case 'moto':
      case 'motocyclette':
        return 'assets/vehicules/moto.png';
      case 'voiture':
      case 'automobile':
        return 'assets/vehicules/voiture.png';
      case 'taxi':
        return 'assets/vehicules/taxi.png';
      case 'bus':
        return 'assets/vehicules/bus.png';
      case 'minibus':
        return 'assets/vehicules/minibus.png';
      case 'suv':
        return 'assets/vehicules/suv.png';
      case 'pickup':
        return 'assets/vehicules/pickup.png';
      case 'camion':
        return 'assets/vehicules/camion.png';
      default:
        return 'assets/vehicules/voiture.png'; // Par défaut
    }
  }

  /// Trouve le véhicule le plus proche de la position actuelle
  /// Retourne le véhicule le plus proche ou null si aucun véhicule n'est disponible
  VehicleModel? _findClosestVehicle() {
    if (_currentLocation == null || _vehicles.isEmpty) {
      return null;
    }

    VehicleModel? closestVehicle;
    double closestDistance = double.infinity;

    for (var vehicle in _vehicles) {
      final distance = _calculateDistanceBetweenPoints(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        vehicle.latitude,
        vehicle.longitude,
      );

      if (distance < closestDistance) {
        closestDistance = distance;
        closestVehicle = vehicle;
      }
    }

    print(
      'Véhicule le plus proche trouvé: ${closestVehicle?.marque} ${closestVehicle?.modele} (${closestDistance.toStringAsFixed(2)} km)',
    );
    return closestVehicle;
  }

  /// Calcule la distance entre deux coordonnées en kilomètres (formule Haversine)
  double _calculateDistanceBetweenPoints(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295;
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  /// Génère les markers des véhicules
  List<Marker> _buildVehicleMarkers() {
    return _vehicles.map((vehicle) {
      return Marker(
        point: LatLng(vehicle.latitude, vehicle.longitude),
        width: 50,
        height: 50,
        child: GestureDetector(
          onTap: () => _showVehicleDetails(vehicle),
          child: Image.asset(
            _getVehicleIcon(vehicle.typeVehicule),
            fit: BoxFit.contain,
          ),
        ),
      );
    }).toList();
  }

  /// Affiche les détails du véhicule
  void _showVehicleDetails(VehicleModel vehicle) {
    // Charger la tarification dès l'ouverture
    _loadPricing(vehicle);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Icône et titre
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.mainColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        _getVehicleIcon(vehicle.typeVehicule),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${vehicle.marque} ${vehicle.modele}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          vehicle.plaque,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Informations détaillées
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      'Type',
                      vehicle.typeVehicule,
                      Icons.directions_car,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Couleur',
                      vehicle.couleur,
                      Icons.palette,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      'Capacité',
                      '${vehicle.capacite} places',
                      Icons.people,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Confort',
                      vehicle.confort,
                      Icons.airline_seat_recline_normal,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Affichage de la tarification (si passager et si route calculée)
              FutureBuilder<Map<String, dynamic>?>(
                future: SessionManager.getUserData(),
                builder: (context, snapshot) {
                  if (snapshot.hasData &&
                      snapshot.data!['type_utilisateur'] == 'passager' &&
                      _routeDistance > 0) {
                    return Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.mainColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.mainColor.withOpacity(0.3),
                            ),
                          ),
                          child: _buildPricingSection(vehicle),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Bouton de contact (si passager)
              FutureBuilder<Map<String, dynamic>?>(
                future: SessionManager.getUserData(),
                builder: (context, snapshot) {
                  if (snapshot.hasData &&
                      snapshot.data!['type_utilisateur'] == 'passager') {
                    return SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.mainColor,
                              AppColors.mainColor.withValues(alpha: 0.85),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.mainColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            await _createRideRequest(vehicle);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 20),
                              const SizedBox(width: 10),
                              const Text(
                                'Demander une course',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.mainColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Créer une demande de course
  Future<void> _createRideRequest(VehicleModel vehicle) async {
    try {
      // Récupérer les données utilisateur
      final userData = await SessionManager.getUserData();
      final token = await SessionManager.getToken();

      if (userData == null || token == null) {
        _showErrorSnackBar('Erreur d\'authentification');
        return;
      }

      if (_currentLocation == null) {
        _showErrorSnackBar('Position actuelle non disponible');
        return;
      }

      if (_routeDistance == 0 || _routeDuration == 0) {
        _showErrorSnackBar('Route non calculée');
        return;
      }

      // Récupérer la tarification
      String vehicleKey = '${vehicle.id}';
      PricingModel? pricing = _vehiclePricing[vehicleKey];

      if (pricing == null) {
        _showErrorSnackBar('Tarification non disponible');
        return;
      }

      // Afficher un dialogue de confirmation
      bool? confirmed = await _showConfirmationDialog(vehicle, pricing);
      if (confirmed != true) return;

      // Créer la demande de course
      final response = await ApiService.createRide(
        token: token,
        passagerId: userData['id'] ?? 0,
        departLatitude: _currentLocation!.latitude,
        departLongitude: _currentLocation!.longitude,
        destinationLatitude: widget.destinationLatitude,
        destinationLongitude: widget.destinationLongitude,
        distance: _routeDistance,
        dureeEstimee: _routeDuration,
        prixEstime: pricing.prixCdf,
      );

      if (response.success) {
        _showSuccessSnackBar(response.message);
        print('Course créée avec succès: ${response.data}');

        // Naviguer vers la page de suivi de la course
        if (mounted) {
          // Récupérer l'ID de la course créée
          int? rideId;
          if (response.data is Map<String, dynamic>) {
            rideId = response.data['id'] ?? response.data['course_id'];
          } else if (response.data is int) {
            rideId = response.data as int;
          }

          if (rideId != null && mounted) {
            // Attendre 1 seconde avant de naviguer pour que le snackbar s'affiche
            await Future.delayed(const Duration(seconds: 1));
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => RideTrackingPage(rideId: rideId!),
                ),
              );
            }
          }
        }
      } else {
        _showErrorSnackBar('Erreur: ${response.message}');
      }
    } catch (e) {
      print('Erreur lors de la création de la course: $e');
      _showErrorSnackBar('Erreur lors de la demande de course');
    }
  }

  /// Afficher un dialogue de confirmation pour la course
  Future<bool?> _showConfirmationDialog(
    VehicleModel vehicle,
    PricingModel pricing,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la course'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Véhicule: ${vehicle.marque} ${vehicle.modele}'),
              Text('Type: ${vehicle.typeVehicule}'),
              Text('Confort: ${vehicle.confort}'),
              const SizedBox(height: 12),
              Text(
                'Distance: ${(_routeDistance / 1000).toStringAsFixed(1)} km',
              ),
              Text('Durée: ${(_routeDuration / 60).toStringAsFixed(0)} min'),
              const SizedBox(height: 12),
              Text(
                'Prix: ${pricing.prixCdf.toStringAsFixed(0)} CDF (≈ \$${pricing.prixUsd.toStringAsFixed(2)})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );
  }

  /// Afficher un message d'erreur
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  /// Afficher un message de succès
  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // Méthodes pour la tarification
  Future<void> _loadPricing(VehicleModel vehicle) async {
    // Convertir les valeurs en unités correctes
    double distanceKm = _routeDistance / 1000; // Convertir mètres en km
    double dureeMin = _routeDuration / 60; // Convertir secondes en minutes

    if (_routeDistance == 0 || _routeDuration == 0) {
      print('Route non calculée, tarification impossible');
      return;
    }

    String vehicleKey = '${vehicle.id}';
    setState(() {
      _loadingPricing[vehicleKey] = true;
    });
    final token = await SessionManager.getToken();
    print('Token utilisateur: $token');
    try {
      // Récupérer le token utilisateur

      if (token == null) {
        throw Exception('Token utilisateur non disponible');
      }

      print('Tarification pour véhicule ${vehicle.id}:');
      print('  Type: ${vehicle.typeVehicule}');
      print('  Confort: ${vehicle.confort}');
      print('  Distance: ${distanceKm.toStringAsFixed(1)} km');
      print('  Durée: ${dureeMin.toStringAsFixed(1)} min');

      final response = await ApiService.calculatePricing(
        token: token,
        typeVehicule: vehicle.typeVehicule,
        confort: vehicle.confort,
        distanceKm: distanceKm,
        dureeMin: dureeMin,
      );

      print("RESPONSE SUCCESS: ${response.success}");
      print("RESPONSE MESSAGE: ${response.message}");
      print("RESPONSE DATA: ${response.data}");

      if (response.success && response.data != null) {
        try {
          final pricing = PricingModel.fromJson(response.data);
          setState(() {
            _vehiclePricing[vehicleKey] = pricing;
            _loadingPricing[vehicleKey] = false;
          });
          print(
            'Tarification calculée: ${pricing.prixCdf} CDF / ${pricing.prixUsd} USD',
          );
        } catch (e) {
          print('Erreur parsing PricingModel: $e');
          print('Data reçue: ${response.data}');
          setState(() {
            _vehiclePricing[vehicleKey] = null;
            _loadingPricing[vehicleKey] = false;
          });
        }
      } else {
        print('Erreur API tarification: ${response.message}');
        setState(() {
          _vehiclePricing[vehicleKey] = null;
          _loadingPricing[vehicleKey] = false;
        });
      }
    } catch (e) {
      print('Erreur calcul tarification: $e');
      print("EEEEEEEEE EEEE=====> ${e.toString()}");
      setState(() {
        _vehiclePricing[vehicleKey] = null;
        _loadingPricing[vehicleKey] = false;
      });
    }
  }

  Widget _buildPricingSection(VehicleModel vehicle) {
    String vehicleKey = '${vehicle.id}';
    bool isLoading = _loadingPricing[vehicleKey] ?? false;
    PricingModel? pricing = _vehiclePricing[vehicleKey];

    if (isLoading) {
      return const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text(
            'Calcul du prix...',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      );
    }

    if (pricing == null) {
      return Row(
        children: [
          Icon(Icons.error_outline, color: Colors.orange, size: 16),
          const SizedBox(width: 8),
          Text(
            'Prix non disponible',
            style: TextStyle(color: Colors.orange, fontSize: 14),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.monetization_on, color: AppColors.mainColor, size: 16),
            const SizedBox(width: 8),
            Text(
              'Tarification estimée',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.mainColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prix en CDF',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  '${pricing.prixCdf.toStringAsFixed(0)} CDF',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Prix en USD',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  '\$${pricing.prixUsd.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[600], size: 12),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Basé sur ${_routeDistance.toStringAsFixed(1)}km - ${(_routeDuration / 60).toStringAsFixed(0)}min',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _adjustMapView() {
    if (_currentLocation != null) {
      // Utiliser les coordonnées corrigées
      double lat =
          widget.destinationLatitude == 0.0 &&
              widget.destinationLongitude == 0.0
          ? 5.3600
          : widget.destinationLatitude;
      double lng =
          widget.destinationLatitude == 0.0 &&
              widget.destinationLongitude == 0.0
          ? -4.0083
          : widget.destinationLongitude;

      final destination = LatLng(lat, lng);

      // Calculer le centre entre les deux points
      LatLng center = LatLng(
        (_currentLocation!.latitude + destination.latitude) / 2,
        (_currentLocation!.longitude + destination.longitude) / 2,
      );

      print(
        'Ajustement carte - Centre: Lat=${center.latitude}, Lng=${center.longitude}',
      );

      // Calculer le zoom approprié selon la distance
      double distance = Geolocator.distanceBetween(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        destination.latitude,
        destination.longitude,
      );

      // Ajuster le zoom selon la distance (plus la distance est grande, plus le zoom est faible)
      double zoom = 15.0;
      if (distance > 10000) {
        zoom = 10.0;
      } else if (distance > 5000) {
        zoom = 12.0;
      } else if (distance > 1000) {
        zoom = 14.0;
      }

      print('Distance calculée: ${distance}m, Zoom: $zoom');
      setState(() {
        _currentZoom = zoom;
      });
      _mapController.move(center, zoom);
    }
  }

  double _calculateDistance() {
    // Utiliser la distance OSRM si disponible (plus précise)
    if (_routeDistance > 0) {
      return _routeDistance;
    }

    // Fallback vers le calcul à vol d'oiseau
    if (_currentLocation == null) return 0;

    // Utiliser les coordonnées corrigées
    double lat =
        widget.destinationLatitude == 0.0 && widget.destinationLongitude == 0.0
        ? 5.3600
        : widget.destinationLatitude;
    double lng =
        widget.destinationLatitude == 0.0 && widget.destinationLongitude == 0.0
        ? -4.0083
        : widget.destinationLongitude;

    return Geolocator.distanceBetween(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      lat,
      lng,
    );
  }

  String _formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.round()} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
  }

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.round());
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}min';
    } else {
      return '${duration.inMinutes}min';
    }
  }

  /// Décode un polyline encodé en une liste de points LatLng
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  /// Calcule la route entre la position actuelle et la destination avec OSRM
  Future<void> _calculateRouteWithOSRM() async {
    if (_currentLocation == null) return;

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      // Utiliser les coordonnées corrigées
      double lat =
          widget.destinationLatitude == 0.0 &&
              widget.destinationLongitude == 0.0
          ? 5.3600
          : widget.destinationLatitude;
      double lng =
          widget.destinationLatitude == 0.0 &&
              widget.destinationLongitude == 0.0
          ? -4.0083
          : widget.destinationLongitude;

      final String url =
          'http://router.project-osrm.org/route/v1/driving/'
          '${_currentLocation!.longitude},${_currentLocation!.latitude};'
          '$lng,$lat'
          '?overview=full&alternatives=true&geometries=polyline&steps=true';

      print('Calling OSRM API: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];

          setState(() {
            _routeDistance = (route['distance'] ?? 0).toDouble();
            _routeDuration = (route['duration'] ?? 0).toDouble();
            _routeSummary = route['summary'] ?? '';

            // Décoder le polyline
            final geometry = route['geometry'] ?? '';
            _routePoints = _decodePolyline(geometry);

            _isLoadingRoute = false;
          });

          print('Route calculée: ${_routeDistance}m, ${_routeDuration}s');
          print('Points de route: ${_routePoints.length}');

          // Trouver et afficher le véhicule le plus proche si un filtre de type est appliqué
          // ou afficher automatiquement le plus proche après le calcul de la route
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted && !_closestVehicleShown && _vehicles.isNotEmpty) {
            final closestVehicle = _findClosestVehicle();
            if (closestVehicle != null) {
              setState(() {
                _closestVehicleShown = true;
              });
              // Afficher les détails du véhicule le plus proche automatiquement
              if (mounted) {
                _showVehicleDetails(closestVehicle);
              }
            }
          }
        } else {
          setState(() {
            _isLoadingRoute = false;
          });
          print('Aucune route trouvée');
        }
      } else {
        setState(() {
          _isLoadingRoute = false;
        });
        print('Erreur OSRM: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoadingRoute = false;
      });
      print('Erreur lors du calcul de la route: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Vérifier si les coordonnées sont valides, sinon utiliser Abidjan comme défaut
    double lat = widget.destinationLatitude;
    double lng = widget.destinationLongitude;

    if (lat == 0.0 && lng == 0.0) {
      // Coordonnées par défaut : Abidjan, Côte d'Ivoire
      lat = 5.3600;
      lng = -4.0083;
      print('ATTENTION: Utilisation des coordonnées par défaut (Abidjan)');
    }

    final destination = LatLng(lat, lng);

    print(
      'Build - Position de destination: Lat=${destination.latitude}, Lng=${destination.longitude}',
    );
    if (_currentLocation != null) {
      print(
        'Build - Position actuelle: Lat=${_currentLocation!.latitude}, Lng=${_currentLocation!.longitude}',
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: AppColors.mainColor,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2)),
                child: const Icon(
                  Icons.navigation,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.destinationTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'Navigation GPS',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Carte FlutterMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: destination,
              initialZoom: _currentZoom,
              onMapEvent: (mapEvent) {
                if (mapEvent is MapEventMove) {
                  setState(() {
                    _currentZoom = mapEvent.camera.zoom;
                  });
                }
              },
            ),
            children: [
              // Couche de tuiles OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.bita_express_new',
                maxZoom: 19,
              ),

              // Ligne de route OSRM ou ligne droite vers la destination
              if (_currentLocation != null)
                PolylineLayer(
                  polylines: [
                    // Route OSRM si disponible (plus fluide et précise)
                    if (_routePoints.isNotEmpty)
                      Polyline(
                        points: _routePoints,
                        color: AppColors.mainColor,
                        strokeWidth: 4.0,
                      )
                    else
                      // Fallback vers une ligne droite
                      Polyline(
                        points: [_currentLocation!, destination],
                        color: AppColors.mainColor.withOpacity(0.6),
                        strokeWidth: 3.0,
                      ),
                  ],
                ),

              // Marqueurs
              MarkerLayer(
                markers: [
                  // Marqueur de destination (toujours visible)
                  Marker(
                    point: destination,
                    width: 50,
                    height: 50,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.mainColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.flag,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),

                  // Marqueurs des véhicules
                  ..._buildVehicleMarkers(),
                ],
              ),
            ],
          ),

          // Panneau d'informations en haut
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.mainColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.navigation,
                          color: AppColors.mainColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.destinationTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              widget.destinationSubtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (_isLoadingLocation)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Localisation en cours...'),
                        ],
                      ),
                    )
                  else if (_locationError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red[400], size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _locationError!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_currentLocation != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.straighten,
                                color: Colors.grey[600],
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Distance: ${_formatDistance(_calculateDistance())}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              // Afficher la durée si la route OSRM est disponible
                              if (_routeDuration > 0) ...[
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.access_time,
                                  color: Colors.grey[600],
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDuration(_routeDuration),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          // Afficher le résumé de la route si disponible
                          if (_routeSummary.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.route,
                                    color: Colors.grey[600],
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _routeSummary,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Indicateur de chargement de la route
                          if (_isLoadingRoute)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: AppColors.mainColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Calcul de l\'itinéraire...',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
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
          ),

          // Boutons d'action en bas
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Boutons de zoom à gauche
                    Column(
                      children: [
                        // Indicateur de zoom
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'x${_currentZoom.toStringAsFixed(1)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        // Bouton Zoom In
                        Container(
                          width: 48,
                          height: 48,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: _currentZoom >= 18
                                ? Colors.grey[300]
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: _currentZoom >= 18
                                ? null
                                : () {
                                    setState(() {
                                      _currentZoom = (_currentZoom + 1).clamp(
                                        1.0,
                                        18.0,
                                      );
                                    });
                                    _mapController.move(
                                      _mapController.camera.center,
                                      _currentZoom,
                                    );
                                  },
                            icon: Icon(
                              Icons.add,
                              color: _currentZoom >= 18
                                  ? Colors.grey[500]
                                  : Colors.black87,
                              size: 20,
                            ),
                          ),
                        ),
                        // Bouton Zoom Out
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _currentZoom <= 1
                                ? Colors.grey[300]
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: _currentZoom <= 1
                                ? null
                                : () {
                                    setState(() {
                                      _currentZoom = (_currentZoom - 1).clamp(
                                        1.0,
                                        18.0,
                                      );
                                    });
                                    _mapController.move(
                                      _mapController.camera.center,
                                      _currentZoom,
                                    );
                                  },
                            icon: Icon(
                              Icons.remove,
                              color: _currentZoom <= 1
                                  ? Colors.grey[500]
                                  : Colors.black87,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Bouton pour recentrer à droite
                    if (_currentLocation != null)
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: _adjustMapView,
                          icon: Icon(
                            Icons.center_focus_strong,
                            color: AppColors.mainColor,
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Statut et contrôles des véhicules
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: FutureBuilder<Map<String, dynamic>?>(
                    future: SessionManager.getUserData(),
                    builder: (context, snapshot) {
                      final bool isChauffeur =
                          snapshot.hasData &&
                          snapshot.data!['type_utilisateur'] == 'chauffeur';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.directions_car,
                                color: AppColors.mainColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isChauffeur
                                    ? 'Mon véhicule'
                                    : 'Véhicules disponibles',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const Spacer(),
                              if (_isLoadingVehicles)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                Row(
                                  children: [
                                    // Indicateur de rafraîchissement automatique
                                    if (_isAutoRefreshing)
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.autorenew,
                                          color: Colors.green,
                                          size: 12,
                                        ),
                                      ),
                                    if (_isAutoRefreshing)
                                      const SizedBox(width: 4),

                                    // Bouton de rafraîchissement manuel
                                    GestureDetector(
                                      onTap: () => _loadVehicles(),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.mainColor
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.refresh,
                                          color: AppColors.mainColor,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isLoadingVehicles
                                ? 'Chargement...'
                                : isChauffeur
                                ? _vehicles.isEmpty
                                      ? 'Aucun véhicule enregistré'
                                      : _isAutoRefreshing
                                      ? 'Véhicule synchronisé (auto)'
                                      : 'Véhicule affiché sur la carte'
                                : _isAutoRefreshing
                                ? '${_vehicles.length} véhicule(s) synchronisé(s)'
                                : '${_vehicles.length} véhicule(s) disponible(s)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Bouton de navigation principal
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Ici on pourrait intégrer avec Google Maps, Apple Maps, etc.
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Fonction de navigation à implémenter',
                          ),
                          backgroundColor: AppColors.mainColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.navigation, size: 20),
                    label: const Text(
                      'Démarrer la navigation',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
