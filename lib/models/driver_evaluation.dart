/// Modèle pour représenter une évaluation de chauffeur
class DriverEvaluation {
  final int id;
  final int chauffeurId;
  final int courseId;
  final int note; // Note de 1 à 5
  final String? commentaire;
  final String dateCreation;
  final String? passagerName;

  DriverEvaluation({
    required this.id,
    required this.chauffeurId,
    required this.courseId,
    required this.note,
    this.commentaire,
    required this.dateCreation,
    this.passagerName,
  });

  factory DriverEvaluation.fromJson(Map<String, dynamic> json) {
    return DriverEvaluation(
      id: json['id'] ?? 0,
      chauffeurId: json['chauffeur'] ?? 0,
      courseId: json['course'] ?? 0,
      note: json['note'] ?? 0,
      commentaire: json['commentaire'],
      dateCreation: json['date_creation'] ?? '',
      passagerName: json['passager_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chauffeur': chauffeurId,
      'course': courseId,
      'note': note,
      'commentaire': commentaire,
      'date_creation': dateCreation,
      'passager_name': passagerName,
    };
  }

  /// Getter pour la note formatée avec étoiles
  String get formattedRating => '★' * note + '☆' * (5 - note);

  /// Getter pour vérifier si c'est une bonne évaluation (4+ étoiles)
  bool get isGoodRating => note >= 4;

  /// Getter pour vérifier si c'est une mauvaise évaluation (2- étoiles)
  bool get isBadRating => note <= 2;

  /// Getter pour le texte descriptif de la note
  String get ratingText {
    switch (note) {
      case 1:
        return 'Très insatisfait';
      case 2:
        return 'Insatisfait';
      case 3:
        return 'Correct';
      case 4:
        return 'Satisfait';
      case 5:
        return 'Très satisfait';
      default:
        return 'Non évalué';
    }
  }

  /// Getter pour la date formatée
  String get formattedDate {
    try {
      final date = DateTime.parse(dateCreation);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateCreation;
    }
  }
}

/// Modèle pour les statistiques d'évaluation d'un chauffeur
class DriverRatingStats {
  final double moyenne;
  final int totalEvaluations;
  final Map<int, int> distributionNotes; // Note => Nombre d'évaluations
  final List<DriverEvaluation> dernieresEvaluations;

  DriverRatingStats({
    required this.moyenne,
    required this.totalEvaluations,
    required this.distributionNotes,
    required this.dernieresEvaluations,
  });

  factory DriverRatingStats.fromJson(Map<String, dynamic> json) {
    // Distribution des notes (par défaut vide)
    Map<int, int> distribution = {};
    if (json['distribution_notes'] != null) {
      final distData = json['distribution_notes'] as Map<String, dynamic>;
      for (int i = 1; i <= 5; i++) {
        distribution[i] = distData[i.toString()] ?? 0;
      }
    }

    // Dernières évaluations
    List<DriverEvaluation> evaluations = [];
    if (json['dernieres_evaluations'] != null) {
      evaluations = (json['dernieres_evaluations'] as List)
          .map((evalJson) => DriverEvaluation.fromJson(evalJson))
          .toList();
    }

    return DriverRatingStats(
      moyenne: (json['moyenne'] ?? 0.0).toDouble(),
      totalEvaluations: json['total_evaluations'] ?? 0,
      distributionNotes: distribution,
      dernieresEvaluations: evaluations,
    );
  }

  /// Getter pour la moyenne formatée avec étoiles
  String get formattedAverage => '★ ${moyenne.toStringAsFixed(1)}';

  /// Getter pour le texte du total d'évaluations
  String get totalText => totalEvaluations == 0
      ? 'Aucune évaluation'
      : totalEvaluations == 1
      ? '1 évaluation'
      : '$totalEvaluations évaluations';

  /// Getter pour vérifier si le chauffeur a une bonne réputation
  bool get hasGoodReputation => moyenne >= 4.0 && totalEvaluations >= 5;

  /// Getter pour le pourcentage d'évaluations positives (4+ étoiles)
  double get positiveRatingPercentage {
    if (totalEvaluations == 0) return 0.0;

    final positiveCount =
        (distributionNotes[4] ?? 0) + (distributionNotes[5] ?? 0);
    return (positiveCount / totalEvaluations) * 100;
  }

  /// Méthode pour obtenir la couleur selon la moyenne
  String get ratingColorHex {
    if (moyenne >= 4.5) return '#4CAF50'; // Vert - Excellent
    if (moyenne >= 4.0) return '#8BC34A'; // Vert clair - Très bon
    if (moyenne >= 3.5) return '#FFC107'; // Jaune - Bon
    if (moyenne >= 3.0) return '#FF9800'; // Orange - Correct
    if (moyenne >= 2.0) return '#FF5722'; // Rouge-orange - Faible
    return '#F44336'; // Rouge - Très faible
  }
}
