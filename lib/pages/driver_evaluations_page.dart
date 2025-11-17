import 'package:flutter/material.dart';
import '../api.dart';
import '../session.dart';
import '../colors.dart';
import '../models/driver_evaluation.dart';

class DriverEvaluationsPage extends StatefulWidget {
  const DriverEvaluationsPage({super.key});

  @override
  State<DriverEvaluationsPage> createState() => _DriverEvaluationsPageState();
}

class _DriverEvaluationsPageState extends State<DriverEvaluationsPage> {
  List<DriverEvaluation> _evaluations = [];
  DriverRatingStats? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvaluations();
  }

  Future<void> _loadEvaluations() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final token = await SessionManager.getToken();
      final userData = await SessionManager.getUserData();

      if (token == null || userData == null) {
        setState(() {
          _error = 'Utilisateur non connecté';
          _isLoading = false;
        });
        return;
      }

      final chauffeurId = userData['id'];
      if (chauffeurId == null) {
        setState(() {
          _error = 'ID chauffeur non trouvé';
          _isLoading = false;
        });
        return;
      }

      // Récupérer les évaluations du chauffeur connecté
      final evaluationsResponse = await ApiService.getMyDriverEvaluations(
        token: token,
        userId: chauffeurId,
      );

      // Pour les statistiques, on utilisera l'ID du chauffeur si disponible
      ApiResponse? statsResponse;
      if (chauffeurId != null) {
        statsResponse = await ApiService.getDriverAverageRating(
          token: token,
          chauffeurId: chauffeurId,
        );
      }

      if (evaluationsResponse.success) {
        final List<dynamic> evaluationsList = evaluationsResponse.data is List
            ? evaluationsResponse.data
            : evaluationsResponse.data['evaluations'] ?? [];

        setState(() {
          _evaluations = evaluationsList
              .map((json) => DriverEvaluation.fromJson(json))
              .toList();

          // Trier par date (plus récentes en premier)
          _evaluations.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
        });
      }

      if (statsResponse != null && statsResponse.success) {
        setState(() {
          _stats = DriverRatingStats.fromJson(statsResponse!.data);
        });
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des évaluations: $e');
      setState(() {
        _error = 'Erreur lors du chargement: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshEvaluations() async {
    await _loadEvaluations();
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 2:
        return Colors.deepOrange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPerformanceBadgeColor(double moyenne) {
    if (moyenne >= 4.5) return AppColors.success;
    if (moyenne >= 4.0) return Colors.lightGreen;
    if (moyenne >= 3.5) return AppColors.warning;
    if (moyenne >= 3.0) return Colors.orange;
    return AppColors.error;
  }

  String _getPerformanceText(double moyenne) {
    if (moyenne >= 4.5) return 'EXCELLENT CHAUFFEUR';
    if (moyenne >= 4.0) return 'TRÈS BON CHAUFFEUR';
    if (moyenne >= 3.5) return 'BON CHAUFFEUR';
    if (moyenne >= 3.0) return 'CHAUFFEUR CORRECT';
    if (moyenne >= 2.0) return 'À AMÉLIORER';
    return 'BESOIN DE FORMATION';
  }

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    if (_stats == null && _evaluations.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.star_outline,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Aucune évaluation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Vous n\'avez pas encore reçu d\'évaluations de vos passagers.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Continuez à offrir un excellent service !',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Calculer les statistiques manuellement si pas de stats de l'API
    double moyenne = 0.0;
    int totalEvaluations = _evaluations.length;
    Map<int, int> distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    if (_evaluations.isNotEmpty) {
      int sommePonts = _evaluations.fold(0, (sum, eval) => sum + eval.note);
      moyenne = sommePonts / totalEvaluations;

      for (var eval in _evaluations) {
        distribution[eval.note] = (distribution[eval.note] ?? 0) + 1;
      }
    }

    // Utiliser les stats de l'API si disponibles
    if (_stats != null) {
      moyenne = _stats!.moyenne;
      totalEvaluations = _stats!.totalEvaluations;
      distribution = _stats!.distributionNotes;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Badge de performance
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getPerformanceBadgeColor(moyenne),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getPerformanceText(moyenne),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 20),

            // Moyenne générale avec animation visuelle
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.15),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          moyenne.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          '/5',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        5,
                        (index) => Icon(
                          Icons.star,
                          size: 12,
                          color: index < moyenne.round()
                              ? Colors.amber
                              : Colors.grey[300],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              totalEvaluations == 0
                  ? 'Aucune évaluation'
                  : totalEvaluations == 1
                  ? '1 évaluation'
                  : '$totalEvaluations évaluations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 24),

            // Distribution des notes avec design amélioré
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Répartition des notes',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12),
                  ...List.generate(5, (index) {
                    final rating = 5 - index;
                    final count = distribution[rating] ?? 0;
                    final percentage = totalEvaluations > 0
                        ? count / totalEvaluations
                        : 0.0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            child: Text(
                              '$rating',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Icon(Icons.star, size: 16, color: Colors.amber),
                          SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: FractionallySizedBox(
                                widthFactor: percentage,
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _getRatingColor(rating),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          SizedBox(
                            width: 32,
                            child: Text(
                              '$count',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Statistiques supplémentaires
            if (totalEvaluations > 0) ...[
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Évaluations positives',
                      '${(((distribution[4] ?? 0) + (distribution[5] ?? 0)) / totalEvaluations * 100).toInt()}%',
                      Icons.thumb_up,
                      AppColors.success,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      'Note moyenne',
                      moyenne >= 4.5
                          ? 'Excellent'
                          : moyenne >= 4.0
                          ? 'Très bon'
                          : moyenne >= 3.0
                          ? 'Bon'
                          : 'À améliorer',
                      Icons.trending_up,
                      moyenne >= 4.0
                          ? AppColors.success
                          : moyenne >= 3.0
                          ? AppColors.warning
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluationCard(DriverEvaluation evaluation) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header coloré avec note
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getRatingColor(evaluation.note).withOpacity(0.08),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Note avec cercle coloré
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getRatingColor(evaluation.note),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${evaluation.note}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(
                              5,
                              (index) => Padding(
                                padding: EdgeInsets.only(right: 2),
                                child: Icon(
                                  Icons.star,
                                  size: 16,
                                  color: index < evaluation.note
                                      ? Colors.amber
                                      : Colors.grey[300],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getRatingColor(evaluation.note),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              evaluation.ratingText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: 2),
                      Text(
                        evaluation.formattedDate,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Contenu principal
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informations du passager et course
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                evaluation.passagerName ?? 'Passager anonyme',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_taxi,
                                    size: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Course #${evaluation.courseId}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          evaluation.note >= 4
                              ? Icons.sentiment_very_satisfied
                              : evaluation.note >= 3
                              ? Icons.sentiment_neutral
                              : Icons.sentiment_dissatisfied,
                          color: _getRatingColor(evaluation.note),
                          size: 24,
                        ),
                      ],
                    ),
                  ),

                  // Commentaire (si présent)
                  if (evaluation.commentaire != null &&
                      evaluation.commentaire!.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.format_quote,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Commentaire du passager',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            '"${evaluation.commentaire!}"',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,

                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(color: AppColors.primary),
          ),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.star, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Mes évaluations',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_evaluations.isNotEmpty)
                      Text(
                        '${_evaluations.length} évaluation${_evaluations.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Container(
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: _refreshEvaluations,
                icon: Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Actualiser',
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Container(
              decoration: BoxDecoration(color: AppColors.background),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Chargement des évaluations...',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Récupération de vos notes et commentaires',
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _error != null
          ? Container(
              decoration: BoxDecoration(color: AppColors.background),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.error.withOpacity(0.2),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.sentiment_dissatisfied,
                          size: 50,
                          color: AppColors.error,
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Oops! Une erreur s\'est produite',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.errorLight),
                        ),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _refreshEvaluations,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(Icons.refresh),
                        label: Text(
                          'Réessayer',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshEvaluations,
              child: ListView(
                children: [
                  // Carte des statistiques
                  _buildStatsCard(),

                  // Liste des évaluations
                  if (_evaluations.isNotEmpty) ...[
                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.history,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Historique des évaluations',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Dernières évaluations reçues de vos passagers',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_evaluations.length}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ..._evaluations.map(
                      (evaluation) => _buildEvaluationCard(evaluation),
                    ),
                  ],

                  // Espacement en bas
                  SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
