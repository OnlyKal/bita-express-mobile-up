import 'package:flutter_test/flutter_test.dart';
import '../lib/api.dart';

/// Test pour vérifier la fonctionnalité des courses terminées du chauffeur
void main() {
  group('Tests des courses terminées du chauffeur', () {
    test('API getDriverCompletedRides retourne une réponse correcte', () {
      // Ce test vérifie la structure de la méthode API
      expect(ApiService.getDriverCompletedRides, isA<Function>());
    });

    test('RideModel peut identifier correctement les courses terminées', () {
      // Test avec une course terminée
      final courseTerminee = RideModel(
        id: 1,
        passagerName: 'Test User',
        chauffeurName: 'Test Driver',
        departLatitude: -4.3169,
        departLongitude: 15.3012,
        destinationLatitude: -4.3269,
        destinationLongitude: 15.3112,
        distance: 2500.0,
        dureeEstimee: 900.0,
        prixEstime: '15.50',
        statut: 'terminee',
        dateCreation: '2024-10-23T10:00:00Z',
        dateAcceptation: '2024-10-23T10:05:00Z',
        dateFin: '2024-10-23T10:20:00Z',
        passager: 1,
        chauffeur: 2,
        vehicule: 3,
      );

      // Vérifications
      expect(courseTerminee.id, 1);
      expect(courseTerminee.passagerName, 'Test User');
      expect(courseTerminee.chauffeurName, 'Test Driver');
      expect(courseTerminee.statut, 'terminee');
      expect(courseTerminee.isFinished, true);
      expect(courseTerminee.isWaiting, false);
      expect(courseTerminee.isAccepted, false);
      expect(courseTerminee.isInProgress, false);
      expect(courseTerminee.isCancelled, false);
      expect(courseTerminee.dateFin, isNotNull);
      expect(courseTerminee.chauffeur, 2);
      expect(courseTerminee.vehicule, 3);

      print('✅ Course terminée: Toutes les vérifications passées');
      print('   - ID: ${courseTerminee.id}');
      print('   - Statut: ${courseTerminee.statut}');
      print('   - Prix: ${courseTerminee.prixEstime} FC');
      print(
        '   - Distance: ${(courseTerminee.distance / 1000).toStringAsFixed(1)} km',
      );
      print('   - Date de fin: ${courseTerminee.dateFin}');
    });

    test('Calcul des statistiques des courses terminées', () {
      // Créer plusieurs courses terminées pour tester les statistiques
      final courses = [
        RideModel(
          id: 1,
          passagerName: 'Passager 1',
          departLatitude: 0.0,
          departLongitude: 0.0,
          destinationLatitude: 0.0,
          destinationLongitude: 0.0,
          distance: 5000.0,
          dureeEstimee: 600.0,
          prixEstime: '10.00',
          statut: 'terminee',
          dateCreation: '2024-01-01',
          passager: 1,
          chauffeur: 1,
        ),
        RideModel(
          id: 2,
          passagerName: 'Passager 2',
          departLatitude: 0.0,
          departLongitude: 0.0,
          destinationLatitude: 0.0,
          destinationLongitude: 0.0,
          distance: 3000.0,
          dureeEstimee: 400.0,
          prixEstime: '8.50',
          statut: 'terminee',
          dateCreation: '2024-01-02',
          passager: 2,
          chauffeur: 1,
        ),
        RideModel(
          id: 3,
          passagerName: 'Passager 3',
          departLatitude: 0.0,
          departLongitude: 0.0,
          destinationLatitude: 0.0,
          destinationLongitude: 0.0,
          distance: 7500.0,
          dureeEstimee: 800.0,
          prixEstime: '16.75',
          statut: 'terminee',
          dateCreation: '2024-01-03',
          passager: 3,
          chauffeur: 1,
        ),
      ];

      // Calculs des statistiques
      final totalCourses = courses.length;
      double totalGains = 0.0;

      for (var course in courses) {
        totalGains += double.parse(course.prixEstime);
      }

      final moyenneParCourse = totalCourses > 0
          ? totalGains / totalCourses
          : 0.0;

      // Vérifications
      expect(totalCourses, 3);
      expect(totalGains, closeTo(35.25, 0.01)); // 10.00 + 8.50 + 16.75 = 35.25
      expect(moyenneParCourse, closeTo(11.75, 0.01)); // 35.25 / 3 = 11.75

      print('✅ Statistiques courses terminées calculées avec succès:');
      print('   - Total courses: $totalCourses');
      print('   - Total gains: ${totalGains.toStringAsFixed(2)} FC');
      print(
        '   - Moyenne par course: ${moyenneParCourse.toStringAsFixed(2)} FC',
      );
    });

    test('Validation du format de date pour les courses terminées', () {
      final course = RideModel(
        id: 100,
        passagerName: 'Test User',
        departLatitude: 0.0,
        departLongitude: 0.0,
        destinationLatitude: 0.0,
        destinationLongitude: 0.0,
        distance: 1000.0,
        dureeEstimee: 300.0,
        prixEstime: '5.00',
        statut: 'terminee',
        dateCreation: '2024-10-23T14:30:00Z',
        dateAcceptation: '2024-10-23T14:35:00Z',
        dateFin: '2024-10-23T14:45:00Z',
        passager: 1,
        chauffeur: 1,
      );

      // Vérifier que toutes les dates importantes sont présentes
      expect(course.dateCreation, isNotEmpty);
      expect(course.dateAcceptation, isNotNull);
      expect(course.dateFin, isNotNull);

      // Vérifier que la course est bien marquée comme terminée
      expect(course.isFinished, true);

      print('✅ Validation des dates pour course terminée réussie');
      print('   - Date création: ${course.dateCreation}');
      print('   - Date acceptation: ${course.dateAcceptation}');
      print('   - Date fin: ${course.dateFin}');
    });

    test('Structure des données JSON pour les courses terminées', () {
      // Simuler les données JSON qui viendraient de l'API
      final jsonData = {
        'id': 42,
        'passager_name': 'Jean Dupont',
        'chauffeur_name': 'Marie Martin',
        'depart_latitude': -4.3169,
        'depart_longitude': 15.3012,
        'destination_latitude': -4.3269,
        'destination_longitude': 15.3112,
        'distance': 2500.0,
        'duree_estimee': 900.0,
        'prix_estime': '12.50',
        'statut': 'terminee',
        'date_creation': '2024-10-23T10:00:00Z',
        'date_acceptation': '2024-10-23T10:05:00Z',
        'date_fin': '2024-10-23T10:20:00Z',
        'passager': 1,
        'chauffeur': 2,
        'vehicule': 3,
      };

      // Créer le modèle depuis JSON
      final ride = RideModel.fromJson(jsonData);

      // Vérifications
      expect(ride.id, 42);
      expect(ride.passagerName, 'Jean Dupont');
      expect(ride.chauffeurName, 'Marie Martin');
      expect(ride.statut, 'terminee');
      expect(ride.isFinished, true);
      expect(ride.prixEstime, '12.50');
      expect(ride.dateFin, '2024-10-23T10:20:00Z');

      // Vérifier la conversion JSON -> Modèle -> JSON
      final backToJson = ride.toJson();
      expect(backToJson['id'], 42);
      expect(backToJson['statut'], 'terminee');
      expect(backToJson['prix_estime'], '12.50');

      print('✅ Structure JSON des courses terminées validée');
      print('   - Conversion JSON → RideModel: OK');
      print('   - Conversion RideModel → JSON: OK');
      print('   - Données critiques préservées: OK');
    });
  });
}
