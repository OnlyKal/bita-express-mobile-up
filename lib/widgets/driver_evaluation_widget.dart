import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../colors.dart';
import '../api.dart';
import '../session.dart';

class DriverEvaluationWidget extends StatefulWidget {
  final int chauffeurId;
  final int courseId;
  final String chauffeurName;
  final VoidCallback? onEvaluationCompleted;

  const DriverEvaluationWidget({
    super.key,
    required this.chauffeurId,
    required this.courseId,
    required this.chauffeurName,
    this.onEvaluationCompleted,
  });

  @override
  State<DriverEvaluationWidget> createState() => _DriverEvaluationWidgetState();
}

class _DriverEvaluationWidgetState extends State<DriverEvaluationWidget> {
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitEvaluation() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez sélectionner une note'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        throw Exception('Token non trouvé');
      }

      final response = await ApiService.evaluateDriver(
        token: token,
        chauffeurId: widget.chauffeurId,
        courseId: widget.courseId,
        note: _selectedRating,
        commentaire: _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : null,
      );

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(CupertinoIcons.check_mark_circled_solid, 
                     color: Colors.white, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text(response.message)),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );

        if (widget.onEvaluationCompleted != null) {
          widget.onEvaluationCompleted!();
        }

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(CupertinoIcons.xmark_circle_fill, 
                     color: Colors.white, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text(response.message)),
              ],
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(CupertinoIcons.exclamationmark_triangle_fill, 
                   color: Colors.white, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text('Erreur: ${e.toString()}')),
            ],
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Widget _buildStarRating() {
    return Column(
      children: [
        Text(
          'Comment évaluez-vous ce chauffeur ?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starNumber = index + 1;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedRating = starNumber;
                });
              },
              child: Container(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.star,
                  size: 40,
                  color: starNumber <= _selectedRating
                      ? Colors.amber
                      : Colors.grey[300],
                ),
              ),
            );
          }),
        ),
        SizedBox(height: 8),
        Text(
          _getRatingText(_selectedRating),
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
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
        return 'Sélectionnez une note';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      title: Row(
        children: [
          Icon(Icons.star, color: Colors.amber),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Évaluer le chauffeur',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.chauffeurName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            _buildStarRating(),
            SizedBox(height: 24),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Commentaire (optionnel)',
                hintText: 'Partagez votre expérience...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text('Passer'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitEvaluation,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          child: _isSubmitting
              ? SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.textWhite),
                  ),
                )
              : Text('Évaluer'),
        ),
      ],
    );
  }
}

/// Widget pour afficher les évaluations d'un chauffeur
class DriverRatingsDisplay extends StatelessWidget {
  final int chauffeurId;
  final String? averageRating;
  final String? totalEvaluations;

  const DriverRatingsDisplay({
    super.key,
    required this.chauffeurId,
    this.averageRating,
    this.totalEvaluations,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: Colors.amber, size: 16),
          SizedBox(width: 4),
          Text(
            averageRating ?? '0.0',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (totalEvaluations != null) ...[
            SizedBox(width: 4),
            Text(
              '($totalEvaluations)',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// Fonction helper pour afficher le modal d'évaluation
Future<bool?> showDriverEvaluationDialog({
  required BuildContext context,
  required int chauffeurId,
  required int courseId,
  required String chauffeurName,
  VoidCallback? onEvaluationCompleted,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => DriverEvaluationWidget(
      chauffeurId: chauffeurId,
      courseId: courseId,
      chauffeurName: chauffeurName,
      onEvaluationCompleted: onEvaluationCompleted,
    ),
  );
}
