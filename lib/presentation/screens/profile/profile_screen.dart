import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/routes.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../widgets/profile/achievement_grid.dart';
import '../../widgets/profile/stats_card.dart';
import '../../widgets/profile/avatar_display.dart';

/// Profile screen - User statistics and achievements
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final _authRepository = AuthRepositoryImpl();
  
  String _username = 'Estudante';
  String? _avatarUrl;
  int _level = 1;
  int _streak = 0;
  int _totalXp = 0;
  int _achievementsCount = 0;
  int _totalQuestions = 0;
  int _correctQuestions = 0;
  Map<String, double> _progressByUnit = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadUserData();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUser = _authRepository.currentUser;

    setState(() {
      _username = currentUser?.displayName ?? 
                  prefs.getString('user_name') ?? 
                  'Estudante';
      _avatarUrl = currentUser?.photoUrl;
      _level = prefs.getInt('user_level') ?? 1;
      _streak = prefs.getInt('current_streak') ?? 0;
      _totalXp = prefs.getInt('user_xp') ?? 0;
      _totalQuestions = prefs.getInt('total_questions') ?? 0;
      _correctQuestions = prefs.getInt('correct_questions') ?? 0;
      
      // Load unlocked achievements count
      final unlockedAchievements = prefs.getStringList('unlocked_achievements') ?? [];
      _achievementsCount = unlockedAchievements.length;
      
      // Load progress by unit
      _progressByUnit = {
        'Números': prefs.getDouble('progress_Números') ?? 0.0,
        'Álgebra': prefs.getDouble('progress_Álgebra') ?? 0.0,
        'Geometria': prefs.getDouble('progress_Geometria') ?? 0.0,
        'Grandezas': prefs.getDouble('progress_Grandezas') ?? 0.0,
        'Estatística': prefs.getDouble('progress_Estatística') ?? 0.0,
      };
      
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  String _calculateAccuracy() {
    if (_totalQuestions == 0) return '0%';
    return '${((_correctQuestions / _totalQuestions) * 100).toInt()}%';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.settings);
            },
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Avatar and user info
                    AvatarDisplay(
                      avatarUrl: _avatarUrl,
                      level: _level,
                      username: _username,
                    ),
                    const SizedBox(height: 24),
                    // Quick stats
                    Row(
                      children: [
                        Expanded(
                          child: _QuickStat(
                            icon: Icons.local_fire_department,
                            value: '$_streak',
                            label: 'Sequência',
                            color: Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: _QuickStat(
                            icon: Icons.star,
                            value: '$_totalXp',
                            label: 'XP Total',
                            color: Colors.amber,
                          ),
                        ),
                        Expanded(
                          child: _QuickStat(
                            icon: Icons.emoji_events,
                            value: '$_achievementsCount',
                            label: 'Conquistas',
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Estatísticas'),
                    Tab(text: 'Conquistas'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Statistics tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  StatsCard(
                    title: 'Questões Respondidas',
                    stats: {
                      'Total': '$_totalQuestions',
                      'Corretas': '$_correctQuestions',
                      'Taxa de Acerto': _calculateAccuracy(),
                    },
                  ),
                  const SizedBox(height: 16),
                  StatsCard(
                    title: 'Progresso por Unidade',
                    stats: {
                      for (final entry in _progressByUnit.entries)
                        entry.key: '${(entry.value * 100).toInt()}%',
                    },
                  ),
                  const SizedBox(height: 16),
                  StatsCard(
                    title: 'Informações Gerais',
                    stats: {
                      'Nível': '$_level',
                      'XP Total': '$_totalXp',
                      'Sequência Atual': '$_streak dias',
                    },
                  ),
                ],
              ),
            ),
            // Achievements tab
            const AchievementGrid(),
          ],
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _QuickStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return _tabBar != oldDelegate._tabBar;
  }
}
