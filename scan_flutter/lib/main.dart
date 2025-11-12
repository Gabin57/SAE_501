import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'src/localization/app_localizations.dart';
import 'src/pages/accueil.dart';
import 'src/pages/profil.dart';
import 'src/pages/connexion.dart';
import 'src/pages/inscription.dart';
import 'src/pages/infos.dart';
import 'src/style/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      restorationScopeId: 'app',
      debugShowCheckedModeBanner: false,

      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'),
      ],

      onGenerateTitle: (BuildContext context) =>
          AppLocalizations.of(context)!.appTitle,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // Pour forcer le thème clair
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
              default:
                return const AccueilPage();
            }
          },
        );
      },
      // home: const AccueilPage(),
    );
  }
}
