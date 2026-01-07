import 'package:flutter/material.dart';
import '../style/colors.dart';
import '../services/local_profile_service.dart';
import '../pages/connexion.dart';
import '../pages/connecte/profil.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.centerTitle = false,
    this.showProfileIcon = true,
    this.actions,
  });

  final String title;
  final bool centerTitle;
  final bool showProfileIcon;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Future<void> _handleProfileTap(BuildContext context) async {
    final profile = await LocalProfileService.getProfile();
    final isAuthenticated =
        profile['name'] != null && profile['name']!.isNotEmpty;

    if (!context.mounted) return;

    if (isAuthenticated) {
      Navigator.pushNamed(context, ProfilPage.routeName);
    } else {
      Navigator.pushNamed(context, ConnexionPage.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> appBarActions = [];

    // Add custom actions first if provided
    if (actions != null) {
      appBarActions.addAll(actions!);
    }

    // Add profile icon if enabled
    if (showProfileIcon) {
      appBarActions.add(
        IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () => _handleProfileTap(context),
        ),
      );
    }

    return AppBar(
      backgroundColor: AppColors.appBarBg,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.textDark,
      iconTheme: const IconThemeData(color: AppColors.textDark),
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: centerTitle,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: appBarActions.isNotEmpty ? appBarActions : null,
    );
  }
}
