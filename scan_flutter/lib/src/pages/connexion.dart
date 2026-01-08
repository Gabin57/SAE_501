import 'package:flutter/material.dart';
import 'package:scan_flutter/src/style/colors.dart';
import 'package:scan_flutter/src/pages/inscription.dart';
import 'package:scan_flutter/src/pages/accueil.dart';
import 'package:scan_flutter/src/widgets/app_bottom_navigation.dart';
import 'package:scan_flutter/src/services/local_profile_service.dart';
import '../../dao.class.dart';

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
  bool _isLoading = false;

  @override
  void dispose() {
    _identifiantController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_identifiantController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Appel à l'API via le DAO
      final response = await DAO.login(
        _identifiantController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      // Récupérer le num de l'utilisateur depuis la table COMPTES
      final user = response['user'];
      final userEmail = user['email'] ?? '';

      int? userNum;
      try {
        // Option 1: Try to get ID from login response directly if available
        if (user['num'] != null || user['id'] != null) {
          final rawId = user['num'] ?? user['id'];
          userNum = rawId is int ? rawId : int.tryParse(rawId.toString());
        }

        // Option 2: Fallback to fetching account if ID not in login response or parsing failed
        if (userNum == null) {
          final comptes = await DAO.getAll('comptes');
          final compte = comptes.firstWhere(
            (c) =>
                c['email'] == userEmail ||
                c['identifiant'] == _identifiantController.text,
            orElse: () => {},
          );

          if (compte.isNotEmpty) {
            final rawId = compte['num'] ?? compte['id'];
            userNum = rawId is int
                ? rawId
                : int.tryParse(rawId?.toString() ?? '');
          }
        }
        print('✅ User num retrieved: $userNum');
      } catch (e) {
        print('⚠️ Could not retrieve user num: $e');
      }

      // Sauvegarder le profil localement pour maintenir la session
      await LocalProfileService.saveProfile(
        name: user['identifiant'] ?? _identifiantController.text,
        email: userEmail,
        theme: 'light',
        num: userNum,
      );

      // Succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connexion réussie'),
          backgroundColor: Colors.green,
        ),
      );

      // Redirection vers l'accueil
      Navigator.pushReplacementNamed(context, AccueilPage.routeName);
    } catch (e) {
      if (!mounted) return;

      // Erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
        titleTextStyle: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(color: textDark),
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
                              context,
                              InscriptionPage.routeName,
                            );
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
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Connexion'),
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
