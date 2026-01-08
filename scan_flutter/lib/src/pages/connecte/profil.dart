import 'package:flutter/material.dart';
import '../../style/colors.dart';
import '../../services/local_profile_service.dart';
import 'package:scan_flutter/src/widgets/custom_app_bar.dart';
import 'package:scan_flutter/src/widgets/app_bottom_navigation.dart';
import '../connexion.dart';
import '../../../dao.class.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});
  static const routeName = '/profil';

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  bool _loading = true;
  bool _isEditing = false;
  bool _isDeleting = false;

  // Controllers for edit mode
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Map<String, dynamic> _profile = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _idController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await LocalProfileService.getProfile();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _idController.text = profile['name'] ?? '';
      _emailController.text = profile['email'] ?? '';
      _loading = false;
    });
  }

  Future<void> _logout() async {
    await LocalProfileService.clearProfile();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(ConnexionPage.routeName, (route) => false);
  }

  // --- Logic for Editing ---

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset if cancelled
        _idController.text = _profile['name'] ?? '';
        _emailController.text = _profile['email'] ?? '';
      }
    });
  }

  Future<void> _saveChanges() async {
    setState(() => _loading = true);
    try {
      final newId = _idController.text.trim();
      final newEmail = _emailController.text.trim();
      final newPassword = _passwordController.text.trim();
      final userId = _profile['num']; // or 'id' depending on typical usage

      if (userId == null) throw Exception("ID utilisateur introuvable");

      await DAO.updateProfile(
        userId,
        newId,
        newEmail,
        password: newPassword.isNotEmpty ? newPassword : null,
      );

      // Update local storage
      await LocalProfileService.saveProfile(
        name: newId,
        email: newEmail,
        theme: _profile['theme'] ?? 'light',
        num: userId,
      );

      // Refresh state
      await _loadProfile();
      setState(() {
        _isEditing = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil mis à jour !')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour : $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // --- Logic for Deleting ---

  void _toggleDelete() {
    setState(() {
      _isDeleting = !_isDeleting;
    });
  }

  Future<void> _confirmDelete() async {
    setState(() => _loading = true);
    try {
      final userId = _profile['num'];
      if (userId == null) throw Exception("ID utilisateur introuvable");

      await DAO.delete('comptes', userId);
      await _logout(); // Clears profile and navigates to login
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression : $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // --- UI Builders ---

  Widget _buildViewMode() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name
        Text(
          _profile['name'] ?? 'Anonyme',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: AppColors.textDark,
          ),
        ),

        const SizedBox(height: 32),

        // Email Section
        const Text(
          'Email :',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _profile['email'] ?? 'adresse@gmail.com',
          style: const TextStyle(fontSize: 16, color: AppColors.textDark),
        ),

        const SizedBox(height: 48),

        // Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _toggleDelete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Supprimer'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _toggleEdit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textDark,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Modifier'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditMode() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Identifiant',
          style: TextStyle(fontSize: 14, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _idController,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Adresse mail',
          style: TextStyle(fontSize: 14, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Mot de passe',
          style: TextStyle(fontSize: 14, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Laisser vide si inchangé',
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _toggleEdit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textDark,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeleteMode() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Etes-vous sûr ?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Vous pouvez encore annuler la suppression du compte',
          style: TextStyle(fontSize: 14, color: AppColors.textDark),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _confirmDelete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Supprimer'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _toggleDelete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textDark,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Annuler'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: 'Profil',
        showProfileIcon: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textDark),
            onPressed: _logout,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.placeholderBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _isDeleting
                      ? _buildDeleteMode()
                      : _isEditing
                      ? _buildEditMode()
                      : _buildViewMode(),
                ),
              ),
            ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 2),
    );
  }
} // End of _ProfilPageState class
