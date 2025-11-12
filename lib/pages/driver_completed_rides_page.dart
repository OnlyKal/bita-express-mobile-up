import 'package:flutter/material.dart';
import 'dart:async';
import '../api.dart';
import '../session.dart';
import '../colors.dart';

class DriverCompletedRidesPage extends StatefulWidget {
  const DriverCompletedRidesPage({Key? key}) : super(key: key);

  @override
  State<DriverCompletedRidesPage> createState() =>
      _DriverCompletedRidesPageState();
}

class _DriverCompletedRidesPageState extends State<DriverCompletedRidesPage> {
  List<RideModel> _completedRides = [];
  bool _isLoading = true;
  String? _error;
  double _totalEarnings = 0.0;
  int _totalRides = 0;

  @override
  void initState() {
    super.initState();
    _loadCompletedRides();
  }

  Future<void> _loadCompletedRides() async {
    print('=== CHARGEMENT COURSES TERMINÉES CHAUFFEUR ===');
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        print('❌ Token non trouvé');
        setState(() {
          _error = 'Token non trouvé';
          _isLoading = false;
        });
        return;
      }

      print('✅ Token trouvé: ${token.substring(0, 20)}...');

      // Vérifier les données utilisateur
      final userData = await SessionManager.getUserData();
      print('👤 Données utilisateur:');
      print('  - ID: ${userData?['id']}');
      print('  - Username: ${userData?['username']}');
      print('  - Type: ${userData?['type_utilisateur']}');
      print('  - Statut: ${userData?['statut']}');

      final response = await ApiService.getDriverCompletedRides(token);

      print('📡 Réponse API courses terminées:');
      print('  - Success: ${response.success}');
      print('  - Message: ${response.message}');
      print('  - Data type: ${response.data?.runtimeType}');
      print('  - Data: ${response.data}');

