import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'user/signin.dart';
import 'home.dart';
import 'func.dart';

class SessionManager {
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _fullResponseKey = 'full_api_response';

  // Stream Controller pour notifier les changements de données utilisateur
  static final ValueNotifier<Map<String, dynamic>?> _userDataNotifier =
      ValueNotifier<Map<String, dynamic>?>(null);

  /// Getter pour écouter les changements de données utilisateur
  static ValueNotifier<Map<String, dynamic>?> get userDataNotifier =>
      _userDataNotifier;

  /// Récupère le token depuis SharedPreferences
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('Erreur lors de la récupération du token: $e');
      return null;
    }
  }

  /// Sauvegarde le token dans SharedPreferences
  static Future<bool> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_tokenKey, token);
    } catch (e) {
      print('Erreur lors de la sauvegarde du token: $e');
      return false;
    }
  }

  /// Sauvegarde les données utilisateur
  static Future<bool> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = json.encode(userData);
      return await prefs.setString(_userDataKey, userDataJson);
    } catch (e) {
      print('Erreur lors de la sauvegarde des données utilisateur: $e');
      return false;
    }
  }

  /// Récupère les données utilisateur
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString(_userDataKey);
      if (userDataJson != null) {
        final userData = json.decode(userDataJson) as Map<String, dynamic>;
        // Mettre à jour le notifier avec les données récupérées
        _userDataNotifier.value = userData;
        return userData;
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération des données utilisateur: $e');
      return null;
    }
  }

  /// Sauvegarde la réponse complète de l'API
  static Future<bool> saveFullApiResponse(
    Map<String, dynamic> fullResponse,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final responseJson = json.encode(fullResponse);
      return await prefs.setString(_fullResponseKey, responseJson);
    } catch (e) {
      print('Erreur lors de la sauvegarde de la réponse complète: $e');
      return false;
    }
  }

  /// Récupère la réponse complète de l'API
  static Future<Map<String, dynamic>?> getFullApiResponse() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final responseJson = prefs.getString(_fullResponseKey);
      if (responseJson != null) {
        return json.decode(responseJson) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de la réponse complète: $e');
      return null;
    }
  }

  /// Sauvegarde toutes les données de la réponse API (token, userData, et réponse complète)
  static Future<bool> saveLoginResponse(
    Map<String, dynamic> apiResponse,
  ) async {
    try {
      bool success = true;

      // Sauvegarder le token
      if (apiResponse.containsKey('token') && apiResponse['token'] != null) {
        success &= await saveToken(apiResponse['token']);
      }

      // Sauvegarder les données utilisateur
      if (apiResponse.containsKey('data') && apiResponse['data'] != null) {
        success &= await saveUserData(apiResponse['data']);
      }

      // Sauvegarder la réponse complète
      success &= await saveFullApiResponse(apiResponse);

      return success;
    } catch (e) {
      print('Erreur lors de la sauvegarde de la réponse de connexion: $e');
      return false;
    }
  }

  /// Récupère des informations spécifiques de l'utilisateur
  static Future<String?> getUserInfo(String key) async {
    try {
      final userData = await getUserData();
      if (userData != null && userData.containsKey(key)) {
        return userData[key]?.toString();
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'info utilisateur "$key": $e');
      return null;
    }
  }

  /// Méthodes d'accès rapide aux informations utilisateur
  static Future<String?> getUsername() async => await getUserInfo('username');
  static Future<String?> getEmail() async => await getUserInfo('email');
  static Future<String?> getFirstName() async =>
      await getUserInfo('first_name');
  static Future<String?> getLastName() async => await getUserInfo('last_name');
  static Future<String?> getTelephone() async => await getUserInfo('telephone');
  static Future<String?> getUserType() async =>
      await getUserInfo('type_utilisateur');
  static Future<String?> getUserStatus() async => await getUserInfo('statut');
  static Future<String?> getAvatarUrl() async =>
      await getUserInfo('avatar_url');

  /// Supprime toutes les données de session (déconnexion complète)
  static Future<bool> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Supprimer les clés principales de session
      final tokenRemoved = await prefs.remove(_tokenKey);
      final userDataRemoved = await prefs.remove(_userDataKey);
      final fullResponseRemoved = await prefs.remove(_fullResponseKey);

      // Notifier la déconnexion
      _userDataNotifier.value = null;

      // Optionnel: Supprimer toutes les autres clés liées à l'authentification
      // qui pourraient exister dans l'application
      final allKeys = prefs.getKeys();
      final authRelatedKeys = allKeys
          .where(
            (key) =>
                key.contains('auth') ||
                key.contains('user') ||
                key.contains('session') ||
                key.contains('login'),
          )
          .toList();

      bool allAuthKeysRemoved = true;
      for (String key in authRelatedKeys) {
        if (key != _tokenKey &&
            key != _userDataKey &&
            key != _fullResponseKey) {
          final removed = await prefs.remove(key);
          allAuthKeysRemoved = allAuthKeysRemoved && removed;
        }
      }

      print(
        'Session cleared: token=$tokenRemoved, userData=$userDataRemoved, fullResponse=$fullResponseRemoved',
      );
      print('Additional auth keys removed: ${authRelatedKeys.length} keys');

      return tokenRemoved && userDataRemoved && fullResponseRemoved;
    } catch (e) {
      print('Erreur lors de la suppression des données de session: $e');
      return false;
    }
  }

  /// Alternative: Suppression complète et forcée de toutes les données
  static Future<bool> clearAllSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Supprime TOUTES les données de l'app
      print('Toutes les données de session ont été supprimées');
      return true;
    } catch (e) {
      print('Erreur lors de la suppression complète: $e');
      return false;
    }
  }

  /// Vérifie si l'utilisateur est connecté
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Notifie que les données utilisateur ont été mises à jour
  static Future<void> notifyUserDataUpdated(
    Map<String, dynamic> newUserData,
  ) async {
    try {
      // Sauvegarder les nouvelles données
      await saveUserData(newUserData);

      // Notifier tous les listeners des changements
      _userDataNotifier.value = newUserData;

      print('Données utilisateur mises à jour dans la session et notifiées');
    } catch (e) {
      print('Erreur lors de la notification de mise à jour: $e');
    }
  }

  /// Navigue vers la page appropriée selon l'état de connexion
  static Future<void> checkAuthAndNavigate(BuildContext context) async {
    final isAuthenticated = await isLoggedIn();

    if (isAuthenticated) {
      // Utilisateur connecté -> aller à la page d'accueil
      NavigationHelper.goto(context, const HomePage());
    } else {
      // Utilisateur non connecté -> aller à la page de connexion
      NavigationHelper.goto(context, const SignInPage());
    }
  }

  /// Vérifie si l'utilisateur est connecté et redirige vers l'accueil si c'est le cas
  /// Retourne true si une redirection a été effectuée, false sinon
  static Future<bool> checkAndRedirectIfAuthenticated(
    BuildContext context,
  ) async {
    final isAuthenticated = await isLoggedIn();

    if (isAuthenticated) {
      // Utilisateur déjà connecté -> rediriger vers l'accueil
      NavigationHelper.goto(context, const HomePage());
      return true;
    }

    return false;
  }
}
