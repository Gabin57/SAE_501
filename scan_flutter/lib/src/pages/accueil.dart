import 'package:flutter/material.dart';

import 'package:scan_flutter/src/pages/connexion.dart';
import 'package:scan_flutter/src/style/colors.dart';
import 'package:scan_flutter/src/widgets/search_bar.dart';
import 'package:scan_flutter/src/widgets/app_bottom_navigation.dart';

class AccueilPage extends StatefulWidget {
  const AccueilPage({super.key});
  static const routeName = '/';

  final String title = "Accueil";

  @override
  State<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> {
  List<List<Map<String, String>>> donnes = [];

  // Palette et tailles centralisées
  static const _appBarBg = AppColors.appBarBg;
  static const _tileBg = AppColors.tileBg;
  static const _iconMuted = AppColors.iconMuted;
  static const _labelBg = AppColors.labelBg;
  static const _placeholderBg = AppColors.placeholderBg;
  static const _textDark = AppColors.textDark;

  List<Widget> _buildGridItems() {
    return [
      _GridCard(
        title: 'Tutoriel',
        imageUrl:
            'https://images.unsplash.com/photo-1502082553048-f009c37129b9?w=640',
        tileColor: _tileBg,
        labelColor: _iconMuted,
        labelBg: _labelBg,
        placeholderBg: _placeholderBg,
        onTap: () {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Ouvrir Tutoriel')));
        },
      ),
      for (int i = 1; i <= 5; i++)
        _GridCard(
          title: 'Image $i',
          tileColor: _tileBg,
          labelColor: _iconMuted,
          labelBg: _labelBg,
          placeholderBg: _placeholderBg,
          onTap: () {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Ouvrir Image $i')));
          },
        ),
    ];
  }

  // Réservé pour les futures données

  /* void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  } */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _appBarBg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _textDark,
        iconTheme: const IconThemeData(color: _textDark),
        automaticallyImplyLeading: false,
        titleTextStyle:
            Theme.of(context).textTheme.titleLarge?.copyWith(color: _textDark),
        title: const Text('Code des Panneaux'),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
              onPressed: () {
                Navigator.pushNamed(context, ConnexionPage.routeName);
              },
              iconSize: 30,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              icon: const Icon(Icons.person_outlined)),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Barre de recherche qui défile avec le contenu
          SliverToBoxAdapter(
            child: CustomSearchBar(
              onSubmitted: (value) {
                // TODO: brancher la logique de recherche
              },
            ),
          ),
          // Grille de cartes
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16.0,
                crossAxisSpacing: 16.0,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildListDelegate(
                _buildGridItems(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(),
      /* floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), */ // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

// Anciennes versions remplacées par _GridCard

class _GridCard extends StatelessWidget {
  const _GridCard({
    required this.title,
    required this.tileColor,
    required this.labelColor,
    required this.labelBg,
    required this.placeholderBg,
    this.imageUrl,
    this.onTap,
  });

  final String title;
  final Color tileColor;
  final Color labelColor;
  final Color labelBg;
  final Color placeholderBg;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: imageUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: placeholderBg,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Center(
                          child: Icon(Icons.image_outlined,
                              size: 28, color: labelColor),
                        ),
                      ),
              ),
              Container(
                height: 36,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: labelBg,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: labelColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
