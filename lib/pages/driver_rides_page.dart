import 'package:flutter/material.dart';
import 'dart:async';
import '../api.dart';
import '../session.dart';
import '../colors.dart';

class DriverRidesPage extends StatefulWidget {
  const DriverRidesPage({super.key});

  @override
  State<DriverRidesPage> createState() => _DriverRidesPageState();
}

class _DriverRidesPageState extends State<DriverRidesPage> {
  List<RideModel> _rides = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  Future<void> _loadRides() async {
    print('=== CHARGEMENT COURSES CHAUFFEUR ===');
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

      final response = await ApiService.getDriverRides(token);

      print('📡 Réponse API:');
      print('  - Success: ${response.success}');
      print('  - Message: ${response.message}');
      print('  - Data type: ${response.data?.runtimeType}');
      print('  - Data: ${response.data}');

      if (response.success && response.data != null) {
        final List<dynamic> ridesData = response.data is List
            ? response.data
            : response.data['courses'] ?? response.data['data'] ?? [];

        print('📊 Données courses:');
        print('  - Type: ${ridesData.runtimeType}');
        print('  - Nombre: ${ridesData.length}');
        print('  - Contenu: $ridesData');

        final List<RideModel> rides = ridesData.map((ride) {
          print('🔄 Conversion: $ride');
          return RideModel.fromJson(ride);
        }).toList();

        print('✅ ${rides.length} courses chargées pour le chauffeur');

        setState(() {
          _rides = rides;
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

  Future<void> _refreshRides() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    await _loadRides();
  }

  Future<void> _cancelRide(RideModel ride) async {
    try {
      // Vérifier si la course peut être annulée
      if (!ride.isWaiting && !ride.isAccepted) {
        _showMessage('Cette course ne peut plus être annulée', isError: true);
        return;
      }

      // Dialogue de confirmation
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Annuler la course'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Voulez-vous vraiment annuler cette course ?'),
              const SizedBox(height: 12),
              Text(
                'Course #${ride.id}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Passager: ${ride.passagerName}'),
              Text('Prix: ${ride.prixEstime} FC'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.background,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                elevation: 0,
              ),
              child: const Text('Non'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.textWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                elevation: 0,
              ),
              child: const Text('Oui, annuler'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final token = await SessionManager.getToken();
      if (token == null) {
        _showMessage('Token non trouvé', isError: true);
        return;
      }

      final response = await ApiService.cancelRide(
        token: token,
        rideId: ride.id,
      );

      if (response.success) {
        _showMessage('Course annulée avec succès !');
        _refreshRides();
      } else {
        _showMessage(
          'Erreur lors de la annulation: ${response.message}',
          isError: true,
        );
      }
    } catch (e) {
      _showMessage('Erreur: $e', isError: true);
    }
  }

  Future<void> _finishRide(RideModel ride) async {
    try {
      // Vérifier si la course peut être terminée
      if (!ride.isAccepted && !ride.isInProgress) {
        _showMessage('Cette course ne peut pas être terminée', isError: true);
        return;
      }

      // Dialogue de confirmation
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Terminer la course'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Voulez-vous marquer cette course comme terminée ?'),
              const SizedBox(height: 12),
              Text(
                'Course #${ride.id}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Passager: ${ride.passagerName}'),
              Text('Prix: ${ride.prixEstime} FC'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.background,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                elevation: 0,
              ),
              child: const Text('Non'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.textWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                elevation: 0,
              ),
              child: const Text('Oui, terminer'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final token = await SessionManager.getToken();
      if (token == null) {
        _showMessage('Token non trouvé', isError: true);
        return;
      }

      final response = await ApiService.finishRide(
        token: token,
        rideId: ride.id,
      );

      if (response.success) {
        _showMessage('Course terminée avec succès !');
        _refreshRides();
      } else {
        _showMessage(
          'Erreur lors de la finalisation: ${response.message}',
          isError: true,
        );
      }
    } catch (e) {
      _showMessage('Erreur: $e', isError: true);
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'en_attente':
        return AppColors.warning;
      case 'acceptee':
        return AppColors.primary;
      case 'en_cours':
        return Colors.blue;
      case 'terminee':
        return AppColors.success;
      case 'annulee':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'en_attente':
        return Icons.schedule;
      case 'acceptee':
        return Icons.check_circle;
      case 'en_cours':
        return Icons.directions_car;
      case 'terminee':
        return Icons.flag;
      case 'annulee':
        return Icons.cancel;
      default:
        return Icons.help;
    }
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

  Widget _buildRideCard(RideModel ride) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: _getStatusColor(ride.statut).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec statut et date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(ride.statut).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: _getStatusColor(ride.statut),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(ride.statut),
                      size: 16,
                      color: _getStatusColor(ride.statut),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getStatusText(ride.statut),
                      style: TextStyle(
                        color: _getStatusColor(ride.statut),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Course #${ride.id}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Informations passager
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.person, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Passager: ${ride.passagerName}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Trajet
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Column(
              children: [
                // Point de départ
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Départ: ${ride.departLatitude.toStringAsFixed(4)}, ${ride.departLongitude.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Ligne verticale
                Container(
                  margin: const EdgeInsets.only(left: 5, top: 4, bottom: 4),
                  height: 20,
                  width: 2,
                  color: AppColors.textSecondary,
                ),

                // Point d'arrivée
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Arrivée: ${ride.destinationLatitude.toStringAsFixed(4)}, ${ride.destinationLongitude.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Informations de course
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.straighten,
                        'Distance',
                        '${(ride.distance / 1000).toStringAsFixed(1)} km',
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.access_time,
                        'Durée',
                        '${(ride.dureeEstimee / 60).toStringAsFixed(0)} min',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.monetization_on,
                        'Prix',
                        '${ride.prixEstime} FC',
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.calendar_today,
                        'Date',
                        _formatDate(ride.dateCreation),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Boutons d'action selon le statut
          const SizedBox(height: 16),
          Row(
            children: [
              // Bouton d'annulation (si possible)
              if (ride.isWaiting || ride.isAccepted) ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _cancelRide(ride),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.textWhite,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cancel,
                          color: AppColors.textWhite,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Annuler',
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (ride.isAccepted || ride.isInProgress)
                  const SizedBox(width: 12),
              ],

              // Bouton de finalisation (si possible)
              if (ride.isAccepted || ride.isInProgress) ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _finishRide(ride),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.textWhite,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag, color: AppColors.textWhite, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Terminer',
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                    'Mes courses',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Suivi et historique',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _refreshRides,
              icon: const Icon(Icons.refresh, color: Colors.white),
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
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshRides,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text(
                      'Réessayer',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          : _rides.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune course trouvée',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vos courses acceptées apparaîtront ici',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshRides,
              child: ListView.builder(
                itemCount: _rides.length,
                itemBuilder: (context, index) {
                  return _buildRideCard(_rides[index]);
                },
              ),
            ),
    );
  }
}
