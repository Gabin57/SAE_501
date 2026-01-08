import 'package:flutter/material.dart';
import 'package:scan_flutter/src/pages/accueil.dart';
import 'package:scan_flutter/src/pages/explorer.dart';
import 'package:scan_flutter/src/style/colors.dart';
import 'package:scan_flutter/src/pages/infos.dart';
import 'package:scan_flutter/src/pages/scan/scan_page.dart';
import 'package:scan_flutter/src/services/local_profile_service.dart';

class AppBottomNavigation extends StatefulWidget {
  const AppBottomNavigation({super.key, this.currentIndex, this.onTap});

  final int? currentIndex;
  final ValueChanged<int>? onTap;

  @override
  State<AppBottomNavigation> createState() => _AppBottomNavigationState();
}

class _AppBottomNavigationState extends State<AppBottomNavigation> {
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final profile = await LocalProfileService.getProfile();
    if (mounted) {
      setState(() {
        _isAuthenticated =
            profile['name'] != null && profile['name']!.isNotEmpty;
      });
    }
  }

  List<BottomNavigationBarItem> _buildNavigationItems() {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        label: 'Accueil',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.center_focus_strong),
        label: 'Scanner',
      ),
    ];

    // Add Explorer button if authenticated
    if (_isAuthenticated) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.public),
          label: 'Explorer',
        ),
      );
    }

    items.add(
      const BottomNavigationBarItem(
        icon: Icon(Icons.info_outline),
        label: 'À propos',
      ),
    );

    return items;
  }

  int _deriveIndex(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    if (_isAuthenticated) {
      // 4 buttons: Accueil(0), Scanner(1), Explorer(2), À propos(3)
      if (currentRoute == ExplorerPage.routeName) return 2;
      if (currentRoute == InfosPage.routeName) return 3;
    } else {
      // 3 buttons: Accueil(0), Scanner(1), À propos(2)
      if (currentRoute == InfosPage.routeName) return 2;
    }

    return 0; // Accueil by default
  }

  @override
  Widget build(BuildContext context) {
    const textDark = AppColors.textDark;
    final unselectedColor = AppColors.textDark.withOpacity(0.5);

    final currentRoute = ModalRoute.of(context)?.settings.name;
    final bool isKnownRoute =
        currentRoute == AccueilPage.routeName ||
        currentRoute == InfosPage.routeName ||
        currentRoute == ExplorerPage.routeName;
    final int effectiveIndex = isKnownRoute ? _deriveIndex(context) : 0;

    return BottomNavigationBar(
      backgroundColor: AppColors.bottomBarBg,
      selectedItemColor: isKnownRoute ? textDark : unselectedColor,
      unselectedItemColor: unselectedColor,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedLabelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: isKnownRoute ? textDark : unselectedColor,
        decoration: isKnownRoute
            ? TextDecoration.underline
            : TextDecoration.none,
        decorationColor: textDark,
        decorationThickness: isKnownRoute ? 2 : 0,
      ),
      unselectedLabelStyle: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(color: unselectedColor),
      selectedIconTheme: IconThemeData(
        size: 28,
        color: isKnownRoute ? textDark : unselectedColor,
      ),
      unselectedIconTheme: IconThemeData(size: 24, color: unselectedColor),
      currentIndex: widget.currentIndex ?? effectiveIndex,
      onTap: (index) {
        if (widget.onTap != null) {
          widget.onTap!(index);
          return;
        }

        final currentRoute = ModalRoute.of(context)?.settings.name;

        // Handle navigation based on authentication state
        if (_isAuthenticated) {
          // 4 buttons: Accueil(0), Scanner(1), Explorer(2), À propos(3)
          if (index == 0 && currentRoute != AccueilPage.routeName) {
            Navigator.of(context).pushReplacementNamed(AccueilPage.routeName);
          } else if (index == 1) {
            Navigator.of(context).pushNamed(ScanPage.routeName);
          } else if (index == 2 && currentRoute != ExplorerPage.routeName) {
            Navigator.of(context).pushReplacementNamed(ExplorerPage.routeName);
          } else if (index == 3 && currentRoute != InfosPage.routeName) {
            Navigator.of(context).pushReplacementNamed(InfosPage.routeName);
          }
        } else {
          // 3 buttons: Accueil(0), Scanner(1), À propos(2)
          if (index == 0 && currentRoute != AccueilPage.routeName) {
            Navigator.of(context).pushReplacementNamed(AccueilPage.routeName);
          } else if (index == 1) {
            Navigator.of(context).pushNamed(ScanPage.routeName);
          } else if (index == 2 && currentRoute != InfosPage.routeName) {
            Navigator.of(context).pushReplacementNamed(InfosPage.routeName);
          }
        }
      },
      items: _buildNavigationItems(),
    );
  }
}
