import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../widgets/home/daily_streak_card.dart';
import '../../widgets/home/progress_overview_card.dart';
import '../../widgets/home/quick_actions.dart';
import '../../widgets/home/user_stats_header.dart';

/// Home screen - Main hub after login
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: const [
            _HomeContent(),
            _MapPlaceholder(),
            _ShopPlaceholder(),
            _ProfilePlaceholder(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store),
            label: 'Loja',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Refresh data
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User stats header
            const UserStatsHeader(
              userName: 'Estudante', // TODO: Get from provider
              level: 5,
              xp: 450,
              xpToNextLevel: 500,
              coins: 120,
            ),
            const SizedBox(height: 24),
            // Daily streak
            DailyStreakCard(
              currentStreak: 7, // TODO: Get from provider
              onClaimReward: () {
                // TODO: Claim daily reward
              },
            ),
            const SizedBox(height: 16),
            // Progress overview
            const ProgressOverviewCard(
              progressByUnit: {
                'Números': 0.75,
                'Álgebra': 0.45,
                'Geometria': 0.30,
                'Grandezas': 0.60,
                'Estatística': 0.20,
              },
            ),
            const SizedBox(height: 16),
            // Quick actions
            QuickActions(
              onStartLesson: () {
                Navigator.of(context).pushNamed(AppRoutes.lessonMap);
              },
              onViewLeaderboard: () {
                Navigator.of(context).pushNamed(AppRoutes.leaderboard);
              },
              onOpenSettings: () {
                Navigator.of(context).pushNamed(AppRoutes.settings);
              },
            ),
            const SizedBox(height: 24),
            // Recent activity section
            Text(
              'Atividade Recente',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // TODO: Add recent activity list
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF6C63FF),
                  child: Icon(Icons.check, color: Colors.white),
                ),
                title: const Text('Lição Completada'),
                subtitle: const Text('Números Naturais - 6º ano'),
                trailing: Text(
                  '+50 XP',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    // Redirect to lesson map screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushNamed(AppRoutes.lessonMap);
    });
    return const Center(child: CircularProgressIndicator());
  }
}

class _ShopPlaceholder extends StatelessWidget {
  const _ShopPlaceholder();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushNamed(AppRoutes.shop);
    });
    return const Center(child: CircularProgressIndicator());
  }
}

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushNamed(AppRoutes.profile);
    });
    return const Center(child: CircularProgressIndicator());
  }
}
