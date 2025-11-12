import 'package:flutter_test/flutter_test.dart';
import '../lib/api.dart';

void main() {
  group('FlexPay Direct Payment Tests', () {
    test('Payment model validation', () {
      final payment = PaymentModel(
        id: 123,
        courseId: 1,
        devise: 'CDF',
        montant: 2500.0,
        moyen: 'mobile_money',
        statut: 'en_cours',
        dateCreation: '2024-01-15T10:00:00Z',
        orderNumber: 'test-123',
      );

      expect(payment.id, equals(123));
      expect(payment.montant, equals(2500.0));
      expect(payment.devise, equals('CDF'));
      expect(payment.moyen, equals('mobile_money'));
      expect(payment.courseId, equals(1));
      expect(payment.isPending, isTrue);
      expect(payment.isSuccessful, isFalse);
    });

    test('API Response validation', () {
      final successResponse = ApiResponse(
        success: true,
        message: 'Paiement réussi',
        data: {'payment_id': 123, 'status': 'completed'},
      );

      final failedResponse = ApiResponse(
        success: false,
        message: 'Paiement échoué',
        data: null,
      );

      expect(successResponse.success, isTrue);
      expect(successResponse.message, equals('Paiement réussi'));
      expect(failedResponse.success, isFalse);
      expect(failedResponse.message, equals('Paiement échoué'));
    });

    test('Payment model status detection', () {
      final successPayment = PaymentModel(
        courseId: 1,
        devise: 'CDF',
        montant: 2500.0,
        moyen: 'mobile_money',
        statut: 'reussi',
        dateCreation: '2024-01-15T10:00:00Z',
      );

      final failedPayment = PaymentModel(
        courseId: 1,
        devise: 'CDF',
        montant: 2500.0,
        moyen: 'mobile_money',
        statut: 'echec',
        dateCreation: '2024-01-15T10:00:00Z',
      );

      expect(successPayment.isSuccessful, isTrue);
      expect(successPayment.isPending, isFalse);
      expect(successPayment.isFailed, isFalse);

      expect(failedPayment.isSuccessful, isFalse);
      expect(failedPayment.isPending, isFalse);
      expect(failedPayment.isFailed, isTrue);
    });

    test('Ride model status detection', () {
      final completedRide = RideModel(
        id: 1,
        passagerName: 'Test Passager',
        departLatitude: -4.4419,
        departLongitude: 15.2663,
        destinationLatitude: -4.4319,
        destinationLongitude: 15.2763,
        distance: 5000.0,
        dureeEstimee: 900.0,
        prixEstime: '2500.00',
        statut: 'terminee',
        dateCreation: '2024-01-15T10:00:00Z',
        passager: 1,
      );

      final waitingRide = RideModel(
        id: 2,
        passagerName: 'Test Passager 2',
        departLatitude: -4.4419,
        departLongitude: 15.2663,
        destinationLatitude: -4.4319,
        destinationLongitude: 15.2763,
        distance: 5000.0,
        dureeEstimee: 900.0,
        prixEstime: '2500.00',
        statut: 'en_attente',
        dateCreation: '2024-01-15T10:00:00Z',
        passager: 1,
      );

      expect(completedRide.isFinished, isTrue);
      expect(completedRide.isWaiting, isFalse);
      expect(completedRide.isAccepted, isFalse);

      expect(waitingRide.isFinished, isFalse);
      expect(waitingRide.isWaiting, isTrue);
      expect(waitingRide.isAccepted, isFalse);
    });

    test('Phone number operator detection', () {
      // Test des différents opérateurs
      expect(getOperatorFromPhone('243812345678'), equals('Vodacom'));
      expect(getOperatorFromPhone('243822345678'), equals('Vodacom'));
      expect(getOperatorFromPhone('243842345678'), equals('Vodacom'));
      expect(getOperatorFromPhone('243852345678'), equals('Vodacom'));

      expect(getOperatorFromPhone('243892345678'), equals('Airtel'));
      expect(getOperatorFromPhone('243972345678'), equals('Airtel'));
      expect(getOperatorFromPhone('243982345678'), equals('Airtel'));
      expect(getOperatorFromPhone('243992345678'), equals('Airtel'));

      expect(getOperatorFromPhone('243902345678'), equals('Orange'));
      expect(getOperatorFromPhone('243912345678'), equals('Orange'));

      expect(getOperatorFromPhone('243803345678'), equals('Tigo'));

      expect(getOperatorFromPhone('243123456789'), equals('Inconnu'));
    });

    test('Phone number validation', () {
      expect(isValidPhoneNumber('243812345678'), isTrue);
      expect(isValidPhoneNumber('243892345678'), isTrue);
      expect(isValidPhoneNumber('243902345678'), isTrue);

      // Numéros invalides
      expect(isValidPhoneNumber('12345678'), isFalse);
      expect(isValidPhoneNumber('244812345678'), isFalse);
      expect(isValidPhoneNumber('243'), isFalse);
      expect(isValidPhoneNumber('abcdefghijkl'), isFalse);
    });

    test('Currency conversion', () {
      // Test de conversion CDF vers USD (taux approximatif: 1 USD = 2500 CDF)
      expect(convertCurrency(2500.0, 'CDF', 'USD'), closeTo(1.0, 0.1));
      expect(convertCurrency(1.0, 'USD', 'CDF'), closeTo(2500.0, 100.0));
      expect(convertCurrency(1000.0, 'CDF', 'CDF'), equals(1000.0));
      expect(convertCurrency(50.0, 'USD', 'USD'), equals(50.0));
    });

    test('Payment type validation', () {
      expect(isValidPaymentType(1), isTrue); // Mobile Money seulement
      expect(isValidPaymentType(0), isFalse);
      expect(isValidPaymentType(2), isFalse); // Carte supprimée
      expect(isValidPaymentType(3), isFalse);
      expect(isValidPaymentType(-1), isFalse);
    });

    test('Amount validation', () {
      expect(isValidAmount(100.0, 'CDF'), isTrue);
      expect(isValidAmount(1000000.0, 'CDF'), isTrue);
      expect(isValidAmount(50.0, 'CDF'), isFalse); // Trop petit
      expect(isValidAmount(2000000.0, 'CDF'), isFalse); // Trop grand

      expect(isValidAmount(1.0, 'USD'), isTrue);
      expect(isValidAmount(500.0, 'USD'), isTrue);
      expect(isValidAmount(0.5, 'USD'), isFalse); // Trop petit
      expect(isValidAmount(1000.0, 'USD'), isFalse); // Trop grand
    });
  });
}

