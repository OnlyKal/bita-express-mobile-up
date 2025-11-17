import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'session.dart';
import 'user/profile.dart';
import 'func.dart';
import 'widgets/user_avatar.dart';
import 'colors.dart';
import 'services/location_service.dart';
import 'services/frequent_destinations_service.dart';
import 'services/vehicle_location_service.dart';
import 'models/place.dart';
import 'pages/vehicle_type_selection_page.dart';
import 'api.dart';
import 'pages/vehicle_page.dart';
import 'pages/driver_map_page.dart';
import 'pages/passenger_rides_page.dart';
import 'pages/driver_completed_rides_page.dart';
import 'pages/driver_rides_page.dart';
import 'pages/driver_evaluations_page.dart';

class ReactiveUserAvatar extends StatelessWidget {
  final double size;

  const ReactiveUserAvatar({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: SessionManager.userDataNotifier,
      builder: (context, userData, child) {
        return UserAvatar(
          avatarUrl: userData?['avatar_url'],
          size: size,
          iconSize: size * 0.6,
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<FrequentDestination> _frequentDestinations = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadFrequentDestinations();
  }

  Future<void> _loadUserData() async {
    final userData = await SessionManager.getUserData();
    print('Loaded user data: $userData');

    // Démarrer le suivi de localisation automatique si l'utilisateur est un chauffeur
    if (userData != null && userData['type_utilisateur'] == 'chauffeur') {
      await VehicleLocationService.startLocationTracking();
    }
  }

  Future<void> _loadFrequentDestinations() async {
    try {
      final destinations =
          await FrequentDestinationsService.getFrequentDestinations();
      setState(() {
        _frequentDestinations = destinations;
      });
      print('Destinations fréquentes chargées: ${destinations.length}');
    } catch (e) {
      print('Erreur chargement destinations fréquentes: $e');
    }
  }

  void _onFrequentDestinationSelected(FrequentDestination destination) async {
    print('Destination fréquente sélectionnée: ${destination.title}');
    print('Coordonnées de la destination:');
    print('  Latitude: ${destination.latitude}');
    print('  Longitude: ${destination.longitude}');
    print('  Sous-titre: ${destination.subtitle}');

    // Sauvegarder à nouveau cette destination pour mettre à jour l'ordre
    await FrequentDestinationsService.saveDestination(
      title: destination.title,
      subtitle: destination.subtitle,
      latitude: destination.latitude,
      longitude: destination.longitude,
    );

    // Recharger les destinations fréquentes
    await _loadFrequentDestinations();

    // Obtenir la position actuelle pour calculer la distance
    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        destination.latitude,
        destination.longitude,
      );

      // Naviguer vers la page de sélection du type de véhicule
      print('Navigation vers VehicleTypeSelectionPage avec:');
      print('  destinationLatitude: ${destination.latitude}');
      print('  destinationLongitude: ${destination.longitude}');
      print('  destinationTitle: ${destination.title}');
      print('  destinationSubtitle: ${destination.subtitle}');
      print('  departLatitude: ${position.latitude}');
      print('  departLongitude: ${position.longitude}');
      print('  distanceMeters: $distance');

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleTypeSelectionPage(
              destinationLatitude: destination.latitude,
              destinationLongitude: destination.longitude,
              destinationTitle: destination.title,
              destinationSubtitle: destination.subtitle,
              departLatitude: position.latitude,
              departLongitude: position.longitude,
              distanceMeters: distance,
              durationSeconds: 0,
            ),
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de l\'obtention de la position actuelle: $e');
      // Fallback: naviguer directement sans distance
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleTypeSelectionPage(
              destinationLatitude: destination.latitude,
              destinationLongitude: destination.longitude,
              destinationTitle: destination.title,
              destinationSubtitle: destination.subtitle,
              departLatitude: 0,
              departLongitude: 0,
              distanceMeters: 0,
              durationSeconds: 0,
            ),
          ),
        );
      }
    }
  }

  Widget _buildDestinationItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap:
          onTap ??
          () {
            // Ouvrir le modal de recherche pour cette destination
            _showDestinationSearchModal(context);
          },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.mainColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.mainColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  void _showDestinationSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: DestinationSearchModal(scrollController: controller),
        ),
      ),
    );
  }

  // ===================================
  // GESTION DES DÉPÔTS ET RETRAITS
  // ===================================

  Future<void> _showDepositModal() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Gestion des dépôts',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choisissez une action :',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showDepositForm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    icon: Icon(Icons.add_circle),
                    label: Text('Déposer'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showDepositBalance();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.textWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    icon: Icon(Icons.visibility),
                    label: Text('Solde'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDepositForm() async {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    String selectedCurrency = 'USD';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          title: Text(
            '💰 Effectuer un dépôt',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Montant',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Numéro de téléphone',
                  hintText: '+243...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedCurrency,
                decoration: InputDecoration(
                  labelText: 'Devise',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                items: ['USD', 'CDF']
                    .map(
                      (currency) => DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => selectedCurrency = value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'amount': amountController.text,
                  'phone': phoneController.text,
                  'currency': selectedCurrency,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              child: Text('Continuer'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _processDeposit(result);
    }
  }

  Future<void> _processDeposit(Map<String, dynamic> depositData) async {
    final double amount = double.tryParse(depositData['amount'] ?? '0') ?? 0;
    final String phone = depositData['phone'] ?? '';
    final String currency = depositData['currency'] ?? 'USD';

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Montant invalide'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Numéro de téléphone requis'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Afficher le loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        content: Row(
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(width: 16),
            Text(
              'Traitement du dépôt...',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );

    try {
      final token = await SessionManager.getToken();
      if (token == null) throw Exception('Token non trouvé');

      final response = await ApiService.processDepositFlexPay(
        token: token,
        amount: amount,
        currency: currency,
        phoneNumber: phone,
      );

      Navigator.pop(context); // Fermer loading

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Dépôt de $amount $currency effectué avec succès'),
            backgroundColor: AppColors.success,
          ),
        );

        // Afficher le nouveau solde
        await _showDepositBalance();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${response.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Fermer loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showDepositBalance() async {
    // Afficher loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        content: Row(
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(width: 16),
            Text(
              'Récupération du solde...',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );

    try {
      final token = await SessionManager.getToken();
      if (token == null) throw Exception('Token non trouvé');

      final response = await ApiService.getDeposit(token: token);

      Navigator.pop(context); // Fermer loading

      if (response.success) {
        final data = response.data;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
            title: Row(
              children: [
                Icon(Icons.account_balance_wallet, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  '💰 Votre solde',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chauffeur: ${data['chauffeur_name']}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('💵 USD:'),
                          Text(
                            '\$${data['amount_usd'] ?? 0}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('🪙 CDF:'),
                          Text(
                            '${data['amount_cdf'] ?? 0} CDF',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Dernière modification:',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        _formatDate(data['date_modification']),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${response.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Fermer loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userType =
        SessionManager.userDataNotifier.value?['type_utilisateur'] ??
        'Utilisateur';
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 100,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Image.asset('assets/logo.png'),
        ),
        title: ValueListenableBuilder<Map<String, dynamic>?>(
          valueListenable: SessionManager.userDataNotifier,
          builder: (context, userData, child) {
            final type = userData?['type_utilisateur'] ?? 'Utilisateur';
            final label = type == 'chauffeur'
                ? 'Chauffeur'
                : (type == 'passager' ? 'Passager' : type);
            return Container(
              decoration: BoxDecoration(
                color: AppColors.mainColor.withOpacity(0.18), // plus opaque
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Text(
                label.toString().toUpperCase(), // en majuscule
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.mainColor,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          },
        ),
        actions: [
          // Bouton "Mes courses" pour les passagers
          FutureBuilder<Map<String, dynamic>?>(
            future: SessionManager.getUserData(),
            builder: (context, snapshot) {
              final userData = snapshot.data;
              final userType = userData?['type_utilisateur'] ?? '';

              if (userType == 'passager') {
                return IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PassengerRidesPage(),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.format_align_justify,
                    color: AppColors.mainColor,
                  ),
                  tooltip: 'Mes courses',
                );
              }
              return const SizedBox.shrink();
            },
          ),

          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                NavigationHelper.goto(context, const ProfilePage());
              },
              child: FutureBuilder<Map<String, dynamic>?>(
                future: SessionManager.getUserData(),
                builder: (context, snapshot) {
                  final userData = snapshot.data;
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.mainColor, width: 2),
                    ),
                    child: UserAvatar(
                      avatarUrl: userData?['avatar_url'],
                      size: 35,
                      iconSize: 20,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: userType == 'chauffeur'
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.of(context).size.height -
                        kToolbarHeight -
                        48,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.dashboard_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Tableau de bord',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 32),
                      GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.1,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        children: [
                          _dashboardButton(
                            Icons.directions_car,
                            'Mon véhicule',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const VehiclePage(),
                                ),
                              );
                            },
                          ),
                          _dashboardButton(
                            Icons.map,
                            'Carte',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DriverMapPage(),
                                ),
                              );
                            },
                          ),
                          _dashboardButton(
                            Icons.assignment,
                            'Commandes',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DriverRidesPage(),
                                ),
                              );
                            },
                          ),
                          _dashboardButton(
                            Icons.history,
                            'Historiques',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const DriverCompletedRidesPage(),
                                ),
                              );
                            },
                          ),
                          _dashboardButton(
                            Icons.account_balance_wallet,
                            'Dépôts',
                            onTap: () => _showDepositModal(),
                          ),
                          _dashboardButton(
                            Icons.star,
                            'Mes évaluations',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const DriverEvaluationsPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Card avec GIF
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/card.gif'),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Découvrez Bita Express',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Votre solution de transport rapide et fiable',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Bouton destination
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _showDestinationSearchModal(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.grey[700],
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Quelle est votre destination ?',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Section destinations fréquentes (seulement si il y en a)
                    if (_frequentDestinations.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Destinations fréquentes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Liste des destinations fréquentes (dynamique)
                          ..._frequentDestinations.asMap().entries.map((entry) {
                            final destination = entry.value;
                            final isLast =
                                entry.key == _frequentDestinations.length - 1;

                            return Column(
                              children: [
                                _buildDestinationItem(
                                  icon: Icons.location_on,
                                  title: destination.title,
                                  subtitle: destination.subtitle,
                                  onTap: () => _onFrequentDestinationSelected(
                                    destination,
                                  ),
                                ),
                                if (!isLast) const SizedBox(height: 12),
                              ],
                            );
                          }),
                        ],
                      ),
                    ],

                    // Section "Devenir chauffeur" pour passager
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.mainColor,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.mainColor.withOpacity(0.13),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.emoji_transportation,
                                color: Colors.white,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Envie de devenir chauffeur Bita Express ?',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const MigrateToDriverPage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.mainColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.emoji_transportation,
                                    color: AppColors.mainColor,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Devenir chauffeur',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Color _getButtonColor(String label) {
    switch (label) {
      case 'Mon véhicule':
        return const Color(0xFF2196F3); // Bleu
      case 'Carte':
        return const Color(0xFF4CAF50); // Vert
      case 'Commandes':
        return const Color(0xFFFF9800); // Orange
      case 'Historiques':
        return const Color(0xFF9C27B0); // Violet
      case 'Dépôts':
        return const Color(0xFF00BCD4); // Cyan
      case 'Mes évaluations':
        return const Color(0xFFFFC107); // Jaune/Or
      default:
        return AppColors.primary;
    }
  }

  Widget _dashboardButton(IconData icon, String label, {VoidCallback? onTap}) {
    final buttonColor = _getButtonColor(label);

    return GestureDetector(
      onTap: onTap ?? () {},
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCirc,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: buttonColor.withOpacity(0.2), width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap ?? () {},
              splashColor: buttonColor.withOpacity(0.1),
              highlightColor: buttonColor.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Conteneur de l'icône avec couleur spécifique
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: buttonColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(icon, size: 30, color: buttonColor),
                    ),
                    const SizedBox(height: 16),
                    // Texte du label avec couleur adaptée
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.2,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DestinationSearchModal extends StatefulWidget {
  final ScrollController scrollController;

  const DestinationSearchModal({super.key, required this.scrollController});

  @override
  State<DestinationSearchModal> createState() => _DestinationSearchModalState();
}

class _DestinationSearchModalState extends State<DestinationSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  List<Place> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await LocationService.searchPlaces(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      print('Erreur de recherche: $e');
    }
  }

  void _onDestinationSelected(Place place) async {
    Navigator.pop(context);

    // Récupérer les coordonnées
    final double latitude = place.latitude;
    final double longitude = place.longitude;

    print('Destination sélectionnée depuis la recherche: ${place.displayName}');
    print('Coordonnées originales du Place:');
    print('  Latitude: $latitude');
    print('  Longitude: $longitude');
    print('Place ID: ${place.placeId}');

    // Extraire le titre et sous-titre
    String title = _getShortName(place.displayName);
    String subtitle = _getLocationSummary(place.displayName);

    // Sauvegarder dans les destinations fréquentes
    await FrequentDestinationsService.saveDestination(
      title: title,
      subtitle: subtitle,
      latitude: latitude,
      longitude: longitude,
    );

    // Informer la page parent de recharger les destinations fréquentes
    if (context.mounted) {
      final homeState = context.findAncestorStateOfType<_HomePageState>();
      homeState?._loadFrequentDestinations();
    }

    // Obtenir la position actuelle pour calculer la distance
    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        latitude,
        longitude,
      );

      // Naviguer vers la page de sélection du type de véhicule
      print('Navigation vers VehicleTypeSelectionPage depuis recherche avec:');
      print('  destinationLatitude: $latitude');
      print('  destinationLongitude: $longitude');
      print('  departLatitude: ${position.latitude}');
      print('  departLongitude: ${position.longitude}');
      print('  distanceMeters: $distance');

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleTypeSelectionPage(
              destinationLatitude: latitude,
              destinationLongitude: longitude,
              destinationTitle: title,
              destinationSubtitle: subtitle,
              departLatitude: position.latitude,
              departLongitude: position.longitude,
              distanceMeters: distance,
              durationSeconds:
                  0, // Will be calculated by OSRM in navigation_map
            ),
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de l\'obtention de la position actuelle: $e');
      // Fallback: naviguer directement sans distance
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleTypeSelectionPage(
              destinationLatitude: latitude,
              destinationLongitude: longitude,
              destinationTitle: title,
              destinationSubtitle: subtitle,
              departLatitude: 0,
              departLongitude: 0,
              distanceMeters: 0,
              durationSeconds: 0,
            ),
          ),
        );
      }
    }
  }

  void _openMapModal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapSelectionModal(
          onLocationSelected: (LatLng location, String? addressName) async {
            Navigator.pop(context);
            Navigator.pop(context);

            print('Lieu sélectionné sur la carte: $addressName');
            print(
              'Coordonnées: Latitude: ${location.latitude}, Longitude: ${location.longitude}',
            );

            // Sauvegarder dans les destinations fréquentes
            String shortTitle = _getShortLocationName(
              addressName ?? 'Lieu sélectionné',
            );
            String shortSubtitle = _getLocationSummary(
              addressName ?? 'Position géographique',
            );

            await FrequentDestinationsService.saveDestination(
              title: shortTitle,
              subtitle: shortSubtitle,
              latitude: location.latitude,
              longitude: location.longitude,
            );

            // Recharger les destinations fréquentes
            final homeState = context.findAncestorStateOfType<_HomePageState>();
            homeState?._loadFrequentDestinations();

            // Obtenir la position actuelle pour calculer la distance
            try {
              final Position position = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high,
              );

              double distance = Geolocator.distanceBetween(
                position.latitude,
                position.longitude,
                location.latitude,
                location.longitude,
              );

              // Naviguer vers la page de sélection du type de véhicule
              print(
                'Navigation vers VehicleTypeSelectionPage depuis carte avec:',
              );
              print('  destinationLatitude: ${location.latitude}');
              print('  destinationLongitude: ${location.longitude}');
              print('  departLatitude: ${position.latitude}');
              print('  departLongitude: ${position.longitude}');
              print('  distanceMeters: $distance');

              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VehicleTypeSelectionPage(
                      destinationLatitude: location.latitude,
                      destinationLongitude: location.longitude,
                      destinationTitle: shortTitle,
                      destinationSubtitle: shortSubtitle,
                      departLatitude: position.latitude,
                      departLongitude: position.longitude,
                      distanceMeters: distance,
                      durationSeconds: 0,
                    ),
                  ),
                );
              }
            } catch (e) {
              print('Erreur lors de l\'obtention de la position actuelle: $e');
              // Fallback: naviguer directement sans distance
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VehicleTypeSelectionPage(
                      destinationLatitude: location.latitude,
                      destinationLongitude: location.longitude,
                      destinationTitle: shortTitle,
                      destinationSubtitle: shortSubtitle,
                      departLatitude: 0,
                      departLongitude: 0,
                      distanceMeters: 0,
                      durationSeconds: 0,
                    ),
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          // Handle du modal
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Titre
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Où souhaitez-vous aller ?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Barre de recherche avec bouton carte
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Rechercher une destination...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchResults = [];
                                  });
                                },
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.grey,
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: AppColors.mainColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.mainColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _openMapModal,
                    icon: const Icon(
                      Icons.map_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Résultats de recherche
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_searchResults.isEmpty &&
                    _searchController.text.isNotEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun résultat trouvé',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Essayez avec un autre terme de recherche',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_searchController.text.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Recherchez votre destination',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tapez le nom d\'un lieu, d\'une ville ou d\'une adresse',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ..._searchResults.map(
                    (place) => _buildSearchResultItem(place),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(Place place) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.mainColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.location_on, color: AppColors.mainColor, size: 22),
        ),
        title: Text(
          _getShortName(place.displayName),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          _getLocationSummary(place.displayName),
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey[400],
          size: 16,
        ),
        onTap: () => _onDestinationSelected(place),
      ),
    );
  }

  String _getShortName(String displayName) {
    // Extraire seulement le nom principal du lieu
    List<String> parts = displayName.split(',');
    String shortName = parts.isNotEmpty ? parts[0].trim() : displayName;

    // Limiter à 24 caractères maximum pour le titre
    if (shortName.length > 24) {
      shortName = '${shortName.substring(0, 21)}...';
    }

    return shortName;
  }

  String _getLocationSummary(String displayName) {
    // Extraire ville et pays seulement
    List<String> parts = displayName.split(',');
    String summary;

    if (parts.length >= 2) {
      // Prendre les 2 dernières parties (ville, pays généralement)
      String city = parts[parts.length - 2].trim();
      String country = parts[parts.length - 1].trim();
      summary = '$city, $country';
    } else if (parts.isNotEmpty) {
      summary = parts[0].trim();
    } else {
      summary = displayName;
    }

    // Limiter à 27 caractères maximum pour le sous-titre
    if (summary.length > 27) {
      summary = '${summary.substring(0, 24)}...';
    }

    return summary;
  }

  String _getShortLocationName(String locationName) {
    List<String> parts = locationName.split(',');
    String shortName = parts.isNotEmpty ? parts[0].trim() : locationName;

    // Limiter à 24 caractères maximum
    if (shortName.length > 24) {
      shortName = '${shortName.substring(0, 21)}...';
    }

    return shortName;
  }
}

