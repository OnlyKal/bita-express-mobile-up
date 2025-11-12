import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FrequentDestination {
  final String title;
  final String subtitle;
  final double latitude;
  final double longitude;
  final DateTime lastSelected;

  FrequentDestination({
    required this.title,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
    required this.lastSelected,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'latitude': latitude,
      'longitude': longitude,
      'lastSelected': lastSelected.millisecondsSinceEpoch,
    };
  }

  factory FrequentDestination.fromJson(Map<String, dynamic> json) {
    return FrequentDestination(
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      lastSelected: DateTime.fromMillisecondsSinceEpoch(
        json['lastSelected'] ?? 0,
      ),
    );
  }

  @override
  String toString() {
    return 'FrequentDestination(title: $title, subtitle: $subtitle, lat: $latitude, lng: $longitude)';
  }
}

class FrequentDestinationsService {
  static const String _storageKey = 'frequent_destinations';
  static const int _maxDestinations = 3;

  /// Sauvegarder une nouvelle destination
  static Future<void> saveDestination({
    required String title,
    required String subtitle,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Récupérer les destinations existantes
      List<FrequentDestination> destinations = await getFrequentDestinations();

      // Limiter le titre à 24 caractères et sous-titre à 27 caractères
      String shortTitle = title.length > 24
          ? '${title.substring(0, 21)}...'
          : title;
      String shortSubtitle = subtitle.length > 27
          ? '${subtitle.substring(0, 24)}...'
          : subtitle;

      // Créer la nouvelle destination
      final newDestination = FrequentDestination(
        title: shortTitle,
        subtitle: shortSubtitle,
        latitude: latitude,
        longitude: longitude,
        lastSelected: DateTime.now(),
      );

      // Supprimer la destination si elle existe déjà (pour éviter les doublons)
      destinations.removeWhere(
        (dest) =>
            dest.title.toLowerCase() == title.toLowerCase() &&
            dest.subtitle.toLowerCase() == subtitle.toLowerCase(),
      );

      // Ajouter la nouvelle destination au début de la liste
      destinations.insert(0, newDestination);

      // Garder seulement les 3 dernières
      if (destinations.length > _maxDestinations) {
        destinations = destinations.take(_maxDestinations).toList();
      }

      // Sauvegarder dans SharedPreferences
      final jsonList = destinations.map((dest) => dest.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));

      print('Destination sauvegardée: $title');
      print(
        '  Coordonnées sauvegardées: Lat=${newDestination.latitude}, Lng=${newDestination.longitude}',
      );
      print('Total destinations fréquentes: ${destinations.length}');
    } catch (e) {
      print('Erreur lors de la sauvegarde de destination: $e');
    }
  }

  /// Récupérer les destinations fréquentes
  static Future<List<FrequentDestination>> getFrequentDestinations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null || jsonString.isEmpty) {
        return []; // Retourner une liste vide au lieu des destinations par défaut
      }

      final jsonList = json.decode(jsonString) as List<dynamic>;
      final destinations = jsonList
          .map((json) => FrequentDestination.fromJson(json))
          .toList();

      print('Destinations chargées:');
      for (var dest in destinations) {
        print('  ${dest.title}: Lat=${dest.latitude}, Lng=${dest.longitude}');
      }

      return destinations.take(_maxDestinations).toList();
    } catch (e) {
      print('Erreur lors du chargement des destinations: $e');
      return []; // Retourner une liste vide en cas d'erreur
    }
  }

  /// Effacer toutes les destinations fréquentes
  static Future<void> clearFrequentDestinations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      print('Destinations fréquentes supprimées');
    } catch (e) {
      print('Erreur lors de la suppression des destinations: $e');
    }
  }
}
