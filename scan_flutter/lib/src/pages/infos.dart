import 'package:flutter/material.dart';
import 'package:scan_flutter/src/style/colors.dart';
import 'package:scan_flutter/src/widgets/app_bottom_navigation.dart';

class InfosPage extends StatelessWidget {
  const InfosPage({super.key});

  static const routeName = '/infos';

  @override
  Widget build(BuildContext context) {
    const textDark = AppColors.textDark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.appBarBg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textDark,
        iconTheme: const IconThemeData(color: textDark),
        automaticallyImplyLeading: false,
        titleTextStyle:
            Theme.of(context).textTheme.titleLarge?.copyWith(color: textDark),
        title: const Text('Informations'),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: const Center(),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 2),
    );
  }
}
