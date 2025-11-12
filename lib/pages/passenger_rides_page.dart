import 'package:flutter/material.dart';
import '../api.dart';
import '../session.dart';
import '../colors.dart';
import '../widgets/driver_evaluation_widget.dart';

class PassengerRidesPage extends StatefulWidget {
  const PassengerRidesPage({super.key});

  @override
  State<PassengerRidesPage> createState() => _PassengerRidesPageState();
}

class _PassengerRidesPageState extends State<PassengerRidesPage> {
  List<RideModel> _rides = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  Future<void> _loadRides() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final token = await SessionManager.getToken();
      if (token == null) {
        setState(() {
          _error = 'Token non disponible';
          _isLoading = false;
        });
        return;
      }

      final response = await ApiService.getPassengerRides(token);

      if (response.success && response.data != null) {
        setState(() {
          if (response.data is List) {
            _rides = (response.data as List)
                .map((json) => RideModel.fromJson(json))
                .toList();
          } else if (response.data is Map<String, dynamic> &&
              response.data['rides'] != null) {
            _rides = (response.data['rides'] as List)
                .map((json) => RideModel.fromJson(json))
                .toList();
          } else {
            _rides = [];
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement: $e';
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
              Text('Prix: ${ride.prixEstime} FC'),
              Text('Statut: ${_getStatusText(ride.statut)}'),
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
              child: const Text(
                'Oui, annuler',
                style: TextStyle(color: AppColors.textWhite),
              ),
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

      // Annuler la course
      final response = await ApiService.cancelRide(
        token: token,
        rideId: ride.id,
      );

      if (response.success) {
        _showMessage('Course annulée avec succès !');
        _refreshRides(); // Recharger la liste
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

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _processDirectPayment(RideModel ride) async {
    if (!mounted) return;

    // Dialogue pour confirmer le paiement
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer le paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Course: ${ride.passagerName}'),
            Text('Montant: ${ride.prixEstime} CDF'),
            const SizedBox(height: 12),
            const Text('Le paiement sera effectué via Mobile Money.'),
            const Text('Continuer?'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context, false),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
              elevation: 0,
            ),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.textWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
              elevation: 0,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Afficher indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Traitement du paiement...'),
          ],
        ),
      ),
    );

    try {
      // Processus de paiement Mobile Money automatique
      final token = await SessionManager.getToken() ?? '';

      final payment = await ApiService.processFlexPayPayment(
        token: token,
        courseId: ride.id,
        phone: await _getDefaultPhoneNumber(),
        amount: double.tryParse(ride.prixEstime) ?? 0.0,
        currency: 'CDF',
        type: 1, // Mobile Money
      );

      // Fermer le dialogue de chargement
      if (mounted) Navigator.pop(context);

      if (payment.success) {
        _showMessage('Paiement effectué avec succès via Mobile Money !');
        _refreshRides();
      } else {
        _showMessage('Échec du paiement: ${payment.message}', isError: true);
      }
    } catch (e) {
      // Fermer le dialogue de chargement
      if (mounted) Navigator.pop(context);
      _showMessage('Erreur lors du paiement: ${e.toString()}', isError: true);
    }
  }

  Future<String> _getDefaultPhoneNumber() async {
    try {
      // Récupérer le numéro de téléphone de l'utilisateur connecté
      final userData = await SessionManager.getUserData();
      String? userPhone = userData?['telephone'];

      if (userPhone != null && userPhone.isNotEmpty) {
        return userPhone;
      }

      // Si pas de numéro dans le profil, demander à l'utilisateur
      if (mounted) {
        final phoneNumber = await _promptForPhoneNumber();
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          return phoneNumber;
        }
      }

      throw Exception('Aucun numéro de téléphone disponible');
    } catch (e) {
      print('Erreur récupération numéro: $e');
      throw Exception('Impossible de récupérer le numéro de téléphone');
    }
  }

  Future<String?> _promptForPhoneNumber() async {
    final TextEditingController phoneController = TextEditingController();

    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Numéro de paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez entrer votre numéro Mobile Money :'),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '243xxxxxxxxx',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context, null),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
              elevation: 0,
            ),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final phone = phoneController.text.trim();
              if (phone.isNotEmpty) {
                Navigator.pop(context, phone);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.textWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
              elevation: 0,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Future<void> _evaluateDriver(RideModel ride) async {
    if (ride.chauffeur == null || ride.chauffeurName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Informations du chauffeur non disponibles'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final result = await showDriverEvaluationDialog(
      context: context,
      chauffeurId: ride.chauffeur!,
      courseId: ride.id,
      chauffeurName: ride.chauffeurName!,
      onEvaluationCompleted: () {
        // Optionnel: recharger les données ou mettre à jour l'interface
        _loadRides();
      },
    );

    if (result == true) {
      // L'évaluation a été soumise avec succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🌟 Merci pour votre évaluation !'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en_attente':
        return Colors.orange;
      case 'acceptee':
        return Colors.blue;
      case 'en_cours':
        return Colors.green;
      case 'terminee':
        return Colors.grey;
      case 'annulee':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
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
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'en_attente':
        return Icons.access_time;
      case 'acceptee':
        return Icons.check_circle;
      case 'en_cours':
        return Icons.directions_car;
      case 'terminee':
        return Icons.flag;
      case 'annulee':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildRideCard(RideModel ride) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    color: _getStatusColor(ride.statut).withValues(alpha: 0.1),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Informations de trajet
            Row(
              children: [
                Expanded(
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
                        margin: const EdgeInsets.only(
                          left: 5,
                          top: 4,
                          bottom: 4,
                        ),
                        height: 20,
                        width: 2,
                        color: Colors.grey[300],
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
              ],
            ),

            const SizedBox(height: 12),

            // Informations de course
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
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

            // Informations chauffeur (si disponible)
            if (ride.chauffeurName != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.mainColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: AppColors.mainColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Chauffeur: ${ride.chauffeurName}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Bouton d'annulation (si la course peut être annulée)
            if (ride.isWaiting || ride.isAccepted) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
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
                      const Icon(
                        Icons.cancel,
                        color: AppColors.textWhite,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Annuler la course',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Boutons pour courses terminées (paiement et évaluation)
            if (ride.isFinished) ...[
              const SizedBox(height: 12),
              Column(
                children: [
                  // Bouton de paiement
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _processDirectPayment(ride),
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
                          const Icon(
                            Icons.payment,
                            color: AppColors.textWhite,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Payer avec FlexPay',
                            style: TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bouton d'évaluation (si chauffeur disponible)
                  if (ride.chauffeurName != null && ride.chauffeur != null) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _evaluateDriver(ride),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                          side: BorderSide(color: Colors.amber),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Évaluer le chauffeur',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 16,
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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
                child: const Icon(Icons.directions_car, color: Colors.white, size: 24),
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
                    'Trajets passagers',
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
              onPressed: _refreshRides,
              icon: const Icon(Icons.refresh, color: Colors.white),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement de vos courses...'),
                ],
              ),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
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
                      backgroundColor: AppColors.mainColor,
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
                    Icons.directions_car_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune course',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vous n\'avez pas encore effectué de course.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshRides,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _rides.length,
                itemBuilder: (context, index) {
                  return _buildRideCard(_rides[index]);
                },
              ),
            ),
    );
  }
}
