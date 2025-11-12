import 'package:flutter/material.dart';
import 'package:scan_flutter/src/style/colors.dart';
import 'package:scan_flutter/src/pages/inscription.dart';
import 'package:scan_flutter/src/widgets/app_bottom_navigation.dart';

class ConnexionPage extends StatefulWidget {
  const ConnexionPage({super.key});

  static const routeName = '/connexion';

  @override
  State<ConnexionPage> createState() => _ConnexionPageState();
}

class _ConnexionPageState extends State<ConnexionPage> {
  final TextEditingController _identifiantController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifiantController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const textDark = AppColors.textDark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.appBarBg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textDark,
        iconTheme: const IconThemeData(color: textDark),
        titleTextStyle:
            Theme.of(context).textTheme.titleLarge?.copyWith(color: textDark),
        title: const Text('Connexion'),
        automaticallyImplyLeading: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: AppColors.placeholderBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connexion',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Identifiant',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _identifiantController,
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Votre identifiant',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Mot de passe',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Votre mot de passe',
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(
                                context, InscriptionPage.routeName);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Inscription'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: implémenter la logique de connexion
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Connexion'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}


