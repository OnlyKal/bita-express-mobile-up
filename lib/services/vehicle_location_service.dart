import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../api.dart';
import '../session.dart';

class VehicleLocationService {
  static Timer? _locationTimer;
  static bool _isRunning = false;
  static const int _intervalSeconds = 4; // Intervalle de 4 secondes

  /// Démarre le suivi automatique de la position du véhicule
  static Future<void> startLocationTracking() async {
    if (_isRunning) {
      print('Le suivi de localisation est déjà en cours');
      return;
    }

    // Vérifier les permissions de géolocalisation
    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) {
      print('Permission de géolocalisation refusée');
      return;
    }

    // Récupérer les informations de session
    final token = await SessionManager.getToken();
    final vehicleId = await _getVehicleId();

    if (token == null || vehicleId == null) {
      print('Token ou ID véhicule manquant pour le suivi de localisation');
      return;
    }

    _isRunning = true;
    print('Démarrage du suivi de localisation du véhicule $vehicleId');

    // Configurer le timer pour mettre à jour la position toutes les 4 secondes
    _locationTimer = Timer.periodic(Duration(seconds: _intervalSeconds), (
      timer,
    ) async {
      try {
        await _updateVehicleLocation(token, vehicleId);
      } catch (e) {
        print('Erreur lors de la mise à jour de la position: $e');
      }
    });

    // Première mise à jour immédiate
    await _updateVehicleLocation(token, vehicleId);
  }

  /// Arrête le suivi automatique de la position
  static void stopLocationTracking() {
    if (_locationTimer != null) {
      _locationTimer!.cancel();
      _locationTimer = null;
      _isRunning = false;
      print('Suivi de localisation arrêté');
    }
  }

  /// Vérifie si le suivi est en cours
  static bool get isRunning => _isRunning;

  /// Met à jour la position du véhicule
  static Future<void> _updateVehicleLocation(
    String token,
    int vehicleId,
  ) async {
    try {
      // Obtenir la position actuelle
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Envoyer la mise à jour au serveur
      final response = await ApiService.updateVehicleLocation(
        token: token,
        vehicleId: vehicleId,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (response.success) {
        print(
          'Position mise à jour: ${position.latitude}, ${position.longitude}',
        );
      } else {
        print('Erreur mise à jour position: ${response.message}');
      }
    } catch (e) {
      print('Erreur lors de la récupération de la position: $e');
    }
  }

  /// Vérifie et demande les permissions de géolocalisation
  static Future<bool> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Vérifier si le service de géolocalisation est activé
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Les services de géolocalisation sont désactivés');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Permissions de géolocalisation refusées');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Permissions de géolocalisation définitivement refusées');
      return false;
    }

    return true;
  }

  /// Récupère l'ID du véhicule depuis l'API
  static Future<int?> _getVehicleId() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return null;

      final response = await ApiService.getVehicle(token);
      if (response.success && response.data != null) {
        // Si c'est un seul véhicule
        if (response.data is Map<String, dynamic>) {
          return response.data['id'];
        }
        // Si c'est une liste de véhicules, prendre le premier
        if (response.data is List && response.data.isNotEmpty) {
          return response.data[0]['id'];
        }
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'ID véhicule: $e');
      return null;
    }
  }

  /// Démarre le suivi automatiquement si l'utilisateur est un chauffeur
  static Future<void> startIfDriver() async {
    final userData = await SessionManager.getUserData();
    if (userData != null && userData['type_utilisateur'] == 'chauffeur') {
      await startLocationTracking();
    }
  }

  /// Arrête le suivi si l'utilisateur n'est plus chauffeur
  static void stopIfNotDriver() async {
    final userData = await SessionManager.getUserData();
    if (userData == null || userData['type_utilisateur'] != 'chauffeur') {
      stopLocationTracking();
    }
  }
}
