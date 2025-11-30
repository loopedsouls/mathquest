import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/routes.dart';
import '../../../data/repositories/auth_repository_impl.dart';

/// Settings screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _musicEnabledKey = 'music_enabled';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _themeModeKey = 'theme_mode';
  static const String _languageKey = 'app_language';

  final _authRepository = AuthRepositoryImpl();

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _notificationsEnabled = true;
  bool _darkMode = true;
  String _selectedLanguage = 'Português';
  bool _isLoading = true;

  final List<String> _languages = ['Português', 'English', 'Español'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool(_soundEnabledKey) ?? true;
      _musicEnabled = prefs.getBool(_musicEnabledKey) ?? true;
      _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
      _darkMode = (prefs.getInt(_themeModeKey) ?? 2) == 2; // 2 = dark
      _selectedLanguage = prefs.getString(_languageKey) ?? 'Português';
      _isLoading = false;
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Configurações')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        children: [
          // Sound section
          const _SectionHeader(title: 'Som'),
          SwitchListTile(
            title: const Text('Efeitos Sonoros'),
            subtitle: const Text('Sons de acerto, erro, etc.'),
            secondary: const Icon(Icons.volume_up),
            value: _soundEnabled,
            onChanged: (value) {
              setState(() => _soundEnabled = value);
              _savePreference(_soundEnabledKey, value);
            },
          ),
          SwitchListTile(
            title: const Text('Música de Fundo'),
            subtitle: const Text('Música durante o jogo'),
            secondary: const Icon(Icons.music_note),
            value: _musicEnabled,
            onChanged: (value) {
              setState(() => _musicEnabled = value);
              _savePreference(_musicEnabledKey, value);
            },
          ),
          const Divider(),
          // Notifications section
          const _SectionHeader(title: 'Notificações'),
          SwitchListTile(
            title: const Text('Lembretes de Estudo'),
            subtitle: const Text('Receba lembretes para manter sua sequência'),
            secondary: const Icon(Icons.notifications),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
              _savePreference(_notificationsEnabledKey, value);
            },
          ),
          const Divider(),
          // Appearance section
          const _SectionHeader(title: 'Aparência'),
          SwitchListTile(
            title: const Text('Modo Escuro'),
            subtitle: const Text('Tema escuro para o aplicativo'),
            secondary: const Icon(Icons.dark_mode),
            value: _darkMode,
            onChanged: (value) {
              setState(() => _darkMode = value);
              _savePreference(_themeModeKey, value ? 2 : 1); // 2 = dark, 1 = light
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Idioma'),
            subtitle: Text(_selectedLanguage),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showLanguagePicker,
          ),
          const Divider(),
          // Account section
          const _SectionHeader(title: 'Conta'),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Editar Perfil'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.profile);
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Alterar Senha'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showChangePasswordDialog,
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Exportar Dados'),
            subtitle: const Text('Baixe uma cópia dos seus dados'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _exportUserData,
          ),
          const Divider(),
          // About section
          const _SectionHeader(title: 'Sobre'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Sobre o MathQuest'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAboutDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Termos de Uso'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openUrl('https://mathquest.app/terms'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Política de Privacidade'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openUrl('https://mathquest.app/privacy'),
          ),
          const Divider(),
          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Sair',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _showLogoutDialog(),
          ),
          const SizedBox(height: 24),
          // Version info
          Center(
            child: Text(
              'MathQuest v1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o link')),
      );
    }
  }

  void _showChangePasswordDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redefinir Senha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Digite seu email para receber um link de redefinição de senha.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;
              try {
                await _authRepository.sendPasswordResetEmail(email);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email de redefinição enviado!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$e'.replaceAll('Exception: ', '')),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    final userData = <String, dynamic>{};
    
    for (final key in allKeys) {
      userData[key] = prefs.get(key);
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seus Dados'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Dados armazenados localmente:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...userData.entries.map((e) => Text('${e.key}: ${e.value}')),
              if (userData.isEmpty) const Text('Nenhum dado encontrado'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: _languages.length,
          itemBuilder: (context, index) {
            final language = _languages[index];
            return ListTile(
              title: Text(language),
              trailing: _selectedLanguage == language
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() => _selectedLanguage = language);
                _savePreference(_languageKey, language);
                Navigator.pop(context);
                // Show restart hint
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reinicie o app para aplicar o idioma'),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'MathQuest',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.calculate,
        size: 48,
        color: Color(0xFF6C63FF),
      ),
      children: [
        const Text(
          'MathQuest é um aplicativo de aprendizado de matemática gamificado, '
          'alinhado com a Base Nacional Comum Curricular (BNCC) para '
          'estudantes do 6º ao 9º ano do Ensino Fundamental.',
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _authRepository.signOut();
              } catch (e) {
                // Ignore errors on sign out
              }
              if (!mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.login,
                (route) => false,
              );
            },
            child: const Text(
              'Sair',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
