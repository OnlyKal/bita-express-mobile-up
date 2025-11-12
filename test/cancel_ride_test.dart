import 'package:flutter_test/flutter_test.dart';
import '../lib/api.dart';

/// Test pour vérifier l'annulation de courses acceptées
void main() {
  group('Tests d\'annulation de course acceptée', () {
    test('Vérifie que les statuts permettent l\'annulation', () {
      // Test des différents statuts de course
      final courseEnAttente = RideModel(
        id: 1,
        passagerName: 'Test User',
        departLatitude: 0.0,
        departLongitude: 0.0,
        destinationLatitude: 0.0,
        destinationLongitude: 0.0,
        distance: 1000.0,
        dureeEstimee: 600.0,
        prixEstime: '5.00',
        statut: 'en_attente',
        dateCreation: '2024-01-01',
        passager: 1,
      );

      final courseAcceptee = RideModel(
        id: 2,
        passagerName: 'Test User',
        departLatitude: 0.0,
        departLongitude: 0.0,
        destinationLatitude: 0.0,
        destinationLongitude: 0.0,
        distance: 1000.0,
        dureeEstimee: 600.0,
        prixEstime: '5.00',
        statut: 'acceptee',
        dateCreation: '2024-01-01',
        passager: 1,
        chauffeur: 1,
        vehicule: 1,
      );

      final courseEnCours = RideModel(
        id: 3,
        passagerName: 'Test User',
        departLatitude: 0.0,
        departLongitude: 0.0,
        destinationLatitude: 0.0,
        destinationLongitude: 0.0,
        distance: 1000.0,
        dureeEstimee: 600.0,
        prixEstime: '5.00',
        statut: 'en_cours',
        dateCreation: '2024-01-01',
        passager: 1,
        chauffeur: 1,
        vehicule: 1,
      );

      final courseTerminee = RideModel(
        id: 4,
        passagerName: 'Test User',
        departLatitude: 0.0,
        departLongitude: 0.0,
        destinationLatitude: 0.0,
        destinationLongitude: 0.0,
        distance: 1000.0,
        dureeEstimee: 600.0,
        prixEstime: '5.00',
        statut: 'terminee',
        dateCreation: '2024-01-01',
        passager: 1,
        chauffeur: 1,
        vehicule: 1,
      );

      // Vérifications
      expect(courseEnAttente.isWaiting, true);
      expect(courseEnAttente.isAccepted, false);
      expect(courseEnAttente.isInProgress, false);
      expect(courseEnAttente.isFinished, false);

      expect(courseAcceptee.isWaiting, false);
      expect(courseAcceptee.isAccepted, true);
      expect(courseAcceptee.isInProgress, false);
      expect(courseAcceptee.isFinished, false);

      expect(courseEnCours.isWaiting, false);
      expect(courseEnCours.isAccepted, false);
      expect(courseEnCours.isInProgress, true);
      expect(courseEnCours.isFinished, false);

      expect(courseTerminee.isWaiting, false);
      expect(courseTerminee.isAccepted, false);
      expect(courseTerminee.isInProgress, false);
      expect(courseTerminee.isFinished, true);

      // Test de la logique d'annulation
      // Peut annuler si en attente OU acceptée
      bool peutAnnulerEnAttente =
          courseEnAttente.isWaiting || courseEnAttente.isAccepted;
      bool peutAnnulerAcceptee =
          courseAcceptee.isWaiting || courseAcceptee.isAccepted;
      bool peutAnnulerEnCours =
          courseEnCours.isWaiting || courseEnCours.isAccepted;
      bool peutAnnulerTerminee =
          courseTerminee.isWaiting || courseTerminee.isAccepted;

      expect(
        peutAnnulerEnAttente,
        true,
        reason: 'Doit pouvoir annuler une course en attente',
      );
      expect(
        peutAnnulerAcceptee,
        true,
        reason: 'Doit pouvoir annuler une course acceptée',
      );
      expect(
        peutAnnulerEnCours,
        false,
        reason: 'Ne doit pas pouvoir annuler une course en cours',
      );
      expect(
        peutAnnulerTerminee,
        false,
        reason: 'Ne doit pas pouvoir annuler une course terminée',
      );

      print('✅ Tous les tests d\'annulation de course sont RÉUSSIS');
      print('   - Course en attente: Annulation AUTORISÉE');
      print('   - Course acceptée: Annulation AUTORISÉE');
      print('   - Course en cours: Annulation INTERDITE');
      print('   - Course terminée: Annulation INTERDITE');
    });

    test('Vérifie la logique métier d\'annulation', () {
      // Test avec une course acceptée (cas d'usage principal)
      final courseAcceptee = RideModel(
        id: 100,
        passagerName: 'Passager Test',
        chauffeurName: 'Chauffeur Test',
        departLatitude: -4.3169,
        departLongitude: 15.3012,
        destinationLatitude: -4.3269,
        destinationLongitude: 15.3112,
        distance: 2500.0,
        dureeEstimee: 900.0,
        prixEstime: '12.50',
        statut: 'acceptee',
        dateCreation: '2024-10-23T10:30:00Z',
        dateAcceptation: '2024-10-23T10:35:00Z',
        passager: 1,
        chauffeur: 2,
        vehicule: 3,
      );

      // Vérifications détaillées
      expect(courseAcceptee.statut, 'acceptee');
      expect(courseAcceptee.isAccepted, true);
      expect(courseAcceptee.chauffeur, isNotNull);
      expect(courseAcceptee.vehicule, isNotNull);
      expect(courseAcceptee.dateAcceptation, isNotNull);

      // Logique d'annulation - les deux types d'utilisateurs peuvent annuler
      bool passagerPeutAnnuler =
          courseAcceptee.isWaiting || courseAcceptee.isAccepted;
      bool chauffeurPeutAnnuler =
          courseAcceptee.isWaiting || courseAcceptee.isAccepted;

      expect(passagerPeutAnnuler, true);
      expect(chauffeurPeutAnnuler, true);

      print('✅ Course acceptée: Les deux utilisateurs peuvent annuler');
      print('   - ID Course: ${courseAcceptee.id}');
      print('   - Statut: ${courseAcceptee.statut}');
      print('   - Passager peut annuler: $passagerPeutAnnuler');
      print('   - Chauffeur peut annuler: $chauffeurPeutAnnuler');
    });
  });
}
