import 'package:flutter/material.dart';
import 'dart:async';
import '../api.dart';
import '../session.dart';
import '../colors.dart';
import 'ride_details_page.dart';

class AvailableRidesPage extends StatefulWidget {
  const AvailableRidesPage({super.key});

  @override
  State<AvailableRidesPage> createState() => _AvailableRidesPageState();
}

class _AvailableRidesPageState extends State<AvailableRidesPage> {
  List<RideModel> _availableRides = [];
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;

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
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2)),
                child: const Icon(
                  Icons.assignment,
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
                    'Courses disponibles',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Demandes en attente',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            // IconButton(
            //   icon: const Icon(Icons.refresh, color: Colors.white),
            //   onPressed: _loadAvailableRides,
            // ),
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
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.mainColor,
                  ),
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
          : _availableRides.isEmpty
          ? Center(
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
                        color: AppColors.mainColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune course disponible',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Les nouvelles demandes de course apparaîtront ici automatiquement.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _availableRides.length,
              itemBuilder: (context, index) {
                return _buildRideCard(_availableRides[index]);
              },
            ),
    );
  }

  Widget _buildRideCard(RideModel ride) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                RideDetailsPage(ride: ride),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Passager et statut
            Row(
              children: [
                Icon(Icons.person, color: AppColors.mainColor, size: 20),
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
                    color: AppColors.mainColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'En attente',
                    style: TextStyle(
                      color: AppColors.mainColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Prix
            Row(
              children: [
                Icon(Icons.monetization_on, color: Colors.green, size: 20),
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
            const SizedBox(height: 12),

            // Distance et durée
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.straighten, color: Colors.grey, size: 16),
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
                      Icon(Icons.access_time, color: Colors.grey, size: 16),
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

            // Indicateur pour naviguer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Appuyer pour voir les détails',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.mainColor,
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
