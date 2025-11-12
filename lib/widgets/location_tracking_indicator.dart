import 'package:flutter/material.dart';
import '../services/vehicle_location_service.dart';

class LocationTrackingIndicator extends StatefulWidget {
  const LocationTrackingIndicator({super.key});

  @override
  State<LocationTrackingIndicator> createState() =>
      _LocationTrackingIndicatorState();
}

class _LocationTrackingIndicatorState extends State<LocationTrackingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (VehicleLocationService.isRunning) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Vérifier le statut en temps réel
    final isRunning = VehicleLocationService.isRunning;

    // Gérer l'animation
    if (isRunning && !_animationController.isAnimating) {
      _animationController.repeat(reverse: true);
    } else if (!isRunning && _animationController.isAnimating) {
      _animationController.stop();
      _animationController.reset();
    }

    if (!isRunning) {
      return const SizedBox.shrink(); // Ne rien afficher si inactif
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: Colors.white.withOpacity(_animation.value),
              ),
              const SizedBox(width: 4),
              Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(_animation.value),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
