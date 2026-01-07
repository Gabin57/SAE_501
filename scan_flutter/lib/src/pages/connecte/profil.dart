import 'package:flutter/material.dart';
import '../../style/colors.dart';
import '../../services/local_profile_service.dart';
import 'package:scan_flutter/src/widgets/custom_app_bar.dart';
import 'package:scan_flutter/src/widgets/app_bottom_navigation.dart';
import '../connexion.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});
  static const routeName = '/profil';

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  bool _loading = true;
  String _name = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await LocalProfileService.getProfile();
    if (!mounted) return;
    setState(() {
      _name = profile['name'] ?? 'Anonyme';
      _email = profile['email'] ?? 'adresse@gmail.com';
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

  void _handleEdit() {
    // Placeholder for edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité de modification à venir')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white, // White background for body
      appBar: CustomAppBar(
        title: 'Profil',
        showProfileIcon: false, // Don't show profile icon on profile page
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
                  color: AppColors
                      .placeholderBg, // Use consistent placeholder background
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      _name.isNotEmpty ? _name : 'Anonyme',
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
                      _email.isNotEmpty ? _email : 'adresse@gmail.com',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textDark,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _logout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppColors.error, // Use defined error color
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
                            onPressed: _handleEdit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors
                                  .textDark, // Use dark text color for button background
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
                ),
              ),
            ),
      bottomNavigationBar: const AppBottomNavigation(
        currentIndex: 2,
      ), // Assuming Profile might be accessible via index, or keep strictly redundant if no tab
    );
  }
}