class MapSelectionModal extends StatefulWidget {
  final Function(LatLng location, String? addressName) onLocationSelected;

  const MapSelectionModal({super.key, required this.onLocationSelected});

  @override
  State<MapSelectionModal> createState() => _MapSelectionModalState();
}

class _MapSelectionModalState extends State<MapSelectionModal> {
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();
  String? _selectedAddress;
  bool _isLoadingAddress = false;

  // Position par défaut : Abidjan, Côte d'Ivoire
  final LatLng _defaultCenter = LatLng(5.3600, -4.0083);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title: const Text(
          'Choisir sur la carte',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_selectedLocation != null)
            TextButton(
              onPressed: () {
                widget.onLocationSelected(_selectedLocation!, _selectedAddress);
              },
              child: Text(
                'Confirmer',
                style: TextStyle(
                  color: AppColors.mainColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Carte FlutterMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 12.0,
              onTap: (tapPosition, point) async {
                setState(() {
                  _selectedLocation = point;
                  _isLoadingAddress = true;
                  _selectedAddress = null;
                });

                // Géocodage inverse pour obtenir l'adresse
                try {
                  final address = await LocationService.reverseGeocode(
                    point.latitude,
                    point.longitude,
                  );
                  setState(() {
                    _selectedAddress = address;
                    _isLoadingAddress = false;
                  });
                } catch (e) {
                  setState(() {
                    _selectedAddress = 'Adresse non trouvée';
                    _isLoadingAddress = false;
                  });
                  print('Erreur géocodage inverse: $e');
                }
              },
            ),
            children: [
              // Couche de tuiles OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.bita_express_new',
                maxZoom: 19,
              ),

              // Marqueur pour la position sélectionnée
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 60,
                      height: 60,
                      child: Icon(
                        Icons.location_on,
                        color: AppColors.mainColor,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Instructions en haut
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.touch_app, color: AppColors.mainColor, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Touchez la carte pour sélectionner votre destination',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Panneau d'informations en bas
          if (_selectedLocation != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.mainColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: AppColors.mainColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Position sélectionnée',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_isLoadingAddress)
                      const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Recherche de l\'adresse...'),
                        ],
                      )
                    else
                      Text(
                        _selectedAddress ?? 'Adresse inconnue',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 8),
                    Text(
                      'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                      'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontFamily: 'monospace',
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
}

// Ajout du widget/page pour devenir chauffeur
class MigrateToDriverPage extends StatefulWidget {
  const MigrateToDriverPage({super.key});

  @override
  State<MigrateToDriverPage> createState() => _MigrateToDriverPageState();
}

class _MigrateToDriverPageState extends State<MigrateToDriverPage> {
  String? _base64Permis;
  bool _loading = false;

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery);

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final base64String = base64Encode(bytes);
        setState(() {
          _base64Permis = 'data:image/png;base64,$base64String';
        });
      }
    } catch (e) {
      print('Erreur lors de la sélection de l\'image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la sélection de l\'image'),
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_base64Permis == null) return;

    setState(() {
      _loading = true;
    });

    try {
      // Récupérer le token
      final token = await SessionManager.getToken();
      if (token == null) {
        throw Exception('Token non trouvé');
      }

      // Appel API
      final response = await ApiService.migrateToDriver(
        token: token,
        permisBase64: _base64Permis!,
      );

      if (response.success) {
        // Mise à jour du type utilisateur dans la session
        final userData = await SessionManager.getUserData();
        if (userData != null) {
          userData['type_utilisateur'] = 'chauffeur';
          await SessionManager.notifyUserDataUpdated(userData);
        }

        setState(() {
          _loading = false;
        });

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(response.message)));
        }
      } else {
        setState(() {
          _loading = false;
        });

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(response.message)));
        }
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devenir chauffeur'),
        backgroundColor: AppColors.mainColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Text(
              'Pour devenir chauffeur, veuillez télécharger une photo de votre permis de conduire.',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.mainColor, width: 2),
                ),
                child: _base64Permis == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.upload_file,
                            color: AppColors.mainColor,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Télécharger permis',
                            style: TextStyle(fontSize: 15),
                          ),
                        ],
                      )
                    : Icon(Icons.check_circle, color: Colors.green, size: 64),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _base64Permis == null || _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Valider et devenir chauffeur',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
