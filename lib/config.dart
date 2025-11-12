class AppConfig {
  // Configuration du serveur
  static const String baseUrl = 'http://localhost:8000';
  static const String apiBaseUrl = '$baseUrl/api/bita';

  // URL pour les médias (avatars, images, etc.)
  static const String mediaBaseUrl = baseUrl;

  // Méthode pour construire l'URL complète d'un avatar
  static String getAvatarUrl(String? avatarPath) {
    if (avatarPath == null || avatarPath.isEmpty) {
      print(avatarPath);
      return '';
    }

    // Si l'URL commence déjà par http, on la retourne telle quelle
    if (avatarPath.startsWith('http')) {
      return avatarPath;
    }

    // Sinon, on construit l'URL complète
    // Enlever le "/" au début si présent
    final cleanPath = avatarPath.startsWith('/')
        ? avatarPath.substring(1)
        : avatarPath;

    return '$mediaBaseUrl/$cleanPath';
  }

  // Méthode pour construire l'URL complète d'un média
  static String getMediaUrl(String? mediaPath) {
    if (mediaPath == null || mediaPath.isEmpty) {
      return '';
    }

    if (mediaPath.startsWith('http')) {
      return mediaPath;
    }

    final cleanPath = mediaPath.startsWith('/')
        ? mediaPath.substring(1)
        : mediaPath;
    return '$mediaBaseUrl/$cleanPath';
  }
}
