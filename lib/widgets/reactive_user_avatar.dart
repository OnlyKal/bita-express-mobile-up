import 'package:flutter/material.dart';
import '../session.dart';
import 'user_avatar.dart';

/// Widget Avatar qui se met à jour automatiquement quand les données utilisateur changent
class ReactiveUserAvatar extends StatefulWidget {
  final double size;
  final double iconSize;

  const ReactiveUserAvatar({super.key, required this.size, double? iconSize})
    : iconSize = iconSize ?? size * 0.6;

  @override
  State<ReactiveUserAvatar> createState() => _ReactiveUserAvatarState();
}

class _ReactiveUserAvatarState extends State<ReactiveUserAvatar> {
  String? avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadInitialAvatar();

    // Écouter les changements de données utilisateur
    SessionManager.userDataNotifier.addListener(_onUserDataChanged);
  }

  @override
  void dispose() {
    // Supprimer le listener pour éviter les fuites mémoire
    SessionManager.userDataNotifier.removeListener(_onUserDataChanged);
    super.dispose();
  }

  void _onUserDataChanged() {
    if (mounted) {
      final userData = SessionManager.userDataNotifier.value;
      setState(() {
        avatarUrl = userData?['avatar_url'];
      });
    }
  }

  Future<void> _loadInitialAvatar() async {
    final userData = await SessionManager.getUserData();
    if (mounted) {
      setState(() {
        avatarUrl = userData?['avatar_url'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return UserAvatar(
      avatarUrl: avatarUrl,
      size: widget.size,
      iconSize: widget.iconSize,
    );
  }
}