      if (response.success && response.data != null) {
        final List<dynamic> ridesData = response.data is List
            ? response.data
            : response.data['courses'] ?? response.data['data'] ?? [];

        print('📊 Données courses terminées:');
        print('  - Type: ${ridesData.runtimeType}');
        print('  - Nombre: ${ridesData.length}');
        print('  - Contenu: $ridesData');

        final List<RideModel> rides = ridesData.map((ride) {
          print('🔄 Conversion: $ride');
          return RideModel.fromJson(ride);
        }).toList();

        // Calculer les statistiques
        double totalEarnings = 0.0;
        for (var ride in rides) {
          try {
            totalEarnings += double.parse(ride.prixEstime);
          } catch (e) {
            print('Erreur parsing prix: ${ride.prixEstime} - $e');
          }
        }

        print('✅ ${rides.length} courses terminées chargées pour le chauffeur');
        print('💰 Total des gains: $totalEarnings FC');

        setState(() {
          _completedRides = rides;
          _totalRides = rides.length;
          _totalEarnings = totalEarnings;
          _isLoading = false;
          _error = null;
        });
      } else {
        print('❌ Échec de chargement: ${response.message}');
        setState(() {
          _error = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('💥 Erreur exception: $e');
      setState(() {
        _error = 'Erreur de chargement: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshCompletedRides() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    await _loadCompletedRides();
  }

  void _showRideDetails(RideModel ride) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails Course #${ride.id}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('Passager', ride.passagerName),
              _buildDetailItem('Statut', _getStatusText(ride.statut)),
              _buildDetailItem('Prix', '${ride.prixEstime} FC'),
              _buildDetailItem(
                'Distance',
                '${(ride.distance / 1000).toStringAsFixed(1)} km',
              ),
              _buildDetailItem(
                'Durée estimée',
                '${(ride.dureeEstimee / 60).toStringAsFixed(0)} min',
              ),
              _buildDetailItem(
                'Date de création',
                _formatDate(ride.dateCreation),
              ),
              if (ride.dateAcceptation != null)
                _buildDetailItem(
                  'Date d\'acceptation',
                  _formatDate(ride.dateAcceptation!),
                ),
              if (ride.dateFin != null)
                _buildDetailItem('Date de fin', _formatDate(ride.dateFin!)),
              const SizedBox(height: 12),
              const Text(
                'Coordonnées:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildDetailItem(
                'Départ',
                '${ride.departLatitude.toStringAsFixed(6)}, ${ride.departLongitude.toStringAsFixed(6)}',
              ),
              _buildDetailItem(
                'Arrivée',
                '${ride.destinationLatitude.toStringAsFixed(6)}, ${ride.destinationLongitude.toStringAsFixed(6)}',
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
              elevation: 0,
            ),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'en_attente':
        return 'En attente';
      case 'acceptee':
        return 'Acceptée';
      case 'en_cours':
        return 'En cours';
      case 'terminee':
        return 'Terminée';
      case 'annulee':
        return 'Annulée';
      default:
        return 'Inconnu';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ), // Optimisé
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec titre et ligne d'accentuation
          Row(
            children: [
              Icon(
                Icons.analytics_rounded,
                color: AppColors.mainColor,
                size: 24, // Réduit pour éviter la saturation
              ),
              const SizedBox(width: 10), // Réduit
              const Text(
                'Statistiques',
                style: TextStyle(
                  fontSize: 20, // Réduit pour éviter la saturation
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: 80,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.mainColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16), // Réduit pour optimiser l'espace
          // Grille des statistiques optimisée pour éviter la saturation
          LayoutBuilder(
            builder: (context, constraints) {
              return GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.4, // Encore augmenté pour plus d'espace
                crossAxisSpacing: 6, // Encore réduit pour éviter le débordement
                mainAxisSpacing: 6,
                children: [
                  _buildStatItem(
                    Icons.assignment_turned_in_rounded,
                    'Courses',
                    _totalRides.toString(),
                    const Color(0xFF4CAF50),
                  ),
                  _buildStatItem(
                    Icons.monetization_on_rounded,
                    'Total gagné',
                    '${_totalEarnings.toStringAsFixed(0)} FC',
                    const Color(0xFFFF9800),
                  ),
                  _buildStatItem(
                    Icons.trending_up_rounded,
                    'Moyenne',
                    _totalRides > 0
                        ? '${(_totalEarnings / _totalRides).toStringAsFixed(0)} FC'
                        : '0 FC',
                    const Color(0xFF2196F3),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8), // Encore plus réduit
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ), // Bordure plus fine
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4), // Encore plus réduit
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: color, size: 18), // Encore plus réduit
          ),
          const SizedBox(height: 4), // Encore plus réduit
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12, // Encore plus réduit pour éviter le débordement
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2), // Réduit
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 9, // Encore plus réduit pour éviter le débordement
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedRideCard(RideModel ride) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ), // Optimisé
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _showRideDetails(ride),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(
              14,
            ), // Encore optimisé pour éviter la saturation
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec ID course et statut optimisé
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      flex: 2,
                      child: Text(
                        'Course #${ride.id}',
                        style: const TextStyle(
                          fontSize: 16, // Réduit pour éviter le débordement
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10, // Réduit
                          vertical: 4, // Réduit
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF4CAF50),
                            width: 1.5, // Légèrement réduit
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 14, // Réduit
                              color: Color(0xFF4CAF50),
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Terminée',
                              style: TextStyle(
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.w600,
                                fontSize: 11, // Réduit
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Info principale optimisée pour éviter le débordement
                Row(
                  children: [
                    // Passager
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6), // Réduit
                            decoration: BoxDecoration(
                              color: AppColors.mainColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              color: AppColors.mainColor,
                              size: 18, // Réduit
                            ),
                          ),
                          const SizedBox(width: 8), // Réduit
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Passager',
                                  style: TextStyle(
                                    fontSize: 10, // Réduit
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  ride.passagerName,
                                  style: const TextStyle(
                                    fontSize: 13, // Réduit
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12), // Réduit
                    // Prix
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6), // Réduit
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.monetization_on_rounded,
                              color: Color(0xFF4CAF50),
                              size: 18, // Réduit
                            ),
                          ),
                          const SizedBox(width: 6), // Réduit
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Montant',
                                  style: TextStyle(
                                    fontSize: 10, // Réduit
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${ride.prixEstime} FC',
                                  style: const TextStyle(
                                    fontSize: 14, // Réduit
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF4CAF50),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16), // Réduit pour optimiser l'espace
                // Ligne de séparation
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                  ),
                ),

                const SizedBox(height: 12), // Réduit pour optimiser l'espace
                // Informations détaillées en grille
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickInfo(
                        Icons.straighten_rounded,
                        'Distance',
                        '${(ride.distance / 1000).toStringAsFixed(1)} km',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickInfo(
                        Icons.access_time_rounded,
                        'Durée',
                        '${(ride.dureeEstimee / 60).toStringAsFixed(0)} min',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickInfo(
                        Icons.calendar_today_rounded,
                        'Date',
                        _formatDate(ride.dateCreation),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12), // Réduit pour optimiser l'espace
                // Indicateur d'action
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Touchez pour voir les détails complets',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickInfo(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16, // Réduit pour éviter la saturation
          color: Colors.grey[600],
        ),
        const SizedBox(height: 3), // Réduit
        Text(
          label,
          style: const TextStyle(
            fontSize: 9, // Réduit pour éviter le débordement
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 1), // Réduit
        Text(
          value,
          style: const TextStyle(
            fontSize: 11, // Réduit pour éviter le débordement
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
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
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                ),
                child: const Icon(Icons.history, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Historique des courses',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Courses terminées',
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
              onPressed: _refreshCompletedRides,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
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
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshCompletedRides,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          : _completedRides.isEmpty
          ? Column(
              children: [
                _buildStatsCard(),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune course terminée',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vos courses terminées apparaîtront ici',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : RefreshIndicator(
              onRefresh: _refreshCompletedRides,
              child: Column(
                children: [
                  _buildStatsCard(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _completedRides.length,
                      itemBuilder: (context, index) {
                        return _buildCompletedRideCard(_completedRides[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
