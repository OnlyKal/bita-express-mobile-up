import 'package:bita_express_new/home.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../colors.dart';
import '../session.dart';
import '../widgets/user_avatar.dart';
import '../config.dart';
import 'change_password.dart';
import '../func.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();

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
      setState(() {
        userData = SessionManager.userDataNotifier.value;
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      final userDataResult = await SessionManager.getUserData();

      setState(() {
        userData = userDataResult;
        isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateUserData({
    required String firstName,
    required String lastName,
    required String email,
    required String telephone,
    required String typeUtilisateur,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        print('Erreur: Token non trouvé');
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }

      print('Envoi de la requête de mise à jour...');
      print('URL: ${AppConfig.apiBaseUrl}/user/update/');
      print('Token: ${token.substring(0, 20)}...');
      print(
        'Données: {firstName: $firstName, lastName: $lastName, email: $email, telephone: $telephone, typeUtilisateur: $typeUtilisateur}',
      );

      final response = await http
          .put(
            Uri.parse('${AppConfig.apiBaseUrl}/user/update/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': token,
            },
            body: json.encode({
              'first_name': firstName,
              'last_name': lastName,
              'email': email,
              'telephone': telephone,
              'type_utilisateur': typeUtilisateur,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Timeout: La requête a pris trop de temps');
            },
          );

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == true) {
          print('Mise à jour réussie, sauvegarde des données...');

          // Notifier SessionManager de la mise à jour
          await SessionManager.notifyUserDataUpdated(responseData['data']);

          // Mettre à jour les données locales immédiatement
          setState(() {
            userData = responseData['data'];
          });

          print('Données de session et interface mises à jour avec succès');
          return;
        } else {
          print('Erreur API: ${responseData['message']}');
          throw Exception(responseData['message'] ?? 'Erreur de mise à jour');
        }
      } else if (response.statusCode == 401) {
        print('Erreur 401: Token invalide ou expiré');
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else if (response.statusCode == 400) {
        print('Erreur 400: Données invalides');
        try {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Données invalides');
        } catch (jsonError) {
          throw Exception('Données invalides');
        }
      } else {
        print('Erreur serveur ${response.statusCode}: ${response.body}');
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('Erreur de connexion: $e');
      throw Exception(
        'Erreur de connexion. Vérifiez votre connexion internet.',
      );
    } on FormatException catch (e) {
      print('Erreur de format JSON: $e');
      throw Exception('Erreur de réponse du serveur');
    } catch (e) {
      print('Erreur lors de la mise à jour: $e');
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connexion trop lente. Veuillez réessayer.');
      }
      rethrow; // Relancer l'erreur pour que le UI puisse l'afficher
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profil'),
          backgroundColor: AppColors.mainColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: AppColors.mainColor,
          elevation: 0,
          leading: IconButton(
            onPressed: () => NavigationHelper.goto(context, HomePage()),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Mon compte',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Profil utilisateur',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Container(
        color: Colors.grey[50],
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header avec photo de profil
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  child: Column(
                    children: [
                      // Avatar
                      UserAvatar(
                        avatarUrl: userData?['avatar_url'],
                        size: 120,
                        iconSize: 80,
                      ),
                      const SizedBox(height: 15),
                      // Nom et username
                      Text(
                        '${userData?['first_name'] ?? ''} ${userData?['last_name'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '@${userData?['username'] ?? 'username'}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.mainColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Informations personnelles
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations personnelles',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Email
                    _buildInfoCard(
                      icon: Icons.email,
                      title: 'Email',
                      value: userData?['email'] ?? 'Non défini',
                    ),
                    const SizedBox(height: 15),

                    // Téléphone
                    _buildInfoCard(
                      icon: Icons.phone,
                      title: 'Téléphone',
                      value: userData?['telephone'] ?? 'Non défini',
                    ),
                    const SizedBox(height: 15),

                    // Type d'utilisateur
                    _buildInfoCard(
                      icon: Icons.badge,
                      title: 'Type d\'utilisateur',
                      value: userData?['type_utilisateur'] ?? 'Non défini',
                    ),
                    const SizedBox(height: 15),

                    // Statut
                    _buildInfoCard(
                      icon: Icons.verified,
                      title: 'Statut',
                      value: userData?['statut'] ?? 'Non défini',
                      isStatus: true,
                    ),
                    const SizedBox(height: 15),

                    // Date d'inscription
                    _buildInfoCard(
                      icon: Icons.calendar_today,
                      title: 'Membre depuis',
                      value: userData?['date_inscription'] != null
                          ? _formatDate(userData!['date_inscription'])
                          : 'Non défini',
                    ),
                    const SizedBox(height: 30),

                    // Boutons d'action
                    _buildActionButtons(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    bool isStatus = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.mainColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.mainColor, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isStatus && value.toLowerCase() == 'actif')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Actif',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Bouton Modifier le profil
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => _showEditProfile(),
            icon: const Icon(Icons.edit),
            label: const Text('Modifier le profil'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),

        // Bouton Changer le mot de passe
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => _showChangePassword(),
            icon: const Icon(Icons.lock),
            label: const Text('Changer le mot de passe'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),

        // Bouton Déconnexion
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => _showLogoutConfirmation(),
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              'Se déconnecter',
              style: TextStyle(color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Janvier',
        'Février',
        'Mars',
        'Avril',
        'Mai',
        'Juin',
        'Juillet',
        'Août',
        'Septembre',
        'Octobre',
        'Novembre',
        'Décembre',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  void _showEditProfile() async {
    if (userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: Données utilisateur non disponibles'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditProfilePage(userData: userData!, onUpdate: _updateUserData),
      ),
    );

    // Si des modifications ont été faites, rafraîchir les données
    if (result == true) {
      _loadUserData();
    }
  }

  void _showChangePassword() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
    );

    // Si le mot de passe a été changé avec succès, afficher un message
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe modifié avec succès'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showLogoutConfirmation() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _performLogout();
    }
  }

  Future<void> _performLogout() async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Supprimer toutes les données de session
      final success = await SessionManager.clearToken();

      // Fermer l'indicateur de chargement
      if (mounted) {
        Navigator.pop(context);
      }

      if (success) {
        // Afficher un message de succès
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Déconnexion réussie'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Attendre un peu pour que l'utilisateur voit le message
        await Future.delayed(const Duration(milliseconds: 500));

        // Naviguer vers la page de connexion
        if (mounted) {
          SessionManager.checkAuthAndNavigate(context);
        }
      } else {
        // En cas d'erreur, afficher un message d'erreur mais déconnecter quand même
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Erreur lors de la déconnexion, mais vous êtes déconnecté',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          // Naviguer vers la page de connexion même en cas d'erreur
          SessionManager.checkAuthAndNavigate(context);
        }
      }
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');

      // Fermer l'indicateur de chargement s'il est encore ouvert
      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );

        // Même en cas d'erreur, essayer de naviguer vers la page de connexion
        SessionManager.checkAuthAndNavigate(context);
      }
    }
  }
}

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Future<void> Function({
    required String firstName,
    required String lastName,
    required String email,
    required String telephone,
    required String typeUtilisateur,
  })
  onUpdate;

  const EditProfilePage({
    super.key,
    required this.userData,
    required this.onUpdate,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  String _selectedUserType = 'passager';
  bool _isLoading = false;
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Pré-remplir les champs avec les données actuelles
    _firstNameController.text = widget.userData['first_name'] ?? '';
    _lastNameController.text = widget.userData['last_name'] ?? '';
    _emailController.text = widget.userData['email'] ?? '';
    _telephoneController.text = widget.userData['telephone'] ?? '';
    _selectedUserType = widget.userData['type_utilisateur'] ?? 'passager';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez corriger les erreurs dans le formulaire'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Vérifier si des modifications ont été apportées
    final hasChanges =
        _firstNameController.text.trim() !=
            (widget.userData['first_name'] ?? '') ||
        _lastNameController.text.trim() !=
            (widget.userData['last_name'] ?? '') ||
        _emailController.text.trim() != (widget.userData['email'] ?? '') ||
        _telephoneController.text.trim() !=
            (widget.userData['telephone'] ?? '') ||
        _selectedUserType !=
            (widget.userData['type_utilisateur'] ?? 'passager');

    if (!hasChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune modification détectée'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onUpdate(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        telephone: _telephoneController.text.trim(),
        typeUtilisateur: _selectedUserType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );

        // Attendre un peu pour que l'utilisateur voie le message de succès
        await Future.delayed(const Duration(milliseconds: 800));

        // Retourner à la page de profil qui se rafraîchira automatiquement
        Navigator.pop(
          context,
          true,
        ); // true indique que des modifications ont été faites
      }
    } catch (e) {
      print('Erreur dans _saveChanges: $e');
      if (mounted) {
        String errorMessage = e.toString();
        // Nettoyer le message d'erreur
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Choisir une photo de profil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.mainColor),
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.mainColor),
                title: const Text('Choisir depuis la galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        await _uploadAvatar();
      }
    } catch (e) {
      _showErrorMessage('Erreur lors de la prise de photo: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        await _uploadAvatar();
      }
    } catch (e) {
      _showErrorMessage('Erreur lors de la sélection d\'image: $e');
    }
  }

  Future<void> _uploadAvatar() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }

      // Convertir l'image en base64
      final bytes = await _selectedImage!.readAsBytes();
      final base64String = base64Encode(bytes);
      final mimeType = _getImageMimeType(_selectedImage!.path);
      final dataUri = 'data:$mimeType;base64,$base64String';

      print('Upload d\'avatar vers: ${AppConfig.apiBaseUrl}/user/avatar/');
      print('Taille de l\'image: ${bytes.length} bytes');

      final response = await http
          .put(
            Uri.parse('${AppConfig.apiBaseUrl}/user/avatar/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': token,
            },
            body: json.encode({'avatar': dataUri}),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Timeout: L\'upload a pris trop de temps');
            },
          );

      print('Status code avatar: ${response.statusCode}');
      print('Response body avatar: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['avatar'] != null) {
          // Mettre à jour les données utilisateur avec le nouvel avatar
          final updatedUserData = Map<String, dynamic>.from(widget.userData);
          updatedUserData['avatar_url'] = responseData['avatar'];

          // Notifier SessionManager de la mise à jour pour toute l'application
          await SessionManager.notifyUserDataUpdated(updatedUserData);

          // Mettre à jour les données locales aussi
          widget.userData['avatar_url'] = responseData['avatar'];

          if (mounted) {
            setState(() {
              // Force la reconstruction du widget avec les nouvelles données
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo de profil mise à jour avec succès'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('Réponse invalide du serveur');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de l\'upload');
      }
    } catch (e) {
      print('Erreur upload avatar: $e');
      _showErrorMessage('Erreur lors de l\'upload: $e');

      // Remettre l'image à null en cas d'erreur
      setState(() {
        _selectedImage = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getImageMimeType(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      String errorMessage = message;
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: AppColors.mainColor,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isLoading ? 'Sauvegarde...' : 'Modifier profil',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _isLoading ? 'En cours' : 'Informations personnelles',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                ),
                child: IconButton(
                  onPressed: _saveChanges,
                  icon: const Icon(Icons.check, color: Colors.white, size: 24),
                  tooltip: 'Sauvegarder les modifications',
                ),
              ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header avec avatar et nom
            Container(
              width: double.infinity,
              color: Colors.white,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Avatar avec badge d'édition
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.mainColor.withOpacity(0.3),
                              width: 3,
                            ),
                          ),
                          child: Stack(
                            children: [
                              _selectedImage != null
                                  ? CircleAvatar(
                                      radius: 60,
                                      backgroundImage: FileImage(
                                        _selectedImage!,
                                      ),
                                    )
                                  : UserAvatar(
                                      avatarUrl: widget.userData['avatar_url'],
                                      size: 120,
                                      iconSize: 60,
                                    ),
                              if (_isLoading)
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withOpacity(0.5),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.mainColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${widget.userData['first_name'] ?? ''} ${widget.userData['last_name'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${widget.userData['username'] ?? 'username'}',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.mainColor.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Formulaire
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre de section
                    const Text(
                      'Informations personnelles',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Modifiez vos informations personnelles ci-dessous',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 25),
                    // Prénom et Nom sur la même ligne
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _firstNameController,
                            label: 'Prénom',
                            icon: Icons.person,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Le prénom est requis';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildTextField(
                            controller: _lastNameController,
                            label: 'Nom',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Le nom est requis';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Email
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'L\'email est requis';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value.trim())) {
                          return 'Email invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Téléphone
                    _buildTextField(
                      controller: _telephoneController,
                      label: 'Téléphone',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le téléphone est requis';
                        }
                        final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{8,}$');
                        if (!phoneRegex.hasMatch(value.trim())) {
                          return 'Format de téléphone invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // Type d'utilisateur avec design amélioré
                    const Text(
                      'Type d\'utilisateur',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          children: [
                            _buildUserTypeOption(
                              'passager',
                              'Passager',
                              Icons.person,
                              'Utilisateur normal de l\'application',
                            ),
                            Container(height: 1, color: Colors.grey[200]),
                            _buildUserTypeOption(
                              'chauffeur',
                              'Chauffeur',
                              Icons.drive_eta,
                              'Conducteur de véhicule',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Boutons d'action
                    Column(
                      children: [
                        // Bouton de sauvegarde principal
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.mainColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                              shadowColor: AppColors.mainColor.withOpacity(0.3),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.save, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Sauvegarder les modifications',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Bouton d'annulation
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Annuler',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeOption(
    String value,
    String title,
    IconData icon,
    String description,
  ) {
    final isSelected = _selectedUserType == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedUserType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.mainColor.withOpacity(0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.mainColor : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.mainColor : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.mainColor : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelected ? AppColors.mainColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Entrez votre ${label.toLowerCase()}',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.only(left: 16, right: 12),
                child: Icon(
                  icon,
                  color: AppColors.mainColor.withOpacity(0.7),
                  size: 22,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.mainColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
