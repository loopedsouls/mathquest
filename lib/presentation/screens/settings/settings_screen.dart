import 'package:flutter/material.dart';
import '../../../app/routes.dart';

/// Settings screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _notificationsEnabled = true;
  bool _darkMode = true;
  String _selectedLanguage = 'Português';

  final List<String> _languages = ['Português', 'English', 'Español'];

  @override
  Widget build(BuildContext context) {
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
              // TODO: Save to preferences
            },
          ),
          SwitchListTile(
            title: const Text('Música de Fundo'),
            subtitle: const Text('Música durante o jogo'),
            secondary: const Icon(Icons.music_note),
            value: _musicEnabled,
            onChanged: (value) {
              setState(() => _musicEnabled = value);
              // TODO: Save to preferences
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
              // TODO: Save to preferences
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
              // TODO: Save to preferences and update theme
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
              // TODO: Navigate to edit profile
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Alterar Senha'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to change password
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Exportar Dados'),
            subtitle: const Text('Baixe uma cópia dos seus dados'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Export user data
            },
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
            onTap: () {
              // TODO: Navigate to terms
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Política de Privacidade'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to privacy policy
            },
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
                Navigator.pop(context);
                // TODO: Update app locale
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
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement logout
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
