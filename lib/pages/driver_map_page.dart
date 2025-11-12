import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../colors.dart';
import '../api.dart';
import '../session.dart';
import 'available_rides_page.dart';
import 'driver_rides_page.dart';

class DriverMapPage extends StatefulWidget {
  const DriverMapPage({super.key});

  @override
  State<DriverMapPage> createState() => _DriverMapPageState();
}

class _DriverMapPageState extends State<DriverMapPage> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  bool _isLoadingLocation = true;
  String? _locationError;
  double _currentZoom = 14.0;
  VehicleModel? _driverVehicle;
  bool _isLoadingVehicle = true;

  // Timer pour le rafraîchissement automatique du véhicule
  Timer? _vehicleRefreshTimer;
  bool _isAutoRefreshing = false;

  @override
  void initState() {
    super.initState();
    print('DriverMapPage - Initialisation de la carte chauffeur');
    _getCurrentLocation();
    _loadDriverVehicle();
    _startVehicleRefreshTimer();
  }

  /// Démarre le timer de rafraîchissement automatique du véhicule
  void _startVehicleRefreshTimer() {
    setState(() {
      _isAutoRefreshing = true;
    });

    _vehicleRefreshTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (mounted) {
        _loadDriverVehicle(showLoading: false);
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

      // Centrer la carte sur la position actuelle
      _mapController.move(_currentLocation!, _currentZoom);
    } catch (e) {
      setState(() {
        _locationError = 'Erreur lors de l\'obtention de la position: $e';
        _isLoadingLocation = false;
      });
      print('Erreur géolocalisation: $e');
    }
  }

  /// Charge le véhicule du chauffeur
  Future<void> _loadDriverVehicle({bool showLoading = true}) async {
    try {
      if (showLoading) {
        setState(() {
          _isLoadingVehicle = true;
        });
      }

      final token = await SessionManager.getToken();

      if (token == null) {
        setState(() {
          _isLoadingVehicle = false;
        });
        return;
      }

      final response = await ApiService.getVehicle(token);

      if (response.success && response.data != null) {
        setState(() {
          if (response.data is Map<String, dynamic>) {
            _driverVehicle = VehicleModel.fromJson(response.data);
          } else if (response.data is List && response.data.isNotEmpty) {
            _driverVehicle = VehicleModel.fromJson(response.data[0]);
          }
          _isLoadingVehicle = false;
        });
        if (showLoading) {
          print(
            'Véhicule du chauffeur chargé: ${_driverVehicle?.marque} ${_driverVehicle?.modele}',
          );
        }
      } else {
        setState(() {
          _driverVehicle = null;
          _isLoadingVehicle = false;
        });
        if (showLoading) {
          print('Erreur chargement véhicule chauffeur: ${response.message}');
        }
      }
    } catch (e) {
      setState(() {
        _driverVehicle = null;
        _isLoadingVehicle = false;
      });
      if (showLoading) {
        print('Erreur lors du chargement du véhicule: $e');
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
        return 'assets/vehicules/voiture.png';
    }
  }

  /// Génère le marker du véhicule du chauffeur
  List<Marker> _buildVehicleMarkers() {
    if (_driverVehicle == null) return [];

    return [
      Marker(
        point: LatLng(_driverVehicle!.latitude, _driverVehicle!.longitude),
        width: 50,
        height: 50,
        child: GestureDetector(
          onTap: () => _showVehicleDetails(),
          child: Image.asset(
            _getVehicleIcon(_driverVehicle!.typeVehicule),
            fit: BoxFit.contain,
          ),
        ),
      ),
    ];
  }

  /// Affiche les détails du véhicule du chauffeur
  void _showVehicleDetails() {
    if (_driverVehicle == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                      _getVehicleIcon(_driverVehicle!.typeVehicule),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mon véhicule',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_driverVehicle!.marque} ${_driverVehicle!.modele}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                    'Plaque',
                    _driverVehicle!.plaque,
                    Icons.confirmation_number,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Type',
                    _driverVehicle!.typeVehicule,
                    Icons.directions_car,
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
                    '${_driverVehicle!.capacite} places',
                    Icons.people,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Confort',
                    _driverVehicle!.confort,
                    Icons.airline_seat_recline_normal,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
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

  @override
  Widget build(BuildContext context) {
    // Position par défaut si pas de géolocalisation
    final center =
        _currentLocation ?? const LatLng(5.3600, -4.0083); // Abidjan par défaut

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
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                ),
                child: const Icon(Icons.local_taxi, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Mode Chauffeur',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Carte interactive',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AvailableRidesPage(),
                  ),
                );
              },
              icon: const Icon(Icons.assignment, color: Colors.white),
              tooltip: 'Courses disponibles',
            ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DriverRidesPage(),
                ),
              );
            },
            icon: const Icon(Icons.list_alt, color: Colors.white),
            tooltip: 'Mes courses',
          ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Carte FlutterMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
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

              // Marqueurs
              MarkerLayer(
                markers: [
                  // Marqueur du véhicule du chauffeur
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
                          Icons.local_taxi,
                          color: AppColors.mainColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mode Chauffeur Actif',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Vous êtes en ligne et visible par les passagers',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
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
                    ),
                ],
              ),
            ),
          ),

          // Contrôles en bas
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Statut du véhicule
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
                  child: Column(
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
                          const Text(
                            'Mon véhicule',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          if (_isLoadingVehicle)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            GestureDetector(
                              onTap: _loadDriverVehicle,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.mainColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
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
                      const SizedBox(height: 8),
                      Text(
                        _isLoadingVehicle
                            ? 'Chargement...'
                            : _driverVehicle == null
                            ? 'Aucun véhicule enregistré'
                            : '${_driverVehicle!.marque} ${_driverVehicle!.modele} - ${_driverVehicle!.plaque}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Bouton de repositionnement
                if (_currentLocation != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _mapController.move(_currentLocation!, _currentZoom);
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
                      icon: const Icon(Icons.my_location, size: 20),
                      label: const Text(
                        'Centrer sur ma position',
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
