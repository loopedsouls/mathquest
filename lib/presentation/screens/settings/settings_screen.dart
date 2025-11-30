import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/routes.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../widgets/shop/duolingo_design_system.dart';

/// Settings screen with Duolingo design system
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _musicEnabledKey = 'music_enabled';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _languageKey = 'app_language';

  final _authRepository = AuthRepositoryImpl();

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _notificationsEnabled = true;
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

  String _getBrightnessLabel(ThemeBrightness brightness) {
    switch (brightness) {
      case ThemeBrightness.light:
        return 'Claro';
      case ThemeBrightness.dark:
        return 'Escuro';
      case ThemeBrightness.system:
        return 'Sistema';
    }
  }

  IconData _getBrightnessIcon(ThemeBrightness brightness) {
    switch (brightness) {
      case ThemeBrightness.light:
        return Icons.light_mode_rounded;
      case ThemeBrightness.dark:
        return Icons.dark_mode_rounded;
      case ThemeBrightness.system:
        return Icons.brightness_auto_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.duoTheme;
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.bgDark,
        appBar: AppBar(
          backgroundColor: theme.bgCard,
          title: Text('Configurações', style: TextStyle(color: theme.textPrimary)),
          iconTheme: IconThemeData(color: theme.iconColor),
        ),
        body: Center(child: CircularProgressIndicator(color: theme.accent)),
      );
    }

    return Scaffold(
      backgroundColor: theme.bgDark,
      appBar: AppBar(
        backgroundColor: theme.bgCard,
        elevation: 0,
        title: Text(
          'Configurações',
          style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        iconTheme: IconThemeData(color: theme.iconColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionCard(
            title: 'Som',
            icon: Icons.volume_up_rounded,
            iconColor: DuoColors.blue,
            children: [
              _buildSwitchTile(
                title: 'Efeitos Sonoros',
                subtitle: 'Sons de acerto, erro, etc.',
                icon: Icons.music_note_rounded,
                value: _soundEnabled,
                onChanged: (value) {
                  setState(() => _soundEnabled = value);
                  _savePreference(_soundEnabledKey, value);
                },
              ),
              _buildDivider(),
              _buildSwitchTile(
                title: 'Música de Fundo',
                subtitle: 'Música durante o jogo',
                icon: Icons.library_music_rounded,
                value: _musicEnabled,
                onChanged: (value) {
                  setState(() => _musicEnabled = value);
                  _savePreference(_musicEnabledKey, value);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Notificações',
            icon: Icons.notifications_rounded,
            iconColor: DuoColors.yellow,
            children: [
              _buildSwitchTile(
                title: 'Lembretes de Estudo',
                subtitle: 'Receba lembretes para manter sua sequência',
                icon: Icons.alarm_rounded,
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                  _savePreference(_notificationsEnabledKey, value);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Aparência',
            icon: Icons.palette_rounded,
            iconColor: DuoColors.purple,
            children: [
              _buildListTile(
                title: 'Modo de Cor',
                subtitle: _getBrightnessLabel(context.duoThemeBrightness),
                icon: _getBrightnessIcon(context.duoThemeBrightness),
                onTap: _showBrightnessPicker,
              ),
              _buildDivider(),
              _buildListTile(
                title: 'Idioma',
                subtitle: _selectedLanguage,
                icon: Icons.language_rounded,
                onTap: _showLanguagePicker,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Conta',
            icon: Icons.person_rounded,
            iconColor: DuoColors.green,
            children: [
              _buildListTile(
                title: 'Editar Perfil',
                icon: Icons.edit_rounded,
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
              ),
              _buildDivider(),
              _buildListTile(
                title: 'Alterar Senha',
                icon: Icons.lock_rounded,
                onTap: _showChangePasswordDialog,
              ),
              _buildDivider(),
              _buildListTile(
                title: 'Exportar Dados',
                subtitle: 'Baixe uma cópia dos seus dados',
                icon: Icons.download_rounded,
                onTap: _exportUserData,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Sobre',
            icon: Icons.info_rounded,
            iconColor: DuoColors.blue,
            children: [
              _buildListTile(
                title: 'Sobre o MathQuest',
                icon: Icons.help_outline_rounded,
                onTap: () => _showAboutDialog(),
              ),
              _buildDivider(),
              _buildListTile(
                title: 'Termos de Uso',
                icon: Icons.description_rounded,
                onTap: () => _openUrl('https://mathquest.app/terms'),
              ),
              _buildDivider(),
              _buildListTile(
                title: 'Política de Privacidade',
                icon: Icons.privacy_tip_rounded,
                onTap: () => _openUrl('https://mathquest.app/privacy'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: theme.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DuoColors.red.withValues(alpha: 0.3), width: 1),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showLogoutDialog(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: DuoColors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.logout_rounded, color: DuoColors.red, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Sair da Conta',
                        style: TextStyle(color: DuoColors.red, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded, color: DuoColors.red),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'MathQuest v1.0.0',
              style: TextStyle(color: theme.textSecondary, fontSize: 13),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    final theme = context.duoTheme;
    return Container(
      decoration: BoxDecoration(
        color: theme.bgCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(color: iconColor, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = context.duoTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: theme.bgElevated, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: theme.textSecondary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: theme.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: theme.textSecondary, fontSize: 12)),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: theme.accent,
            activeTrackColor: theme.accent.withValues(alpha: 0.4),
            inactiveThumbColor: theme.textSecondary,
            inactiveTrackColor: theme.bgElevated,
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = context.duoTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: theme.bgElevated, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: theme.textSecondary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: theme.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(color: theme.textSecondary, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: theme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    final theme = context.duoTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(color: theme.bgElevated, height: 1, thickness: 1),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Não foi possível abrir o link'),
          backgroundColor: DuoColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showChangePasswordDialog() {
    final emailController = TextEditingController();
    final theme = context.duoTheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.lock_rounded, color: theme.accent),
            const SizedBox(width: 12),
            Text('Redefinir Senha', style: TextStyle(color: theme.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Digite seu email para receber um link de redefinição de senha.',
              style: TextStyle(color: DuoColors.gray),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              style: TextStyle(color: theme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: const TextStyle(color: DuoColors.gray),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.bgElevated)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.bgElevated)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.accent)),
                filled: true,
                fillColor: theme.bgElevated,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: DuoColors.gray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.accent,
              foregroundColor: theme.textPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;
              try {
                await _authRepository.sendPasswordResetEmail(email);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Email de redefinição enviado!'),
                    backgroundColor: DuoColors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$e'.replaceAll('Exception: ', '')),
                    backgroundColor: DuoColors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final theme = context.duoTheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.download_rounded, color: DuoColors.blue),
            const SizedBox(width: 12),
            Text('Seus Dados', style: TextStyle(color: theme.textPrimary)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Dados armazenados localmente:', style: TextStyle(fontWeight: FontWeight.bold, color: DuoColors.gray)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: theme.bgElevated, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: userData.entries.isEmpty
                      ? [const Text('Nenhum dado encontrado', style: TextStyle(color: DuoColors.gray))]
                      : userData.entries.map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text('${e.key}: ${e.value}', style: TextStyle(color: theme.textPrimary, fontSize: 12)),
                        )).toList(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.accent,
              foregroundColor: theme.textPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showBrightnessPicker() {
    final theme = context.duoTheme;
    final currentBrightness = context.duoThemeBrightness;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: DuoColors.gray.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Modo de Cor', style: TextStyle(color: theme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ...ThemeBrightness.values.map((brightness) {
              final isSelected = currentBrightness == brightness;
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.accent.withValues(alpha: 0.15) : theme.bgElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_getBrightnessIcon(brightness), color: isSelected ? theme.accent : DuoColors.gray),
                ),
                title: Text(
                  _getBrightnessLabel(brightness),
                  style: TextStyle(color: isSelected ? theme.accent : theme.textPrimary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                ),
                subtitle: Text(
                  brightness == ThemeBrightness.system 
                      ? 'Segue as configurações do dispositivo' 
                      : brightness == ThemeBrightness.dark 
                          ? 'Sempre usar tema escuro'
                          : 'Sempre usar tema claro',
                  style: TextStyle(color: theme.textSecondary, fontSize: 12),
                ),
                trailing: isSelected ? Icon(Icons.check_circle_rounded, color: theme.accent) : null,
                onTap: () {
                  DuoThemeProvider.of(context)?.setBrightness(brightness);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  void _showLanguagePicker() {
    final theme = context.duoTheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: DuoColors.gray.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Selecionar Idioma', style: TextStyle(color: theme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ..._languages.map((language) {
              final isSelected = _selectedLanguage == language;
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.accent.withValues(alpha: 0.15) : theme.bgElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.language_rounded, color: isSelected ? theme.accent : DuoColors.gray),
                ),
                title: Text(
                  language,
                  style: TextStyle(color: isSelected ? theme.accent : theme.textPrimary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                ),
                trailing: isSelected ? Icon(Icons.check_circle_rounded, color: theme.accent) : null,
                onTap: () {
                  setState(() => _selectedLanguage = language);
                  _savePreference(_languageKey, language);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Reinicie o app para aplicar o idioma'),
                      backgroundColor: DuoColors.blue,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    final theme = context.duoTheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [theme.accent.withValues(alpha: 0.2), DuoColors.blue.withValues(alpha: 0.2)]),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.calculate_rounded, size: 48, color: theme.accent),
            ),
            const SizedBox(height: 16),
            Text('MathQuest', style: TextStyle(color: theme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Versão 1.0.0', style: TextStyle(color: DuoColors.gray.withValues(alpha: 0.7), fontSize: 14)),
            const SizedBox(height: 16),
            const Text(
              'MathQuest é um aplicativo de aprendizado de matemática gamificado, alinhado com a Base Nacional Comum Curricular (BNCC) para estudantes do 6º ao 9º ano do Ensino Fundamental.',
              textAlign: TextAlign.center,
              style: TextStyle(color: DuoColors.gray, height: 1.4),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.accent,
                foregroundColor: theme.textPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    final theme = context.duoTheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: DuoColors.red),
            const SizedBox(width: 12),
            Text('Sair', style: TextStyle(color: theme.textPrimary)),
          ],
        ),
        content: const Text('Tem certeza que deseja sair da sua conta?', style: TextStyle(color: DuoColors.gray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: DuoColors.gray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DuoColors.red,
              foregroundColor: theme.textPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _authRepository.signOut();
              } catch (e) {
                // Ignore errors on sign out
              }
              if (!mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}
