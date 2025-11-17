import 'package:flutter/material.dart';
import '../api.dart';
import '../session.dart';
import '../colors.dart';
import '../pages/ride_tracking_page.dart';

class ActiveRidesWidget extends StatefulWidget {
  const ActiveRidesWidget({super.key});

  @override
  State<ActiveRidesWidget> createState() => _ActiveRidesWidgetState();
}

class _ActiveRidesWidgetState extends State<ActiveRidesWidget> {
  late Future<List<RideModel>> _activeRidesFuture;

  @override
  void initState() {
    super.initState();
    _loadActiveRides();
  }

  void _loadActiveRides() {
    _activeRidesFuture = _fetchActiveRides();
  }

  Future<List<RideModel>> _fetchActiveRides() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return [];

      final response = await ApiService.getPassengerRides(token);

      if (response.success && response.data != null) {
        List<RideModel> rides = [];

        if (response.data is List) {
          rides = (response.data as List)
              .map((json) => RideModel.fromJson(json))
              .toList();
        } else if (response.data is Map<String, dynamic> &&
            response.data['rides'] != null) {
          rides = (response.data['rides'] as List)
              .map((json) => RideModel.fromJson(json))
              .toList();
        }

        // Filtrer uniquement les courses en cours (non terminées, non annulées)
        return rides
            .where(
              (ride) => ride.isWaiting || ride.isAccepted || ride.isInProgress,
            )
            .toList();
      }
      return [];
    } catch (e) {
      print('Erreur lors du chargement des courses actives: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RideModel>>(
      future: _activeRidesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final activeRides = snapshot.data ?? [];

        if (activeRides.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.mainColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.local_taxi,
                      color: AppColors.mainColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Courses en cours',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mainColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${activeRides.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: activeRides.length,
                itemBuilder: (context, index) {
                  final ride = activeRides[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildRideCard(ride, context),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildRideCard(RideModel ride, BuildContext context) {
    Color statusColor = AppColors.mainColor;
    String statusText = 'En attente';
    IconData statusIcon = Icons.access_time;

    if (ride.isAccepted) {
      statusColor = Colors.blue;
      statusText = 'Acceptée';
      statusIcon = Icons.check_circle;
    } else if (ride.isInProgress) {
      statusColor = Colors.green;
      statusText = 'En cours';
      statusIcon = Icons.directions_car;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RideTrackingPage(rideId: ride.id),
          ),
        );
      },
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec ID et statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${ride.id}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Détails de la course
            if (ride.distance > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      '${(ride.distance / 1000).toStringAsFixed(1)} km',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),

            if (ride.prixEstime.isNotEmpty && ride.prixEstime != '0.00')
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.local_atm, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      '${ride.prixEstime} FC',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),

            if (ride.chauffeurName != null && ride.chauffeurName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ride.chauffeurName ?? 'En attente',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            const Spacer(),

            // Bouton d'action
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RideTrackingPage(rideId: ride.id),
                    ),
                  );
                },
                child: const Text(
                  'Voir la course',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
