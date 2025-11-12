import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

String flextoken =
    "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJcL2xvZ2luIiwicm9sZXMiOlsiTUVSQ0hBTlQiXSwiZXhwIjoxODE1NTcyMDYyLCJzdWIiOiI0MjY1OGVlNmE5MDYxOTkxZDM3NmM1ZDNiM2U1NGFhZSJ9.YcwgTZZbw5HBV_JV6VaHHE1KDa_r-MeuJD-fgYyl6eo";

class ApiService {
  // Configuration de l'API
  static const String baseUrl = AppConfig.apiBaseUrl;
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Méthode privée pour vérifier si le login est un email
  static bool _isEmailFormat(String login) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(login);
  }

  /// Modèle de réponse API
  static Map<String, String> getAuthHeaders(String token) {
    return {
      ...headers,
      'Authorization': token, // Le token contient déjà "Bearer "
    };
  }

  /// Connexion utilisateur (email ou username + password)
  static Future<ApiResponse> signIn({
    required String login, // peut être email ou username
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/user/signin/');

      // Déterminer si c'est un email ou un username
      final bool isEmail = _isEmailFormat(login);

      final Map<String, String> bodyData = {'password': password};

      // Ajouter le champ approprié selon le format
      if (isEmail) {
        bodyData['email'] = login;
      } else {
        bodyData['username'] = login;
      }

      final body = json.encode(bodyData);

      print('Envoi de la requête de connexion vers: $url');
      print('Body: $body');
      print('Type de login détecté: ${isEmail ? "Email" : "Username"}');

      final response = await http.post(url, headers: headers, body: body);

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: responseData['status'] ?? false,
          message: responseData['message'] ?? 'Connexion réussie',
          data: responseData,
        );
      } else {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Erreur de connexion',
          data: responseData,
        );
      }
    } catch (e) {
      print('Erreur lors de l\'appel API: $e');
      return ApiResponse(
        success: false,
        message: 'Erreur de connexion: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Vérification du token
  static Future<ApiResponse> verifyToken(String token) async {
    try {
      final url = Uri.parse('$baseUrl/user/verify-token/');

      final response = await http.get(url, headers: getAuthHeaders(token));

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: 'Token valide',
          data: responseData,
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Token invalide',
          data: responseData,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erreur de vérification: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Inscription utilisateur
  static Future<ApiResponse> signUp({
    required String username,
    required String email,
    required String telephone,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/user/signup/');

      final Map<String, String> bodyData = {
        'username': username,
        'email': email,
        'telephone': telephone,
        'password': password,
      };

      final body = json.encode(bodyData);

      print('Envoi de la requête d\'inscription vers: $url');
      print('Body: $body');

      final response = await http.post(url, headers: headers, body: body);

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(
          success: responseData['status'] ?? false,
          message: responseData['message'] ?? 'Inscription réussie',
          data: responseData,
        );
      } else {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Erreur lors de l\'inscription',
          data: responseData,
        );
      }
    } catch (e) {
      print('Erreur lors de l\'appel API: $e');
      return ApiResponse(
        success: false,
        message: 'Erreur d\'inscription: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Déconnexion
  static Future<ApiResponse> signOut(String token) async {
    try {
      final url = Uri.parse('$baseUrl/user/signout/');

      final response = await http.post(url, headers: getAuthHeaders(token));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return ApiResponse(
          success: true,
          message: 'Déconnexion réussie',
          data: responseData,
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Erreur lors de la déconnexion',
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Erreur de déconnexion: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Migration vers chauffeur
  static Future<ApiResponse> migrateToDriver({
    required String token,
    required String permisBase64,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/user/migrate/driver/');

      final Map<String, String> bodyData = {
        'type_utilisateur': 'chauffeur',
        'permis': permisBase64,
      };

      final body = json.encode(bodyData);

      print('Envoi de la requête de migration vers: $url');
      print(
        'Body: ${bodyData.keys.toList()}',
      ); // Log sans le base64 pour éviter de polluer

      final response = await http.post(
        url,
        headers: getAuthHeaders(token),
        body: body,
      );

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: responseData['status'] ?? true,
          message: responseData['message'] ?? 'Migration réussie',
          data: responseData,
        );
      } else {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Erreur lors de la migration',
          data: responseData,
        );
      }
    } catch (e) {
      print('Erreur lors de l\'appel API de migration: $e');
      return ApiResponse(
        success: false,
        message: 'Erreur de migration: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Ajouter/Modifier un véhicule
  static Future<ApiResponse> addVehicle({
    required String token,
    required String marque,
    required String modele,
    required String plaque,
    required String couleur,
    required String typeVehicule,
    required String confort,
    required int capacite,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/vehicule/add/');

      final Map<String, dynamic> bodyData = {
        'marque': marque,
        'modele': modele,
        'plaque': plaque,
        'couleur': couleur,
        'type_vehicule': typeVehicule,
        'confort': confort,
        'capacite': capacite,
        'latitude': latitude,
        'longitude': longitude,
      };

      final body = json.encode(bodyData);

      print('Envoi de la requête d\'ajout véhicule vers: $url');
      print('Body: $body');

      final response = await http.post(
        url,
        headers: getAuthHeaders(token),
        body: body,
      );

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(
          success: responseData['status'] ?? true,
          message: responseData['message'] ?? 'Véhicule ajouté avec succès',
          data: responseData,
        );
      } else {
        return ApiResponse(
          success: false,
          message:
              responseData['message'] ?? 'Erreur lors de l\'ajout du véhicule',
          data: responseData,
        );
      }
    } catch (e) {
      print('Erreur lors de l\'appel API d\'ajout véhicule: $e');
      return ApiResponse(
        success: false,
        message: 'Erreur d\'ajout véhicule: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Récupérer le véhicule du chauffeur
  static Future<ApiResponse> getVehicle(String token) async {
    try {
      final url = Uri.parse('$baseUrl/vehicule/');

      final response = await http.get(url, headers: getAuthHeaders(token));

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      final dynamic responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: 'Véhicule récupéré avec succès',
          data: responseData,
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Erreur lors de la récupération du véhicule',
          data: responseData,
        );
      }
    } catch (e) {
      print('Erreur lors de l\'appel API de récupération véhicule: $e');
      return ApiResponse(
        success: false,
        message: 'Erreur de récupération véhicule: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Récupérer la liste de tous les véhicules disponibles (pour les passagers)
  static Future<ApiResponse> getVehiclesList(String token) async {
    try {
      final url = Uri.parse('$baseUrl/vehicule/list/');

      final response = await http.get(url, headers: getAuthHeaders(token));

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      final dynamic responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: 'Liste des véhicules récupérée avec succès',
          data: responseData,
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Erreur lors de la récupération de la liste des véhicules',
          data: responseData,
        );
      }
    } catch (e) {
      print('Erreur lors de l\'appel API de récupération liste véhicules: $e');
      return ApiResponse(
        success: false,
        message: 'Erreur de récupération liste véhicules: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Mettre à jour un véhicule spécifique
  static Future<ApiResponse> updateVehicle({
    required String token,
    required int vehicleId,
    required String marque,
    required String modele,
    required String plaque,
    required String couleur,
    required String typeVehicule,
    required String confort,
    required int capacite,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/vehicule/$vehicleId/update/');

      final Map<String, dynamic> bodyData = {
        'marque': marque,
        'modele': modele,
        'plaque': plaque,
        'couleur': couleur,
        'type_vehicule': typeVehicule,
        'confort': confort,
        'capacite': capacite,
        'latitude': latitude,
        'longitude': longitude,
      };

      final body = json.encode(bodyData);

      print('Envoi de la requête de mise à jour véhicule vers: $url');
      print('Body: $body');

      final response = await http.put(
        url,
        headers: getAuthHeaders(token),
        body: body,
      );

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: responseData['status'] ?? true,
          message: responseData['message'] ?? 'Véhicule mis à jour avec succès',
          data: responseData,
        );
      } else {
        return ApiResponse(
          success: false,
          message:
              responseData['message'] ??
              'Erreur lors de la mise à jour du véhicule',
          data: responseData,
        );
      }
    } catch (e) {
      print('Erreur lors de l\'appel API de mise à jour véhicule: $e');
      return ApiResponse(
        success: false,
        message: 'Erreur de mise à jour véhicule: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Mettre à jour uniquement les coordonnées d'un véhicule
  static Future<ApiResponse> updateVehicleLocation({
    required String token,
    required int vehicleId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/vehicule/$vehicleId/update/');

      final Map<String, dynamic> bodyData = {
        'latitude': latitude,
        'longitude': longitude,
      };

      final body = json.encode(bodyData);

      print(
        'Mise à jour coordonnées véhicule $vehicleId: lat=$latitude, lng=$longitude',
      );

      final response = await http.put(
        url,
        headers: getAuthHeaders(token),
        body: body,
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: responseData['status'] ?? true,
          message: 'Coordonnées mises à jour',
          data: responseData,
        );
      } else {
        return ApiResponse(
          success: false,
          message:
              responseData['message'] ??
              'Erreur lors de la mise à jour des coordonnées',
          data: responseData,
        );
      }
    } catch (e) {
      print('Erreur lors de la mise à jour des coordonnées: $e');
      return ApiResponse(
        success: false,
        message: 'Erreur de mise à jour coordonnées: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Calcule la tarification pour un trajet
  static Future<ApiResponse> calculatePricing({
    required String token,
    required String typeVehicule,
    required String confort,
    required double distanceKm,
    required double dureeMin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tarification/'),
        headers: getAuthHeaders(token),
        body: jsonEncode({
          'type_vehicule': typeVehicule,
          'confort': confort,
          'distance_km': distanceKm,
          'duree_min': dureeMin,
        }),
      );

      print('Réponse tarification - Status: ${response.statusCode}');
      print('Réponse tarification - Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: 'Tarification calculée avec succès',
          data: responseData,
        );
      } else {
        return ApiResponse(
          success: false,
          message:
              responseData['error'] ??
              responseData['message'] ??
              'Erreur lors du calcul de la tarification',
          data: responseData,
        );
      }
    } catch (e) {
      print('Erreur lors du calcul de la tarification: $e');
      return ApiResponse(
        success: false,
        message: 'Erreur de calcul tarification: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Créer une nouvelle course (demande de course par le passager)
  static Future<ApiResponse> createRide({
    required String token,
    required int passagerId,
    required double departLatitude,
    required double departLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
    required double distance,
    required double dureeEstimee,
    required double prixEstime,
  }) async {
    try {
      print('=== CRÉATION COURSE ===');
      print('  Passager ID: $passagerId');
      print('  Départ: ($departLatitude, $departLongitude)');
      print('  Destination: ($destinationLatitude, $destinationLongitude)');
      print('  Distance: ${distance}m');
      print('  Durée estimée: ${dureeEstimee}s');
      print('  Prix estimé: ${prixEstime}FC');
      print('  Token: ${token.substring(0, 20)}...');

      final Map<String, dynamic> bodyData = {
        'passager': passagerId,
        'depart_latitude': departLatitude,
        'depart_longitude': departLongitude,
        'destination_latitude': destinationLatitude,
        'destination_longitude': destinationLongitude,
        'distance': distance,
        'duree_estimee': dureeEstimee,
        'prix_estime': prixEstime,
      };

      print('  Body JSON: ${jsonEncode(bodyData)}');

      final response = await http.post(
        Uri.parse('$baseUrl/course/command/'),
        headers: getAuthHeaders(token),
        body: jsonEncode(bodyData),
      );

      print('=== RÉPONSE COURSE ===');
      print('  Status: ${response.statusCode}');
      print('  Headers: ${response.headers}');
      print('  Body: ${response.body}');

      if (response.body.isEmpty) {
        throw Exception('Réponse vide du serveur');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('  ✅ Course créée avec succès');
        return ApiResponse(
          success: responseData['status'] ?? true,
          message: responseData['message'] ?? 'Course créée avec succès',
          data: responseData['data'],
        );
      } else {
        print('  ❌ Erreur HTTP: ${response.statusCode}');
        return ApiResponse(
          success: false,
          message:
              responseData['error'] ??
              responseData['message'] ??
              'Erreur lors de la création de la course (${response.statusCode})',
          data: responseData,
        );
      }
    } catch (e) {
      print('❌ ERREUR CRÉATION COURSE: $e');
      return ApiResponse(
        success: false,
        message: 'Erreur de création course: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Récupérer les courses du passager connecté
  static Future<ApiResponse> getPassengerRides(String token) async {
    try {
      print('Récupération des courses du passager...');

      final response = await http.get(
        Uri.parse('$baseUrl/course/passager/'),
        headers: getAuthHeaders(token),
      );

      print('Réponse courses passager - Status: ${response.statusCode}');
      print('Réponse courses passager - Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: 'Courses récupérées avec succès',
          data: responseData,
        );
      } else {
        return ApiResponse(
          success: false,
          message:
              responseData['error'] ??
              responseData['message'] ??
              'Erreur lors de la récupération des courses',
          data: responseData,
        );
      }
    } catch (e) {
      print('Erreur lors de la récupération des courses: $e');
      return ApiResponse(
        success: false,
        message: 'Erreur de récupération courses: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Récupérer les courses du chauffeur connecté
  static Future<ApiResponse> getDriverRides(String token) async {
    try {
      print('=== APPEL API COURSES CHAUFFEUR ===');
      print('URL: $baseUrl/course/chauffeur/');
      print('Token: ${token.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse('$baseUrl/course/chauffeur/'),
        headers: getAuthHeaders(token),
      );

      print('=== RÉPONSE API CHAUFFEUR ===');
      print('Status Code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');

      if (response.body.isEmpty) {
        print('❌ Réponse vide du serveur');
        return ApiResponse(
          success: false,
          message: 'Réponse vide du serveur',
          data: null,
        );
      }

      final responseData = jsonDecode(response.body);
      print('Données parsées: $responseData');
      print('Type de données: ${responseData.runtimeType}');

      if (response.statusCode == 200) {
        print('✅ Succès - retour des données');
        return ApiResponse(
          success: true,
          message: 'Courses récupérées avec succès',
          data: responseData,
        );
      } else {
        print('❌ Erreur HTTP ${response.statusCode}');
        return ApiResponse(
          success: false,
          message:
              responseData['error'] ??
              responseData['message'] ??
              'Erreur lors de la récupération des courses (${response.statusCode})',
          data: responseData,
        );
      }
    } catch (e) {
      print('💥 ERREUR EXCEPTION: $e');
      return ApiResponse(
        success: false,
        message: 'Erreur de récupération courses: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Récupérer les courses disponibles (en attente) pour les chauffeurs
  static Future<ApiResponse> getAvailableRides(String token) async {
    try {
      print('Récupération des courses disponibles...');

      final response = await http.get(
        Uri.parse('$baseUrl/course/disponibles/'),
        headers: getAuthHeaders(token),
      );

      print('Réponse courses disponibles - Status: ${response.statusCode}');
      print('Réponse courses disponibles - Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: 'Courses disponibles récupérées avec succès',
          data: responseData,
        );
      } else {
        return ApiResponse(
          success: false,
          message:
              responseData['error'] ??
              responseData['message'] ??
              'Erreur lors de la récupération des courses disponibles',
          data: responseData,
        );
      }
    } catch (e) {
      print('Erreur lors de la récupération des courses disponibles: $e');
      return ApiResponse(
        success: false,
        message: 'Erreur de récupération courses disponibles: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Accepter une course (pour le chauffeur)
  static Future<ApiResponse> acceptRide({
    required String token,
    required int rideId,
    required int chauffeurId,
    required int vehiculeId,
  }) async {
    try {
      print('Acceptation de la course $rideId...');
      print('  Chauffeur ID: $chauffeurId (type: ${chauffeurId.runtimeType})');
      print('  Véhicule ID: $vehiculeId (type: ${vehiculeId.runtimeType})');

      final Map<String, dynamic> bodyData = {
        'chauffeur': chauffeurId,
        'vehicule': vehiculeId,
      };

      print('  Body JSON: ${jsonEncode(bodyData)}');

      final response = await http.put(
        Uri.parse('$baseUrl/course/$rideId/accept/'),
        headers: getAuthHeaders(token),
        body: jsonEncode(bodyData),
      );

      print('Réponse acceptation course - Status: ${response.statusCode}');
      print('Réponse acceptation course - Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: responseData['status'] ?? true,
          message: responseData['message'] ?? 'Course acceptée avec succès',
          data: responseData['data'],
        );
      } else {
        return ApiResponse(
          success: false,
          message:
              responseData['error'] ??
              responseData['message'] ??
              'Erreur lors de l\'acceptation de la course',
          data: responseData,
        );
      }
    } catch (e) {
      print('Erreur lors de l\'acceptation de la course: $e');
      return ApiResponse(
        success: false,
        message: 'Erreur d\'acceptation course: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Terminer une course
  static Future<ApiResponse> finishRide({
    required String token,
    required int rideId,
  }) async {
    try {
      print('Fin de la course $rideId...');

      final response = await http.put(
        Uri.parse('$baseUrl/course/$rideId/finish/'),
        headers: getAuthHeaders(token),
      );

      print('Réponse fin course - Status: ${response.statusCode}');
      print('Réponse fin course - Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: responseData['status'] ?? true,
          message: responseData['message'] ?? 'Course terminée avec succès',
          data: responseData['data'],
        );
      } else {
        return ApiResponse(
          success: false,
          message:
              responseData['error'] ??
              responseData['message'] ??
              'Erreur lors de la fin de la course',
          data: responseData,
        );
      }
    } catch (e) {
      print('Erreur lors de la fin de la course: $e');
      return ApiResponse(
        success: false,
        message: 'Erreur de fin course: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Annuler une course (pour le chauffeur ou le passager)
  static Future<ApiResponse> cancelRide({
    required String token,
    required int rideId,
  }) async {
    try {
      print('Annulation de la course $rideId...');

      final response = await http.put(
        Uri.parse('$baseUrl/course/$rideId/cancel/'),
        headers: getAuthHeaders(token),
      );

      print('Réponse annulation course - Status: ${response.statusCode}');
      print('Réponse annulation course - Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: responseData['status'] ?? true,
          message: responseData['message'] ?? 'Course annulée avec succès',
          data: responseData['data'],
        );
      } else {
        return ApiResponse(
          success: false,
          message:
              responseData['error'] ??
              responseData['message'] ??
              'Erreur lors de l\'annulation de la course',
          data: responseData,
        );
      }
    } catch (e) {
      print('Erreur lors de l\'annulation de la course: $e');
      return ApiResponse(
        success: false,
        message: 'Erreur d\'annulation course: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Récupérer les courses terminées du chauffeur connecté
  static Future<ApiResponse> getDriverCompletedRides(String token) async {
    try {
      print('=== APPEL API COURSES TERMINÉES CHAUFFEUR ===');
      print('URL: $baseUrl/course/chauffeur/terminee/');
      print('Token: ${token.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse('$baseUrl/course/chauffeur/terminee/'),
        headers: getAuthHeaders(token),
      );

      print('=== RÉPONSE API COURSES TERMINÉES ===');
      print('Status Code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');

      if (response.body.isEmpty) {
        print('❌ Réponse vide du serveur');
        return ApiResponse(
          success: false,
          message: 'Réponse vide du serveur',
          data: null,
        );
      }

      final responseData = jsonDecode(response.body);
      print('Données parsées: $responseData');
      print('Type de données: ${responseData.runtimeType}');

      if (response.statusCode == 200) {
        print('✅ Succès - retour des données courses terminées');
        return ApiResponse(
          success: true,
          message: 'Courses terminées récupérées avec succès',
          data: responseData,
        );
      } else {
        print('❌ Erreur HTTP ${response.statusCode}');
        return ApiResponse(
          success: false,
          message:
              responseData['error'] ??
              responseData['message'] ??
              'Erreur lors de la récupération des courses terminées (${response.statusCode})',
          data: responseData,
        );
      }
    } catch (e) {
      print('💥 ERREUR EXCEPTION COURSES TERMINÉES: $e');
      return ApiResponse(
        success: false,
        message: 'Erreur de récupération courses terminées: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Créer une transaction de paiement FlexPay
  static Future<ApiResponse> createPayment({
    required String token,
    required String phone,
    required String reference,
    required double amount,
    required String currency,
    required String callbackUrl,
    int type = 1, // 1 = mobile money, 2 = carte bancaire
  }) async {
    try {
      final Map<String, String> bodyData = {
        'merchant': 'NEPA_RDC',
        'type': type.toString(),
        'phone': phone,
        'reference': reference,
        'amount': amount.toString(),
        'currency': currency,
        'callbackUrl': callbackUrl,
      };
      final response = await http.post(
        Uri.parse('https://backend.flexpay.cd/api/rest/v1/paymentService'),
        headers: getAuthHeaders(flextoken),
        body: jsonEncode(bodyData),
      );

      print('=== RÉPONSE CRÉATION PAIEMENT ===');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.body.isEmpty) {
        throw Exception('Réponse vide du serveur FlexPay');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Transaction FlexPay créée avec succès');
        return ApiResponse(
          success: true,
          message: 'Transaction créée avec succès',
          data: responseData,
        );
      } else {
        print('❌ Erreur création transaction FlexPay');
        return ApiResponse(
          success: false,
          message:
              responseData['message'] ??
              'Erreur lors de la création du paiement',
          data: responseData,
        );
      }
    } catch (e) {
      print('💥 ERREUR CRÉATION PAIEMENT FLEXPAY: $e');
      return ApiResponse(
        success: false,
        message: 'Erreur de création paiement: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Vérifier le statut d'une transaction FlexPay
  static Future<ApiResponse> checkPaymentStatus({
    required String token,
    required String orderNumber,
  }) async {
    try {
      print('=== VÉRIFICATION PAIEMENT FLEXPAY ===');
      print('Order Number: $orderNumber');

      final response = await http.get(
        Uri.parse('https://backend.flexpay.cd/api/rest/v1/check/$orderNumber'),
        headers: getAuthHeaders(flextoken),
      );

      print('=== RÉPONSE VÉRIFICATION PAIEMENT ===');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.body.isEmpty) {
        throw Exception('Réponse vide du serveur FlexPay');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final int status = _safeParseInt(responseData['transaction']?['status'], defaultValue: -1);
        final bool isSuccess = status == 0;

        print('Status transaction: $status');
        print('Succès: ${isSuccess ? "✅" : "❌"}');

        return ApiResponse(
          success: true,
          message: isSuccess
              ? 'Paiement réussi'
              : 'Paiement en cours ou échoué',
          data: {
            ...responseData,
            'payment_success': isSuccess,
            'payment_status': status,
          },
        );
      } else {
        print('❌ Erreur vérification transaction FlexPay');
        return ApiResponse(
          success: false,
          message:
              responseData['message'] ??
              'Erreur lors de la vérification du paiement',
          data: responseData,
        );
      }
    } catch (e) {
      print('💥 ERREUR VÉRIFICATION PAIEMENT FLEXPAY: $e');
      return ApiResponse(
        success: false,
        message: 'Erreur de vérification paiement: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Enregistrer un paiement réussi dans le backend
  static Future<ApiResponse> recordPayment({
    required String token,
    required int courseId,
    required String devise,
    required double montant,
    required String moyen,
  }) async {
    try {
      print('=== ENREGISTREMENT PAIEMENT ===');
      print('Course ID: $courseId');
      print('Devise: $devise');
      print('Montant: $montant');
      print('Moyen: $moyen');

      final Map<String, dynamic> bodyData = {
        'course': courseId,
        'devise': devise,
        'montant': montant.toString(),
        'moyen': moyen,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/paiement/add/'),
        headers: getAuthHeaders(token),
        body: jsonEncode(bodyData),
      );

      print('=== RÉPONSE ENREGISTREMENT PAIEMENT ===');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Paiement enregistré avec succès');
        return ApiResponse(
          success: responseData['status'] ?? true,
          message: responseData['message'] ?? 'Paiement enregistré avec succès',
          data: responseData,
        );
      } else {
        print('❌ Erreur enregistrement paiement');
        return ApiResponse(
          success: false,
          message:
              responseData['message'] ??
              'Erreur lors de l\'enregistrement du paiement',
          data: responseData,
        );
      }
    } catch (e) {
      print('💥 ERREUR ENREGISTREMENT PAIEMENT: $e');
      return ApiResponse(
        success: false,
        message: 'Erreur d\'enregistrement paiement: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Récupérer la configuration de répartition des paiements
  static Future<ApiResponse> getPaymentConfig({required String token}) async {
    try {
      print('=== RÉCUPÉRATION CONFIGURATION PAIEMENT ===');

      final response = await http.get(
        Uri.parse('$baseUrl/config/'),
        headers: getAuthHeaders(token),
      );

      print('=== RÉPONSE CONFIG PAIEMENT ===');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ Configuration récupérée avec succès');
        return ApiResponse(
          success: true,
          message: 'Configuration récupérée avec succès',
          data: responseData,
        );
      } else {
        print('❌ Erreur récupération configuration');
        return ApiResponse(
          success: false,
          message:
              responseData['message'] ??
              'Erreur lors de la récupération de la configuration',
          data: responseData,
        );
      }
    } catch (e) {
      print('💥 ERREUR RÉCUPÉRATION CONFIG: $e');
      return ApiResponse(
        success: false,
        message: 'Erreur de récupération configuration: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Ajouter un montant au portefeuille
  static Future<ApiResponse> addAmountToWallet({
    required String token,
    required double amount,
    required String devise,
    required bool isAdmin,
  }) async {
    try {
      print('=== AJOUT MONTANT PORTEFEUILLE ===');
      print('Montant: $amount $devise');
      print('Pour admin: $isAdmin');

      final Map<String, dynamic> bodyData = {
        'amount': amount,
        'devise': devise,
        'is_admin': isAdmin,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/wallet/add-amount/'),
        headers: getAuthHeaders(token),
        body: jsonEncode(bodyData),
      );

      print('=== RÉPONSE AJOUT PORTEFEUILLE ===');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Montant ajouté au portefeuille avec succès');
        return ApiResponse(
          success: responseData['status'] ?? true,
          message: responseData['message'] ?? 'Montant ajouté avec succès',
          data: responseData,
        );
      } else {
        print('❌ Erreur ajout portefeuille');
        return ApiResponse(
          success: false,
          message:
              responseData['message'] ??
              'Erreur lors de l\'ajout au portefeuille',
          data: responseData,
        );
      }
    } catch (e) {
      print('💥 ERREUR AJOUT PORTEFEUILLE: $e');
      return ApiResponse(
        success: false,
        message: 'Erreur d\'ajout portefeuille: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Processus de répartition du paiement entre admin et chauffeur
  static Future<ApiResponse> distributePayment({
    required String token,
    required double montantPaye,
    required String devise,
  }) async {
    try {
      print('=== RÉPARTITION PAIEMENT ===');
      print('Montant à répartir: $montantPaye $devise');

      // 1. Récupérer la configuration de répartition
      final configResponse = await getPaymentConfig(token: token);

      if (!configResponse.success) {
        return configResponse;
      }

      final configData = configResponse.data;
      if (configData == null) {
        return ApiResponse(
          success: false,
          message: 'Configuration de répartition non trouvée',
          data: null,
        );
      }

      // Extraire les pourcentages
      final String pourcentageAdminStr =
          configData['pourcentage_admin']?.toString() ?? '90.00';
      final String pourcentageChauffeurStr =
          configData['pourcentage_chauffeur']?.toString() ?? '10.00';

      final double pourcentageAdmin =
          double.tryParse(pourcentageAdminStr) ?? 90.0;
      final double pourcentageChauffeur =
          double.tryParse(pourcentageChauffeurStr) ?? 10.0;

      print('Pourcentage Admin: $pourcentageAdmin%');
      print('Pourcentage Chauffeur: $pourcentageChauffeur%');

      // 2. Calculer les parts
      final double partAdmin = montantPaye * pourcentageAdmin / 100;
      final double partChauffeur = montantPaye * pourcentageChauffeur / 100;

      print('Part Admin: $partAdmin $devise');
      print('Part Chauffeur: $partChauffeur $devise');

      // 3. Ajouter au portefeuille admin
      final adminWalletResponse = await addAmountToWallet(
        token: token,
        amount: partAdmin,
        devise: devise,
        isAdmin: true,
      );

      if (!adminWalletResponse.success) {
        return ApiResponse(
          success: false,
          message:
              'Erreur lors de l\'ajout au portefeuille admin: ${adminWalletResponse.message}',
          data: adminWalletResponse.data,
        );
      }

      // 4. Ajouter au portefeuille chauffeur
      final chauffeurWalletResponse = await addAmountToWallet(
        token: token,
        amount: partChauffeur,
        devise: devise,
        isAdmin: false,
      );

      if (!chauffeurWalletResponse.success) {
        return ApiResponse(
          success: false,
          message:
              'Erreur lors de l\'ajout au portefeuille chauffeur: ${chauffeurWalletResponse.message}',
          data: chauffeurWalletResponse.data,
        );
      }

      print('🎉 Répartition du paiement terminée avec succès');

      return ApiResponse(
        success: true,
        message: 'Paiement réparti avec succès',
        data: {
          'montant_total': montantPaye,
          'devise': devise,
          'part_admin': partAdmin,
          'part_chauffeur': partChauffeur,
          'pourcentage_admin': pourcentageAdmin,
          'pourcentage_chauffeur': pourcentageChauffeur,
          'admin_wallet_response': adminWalletResponse.data,
          'chauffeur_wallet_response': chauffeurWalletResponse.data,
        },
      );
    } catch (e) {
      print('💥 ERREUR RÉPARTITION PAIEMENT: $e');
      return ApiResponse(
        success: false,
        message: 'Erreur de répartition paiement: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Processus complet de paiement FlexPay avec vérification
  static Future<ApiResponse> processFlexPayPayment({
    required String token,
    required int courseId,
    required String phone,
    required double amount,
    required String currency,
    String callbackUrl = 'https://abcd.efgh.cd',
    int type = 1,
    int maxRetries = 3,
    Duration verificationDelay = const Duration(seconds: 6),
  }) async {
    try {
      print('=== PROCESSUS COMPLET PAIEMENT FLEXPAY ===');

      // Valider le format du numéro de téléphone
      String formattedPhone = _formatPhoneNumber(phone);
      if (formattedPhone.isEmpty) {
        return ApiResponse(
          success: false,
          message:
              'Format de numéro de téléphone invalide. Utilisez le format 243xxxxxxxxx',
          data: null,
        );
      }

      // Générer une référence unique
      String reference = _generatePaymentReference();

      // 1. Créer la transaction
      final createResponse = await createPayment(
        token: token,
        phone: formattedPhone,
        reference: reference,
        amount: amount,
        currency: currency,
        callbackUrl: callbackUrl,
        type: type,
      );

      if (!createResponse.success) {
        return createResponse;
      }

      String? orderNumber = createResponse.data?['orderNumber'];
      if (orderNumber == null) {
        return ApiResponse(
          success: false,
          message: 'Numéro de commande manquant dans la réponse FlexPay',
          data: createResponse.data,
        );
      }

      print('📝 Transaction créée - Order Number: $orderNumber');

      // 2. Attendre et vérifier la transaction
      print(
        '⏳ Attente de ${verificationDelay.inSeconds} secondes avant vérification...',
      );
      await Future.delayed(verificationDelay);

      ApiResponse? verificationResponse;
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        print('🔍 Tentative de vérification $attempt/$maxRetries');

        verificationResponse = await checkPaymentStatus(
          token: token,
          orderNumber: orderNumber,
        );

        if (!verificationResponse.success) {
          if (attempt == maxRetries) {
            return verificationResponse;
          }
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }

        bool paymentSuccess =
            verificationResponse.data?['payment_success'] ?? false;

        if (paymentSuccess) {
          print('✅ Paiement vérifié comme réussi');
          break;
        } else if (attempt < maxRetries) {
          print(
            '⏳ Paiement encore en cours, nouvelle tentative dans 3 secondes...',
          );
          await Future.delayed(const Duration(seconds: 3));
        }
      }

      if (verificationResponse == null ||
          !(verificationResponse.data?['payment_success'] ?? false)) {
        return ApiResponse(
          success: false,
          message:
              'Le paiement n\'a pas pu être confirmé après $maxRetries tentatives',
          data: verificationResponse?.data,
        );
      }

      // 3. Enregistrer le paiement réussi
      final recordResponse = await recordPayment(
        token: token,
        courseId: courseId,
        devise: currency,
        montant: amount,
        moyen: type == 1 ? 'mobile_money' : 'carte_bancaire',
      );

      if (!recordResponse.success) {
        return recordResponse;
      }

      // 4. Répartir le paiement entre admin et chauffeur
      print('💰 Démarrage de la répartition du paiement...');
      final distributionResponse = await distributePayment(
        token: token,
        montantPaye: amount,
        devise: currency,
      );

      if (distributionResponse.success) {
        print(
          '🎉 Processus de paiement FlexPay et répartition terminés avec succès',
        );
        return ApiResponse(
          success: true,
          message: 'Paiement FlexPay réussi, enregistré et réparti',
          data: {
            'order_number': orderNumber,
            'verification_data': verificationResponse.data,
            'record_data': recordResponse.data,
            'distribution_data': distributionResponse.data,
          },
        );
      } else {
        // Le paiement est enregistré mais la répartition a échoué
        print('⚠️ Paiement enregistré mais échec de la répartition');
        return ApiResponse(
          success: true,
          message:
              'Paiement réussi mais échec de la répartition: ${distributionResponse.message}',
          data: {
            'order_number': orderNumber,
            'verification_data': verificationResponse.data,
            'record_data': recordResponse.data,
            'distribution_error': distributionResponse.message,
          },
        );
      }
    } catch (e) {
      print('💥 ERREUR PROCESSUS PAIEMENT FLEXPAY: $e');
      return ApiResponse(
        success: false,
        message: 'Erreur du processus de paiement: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Récupérer les informations du chauffeur d'une course
  static Future<ApiResponse> getCourseDriverInfo({
    required String token,
    required int courseId,
  }) async {
    try {
      print('=== RÉCUPÉRATION INFO CHAUFFEUR COURSE ===');
      print('Course ID: $courseId');

      final response = await http.get(
        Uri.parse('$baseUrl/course/$courseId/driver/'),
        headers: getAuthHeaders(token),
      );

      print('=== RÉPONSE INFO CHAUFFEUR ===');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ Info chauffeur récupérées avec succès');
        return ApiResponse(
          success: true,
          message: 'Informations du chauffeur récupérées avec succès',
          data: responseData,
        );
      } else {
        print('❌ Erreur récupération info chauffeur');
        return ApiResponse(
          success: false,
          message:
              responseData['message'] ??
              'Erreur lors de la récupération des informations du chauffeur',
          data: responseData,
        );
      }
    } catch (e) {
      print('💥 ERREUR RÉCUPÉRATION INFO CHAUFFEUR: $e');
      return ApiResponse(
        success: false,
        message: 'Erreur de récupération info chauffeur: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Test de la répartition d'un paiement (pour débogage)
  static Future<ApiResponse> testPaymentDistribution({
    required String token,
    required double testAmount,
    required String currency,
  }) async {
    print('=== TEST RÉPARTITION PAIEMENT ===');
    print('Montant test: $testAmount $currency');

    final distributionResponse = await distributePayment(
      token: token,
      montantPaye: testAmount,
      devise: currency,
    );

    if (distributionResponse.success) {
      print('✅ Test de répartition réussi');
      final data = distributionResponse.data;
      print('📊 Résultats:');
      print('  - Montant total: ${data['montant_total']} ${data['devise']}');
      print(
        '  - Part admin (${data['pourcentage_admin']}%): ${data['part_admin']} ${data['devise']}',
      );
      print(
        '  - Part chauffeur (${data['pourcentage_chauffeur']}%): ${data['part_chauffeur']} ${data['devise']}',
      );
    } else {
      print('❌ Test de répartition échoué: ${distributionResponse.message}');
    }

    return distributionResponse;
  }

  /// Formater le numéro de téléphone au format requis (243xxxxxxxxx)
  static String _formatPhoneNumber(String phone) {
    // Nettoyer le numéro (supprimer espaces, tirets, etc.)
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Si commence par +243
    if (cleaned.startsWith('+243')) {
      cleaned = cleaned.substring(1);
    }

    // Si commence par 0043
    if (cleaned.startsWith('0043')) {
      cleaned = '243${cleaned.substring(4)}';
    }

    // Si commence par 0 (numéro local)
    if (cleaned.startsWith('0') && cleaned.length >= 10) {
      cleaned = '243${cleaned.substring(1)}';
    }

    // Vérifier le format final
    if (cleaned.startsWith('243') && cleaned.length >= 12) {
      return cleaned;
    }

    return '';
  }

  /// Générer une référence unique pour le paiement
  static String _generatePaymentReference() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'MM$random';
  }

  // ===============================
  // SYSTÈME DE DÉPÔT ET RETRAIT
  // ===============================

  /// Méthode utilitaire pour conversion sécurisée des nombres
  static double _safeParseDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  /// Méthode utilitaire pour conversion sécurisée vers int
  static int _safeParseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  /// Enregistrement d'un dépôt après validation FlexPay
  static Future<ApiResponse> addDeposit({
    required String token,
    required double amount,
    required String devise, // "USD" ou "CDF"
  }) async {
    try {
      print('=== ENREGISTREMENT DÉPÔT ===');
      print('Montant: $amount $devise');

      final Map<String, dynamic> bodyData = {
        'amount': amount,
        'devise': devise,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/deposit/add/'),
        headers: getAuthHeaders(token),
        body: jsonEncode(bodyData),
      );

      print('Réponse enregistrement dépôt - Status: ${response.statusCode}');
      print('Réponse enregistrement dépôt - Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Dépôt enregistré avec succès');
        return ApiResponse.success(
          message: data['message'] ?? 'Dépôt enregistré avec succès',
          data: data,
        );
      } else {
        print('❌ Erreur enregistrement dépôt');
        return ApiResponse.error(
          data['message'] ?? 'Erreur lors de l\'enregistrement du dépôt',
        );
      }
    } catch (e) {
      print('💥 ERREUR ENREGISTREMENT DÉPÔT: $e');
      return ApiResponse.error('Erreur réseau: ${e.toString()}');
    }
  }

  /// Récupération du solde de dépôt du chauffeur
  static Future<ApiResponse> getDeposit({required String token}) async {
    try {
      print('=== RÉCUPÉRATION SOLDE DÉPÔT ===');

      final response = await http.get(
        Uri.parse('$baseUrl/deposit/get/'),
        headers: getAuthHeaders(token),
      );

      print('Réponse récupération dépôt - Status: ${response.statusCode}');
      print('Réponse récupération dépôt - Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ Solde dépôt récupéré avec succès');
        return ApiResponse.success(
          message: 'Solde récupéré avec succès',
          data: data,
        );
      } else {
        print('❌ Erreur récupération solde dépôt');
        return ApiResponse.error(
          data['message'] ?? 'Erreur lors de la récupération du solde',
        );
      }
    } catch (e) {
      print('💥 ERREUR RÉCUPÉRATION DÉPÔT: $e');
      return ApiResponse.error('Erreur réseau: ${e.toString()}');
    }
  }

  /// Retrait de dépôt (utilisé lors de paiement cash)
  static Future<ApiResponse> withdrawDeposit({
    required String token,
    required double amount,
    required String devise, // "USD" ou "CDF"
  }) async {
    try {
      print('=== RETRAIT DÉPÔT ===');
      print('Montant: $amount $devise');

      final Map<String, dynamic> bodyData = {
        'amount': amount,
        'devise': devise,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/deposit/withdraw/'),
        headers: getAuthHeaders(token),
        body: jsonEncode(bodyData),
      );

      print('Réponse retrait dépôt - Status: ${response.statusCode}');
      print('Réponse retrait dépôt - Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Retrait effectué avec succès');
        return ApiResponse.success(
          message: data['message'] ?? 'Retrait effectué avec succès',
          data: data,
        );
      } else {
        print('❌ Erreur lors du retrait');
        return ApiResponse.error(data['message'] ?? 'Erreur lors du retrait');
      }
    } catch (e) {
      print('💥 ERREUR RETRAIT DÉPÔT: $e');
      return ApiResponse.error('Erreur réseau: ${e.toString()}');
    }
  }

  /// Processus complet de dépôt FlexPay
  static Future<ApiResponse> processDepositFlexPay({
    required String token,
    required double amount,
    required String currency, // "USD" ou "CDF"
    required String phoneNumber,
  }) async {
    try {
      print('=== DÉBUT PROCESSUS DÉPÔT FLEXPAY ===');
      print('Montant: $amount $currency');
      print('Téléphone: $phoneNumber');

      // Étape 1: Initier le paiement FlexPay
      final reference = 'DEP${DateTime.now().millisecondsSinceEpoch}';
      final flexPayResponse = await createPayment(
        token: token,
        phone: phoneNumber,
        reference: reference,
        amount: amount,
        currency: currency,
        callbackUrl: '$baseUrl/flexpay/callback/',
      );

      if (!flexPayResponse.success) {
        print('❌ Échec création paiement FlexPay');
        return flexPayResponse;
      }

      // Récupérer l'orderNumber de la réponse FlexPay
      final String? orderNumber = flexPayResponse.data?['orderNumber'];
      if (orderNumber == null) {
        print('❌ OrderNumber manquant dans la réponse FlexPay');
        return ApiResponse.error('Numéro de commande FlexPay manquant');
      }

      print('✅ Paiement FlexPay créé - OrderNumber: $orderNumber');

      // Étape 2: Attendre validation et vérifier le statut
      print('⏳ Attente de validation du paiement...');
      await Future.delayed(Duration(seconds: 6));

      // Tentatives de vérification avec retry
      int maxRetries = 3;
      bool paymentValidated = false;

      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        print('🔍 Tentative de vérification $attempt/$maxRetries');

        final statusResponse = await checkPaymentStatus(
          token: token,
          orderNumber: orderNumber,
        );

        print("Réponse vérification: ${statusResponse.data}");

        if (statusResponse.success) {
          final bool isPaymentSuccess =
              statusResponse.data?['payment_success'] ?? false;

          if (isPaymentSuccess) {
            print('✅ Paiement FlexPay validé avec succès');
            paymentValidated = true;
            break;
          } else {
            print('⏳ Paiement en cours... tentative $attempt/$maxRetries');
            if (attempt < maxRetries) {
              await Future.delayed(Duration(seconds: 3));
            }
          }
        } else {
          print('❌ Erreur lors de la vérification: ${statusResponse.message}');
          if (attempt == maxRetries) {
            return statusResponse;
          }
          await Future.delayed(Duration(seconds: 2));
        }
      }

      if (!paymentValidated) {
        print('❌ Paiement non validé après $maxRetries tentatives');
        return ApiResponse.error(
          'Le paiement FlexPay n\'a pas pu être validé. Vérifiez votre téléphone et réessayez.',
        );
      }

      // Étape 3: Enregistrer le dépôt
      print('💰 Enregistrement du dépôt...');
      final depositResponse = await addDeposit(
        token: token,
        amount: amount,
        devise: currency,
      );

      if (depositResponse.success) {
        print('🎉 Dépôt FlexPay traité avec succès');
        return ApiResponse.success(
          message: 'Dépôt de $amount $currency effectué avec succès',
          data: {
            'order_number': orderNumber,
            'amount': amount,
            'currency': currency,
            'deposit_data': depositResponse.data,
          },
        );
      } else {
        print('❌ Erreur lors de l\'enregistrement du dépôt');
        return depositResponse;
      }
    } catch (e) {
      print('💥 ERREUR PROCESSUS DÉPÔT: $e');
      print('Stack trace: ${StackTrace.current}');

      String errorMessage = 'Erreur lors du dépôt';
      if (e.toString().contains(
        'type \'String\' is not a subtype of type \'int\'',
      )) {
        errorMessage = 'Erreur de conversion de données. Veuillez réessayer.';
      } else if (e.toString().contains(
        'type \'String\' is not a subtype of type \'double\'',
      )) {
        errorMessage = 'Erreur de format numérique. Veuillez réessayer.';
      }

      return ApiResponse.error('$errorMessage: ${e.toString()}');
    }
  }

  /// Vérifier si le chauffeur a suffisamment de dépôt pour un paiement cash
  static Future<ApiResponse> checkDepositForCashPayment({
    required String token,
    required double cashAmount,
    required String currency,
  }) async {
    try {
      print('=== VÉRIFICATION DÉPÔT POUR PAIEMENT CASH ===');
      print('Montant requis: $cashAmount $currency');

      // Récupérer le solde actuel
      final depositResponse = await getDeposit(token: token);

      if (!depositResponse.success) {
        return depositResponse;
      }

      final deposit = depositResponse.data;
      print('Données de dépôt reçues: $deposit');

      // Conversion sécurisée des montants (gestion String/int/double)
      final double availableAmount = currency == 'USD'
          ? _safeParseDouble(deposit['amount_usd'])
          : _safeParseDouble(deposit['amount_cdf']);

      print('Montant disponible: $availableAmount $currency');

      if (availableAmount >= cashAmount) {
        print('✅ Solde suffisant pour le paiement');
        return ApiResponse.success(
          message: 'Solde suffisant pour le paiement cash',
          data: {
            'sufficient': true,
            'available_amount': availableAmount,
            'required_amount': cashAmount,
            'currency': currency,
            'deposit_info': deposit,
          },
        );
      } else {
        print('❌ Solde insuffisant');
        return ApiResponse.error(
          'Solde insuffisant. Disponible: $availableAmount $currency, Requis: $cashAmount $currency',
        );
      }
    } catch (e) {
      print('💥 ERREUR VÉRIFICATION DÉPÔT: $e');
      return ApiResponse.error(
        'Erreur lors de la vérification: ${e.toString()}',
      );
    }
  }

  /// Processus complet pour paiement cash avec retrait automatique
  static Future<ApiResponse> processCashPaymentWithWithdrawal({
    required String token,
    required double amount,
    required String currency,
    required String courseId,
  }) async {
    try {
      // Étape 1: Vérifier le solde disponible
      final checkResponse = await checkDepositForCashPayment(
        token: token,
        cashAmount: amount,
        currency: currency,
      );

      if (!checkResponse.success) {
        return checkResponse;
      }

      // Étape 2: Enregistrer le paiement comme cash
      final paymentResponse = await recordPayment(
        token: token,
        courseId: int.parse(courseId),
        montant: amount,
        devise: currency,
        moyen: 'especes', // Cash en français
      );

      if (!paymentResponse.success) {
        return paymentResponse;
      }

      // Étape 3: Effectuer le retrait du dépôt
      final withdrawResponse = await withdrawDeposit(
        token: token,
        amount: amount,
        devise: currency,
      );

      if (!withdrawResponse.success) {
        // En cas d'erreur de retrait, on pourrait annuler le paiement
        // Mais pour simplifier, on retourne l'erreur
        return withdrawResponse;
      }

      // Étape 4: Distribution des bénéfices (comme pour les autres paiements)
      await distributePayment(
        token: token,
        montantPaye: amount,
        devise: currency,
      );

      return ApiResponse.success(
        message: 'Paiement cash traité avec succès',
        data: {
          'payment': paymentResponse.data,
          'withdrawal': withdrawResponse.data,
          'cash_amount': amount,
          'currency': currency,
        },
      );
    } catch (e) {
      return ApiResponse.error('Erreur lors du paiement cash: ${e.toString()}');
    }
  }

  // ===================================
  // SYSTÈME D'ÉVALUATION DES CHAUFFEURS
  // ===================================

  /// Évaluer un chauffeur après une course terminée
  static Future<ApiResponse> evaluateDriver({
    required String token,
    required int chauffeurId,
    required int courseId,
    required int note, // Note de 1 à 5
    String? commentaire,
  }) async {
    try {
      print('⭐ Évaluation du chauffeur');
      print('  Chauffeur ID: $chauffeurId');
      print('  Course ID: $courseId');
      print('  Note: $note/5');
      print('  Commentaire: ${commentaire ?? "Aucun"}');

      // Validation de la note
      if (note < 1 || note > 5) {
        return ApiResponse.error('La note doit être entre 1 et 5');
      }

      final url = Uri.parse('$baseUrl/evaluation/add/');
      final response = await http.post(
        url,
        headers: getAuthHeaders(token),
        body: json.encode({
          'chauffeur': chauffeurId,
          'course': courseId,
          'note': note,
          'commentaire': commentaire ?? '',
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(
          data: data,
          message: 'Évaluation ajoutée avec succès',
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(
          errorData['message'] ?? 'Erreur lors de l\'évaluation',
        );
      }
    } catch (e) {
      print('Erreur lors de l\'évaluation: $e');
      return ApiResponse.error('Erreur: ${e.toString()}');
    }
  }

  /// Récupérer les évaluations d'un chauffeur spécifique
  static Future<ApiResponse> getDriverEvaluations({
    required String token,
    required int chauffeurId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/evaluation/chauffeur/$chauffeurId/');
      final response = await http.get(url, headers: getAuthHeaders(token));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(
          data: data,
          message: 'Évaluations récupérées avec succès',
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(
          errorData['message'] ?? 'Erreur lors de la récupération',
        );
      }
    } catch (e) {
      print('Erreur récupération évaluations: $e');
      return ApiResponse.error('Erreur: ${e.toString()}');
    }
  }

  /// Récupérer les évaluations du chauffeur connecté (utilise l'ID de session)
  static Future<ApiResponse> getMyDriverEvaluations({
    required String token,
    required int userId, // ID de l'utilisateur connecté
  }) async {
    try {
      // L'endpoint utilise l'ID de session pour identifier le chauffeur connecté
      final url = Uri.parse('$baseUrl/evaluation/chauffeur/$userId/');
      final response = await http.get(url, headers: getAuthHeaders(token));

      print('🌟 Récupération évaluations chauffeur ID: $userId');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(
          data: data,
          message: 'Mes évaluations récupérées avec succès',
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(
          errorData['message'] ?? 'Erreur lors de la récupération',
        );
      }
    } catch (e) {
      print('Erreur récupération mes évaluations: $e');
      return ApiResponse.error('Erreur: ${e.toString()}');
    }
  }

  /// Récupérer la moyenne des évaluations d'un chauffeur
  static Future<ApiResponse> getDriverAverageRating({
    required String token,
    required int chauffeurId,
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl/evaluation/chauffeur/$chauffeurId/moyenne/',
      );
      final response = await http.get(url, headers: getAuthHeaders(token));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(
          data: data,
          message: 'Moyenne récupérée avec succès',
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(
          errorData['message'] ?? 'Erreur lors de la récupération',
        );
      }
    } catch (e) {
      print('Erreur récupération moyenne: $e');
      return ApiResponse.error('Erreur: ${e.toString()}');
    }
  }
}

/// Classe pour représenter la réponse de l'API
class ApiResponse {
  final bool success;
  final String message;
  final dynamic data;

  ApiResponse({required this.success, required this.message, this.data});

  /// Constructeur pour une réponse de succès
  factory ApiResponse.success({required String message, dynamic data}) {
    return ApiResponse(success: true, message: message, data: data);
  }

  /// Constructeur pour une réponse d'erreur
  factory ApiResponse.error(String message) {
    return ApiResponse(success: false, message: message);
  }

  /// Récupère le token depuis la réponse
  String? get token {
    if (data != null && data is Map<String, dynamic>) {
      return data['token'];
    }
    return null;
  }

  /// Récupère les données utilisateur depuis la réponse
  Map<String, dynamic>? get userData {
    if (data != null && data is Map<String, dynamic>) {
      return data['data'];
    }
    return null;
  }
}

/// Modèle utilisateur
class UserModel {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String telephone;
  final String typeUtilisateur;
  final String statut;
  final String dateInscription;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.telephone,
    required this.typeUtilisateur,
    required this.statut,
    required this.dateInscription,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      telephone: json['telephone'] ?? '',
      typeUtilisateur: json['type_utilisateur'] ?? '',
      statut: json['statut'] ?? '',
      dateInscription: json['date_inscription'] ?? '',
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'telephone': telephone,
      'type_utilisateur': typeUtilisateur,
      'statut': statut,
      'date_inscription': dateInscription,
      'avatar_url': avatarUrl,
    };
  }
}

/// Modèle véhicule
class VehicleModel {
  final int id;
  final String marque;
  final String modele;
  final String plaque;
  final String couleur;
  final String typeVehicule;
  final String confort;
  final int capacite;
  final double latitude;
  final double longitude;
  final Map<String, dynamic>? chauffeur;

  VehicleModel({
    required this.id,
    required this.marque,
    required this.modele,
    required this.plaque,
    required this.couleur,
    required this.typeVehicule,
    required this.confort,
    required this.capacite,
    required this.latitude,
    required this.longitude,
    this.chauffeur,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] ?? 0,
      marque: json['marque'] ?? '',
      modele: json['modele'] ?? '',
      plaque: json['plaque'] ?? '',
      couleur: json['couleur'] ?? '',
      typeVehicule: json['type_vehicule'] ?? '',
      confort: json['confort'] ?? '',
      capacite: json['capacite'] ?? 0,
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      chauffeur: json['chauffeur'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'marque': marque,
      'modele': modele,
      'plaque': plaque,
      'couleur': couleur,
      'type_vehicule': typeVehicule,
      'confort': confort,
      'capacite': capacite,
      'latitude': latitude,
      'longitude': longitude,
      'chauffeur': chauffeur,
    };
  }
}

/// Modèle pour la tarification
class PricingModel {
  final double prixCdf;
  final double prixUsd;

  PricingModel({required this.prixCdf, required this.prixUsd});

  factory PricingModel.fromJson(Map<String, dynamic> json) {
    return PricingModel(
      prixCdf: (json['prix_cdf'] ?? 0).toDouble(),
      prixUsd: (json['prix_usd'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'prix_cdf': prixCdf, 'prix_usd': prixUsd};
  }
}

/// Modèle pour les courses
class RideModel {
  final int id;
  final String passagerName;
  final String? chauffeurName;
  final double departLatitude;
  final double departLongitude;
  final double destinationLatitude;
  final double destinationLongitude;
  final double distance;
  final double dureeEstimee;
  final String prixEstime;
  final String statut;
  final String dateCreation;
  final String? dateAcceptation;
  final String? dateFin;
  final int passager;
  final int? chauffeur;
  final int? vehicule;

  RideModel({
    required this.id,
    required this.passagerName,
    this.chauffeurName,
    required this.departLatitude,
    required this.departLongitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.distance,
    required this.dureeEstimee,
    required this.prixEstime,
    required this.statut,
    required this.dateCreation,
    this.dateAcceptation,
    this.dateFin,
    required this.passager,
    this.chauffeur,
    this.vehicule,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['id'] ?? 0,
      passagerName: json['passager_name'] ?? '',
      chauffeurName: json['chauffeur_name'],
      departLatitude: (json['depart_latitude'] ?? 0.0).toDouble(),
      departLongitude: (json['depart_longitude'] ?? 0.0).toDouble(),
      destinationLatitude: (json['destination_latitude'] ?? 0.0).toDouble(),
      destinationLongitude: (json['destination_longitude'] ?? 0.0).toDouble(),
      distance: (json['distance'] ?? 0.0).toDouble(),
      dureeEstimee: (json['duree_estimee'] ?? 0.0).toDouble(),
      prixEstime: json['prix_estime']?.toString() ?? '0.00',
      statut: json['statut'] ?? '',
      dateCreation: json['date_creation'] ?? '',
      dateAcceptation: json['date_acceptation'],
      dateFin: json['date_fin'],
      passager: json['passager'] ?? 0,
      chauffeur: json['chauffeur'],
      vehicule: json['vehicule'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'passager_name': passagerName,
      'chauffeur_name': chauffeurName,
      'depart_latitude': departLatitude,
      'depart_longitude': departLongitude,
      'destination_latitude': destinationLatitude,
      'destination_longitude': destinationLongitude,
      'distance': distance,
      'duree_estimee': dureeEstimee,
      'prix_estime': prixEstime,
      'statut': statut,
      'date_creation': dateCreation,
      'date_acceptation': dateAcceptation,
      'date_fin': dateFin,
      'passager': passager,
      'chauffeur': chauffeur,
      'vehicule': vehicule,
    };
  }

  /// Getter pour vérifier si la course est en attente
  bool get isWaiting => statut == 'en_attente';

  /// Getter pour vérifier si la course est acceptée
  bool get isAccepted => statut == 'acceptee';

  /// Getter pour vérifier si la course est en cours
  bool get isInProgress => statut == 'en_cours';

  /// Getter pour vérifier si la course est terminée
  bool get isFinished => statut == 'terminee';

  /// Getter pour vérifier si la course est annulée
  bool get isCancelled => statut == 'annulee';
}

/// Modèle pour les paiements FlexPay
class PaymentModel {
  final int? id;
  final int courseId;
  final String devise;
  final double montant;
  final String moyen;
  final String statut;
  final String dateCreation;
  final String? orderNumber;
  final Map<String, dynamic>? transactionData;

  PaymentModel({
    this.id,
    required this.courseId,
    required this.devise,
    required this.montant,
    required this.moyen,
    required this.statut,
    required this.dateCreation,
    this.orderNumber,
    this.transactionData,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      courseId: json['course'] ?? json['course_id'] ?? 0,
      devise: json['devise'] ?? 'CDF',
      montant: (json['montant'] ?? 0).toDouble(),
      moyen: json['moyen'] ?? '',
      statut: json['statut'] ?? '',
      dateCreation: json['date_creation'] ?? '',
      orderNumber: json['order_number'],
      transactionData: json['transaction_data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course': courseId,
      'devise': devise,
      'montant': montant,
      'moyen': moyen,
      'statut': statut,
      'date_creation': dateCreation,
      'order_number': orderNumber,
      'transaction_data': transactionData,
    };
  }

  /// Getter pour vérifier si le paiement est réussi
  bool get isSuccessful =>
      statut.toLowerCase() == 'reussi' || statut.toLowerCase() == 'success';

  /// Getter pour vérifier si le paiement est en cours
  bool get isPending =>
      statut.toLowerCase() == 'en_cours' || statut.toLowerCase() == 'pending';

  /// Getter pour vérifier si le paiement a échoué
  bool get isFailed =>
      statut.toLowerCase() == 'echec' || statut.toLowerCase() == 'failed';

  /// Getter pour le montant formaté
  String get formattedAmount => '${montant.toStringAsFixed(0)} $devise';

  /// Getter pour le type de paiement formaté
  String get formattedMoyen {
    switch (moyen.toLowerCase()) {
      case 'mobile_money':
        return 'Mobile Money';
      case 'carte_bancaire':
        return 'Carte Bancaire';
      case 'especes':
        return 'Espèces';
      default:
        return moyen;
    }
  }
}
