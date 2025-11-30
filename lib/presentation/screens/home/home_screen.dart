import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/routes.dart';
import '../../../data/repositories/auth_repository_impl.dart';
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

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  static const String _streakKey = 'current_streak';
  static const String _lastStudyDateKey = 'last_study_date';
  static const String _dailyRewardClaimedKey = 'daily_reward_claimed';
  static const String _userCoinsKey = 'user_coins';
  static const String _userXpKey = 'user_xp';
  static const String _userLevelKey = 'user_level';

  final _authRepository = AuthRepositoryImpl();

  String _userName = 'Estudante';
  int _level = 1;
  int _xp = 0;
  int _xpToNextLevel = 100;
  int _coins = 0;
  int _currentStreak = 0;
  bool _dailyRewardClaimed = false;
  bool _isLoading = true;

  Map<String, double> _progressByUnit = {
    'Números': 0.0,
    'Álgebra': 0.0,
    'Geometria': 0.0,
    'Grandezas': 0.0,
    'Estatística': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get user name from auth
    final currentUser = _authRepository.currentUser;
    final userName = currentUser?.displayName ?? 
                     prefs.getString('user_name') ?? 
                     'Estudante';

    // Load stats
    final level = prefs.getInt(_userLevelKey) ?? 1;
    final xp = prefs.getInt(_userXpKey) ?? 0;
    final coins = prefs.getInt(_userCoinsKey) ?? 0;
    final streak = prefs.getInt(_streakKey) ?? 0;
    
    // Check if daily reward was already claimed today
    final lastClaimDate = prefs.getString(_dailyRewardClaimedKey);
    final today = DateTime.now().toIso8601String().split('T')[0];
    final dailyRewardClaimed = lastClaimDate == today;

    // Check and update streak
    final lastStudyDate = prefs.getString(_lastStudyDateKey);
    int updatedStreak = streak;
    if (lastStudyDate != null) {
      final lastDate = DateTime.parse(lastStudyDate);
      final difference = DateTime.now().difference(lastDate).inDays;
      if (difference > 1) {
        // Streak broken
        updatedStreak = 0;
        await prefs.setInt(_streakKey, 0);
      }
    }

    // Load progress by unit
    final progressByUnit = <String, double>{};
    for (final unit in ['Números', 'Álgebra', 'Geometria', 'Grandezas', 'Estatística']) {
      progressByUnit[unit] = prefs.getDouble('progress_$unit') ?? 0.0;
    }

    setState(() {
      _userName = userName;
      _level = level;
      _xp = xp;
      _xpToNextLevel = level * 100; // XP needed increases with level
      _coins = coins;
      _currentStreak = updatedStreak;
      _dailyRewardClaimed = dailyRewardClaimed;
      _progressByUnit = progressByUnit;
      _isLoading = false;
    });
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _loadUserData();
  }

  Future<void> _claimDailyReward() async {
    if (_dailyRewardClaimed) return;

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    // Give reward based on streak
    final reward = 10 + (_currentStreak * 5); // More coins for longer streaks
    final newCoins = _coins + reward;
    
    await prefs.setString(_dailyRewardClaimedKey, today);
    await prefs.setInt(_userCoinsKey, newCoins);
    await prefs.setString(_lastStudyDateKey, today);
    
    // Update streak
    final newStreak = _currentStreak + 1;
    await prefs.setInt(_streakKey, newStreak);

    setState(() {
      _dailyRewardClaimed = true;
      _coins = newCoins;
      _currentStreak = newStreak;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Você ganhou $reward moedas! 🎉'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User stats header
            UserStatsHeader(
              userName: _userName,
              level: _level,
              xp: _xp,
              xpToNextLevel: _xpToNextLevel,
              coins: _coins,
            ),
            const SizedBox(height: 24),
            // Daily streak
            DailyStreakCard(
              currentStreak: _currentStreak,
              onClaimReward: _dailyRewardClaimed ? null : _claimDailyReward,
            ),
            const SizedBox(height: 16),
            // Progress overview
            ProgressOverviewCard(
              progressByUnit: _progressByUnit,
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
            // Recent activity list
            _buildRecentActivityList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityList() {
    // Show placeholder if no activity
    if (_xp == 0) {
      return Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey[300],
            child: const Icon(Icons.play_arrow, color: Colors.grey),
          ),
          title: const Text('Comece sua jornada!'),
          subtitle: const Text('Complete sua primeira lição'),
        ),
      );
    }

    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF6C63FF),
          child: Icon(Icons.check, color: Colors.white),
        ),
        title: const Text('Lição Completada'),
        subtitle: const Text('Continue estudando!'),
        trailing: Text(
          '+$_xp XP',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
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
