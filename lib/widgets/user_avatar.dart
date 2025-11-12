import 'package:flutter/material.dart';
import '../config.dart';
import '../colors.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double size;
  final double iconSize;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    required this.size,
    double? iconSize,
  }) : iconSize = iconSize ?? size * 0.6;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: avatarUrl != null && avatarUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(size / 2),
              child: Image.network(
                AppConfig.getAvatarUrl(avatarUrl),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.person,
                    size: iconSize,
                    color: AppColors.mainColor,
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: iconSize * 0.6,
                      height: iconSize * 0.6,
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        color: AppColors.mainColor,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
              ),
            )
          : Icon(Icons.person, size: iconSize, color: AppColors.mainColor),
    );
  }
}
