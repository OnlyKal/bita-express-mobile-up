import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../api.dart';
import '../colors.dart';
import '../session.dart';

class RideDetailsPage extends StatefulWidget {
  final RideModel ride;

  const RideDetailsPage({super.key, required this.ride});

  @override
  State<RideDetailsPage> createState() => _RideDetailsPageState();
}

class _RideDetailsPageState extends State<RideDetailsPage> {
  final MapController _mapController = MapController();
  bool _isAccepting = false;

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final departLocation = LatLng(ride.departLatitude, ride.departLongitude);
    final destinationLocation = LatLng(
      ride.destinationLatitude,
      ride.destinationLongitude,
    );

    // Calculer le centre entre les deux points
    final centerLat =
        (departLocation.latitude + destinationLocation.latitude) / 2;
    final centerLng =
        (departLocation.longitude + destinationLocation.longitude) / 2;
    final centerLocation = LatLng(centerLat, centerLng);

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
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2)),
                child: const Icon(
                  Icons.location_on,
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
                    'Détails de la course',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Localisation et informations',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Carte
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centerLocation,
              initialZoom: 13.0,
              minZoom: 10.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.bita_express_mobile',
              ),
              // Ligne de route entre départ et destination
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [departLocation, destinationLocation],
                    color: AppColors.mainColor,
                    strokeWidth: 3,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Marqueur départ
                  Marker(
                    point: departLocation,
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Point de départ'),
                            backgroundColor: const Color(0xFF4CAF50),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF4CAF50,
                                    ).withOpacity(0.4),
                                    blurRadius: 4,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Marqueur destination
                  Marker(
                    point: destinationLocation,
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Destination'),
                            backgroundColor: const Color(0xFFE53935),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53935),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFE53935,
                                    ).withOpacity(0.4),
                                    blurRadius: 4,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Boutons flottants (zoom + location)
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                // Zoom in button
                GestureDetector(
                  onTap: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.mainColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(height: 8),
                // Zoom out button
                GestureDetector(
                  onTap: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.mainColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.remove,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Location button
                GestureDetector(
                  onTap: () {
                    _mapController.move(departLocation, 15.0);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.mainColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Info et actions au bas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom du passager
                  Row(
                    children: [
                      Icon(Icons.person, color: AppColors.mainColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Passager',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              ride.passagerName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Distance et durée
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.straighten,
                              color: Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${(ride.distance / 1000).toStringAsFixed(1)} km',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${(ride.dureeEstimee / 60).toStringAsFixed(0)} min',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Prix
                  Row(
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${ride.prixEstime} FC',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Bouton accepter
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isAccepting ? null : () => _acceptRide(ride),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isAccepting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
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
        ],
      ),
    );
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

      // Conversion en entiers
      int chauffeurIdInt = int.parse(userData['id'].toString());
      int vehiculeIdInt = int.parse(vehicleInfo['id'].toString());

      setState(() {
        _isAccepting = true;
      });

      final response = await ApiService.acceptRide(
        token: token,
        rideId: ride.id,
        chauffeurId: chauffeurIdInt,
        vehiculeId: vehiculeIdInt,
      );

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Course acceptée avec succès!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Montrer le dialog d'appel du client
          _showCallClientDialog(ride);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${response.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Erreur lors de l\'acceptation de la course: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAccepting = false;
        });
      }
    }
  }

  void _showCallClientDialog(RideModel ride) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            const Expanded(child: Text('Course acceptée!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Passager: ${ride.passagerName}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'Voulez-vous appeler le passager pour confirmer votre arrivée?',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Retour à la liste
            },
            child: const Text('Plus tard'),
          ),
          ElevatedButton.icon(
            onPressed: () => _callClient(ride),
            icon: const Icon(Icons.phone),
            label: const Text('Appeler'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _callClient(RideModel ride) async {
    // Pour maintenant, afficher un message car nous n'avons pas le numéro
    // En production, vous appelleriez le backend pour obtenir le numéro du passager
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appel du client'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone, color: AppColors.mainColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Appel en cours...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ride.passagerName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'L\'appel a été initialisé. Patientez...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.pop(context); // Retour à la liste
            },
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
