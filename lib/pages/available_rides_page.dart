import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../api.dart';
import '../session.dart';
import '../colors.dart';

class AvailableRidesPage extends StatefulWidget {
  const AvailableRidesPage({Key? key}) : super(key: key);

  @override
  State<AvailableRidesPage> createState() => _AvailableRidesPageState();
}

class _AvailableRidesPageState extends State<AvailableRidesPage> {
  final MapController _mapController = MapController();
  List<RideModel> _availableRides = [];
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;
  RideModel? _selectedRide;

  // Position par défaut (Kinshasa)
  static const LatLng _defaultCenter = LatLng(-4.4419, 15.2663);

  @override
  void initState() {
    super.initState();
    _loadAvailableRides();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadAvailableRides();
    });
  }

  Future<void> _loadAvailableRides() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        setState(() {
          _error = 'Token non trouvé';
          _isLoading = false;
        });
        return;
      }

      final response = await ApiService.getAvailableRides(token);

      if (response.success && response.data != null) {
        final List<dynamic> ridesData = response.data is List
            ? response.data
            : response.data['courses'] ?? response.data['data'] ?? [];

        setState(() {
          _availableRides = ridesData
              .map((ride) => RideModel.fromJson(ride))
              .where(
                (ride) => ride.isWaiting,
              ) // Filtrer uniquement les courses en attente
              .toList();
          _isLoading = false;
          _error = null;
        });

        print('${_availableRides.length} courses disponibles chargées');
      } else {
        setState(() {
          _error = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur de chargement: $e';
        _isLoading = false;
      });
      print('Erreur lors du chargement des courses disponibles: $e');
    }
  }

  Future<void> _acceptRide(RideModel ride) async {
    print('Tentative d\'acceptation de la course ${ride.id}');

    try {
      // Récupérer les données du chauffeur connecté
      Map<String, dynamic>? userData = await SessionManager.getUserData();
      final token = await SessionManager.getToken();

      if (userData == null || token == null) {
        throw Exception('Données du chauffeur ou token non disponibles');
      }

      print('Données utilisateur: $userData');

      // Récupérer les données du véhicule via l'API
      final vehicleResponse = await ApiService.getVehicle(token);
      if (!vehicleResponse.success || vehicleResponse.data == null) {
        throw Exception('Impossible de récupérer les données du véhicule');
      }

      final vehicleData = vehicleResponse.data;
      print('Données véhicule API: $vehicleData');

      // Le véhicule est dans une liste, prendre le premier
      Map<String, dynamic> vehicleInfo;
      if (vehicleData is List && vehicleData.isNotEmpty) {
        vehicleInfo = vehicleData[0];
      } else {
        throw Exception('Aucun véhicule trouvé pour ce chauffeur');
      }

      // Conversion en entiers avec debugging
      dynamic chauffeurIdRaw = userData['id'];
      dynamic vehiculeIdRaw = vehicleInfo['id'];

      print(
        'Chauffeur ID brut: $chauffeurIdRaw (type: ${chauffeurIdRaw.runtimeType})',
      );
      print(
        'Véhicule ID brut: $vehiculeIdRaw (type: ${vehiculeIdRaw.runtimeType})',
      );

      int chauffeurIdInt = int.parse(chauffeurIdRaw.toString());
      int vehiculeIdInt = int.parse(vehiculeIdRaw.toString());

      print(
        'Chauffeur ID converti: $chauffeurIdInt (type: ${chauffeurIdInt.runtimeType})',
      );
      print(
        'Véhicule ID converti: $vehiculeIdInt (type: ${vehiculeIdInt.runtimeType})',
      );

      final response = await ApiService.acceptRide(
        token: token,
        rideId: ride.id,
        chauffeurId: chauffeurIdInt,
        vehiculeId: vehiculeIdInt,
      );

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course acceptée avec succès'),
            backgroundColor: Colors.green,
          ),
        );

        // Rafraîchir la liste des courses disponibles
        _loadAvailableRides();
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      print('Erreur lors de l\'acceptation de la course: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'acceptation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  List<Marker> _buildRideMarkers() {
    return _availableRides.map((ride) {
      final isSelected = _selectedRide?.id == ride.id;

      return Marker(
        point: LatLng(ride.departLatitude, ride.departLongitude),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedRide = isSelected ? null : ride;
            });
          },
          child: Container(
            width: isSelected ? 50 : 40,
            height: isSelected ? 50 : 40,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.secondary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.location_on,
              color: Colors.white,
              size: isSelected ? 30 : 24,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildRideInfoCard() {
    if (_selectedRide == null) return const SizedBox.shrink();

    final ride = _selectedRide!;

    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ride.passagerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'En attente',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Icon(
                    Icons.monetization_on,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${ride.prixEstime} FC',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.straighten,
                          color: AppColors.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(ride.distance / 1000).toStringAsFixed(1)} km',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: AppColors.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(ride.dureeEstimee / 60).toStringAsFixed(0)} min',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _acceptRide(ride),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Accepter la course',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                child: const Icon(Icons.assignment, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Courses disponibles',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Demandes en attente',
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
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadAvailableRides,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_availableRides.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAvailableRides,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _availableRides.isNotEmpty
                        ? LatLng(
                            _availableRides.first.departLatitude,
                            _availableRides.first.departLongitude,
                          )
                        : _defaultCenter,
                    initialZoom: 12.0,
                    minZoom: 10.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.bita_express_mobile',
                    ),
                    MarkerLayer(markers: _buildRideMarkers()),
                  ],
                ),
                _buildRideInfoCard(),
                if (_availableRides.isEmpty && !_isLoading)
                  Center(
                    child: Card(
                      margin: const EdgeInsets.all(32),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune course disponible',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Les nouvelles demandes de course apparaîtront ici automatiquement.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
