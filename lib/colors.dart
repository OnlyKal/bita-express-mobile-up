import 'package:flutter/material.dart';

class AppColors {
  static const Color mainColor = Color(0xFFEB502D);

  // Couleurs principales
  static const Color primary = Color(0xFFEB502D);
  static const Color primaryLight = Color(0xFFFFEBE5);
  static const Color primaryDark = Color(0xFFD63F1F);

  static const Color secondary = Color(0xFF6C757D);
  static const Color success = Color(0xFF198754);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFDC3545);
  static const Color info = Color(0xFF0DCAF0);

  // Couleurs de texte
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textLight = Color(0xFF8E8E8E);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Couleurs de fond
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF5F5F5);

  // Couleurs d'état
  static const Color successLight = Color(0xFFE8F5E8);
  static const Color warningLight = Color(0xFFFFF3CD);
  static const Color errorLight = Color(0xFFF8D7DA);
  static const Color infoLight = Color(0xFFD1ECF1);

  // Bordures
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF0F0F0);

  // Couleurs spéciales
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;
}

// Constantes de design
class AppDesign {
  static const double radius = 7.0;
  static const double radiusSmall = 4.0;
  static const double radiusLarge = 12.0;

  // Espacements
  static const double spacingXs = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXl = 32.0;

  // Tailles de police
  static const double fontSizeXs = 12.0;
  static const double fontSizeS = 14.0;
  static const double fontSizeM = 16.0;
  static const double fontSizeL = 18.0;
  static const double fontSizeXl = 24.0;
  static const double fontSizeXxl = 32.0;

  // BorderRadius
  static BorderRadius get borderRadius => BorderRadius.circular(radius);
  static BorderRadius get borderRadiusSmall =>
      BorderRadius.circular(radiusSmall);
  static BorderRadius get borderRadiusLarge =>
      BorderRadius.circular(radiusLarge);
}

// Widgets de design personnalisés
class AppContainer extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;

  const AppContainer({
    Key? key,
    required this.child,
    this.backgroundColor,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderColor,
    this.borderWidth = 1.0,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget container = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(AppDesign.spacingM),
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: AppDesign.borderRadius,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: container);
    }

    return container;
  }
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final bool isOutlined;
  final IconData? icon;

  const AppButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.padding,
    this.width,
    this.isOutlined = false,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.primary;
    final txtColor = textColor ?? AppColors.textWhite;

    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? AppColors.transparent : bgColor,
          foregroundColor: isOutlined ? bgColor : txtColor,
          side: isOutlined ? BorderSide(color: bgColor, width: 1.5) : null,
          shape: RoundedRectangleBorder(borderRadius: AppDesign.borderRadius),
          padding:
              padding ??
              const EdgeInsets.symmetric(
                horizontal: AppDesign.spacingL,
                vertical: AppDesign.spacingM,
              ),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: AppDesign.spacingS),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: AppDesign.fontSizeM,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
