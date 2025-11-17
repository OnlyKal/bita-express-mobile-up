import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../api.dart';
import '../colors.dart';
import '../session.dart';
import '../services/vehicle_location_service.dart';
import '../widgets/location_tracking_indicator.dart';

class VehiclePage extends StatefulWidget {
  const VehiclePage({super.key});

  @override
  State<VehiclePage> createState() => _VehiclePageState();
}

class _VehiclePageState extends State<VehiclePage> {
  VehicleModel? _currentVehicle;
  bool _loading = true;
  bool _hasVehicle = false;

  @override
  void initState() {
    super.initState();
    _loadVehicle();
  }

  Future<void> _loadVehicle() async {
    setState(() {
      _loading = true;
    });

    try {
      final token = await SessionManager.getToken();
      if (token == null) throw Exception('Token non trouvé');

      final response = await ApiService.getVehicle(token);

      if (response.success && response.data != null) {
        final vehicleData = response.data;
        if (vehicleData is List && vehicleData.isNotEmpty) {
          setState(() {
            _currentVehicle = VehicleModel.fromJson(vehicleData[0]);
            _hasVehicle = true;
          });
        } else {
          setState(() {
            _hasVehicle = false;
            _currentVehicle = null;
          });
        }
      } else {
        setState(() {
          _hasVehicle = false;
          _currentVehicle = null;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement du véhicule: $e');
      setState(() {
        _hasVehicle = false;
        _currentVehicle = null;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _navigateToAddVehicle() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddVehiclePage()),
    );

    if (result == true) {
      _loadVehicle(); // Recharger le véhicule après ajout
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
                  Icons.directions_car,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Mon véhicule',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Gestion et suivi',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: LocationTrackingIndicator(),
            ),
          ],
        ),
      ),
      body: _loading
          ? _buildLoadingState()
          : _hasVehicle && _currentVehicle != null
          ? _buildVehicleInfo()
          : _buildNoVehicle(),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[50]),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.mainColor,
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chargement de votre véhicule...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleInfo() {
    final vehicle = _currentVehicle!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte principale du véhicule - Design réduit
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Badge de statut moderne
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Véhicule actif',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Image/Icône du véhicule moderne (réduite)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.mainColor.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    vehicle.typeVehicule == 'voiture'
                        ? Icons.directions_car_rounded
                        : Icons.motorcycle,
                    size: 40,
                    color: AppColors.mainColor,
                  ),
                ),

                const SizedBox(height: 16),