// Fonctions utilitaires pour les tests
String getOperatorFromPhone(String phone) {
  if (phone.length != 12 || !phone.startsWith('243')) {
    return 'Inconnu';
  }

  final prefix = phone.substring(3, 5);
  switch (prefix) {
    case '81':
    case '82':
    case '84':
    case '85':
      return 'Vodacom';
    case '89':
    case '97':
    case '98':
    case '99':
      return 'Airtel';
    case '90':
    case '91':
      return 'Orange';
    case '80':
      return 'Tigo';
    default:
      return 'Inconnu';
  }
}

bool isValidPhoneNumber(String phone) {
  if (phone.length != 12) return false;
  if (!phone.startsWith('243')) return false;

  final regex = RegExp(r'^243[0-9]{9}$');
  return regex.hasMatch(phone);
}

double convertCurrency(double amount, String fromCurrency, String toCurrency) {
  if (fromCurrency == toCurrency) {
    return amount;
  }

  // Taux de change approximatifs (à remplacer par des taux réels en production)
  const double usdToCdf = 2500.0;

  if (fromCurrency == 'CDF' && toCurrency == 'USD') {
    return amount / usdToCdf;
  } else if (fromCurrency == 'USD' && toCurrency == 'CDF') {
    return amount * usdToCdf;
  }

  return amount;
}

bool isValidPaymentType(int type) {
  return type == 1; // 1 = Mobile Money seulement
}

bool isValidAmount(double amount, String currency) {
  if (currency == 'CDF') {
    return amount >= 100.0 && amount <= 1000000.0;
  } else if (currency == 'USD') {
    return amount >= 1.0 && amount <= 500.0;
  }
  return false;
}
