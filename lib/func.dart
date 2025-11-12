import 'package:flutter/material.dart';

class NavigationHelper {
  /// Méthode goto pour naviguer vers une nouvelle page en remplaçant la page actuelle
  static void goto(BuildContext context, Widget destination) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  /// Méthode pour naviguer vers une nouvelle page sans remplacer
  static void navigateTo(BuildContext context, Widget destination) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  /// Méthode pour revenir à la page précédente
  static void goBack(BuildContext context) {
    Navigator.pop(context);
  }

  /// Méthode pour naviguer vers une page nommée
  static void gotoNamed(BuildContext context, String routeName) {
    Navigator.pushReplacementNamed(context, routeName);
  }
}
