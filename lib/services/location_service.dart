import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place.dart';

class LocationService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';

  /// Recherche des lieux basés sur une requête textuelle
  static Future<List<Place>> searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final encodedQuery = Uri.encodeComponent(query.trim());
      final url = '$_baseUrl/search?q=$encodedQuery&format=json&limit=5';

      print('Recherche de lieux: $url');

      final response = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'BitaExpress/1.0.0'})
          .timeout(const Duration(seconds: 10));

      print('Status code: ${response.statusCode}');
      print('Response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Place.fromJson(json)).toList();
      } else {
        print('Erreur de requête: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Erreur lors de la recherche de lieux: $e');
      return [];
    }
  }

  /// Recherche inverse pour obtenir l'adresse à partir des coordonnées
  static Future<String?> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      final url = '$_baseUrl/reverse?lat=$latitude&lon=$longitude&format=json';

      final response = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'BitaExpress/1.0.0'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name']?.toString();
      }
      return null;
    } catch (e) {
      print('Erreur lors du géocodage inverse: $e');
      return null;
    }
  }
}
