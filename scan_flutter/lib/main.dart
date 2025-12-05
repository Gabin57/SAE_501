import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:camera/camera.dart';
import 'package:scan_flutter/src/pages/scan/resultat.dart';

import 'src/pages/accueil.dart';
import 'src/pages/profil.dart';
import 'src/pages/connexion.dart';
import 'src/pages/inscription.dart';
import 'src/pages/infos.dart';
import 'src/pages/scan/scan_page.dart';
import 'src/style/app_theme.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  // Assurez-vous que les bindings Flutter sont initialisés
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Obtenir la liste des caméras disponibles
    cameras = await availableCameras();
  } on CameraException catch (e) {
    // Gérer silencieusement l'erreur de caméra (notamment dans les navigateurs web)
    // La caméra n'est pas disponible, mais l'application peut continuer avec une liste vide
    cameras = [];
    debugPrint(
      'Caméra non disponible: ${e.description}. L\'application continuera sans caméra.',
    );
  } catch (e) {
    // Gérer toute autre erreur
    cameras = [];
    debugPrint(
      'Erreur lors de l\'initialisation des caméras: $e. L\'application continuera sans caméra.',
    );
  }

  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scan de panneaux',
      restorationScopeId: 'app',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', '')],
      onGenerateTitle: (BuildContext context) => 'Scan de panneaux',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      onGenerateRoute: (RouteSettings routeSettings) {
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (BuildContext context) {
            switch (routeSettings.name) {
              case AccueilPage.routeName:
                return const AccueilPage();
              case ConnexionPage.routeName:
                return const ConnexionPage();
              case InscriptionPage.routeName:
                return const InscriptionPage();
              case InfosPage.routeName:
                return const InfosPage();
              case ProfilPage.routeName:
                return const ProfilPage();
              case ResultatPage.routeName:
                return ResultatPage();
              case ScanPage.routeName:
                return ScanPage(cameras: cameras);
              default:
                return const AccueilPage();
            }
          },
        );
      },
    );
  }
}
