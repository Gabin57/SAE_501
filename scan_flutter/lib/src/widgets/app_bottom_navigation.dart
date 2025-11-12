import 'package:flutter/material.dart';
import 'package:scan_flutter/src/pages/accueil.dart';
import 'package:scan_flutter/src/style/colors.dart';
import 'package:scan_flutter/src/pages/infos.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    this.currentIndex,
    this.onTap,
  });

  final int? currentIndex;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    const textDark = AppColors.textDark;
    final unselectedColor = AppColors.textDark.withOpacity(0.5);

    final currentRoute = ModalRoute.of(context)?.settings.name;
    final bool isKnownRoute =
        currentRoute == AccueilPage.routeName || currentRoute == InfosPage.routeName;
    final int effectiveIndex = isKnownRoute ? _deriveIndex(context) : 0;

    return BottomNavigationBar(
      backgroundColor: AppColors.bottomBarBg,
      selectedItemColor: isKnownRoute ? textDark : unselectedColor,
      unselectedItemColor: unselectedColor,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedLabelStyle:
          Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isKnownRoute ? textDark : unselectedColor,
                decoration:
                    isKnownRoute ? TextDecoration.underline : TextDecoration.none,
                decorationColor: textDark,
                decorationThickness: isKnownRoute ? 2 : 0,
              ),
      unselectedLabelStyle:
          Theme.of(context).textTheme.labelMedium?.copyWith(
                color: unselectedColor,
              ),
      selectedIconTheme:
          IconThemeData(size: 28, color: isKnownRoute ? textDark : unselectedColor),
      unselectedIconTheme: IconThemeData(size: 24, color: unselectedColor),
      currentIndex: currentIndex ?? effectiveIndex,
      onTap: (index) {
        if (onTap != null) {
          onTap!(index);
          return;
        }

        final currentRoute = ModalRoute.of(context)?.settings.name;

        if (index == 0 && currentRoute != AccueilPage.routeName) {
          Navigator.of(context).pushReplacementNamed(AccueilPage.routeName);
        } else if (index == 2 && currentRoute != InfosPage.routeName) {
          Navigator.of(context).pushReplacementNamed(InfosPage.routeName);
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.center_focus_strong),
          label: 'Scanner',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.info_outline),
          label: 'À propos',
        ),
      ],
    );
  }

  int _deriveIndex(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute == InfosPage.routeName) {
      return 2;
    }
    return 0;
  }
}


