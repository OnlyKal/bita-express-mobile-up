import 'package:flutter/material.dart';
import '../api.dart';
import '../colors.dart';
import '../models/vehicle_type.dart';
import '../navigation_map.dart';
import '../session.dart';

class VehicleTypeSelectionPage extends StatefulWidget {
  final double departLatitude;
  final double departLongitude;
  final double destinationLatitude;
  final double destinationLongitude;
  final String destinationTitle;
  final String destinationSubtitle;
  final double distanceMeters; // Distance en mètres
  final double durationSeconds; // Durée en secondes

  const VehicleTypeSelectionPage({
    super.key,
    required this.departLatitude,
    required this.departLongitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.destinationTitle,
    required this.destinationSubtitle,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  @override
  State<VehicleTypeSelectionPage> createState() =>
      _VehicleTypeSelectionPageState();
}

class _VehicleTypeSelectionPageState extends State<VehicleTypeSelectionPage> {
  // Types de véhicules prédéfinis
  final List<VehicleType> _vehicleTypes = [
    VehicleType(
      id: 'moto',
      name: 'motocyclette',
      label: 'Moto',
      icon: Icons.two_wheeler,
      color: Colors.orange,
      minCapacity: 1,
      description: 'Rapide et économique',
    ),
    VehicleType(
      id: 'voiture',
      name: 'automobile',
      label: 'Voiture',
      icon: Icons.directions_car,
      color: Colors.blue,
      minCapacity: 4,
      description: 'Confortable pour vous et vos proches',
    ),
    VehicleType(
      id: 'taxi',
      name: 'taxi',
      label: 'Taxi',
      icon: Icons.local_taxi,
      color: Colors.yellow,
      minCapacity: 4,
      description: 'Professionnel et fiable',
    ),
    VehicleType(
      id: 'bus',
      name: 'bus',
      label: 'Bus',
      icon: Icons.directions_bus,
      color: Colors.green,
      minCapacity: 20,
      description: 'Pour les groupes',
    ),
  ];

  late Map<String, PricingModel?> _pricingByType;
  late Map<String, bool> _loadingByType;
  String? _selectedTypeId;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _pricingByType = {};
    _loadingByType = {};
    _initializeAndLoadPrices();
  }

  Future<void> _initializeAndLoadPrices() async {
    try {
      // Convertir distances et durées aux bonnes unités
      double distanceKm = widget.distanceMeters / 1000;
      double durationMin = widget.durationSeconds / 60;

      print('=== SÉLECTION TYPES DE VÉHICULES ===');
      print('Distance: ${distanceKm.toStringAsFixed(2)} km');
      print('Durée: ${durationMin.toStringAsFixed(2)} min');

      final token = await SessionManager.getToken();
      if (token == null) {
        _showError('Token non disponible');
        return;
      }

      // Charger la tarification pour chaque type
      for (var vehicleType in _vehicleTypes) {
        await _loadPricingForType(vehicleType, distanceKm, durationMin, token);
      }

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      print('Erreur initialisation: $e');
      _showError('Erreur lors du chargement des tarifs');
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _loadPricingForType(
    VehicleType vehicleType,
    double distanceKm,
    double durationMin,
    String token,
  ) async {
    try {
      setState(() {
        _loadingByType[vehicleType.id] = true;
      });

      print('Chargement tarif pour: ${vehicleType.name}');

      final response = await ApiService.calculatePricing(
        token: token,
        typeVehicule: vehicleType.name,
        confort: 'standard', // Confort par défaut
        distanceKm: distanceKm,
        dureeMin: durationMin,
      );

      if (response.success && response.data != null) {
        final pricing = PricingModel.fromJson(response.data);
        setState(() {
          _pricingByType[vehicleType.id] = pricing;
          _loadingByType[vehicleType.id] = false;
        });
        print('Tarif ${vehicleType.name}: ${pricing.prixCdf} CDF');
      } else {
        setState(() {
          _pricingByType[vehicleType.id] = null;
          _loadingByType[vehicleType.id] = false;
        });
        print('Erreur tarification ${vehicleType.name}: ${response.message}');
      }
    } catch (e) {
      print('Exception tarification ${vehicleType.name}: $e');
      setState(() {
        _pricingByType[vehicleType.id] = null;
        _loadingByType[vehicleType.id] = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _selectVehicleType(String typeId) {
    setState(() {
      _selectedTypeId = typeId;
    });

    // Petite animation avant navigation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NavigationMapPage(
              destinationLatitude: widget.destinationLatitude,
              destinationLongitude: widget.destinationLongitude,
              destinationTitle: widget.destinationTitle,
              destinationSubtitle: widget.destinationSubtitle,
              vehicleTypeFilter: typeId,
              departLatitude: widget.departLatitude,
              departLongitude: widget.departLongitude,
              distanceMeters: widget.distanceMeters,
              durationSeconds: widget.durationSeconds,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.mainColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: const Text(
          'Choisir un véhicule',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isInitializing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des tarifs...'),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Destination info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: AppColors.mainColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.destinationTitle,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      widget.destinationSubtitle,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.straighten,
                                color: Colors.grey[600],
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Distance: ${(widget.distanceMeters / 1000).toStringAsFixed(1)} km',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.access_time,
                                color: Colors.grey[600],
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(widget.durationSeconds / 60).toStringAsFixed(0)} min',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Titre section
                    Text(
                      'Types de véhicules disponibles',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Grille des types de véhicules
                    ..._vehicleTypes.map((vehicleType) {
                      final pricing = _pricingByType[vehicleType.id];
                      final isLoading = _loadingByType[vehicleType.id] ?? false;
                      final isSelected = _selectedTypeId == vehicleType.id;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildVehicleTypeCard(
                          vehicleType: vehicleType,
                          pricing: pricing,
                          isLoading: isLoading,
                          isSelected: isSelected,
                          onTap: () => _selectVehicleType(vehicleType.id),
                        ),
                      );
                    }),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildVehicleTypeCard({
    required VehicleType vehicleType,
    required PricingModel? pricing,
    required bool isLoading,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? vehicleType.color.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? vehicleType.color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: vehicleType.color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Icône du type
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: vehicleType.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(vehicleType.icon, color: vehicleType.color, size: 32),
            ),

            const SizedBox(width: 16),

            // Infos du type
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicleType.label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vehicleType.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Capacité: ${vehicleType.minCapacity} places',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),

            // Prix
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (pricing != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${pricing.prixCdf.toStringAsFixed(0)} CDF',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '\$${pricing.prixUsd.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  )
                else
                  Text(
                    'N/A',
                    style: TextStyle(fontSize: 14, color: Colors.red[400]),
                  ),
              ],
            ),

            const SizedBox(width: 12),

            // Checkmark si sélectionné
            if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: vehicleType.color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}
