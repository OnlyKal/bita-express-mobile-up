import 'package:flutter/material.dart';
import 'dart:async';
import '../api.dart';
import '../session.dart';
import '../colors.dart';

class RideTrackingPage extends StatefulWidget {
  final int rideId;

  const RideTrackingPage({super.key, required this.rideId});

  @override
  State<RideTrackingPage> createState() => _RideTrackingPageState();
}

class _RideTrackingPageState extends State<RideTrackingPage> {
  RideModel? _ride;
  bool _isLoading = true;
  String? _error;
  late Timer _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadRideStatus();
    // Actualiser le statut toutes les 3 secondes
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _loadRideStatus();
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  Future<void> _loadRideStatus() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        if (mounted) {
          setState(() {
            _error = 'Token non disponible';
            _isLoading = false;
          });
        }
        return;
      }

      // Charger les courses du passager et trouver celle avec l'ID correspondant
      final response = await ApiService.getPassengerRides(token);

      if (response.success && response.data != null) {
        final List<dynamic> ridesData = response.data is List
            ? response.data as List<dynamic>
            : response.data is Map<String, dynamic> &&
                  (response.data as Map<String, dynamic>)['rides'] != null
            ? (response.data as Map<String, dynamic>)['rides'] as List<dynamic>
            : [];

        final rides = ridesData
            .map((json) => RideModel.fromJson(json))
            .toList();
        final ride = rides.firstWhere(
          (r) => r.id == widget.rideId,
          orElse: () => throw Exception('Course non trouvée'),
        );

        if (mounted) {
          setState(() {
            _ride = ride;
            _isLoading = false;
            _error = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = response.message;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur: $e';
          _isLoading = false;
        });
      }
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
        return 'En attente de chauffeur';
      case 'acceptee':
        return 'Chauffeur trouvé !';
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

  Widget _buildStatusIndicator() {
    return Column(
      children: [
        // Cercle animé du statut
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getStatusColor(_ride!.statut).withOpacity(0.1),
            border: Border.all(color: _getStatusColor(_ride!.statut), width: 3),
          ),
          child: Center(
            child: Icon(
              _getStatusIcon(_ride!.statut),
              size: 60,
              color: _getStatusColor(_ride!.statut),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Texte du statut
        Text(
          _getStatusText(_ride!.statut),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _getStatusColor(_ride!.statut),
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Numéro de course
        Text(
          'Course #${_ride!.id}',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildDetailSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informations du trajet
          const Text(
            'Détails de la course',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Distance
          _buildInfoRow(
            Icons.straighten,
            'Distance',
            '${(_ride!.distance / 1000).toStringAsFixed(1)} km',
          ),
          const SizedBox(height: 12),

          // Durée estimée
          _buildInfoRow(
            Icons.access_time,
            'Durée estimée',
            '${(_ride!.dureeEstimee / 60).toStringAsFixed(0)} min',
          ),
          const SizedBox(height: 12),

          // Prix
          _buildInfoRow(
            Icons.monetization_on,
            'Prix estimé',
            '${_ride!.prixEstime} CDF',
            highlight: true,
          ),
          const SizedBox(height: 12),

          // Chauffeur (si acceptée)
          if (_ride!.isAccepted && _ride!.chauffeurName != null) ...[
            _buildInfoRow(Icons.person, 'Chauffeur', _ride!.chauffeurName!),
            const SizedBox(height: 12),
          ],

          // Statut détaillé
          _buildInfoRow(
            _getStatusIcon(_ride!.statut),
            'Statut actuel',
            _getStatusText(_ride!.statut),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            color: highlight ? AppColors.mainColor : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStatus() {
    final statuses = [
      ('en_attente', 'En attente'),
      ('acceptee', 'Acceptée'),
      ('en_cours', 'En cours'),
      ('terminee', 'Terminée'),
    ];

    final statusIndex = statuses.indexWhere(
      (s) => s.$1 == _ride!.statut.toLowerCase(),
    );

    return Column(
      children: [
        const Text(
          'Progression',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: statuses.length,
            separatorBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Container(
                width: 2,
                color: index < statusIndex
                    ? AppColors.success
                    : AppColors.border,
              ),
            ),
            itemBuilder: (context, index) {
              final isCompleted = index < statusIndex;
              final isCurrent = index == statusIndex;

              return Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrent
                          ? AppColors.mainColor
                          : isCompleted
                          ? AppColors.success
                          : AppColors.border,
                    ),
                    child: Center(
                      child: Icon(
                        isCompleted || isCurrent
                            ? Icons.check
                            : Icons.circle_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    statuses[index].$2,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isCurrent
                          ? AppColors.mainColor
                          : isCompleted
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Suivi de la course'),
        backgroundColor: AppColors.mainColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (!_isLoading && _ride != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '#${_ride!.id}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadRideStatus,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            )
          : _ride == null
          ? const Center(child: Text('Course non trouvée'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatusIndicator(),
                  const SizedBox(height: 32),
                  _buildTimelineStatus(),
                  const SizedBox(height: 32),
                  _buildDetailSection(),
                  const SizedBox(height: 32),
                  // Bouton pour retourner à l'accueil
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      icon: const Icon(Icons.home),
                      label: Text(
                        _ride!.isFinished
                            ? 'Retourner à l\'accueil'
                            : 'Retourner au menu',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
