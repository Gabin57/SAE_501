import 'package:flutter/material.dart';
import '../../style/app_theme.dart';
import '../../services/local_profile_service.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});
  static const routeName = '/profil';

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _theme = 'light';
  bool _editing = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await LocalProfileService.getProfile();
    setState(() {
      _nameController.text = profile['name'] ?? '';
      _emailController.text = profile['email'] ?? '';
      _theme = profile['theme'] ?? 'light';
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    await LocalProfileService.saveProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      theme: _theme,
    );
    setState(() {
      _editing = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil enregistré localement')),
    );
  }

  Future<void> _logout() async {
    await LocalProfileService.clearProfile();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/connexion');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(AppTheme.mediumPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppTheme.surfaceColor,
                      child: Text(
                        _nameController.text.isNotEmpty
                            ? _nameController.text[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      enabled: _editing,
                      decoration: const InputDecoration(labelText: 'Nom'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Entrez un nom';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      enabled: _editing,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Entrez un email';
                        if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(v)) return 'Email invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    InputDecorator(
                      decoration: const InputDecoration(labelText: 'Thème local'),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _theme,
                          items: const [
                            DropdownMenuItem(value: 'light', child: Text('Clair')),
                            DropdownMenuItem(value: 'dark', child: Text('Sombre')),
                            DropdownMenuItem(value: 'system', child: Text('Système')),
                          ],
                          onChanged: _editing
                              ? (v) {
                                  if (v == null) return;
                                  setState(() => _theme = v);
                                }
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _editing ? _saveProfile : () => setState(() => _editing = true),
                          icon: Icon(_editing ? Icons.save : Icons.edit),
                          label: Text(_editing ? 'Sauvegarder' : 'Modifier'),
                        ),
                        TextButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.exit_to_app),
                          label: const Text('Déconnexion'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
