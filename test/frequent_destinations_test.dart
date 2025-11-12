import 'package:flutter_test/flutter_test.dart';

// Fonctions utilitaires pour les tests
String getShortName(String displayName) {
  List<String> parts = displayName.split(',');
  String shortName = parts.isNotEmpty ? parts[0].trim() : displayName;

  if (shortName.length > 24) {
    shortName = '${shortName.substring(0, 21)}...';
  }

  return shortName;
}

String getLocationSummary(String displayName) {
  List<String> parts = displayName.split(',');
  String summary;

  if (parts.length >= 2) {
    String city = parts[parts.length - 2].trim();
    String country = parts[parts.length - 1].trim();
    summary = '$city, $country';
  } else if (parts.isNotEmpty) {
    summary = parts[0].trim();
  } else {
    summary = displayName;
  }

  if (summary.length > 27) {
    summary = '${summary.substring(0, 24)}...';
  }

  return summary;
}

void main() {
  group('String Formatting Tests', () {
    test('Should limit title to 24 characters maximum', () {
      // Test avec un titre long
      const longTitle =
          'Ceci est un titre très très long qui dépasse largement 24 caractères';
      final result = getShortName(longTitle);

      expect(result.length, lessThanOrEqualTo(24));
      expect(result, endsWith('...'));
      expect(result, equals('Ceci est un titre trè...'));
    });

    test('Should limit subtitle to 27 characters maximum', () {
      // Test avec une adresse qui génère un résumé long
      const longAddress =
          'Avenue de la République, Plateau du Centre Ville Très Long, Abidjan Centre, République de Côte d\'Ivoire';
      final result = getLocationSummary(longAddress);

      expect(result.length, lessThanOrEqualTo(27));
      if (result.length == 27) {
        expect(result, endsWith('...'));
      }
    });

    test('Should not modify short titles', () {
      const shortTitle = 'Court titre';
      final result = getShortName(shortTitle);

      expect(result, equals(shortTitle));
      expect(result.length, lessThan(24));
    });

    test('Should not modify short subtitles', () {
      const shortAddress = 'Abidjan, CI';
      final result = getLocationSummary(shortAddress);

      expect(result, equals(shortAddress));
      expect(result.length, lessThan(27));
    });

    test('Should extract city and country for subtitle', () {
      const fullAddress =
          'Place de la République, Plateau, Abidjan, Côte d\'Ivoire';
      final result = getLocationSummary(fullAddress);

      expect(result, contains('Abidjan'));
      expect(result, contains('Côte'));
    });
  });
}