                // Marque et modèle - Typography réduite
                Text(
                  '${vehicle.marque} ${vehicle.modele}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Plaque d'immatriculation - Design réduit
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    vehicle.plaque,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Section des caractéristiques - Design moderne
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.mainColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.mainColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Caractéristiques',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Column(
                  children: [
                    _buildModernInfoCard(
                      'Couleur',
                      vehicle.couleur,
                      Icons.palette,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildModernInfoCard(
                      'Type',
                      vehicle.typeVehicule,
                      Icons.category,
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildModernInfoCard(
                      'Confort',
                      vehicle.confort,
                      Icons.star,
                      Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _buildModernInfoCard(
                      'Capacité',
                      '${vehicle.capacite} places',
                      Icons.people,
                      Colors.purple,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Section suivi de localisation - Design moderne
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: VehicleLocationService.isRunning
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: VehicleLocationService.isRunning
                            ? Colors.green
                            : Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Localisation en temps réel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Statut de la localisation
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: VehicleLocationService.isRunning
                        ? Colors.green.withOpacity(0.05)
                        : Colors.orange.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: VehicleLocationService.isRunning
                          ? Colors.green.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: VehicleLocationService.isRunning
                              ? Colors.green
                              : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              VehicleLocationService.isRunning
                                  ? 'Suivi activé'
                                  : 'Suivi désactivé',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: VehicleLocationService.isRunning
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              VehicleLocationService.isRunning
                                  ? 'Votre position est partagée en temps réel'
                                  : 'Activez le suivi pour recevoir des commandes',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
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

          const SizedBox(height: 28),

          // Section actions - Design moderne
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: VehicleLocationService.isRunning
                      ? 'Arrêter le suivi'
                      : 'Démarrer le suivi',
                  icon: VehicleLocationService.isRunning
                      ? Icons.pause_circle
                      : Icons.play_circle,
                  color: VehicleLocationService.isRunning
                      ? Colors.red
                      : Colors.green,
                  onTap: () async {
                    if (VehicleLocationService.isRunning) {
                      VehicleLocationService.stopLocationTracking();
                      _showSnackBar('Suivi de localisation arrêté', Colors.red);
                    } else {
                      await VehicleLocationService.startLocationTracking();
                      _showSnackBar(
                        'Suivi de localisation démarré',
                        Colors.green,
                      );
                    }
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  label: 'Modifier',
                  icon: Icons.edit_rounded,
                  color: AppColors.mainColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddVehiclePage(vehicle: vehicle),
                      ),
                    ).then((result) {
                      if (result == true) {
                        _loadVehicle();
                        _showSnackBar(
                          'Véhicule modifié avec succès',
                          Colors.green,
                        );
                      }
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildModernInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
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
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildNoVehicle() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration moderne avec animation
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    Icons.directions_car_rounded,
                    size: 40,
                    color: AppColors.mainColor,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'En attente',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          const Text(
            'Aucun véhicule enregistré',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            'Ajoutez votre premier véhicule pour commencer à recevoir des demandes de course et générer des revenus.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Avantages de l'ajout d'un véhicule
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _buildBenefit(
                  Icons.monetization_on,
                  'Générez des revenus',
                  Colors.green,
                ),
                const SizedBox(height: 16),
                _buildBenefit(
                  Icons.schedule,
                  'Travaillez à votre rythme',
                  Colors.blue,
                ),
                const SizedBox(height: 16),
                _buildBenefit(
                  Icons.people,
                  'Rejoignez notre communauté',
                  Colors.purple,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Bouton d'ajout moderne avec design attrayant
          Container(
            width: double.infinity,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
            child: Material(
              color: AppColors.mainColor,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _navigateToAddVehicle,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Ajouter mon véhicule',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class AddVehiclePage extends StatefulWidget {
  final VehicleModel? vehicle; // Pour modification

  const AddVehiclePage({super.key, this.vehicle});

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _plaqueController = TextEditingController();
  final _couleurController = TextEditingController();

  String _typeVehicule = 'voiture';
  String _confort = 'confort';
  int _capacite = 4;
  bool _loading = false;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();

    // Si mode modification, pré-remplir les champs
    if (widget.vehicle != null) {
      final vehicle = widget.vehicle!;
      _marqueController.text = vehicle.marque;
      _modeleController.text = vehicle.modele;
      _plaqueController.text = vehicle.plaque;
      _couleurController.text = vehicle.couleur;
      _typeVehicule = vehicle.typeVehicule;
      _confort = vehicle.confort;
      _capacite = vehicle.capacite;
      _latitude = vehicle.latitude;
      _longitude = vehicle.longitude;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      print('Erreur localisation: $e');
      // Valeurs par défaut (Abidjan)
      setState(() {
        _latitude = 5.3600;
        _longitude = -4.0083;
      });
    }
  }

  Future<void> _submitVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Localisation en cours...')));
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final token = await SessionManager.getToken();
      if (token == null) throw Exception('Token non trouvé');

      final ApiResponse response;

      if (widget.vehicle != null) {
        // Mode modification - utiliser updateVehicle
        response = await ApiService.updateVehicle(
          token: token,
          vehicleId: widget.vehicle!.id,
          marque: _marqueController.text.trim(),
          modele: _modeleController.text.trim(),
          plaque: _plaqueController.text.trim().toUpperCase(),
          couleur: _couleurController.text.trim(),
          typeVehicule: _typeVehicule,
          confort: _confort,
          capacite: _capacite,
          latitude: _latitude!,
          longitude: _longitude!,
        );
      } else {
        // Mode ajout - utiliser addVehicle
        response = await ApiService.addVehicle(
          token: token,
          marque: _marqueController.text.trim(),
          modele: _modeleController.text.trim(),
          plaque: _plaqueController.text.trim().toUpperCase(),
          couleur: _couleurController.text.trim(),
          typeVehicule: _typeVehicule,
          confort: _confort,
          capacite: _capacite,
          latitude: _latitude!,
          longitude: _longitude!,
        );
      }

      if (response.success) {
        if (context.mounted) {
          Navigator.pop(
            context,
            true,
          ); // Retourner true pour indiquer le succès
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(response.message)));
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(response.message)));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
                child: Icon(
                  widget.vehicle != null ? Icons.edit : Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.vehicle != null
                        ? 'Modifier véhicule'
                        : 'Ajouter véhicule',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.vehicle != null
                        ? 'Mettre à jour les informations'
                        : 'Configurer votre véhicule',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec instructions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.mainColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.info_outline,
                            color: AppColors.mainColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Informations du véhicule',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Remplissez soigneusement toutes les informations de votre véhicule. Ces données seront visibles par vos passagers.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Marque
              _buildModernTextField(
                controller: _marqueController,
                label: 'Marque du véhicule',
                hint: 'Ex: Toyota, Nissan, Mercedes...',
                icon: Icons.branding_watermark,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La marque est obligatoire';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Modèle
              _buildModernTextField(
                controller: _modeleController,
                label: 'Modèle du véhicule',
                hint: 'Ex: Corolla, Micra, C-Class...',
                icon: Icons.directions_car,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le modèle est obligatoire';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Plaque
              _buildModernTextField(
                controller: _plaqueController,
                label: 'Plaque d\'immatriculation',
                hint: 'Ex: ABC123CI, 1234-AB-567',
                icon: Icons.confirmation_number,
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La plaque est obligatoire';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Couleur
              _buildModernTextField(
                controller: _couleurController,
                label: 'Couleur principale',
                hint: 'Ex: Blanc, Noir, Rouge, Bleu...',
                icon: Icons.palette,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La couleur est obligatoire';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Type de véhicule
              _buildModernDropdown<String>(
                label: 'Type de véhicule',
                value: _typeVehicule,
                icon: Icons.category,
                items: const [
                  DropdownMenuItem(value: 'voiture', child: Text('🚗 Voiture')),
                  DropdownMenuItem(value: 'moto', child: Text('🏍️ Moto')),
                ],
                onChanged: (value) {
                  setState(() {
                    _typeVehicule = value!;
                    // Ajuster la capacité selon le type
                    if (_typeVehicule == 'moto' && _capacite > 2) {
                      _capacite = 2;
                    }
                  });
                },
              ),

              const SizedBox(height: 20),

              // Confort
              _buildModernDropdown<String>(
                label: 'Niveau de confort',
                value: _confort,
                icon: Icons.airline_seat_recline_normal,
                items: const [
                  DropdownMenuItem(value: 'basique', child: Text('⭐ Basique')),
                  DropdownMenuItem(value: 'confort', child: Text('⭐⭐ Confort')),
                  DropdownMenuItem(
                    value: 'premium',
                    child: Text('⭐⭐⭐ Premium'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _confort = value!;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Capacité
              _buildModernDropdown<int>(
                label: 'Capacité (nombre de places)',
                value: _capacite,
                icon: Icons.people,
                items: _typeVehicule == 'moto'
                    ? const [
                        DropdownMenuItem(value: 1, child: Text('👤 1 place')),
                        DropdownMenuItem(value: 2, child: Text('👥 2 places')),
                      ]
                    : const [
                        DropdownMenuItem(value: 2, child: Text('👥 2 places')),
                        DropdownMenuItem(value: 4, child: Text('👪 4 places')),
                        DropdownMenuItem(
                          value: 5,
                          child: Text('👨‍👩‍👧‍👦 5 places'),
                        ),
                        DropdownMenuItem(value: 7, child: Text('🚐 7 places')),
                        DropdownMenuItem(value: 9, child: Text('🚌 9 places')),
                      ],
                onChanged: (value) {
                  setState(() {
                    _capacite = value!;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Info localisation moderne
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _latitude != null && _longitude != null
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _latitude != null && _longitude != null
                            ? Icons.location_on
                            : Icons.location_searching,
                        color: _latitude != null && _longitude != null
                            ? Colors.green
                            : Colors.orange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _latitude != null && _longitude != null
                                ? 'Localisation confirmée'
                                : 'Détection de la position',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _latitude != null && _longitude != null
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _latitude != null && _longitude != null
                                ? 'Votre position sera partagée avec les passagers'
                                : 'Nous localisons votre véhicule automatiquement',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Bouton soumettre moderne
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Material(
                  color: _loading ? Colors.grey[300] : AppColors.mainColor,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _loading ? null : _submitVehicle,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_loading) ...[
                            const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Traitement en cours...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                widget.vehicle != null
                                    ? Icons.update
                                    : Icons.add_circle,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              widget.vehicle != null
                                  ? 'Mettre à jour le véhicule'
                                  : 'Enregistrer le véhicule',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        controller: controller,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.mainColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.mainColor, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.mainColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildModernDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.mainColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.mainColor, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.mainColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  @override
  void dispose() {
    _marqueController.dispose();
    _modeleController.dispose();
    _plaqueController.dispose();
    _couleurController.dispose();
    super.dispose();
  }
}
