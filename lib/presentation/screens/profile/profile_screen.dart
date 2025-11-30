import 'package:flutter/material.dart';
import '../../../app/routes.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    const AvatarDisplay(
                      avatarUrl: null, // TODO: Get from user data
                      level: 5,
                      username: 'Estudante',
                    ),
                    const SizedBox(height: 24),
                    // Quick stats
                    Row(
                      children: [
                        Expanded(
                          child: _QuickStat(
                            icon: Icons.local_fire_department,
                            value: '7',
                            label: 'Sequência',
                            color: Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: _QuickStat(
                            icon: Icons.star,
                            value: '450',
                            label: 'XP Total',
                            color: Colors.amber,
                          ),
                        ),
                        Expanded(
                          child: _QuickStat(
                            icon: Icons.emoji_events,
                            value: '12',
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
                children: const [
                  StatsCard(
                    title: 'Questões Respondidas',
                    stats: {
                      'Total': '247',
                      'Corretas': '198',
                      'Taxa de Acerto': '80%',
                    },
                  ),
                  SizedBox(height: 16),
                  StatsCard(
                    title: 'Progresso por Unidade',
                    stats: {
                      'Números': '75%',
                      'Álgebra': '45%',
                      'Geometria': '30%',
                      'Grandezas': '60%',
                      'Estatística': '20%',
                    },
                  ),
                  SizedBox(height: 16),
                  StatsCard(
                    title: 'Tempo de Estudo',
                    stats: {
                      'Total': '12h 30min',
                      'Esta Semana': '2h 15min',
                      'Média Diária': '25min',
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
    return false;
  }
}
