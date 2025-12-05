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
        titleTextStyle: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(color: textDark),
        title: const Text('Informations'),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'But de l\'application',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Cette application a pour objectif d\'aider les utilisateurs à scanner et reconnaître des panneaux et signaux routiers, '
              'fournir des informations sur leur signification et offrir des fonctionnalités d\'exploration et de suivi local.',
            ),
            const SizedBox(height: 16),
            Text('L\'équipe', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            // Team member cards
            _memberCard(
              name: 'Gabin HUMBERT',
              role: 'Développeur principal',
              description:
                  'Conception et architecture de l\'application, intégration de la détection d\'objets.',
            ),
            _memberCard(
              name: 'Margaux HALLER',
              role: 'Développeuse API et mobile',
              description:
                  'Développement de Flutter et API, tests, scraping, base de données et documentation.',
            ),
            _memberCard(
              name: 'Zain-Alabaidine AIT BAMMOU',
              role: 'Développeur mobile',
              description:
                  'Développement Flutter, interface utilisateur et tests.',
            ),
            const SizedBox(height: 24),
            const Text(
              'Remarques',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Les données de profil et préférences sont stockées localement sur l\'appareil et ne sont pas transmises par défaut.',
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 2),
    );
  }

  Widget _memberCard({
    required String name,
    required String role,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
