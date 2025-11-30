import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/routes.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../data/repositories/lesson_repository_impl.dart';
import '../../widgets/home/daily_streak_card.dart';
import '../../widgets/home/progress_overview_card.dart';
import '../../widgets/home/quick_actions.dart';
import '../../widgets/home/user_stats_header.dart';
import '../../widgets/lesson_map/lesson_node.dart';
import '../../widgets/lesson_map/map_path.dart';
import '../lesson_map/lesson_map_screen.dart';

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

class _MapPlaceholder extends StatefulWidget {
  const _MapPlaceholder();

  @override
  State<_MapPlaceholder> createState() => _MapPlaceholderState();
}

class _MapPlaceholderState extends State<_MapPlaceholder> {
  String _selectedUnit = 'Números';
  String _selectedYear = '6º ano';
  bool _isLoading = true;
  List<LessonNodeData> _lessons = [];
  
  final LessonRepositoryImpl _lessonRepository = LessonRepositoryImpl();

  final List<String> _units = [
    'Números',
    'Álgebra',
    'Geometria',
    'Grandezas e Medidas',
    'Probabilidade e Estatística',
  ];

  final List<String> _years = ['6º ano', '7º ano', '8º ano', '9º ano'];

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    setState(() => _isLoading = true);
    
    try {
      final allLessons = await _lessonRepository.getAllLessons();
      final filteredLessons = allLessons
          .where((l) => l.thematicUnit == _selectedUnit && l.schoolYear == _selectedYear)
          .toList();
      
      filteredLessons.sort((a, b) => a.order.compareTo(b.order));
      
      final prefs = await SharedPreferences.getInstance();
      final completedLessons = prefs.getStringList('completed_lessons') ?? [];
      final lessonStars = prefs.getString('lesson_stars');
      final starsMap = lessonStars != null 
          ? Map<String, int>.from(
              (lessonStars.isNotEmpty ? _parseStarsMap(lessonStars) : {})
            )
          : <String, int>{};
      
      final unlockedIds = prefs.getStringList('unlocked_lessons') ?? 
          ['numeros_6_1', 'algebra_6_1', 'numeros_7_1'];
      
      final lessonNodes = <LessonNodeData>[];
      for (int i = 0; i < filteredLessons.length; i++) {
        final lesson = filteredLessons[i];
        final isCompleted = completedLessons.contains(lesson.id);
        final isUnlocked = unlockedIds.contains(lesson.id) || !lesson.isLocked;
        
        LessonStatus status;
        if (isCompleted) {
          status = LessonStatus.completed;
        } else if (isUnlocked) {
          status = LessonStatus.current;
        } else {
          status = LessonStatus.locked;
        }
        
        lessonNodes.add(LessonNodeData(
          id: lesson.id,
          title: lesson.title,
          status: status,
          stars: starsMap[lesson.id] ?? 0,
        ));
      }
      
      if (mounted) {
        setState(() {
          _lessons = lessonNodes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lessons = [];
          _isLoading = false;
        });
      }
    }
  }

  Map<String, int> _parseStarsMap(String json) {
    try {
      final trimmed = json.trim();
      if (trimmed.isEmpty || trimmed == '{}') return {};
      
      final content = trimmed.substring(1, trimmed.length - 1);
      if (content.isEmpty) return {};
      
      final result = <String, int>{};
      final pairs = content.split(',');
      for (final pair in pairs) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          final key = parts[0].trim().replaceAll('"', '');
          final value = int.tryParse(parts[1].trim()) ?? 0;
          result[key] = value;
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  void _onLessonTap(LessonNodeData lesson) {
    if (lesson.status == LessonStatus.locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete as lições anteriores para desbloquear'),
        ),
      );
      return;
    }

    Navigator.of(context).pushNamed(
      AppRoutes.gameplay,
      arguments: {'lessonId': lesson.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.map, size: 28),
              const SizedBox(width: 12),
              Text(
                'Mapa de Lições',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              FilterChip(
                label: Text(_selectedUnit),
                selected: true,
                onSelected: (_) => _showUnitPicker(),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(_selectedYear),
                selected: true,
                onSelected: (_) => _showYearPicker(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Lesson map
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _lessons.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma lição disponível\npara $_selectedUnit - $_selectedYear',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Column(
                          children: [
                            for (int i = 0; i < _lessons.length; i++) ...[
                              if (i > 0)
                                const MapPath(height: 40),
                              LessonNode(
                                data: LessonNodeData(
                                  id: _lessons[i].id,
                                  title: _lessons[i].title,
                                  status: _lessons[i].status,
                                  stars: _lessons[i].stars,
                                ),
                                onTap: () => _onLessonTap(_lessons[i]),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  void _showUnitPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: _units.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(_units[index]),
              trailing: _selectedUnit == _units[index]
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                setState(() => _selectedUnit = _units[index]);
                Navigator.pop(context);
                _loadLessons();
              },
            );
          },
        );
      },
    );
  }

  void _showYearPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: _years.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(_years[index]),
              trailing: _selectedYear == _years[index]
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                setState(() => _selectedYear = _years[index]);
                Navigator.pop(context);
                _loadLessons();
              },
            );
          },
        );
      },
    );
  }
}

class _ShopPlaceholder extends StatelessWidget {
  const _ShopPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_outlined,
            size: 64,
            color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Loja',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Personalize seu personagem',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.shop);
            },
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Abrir Loja'),
          ),
        ],
      ),
    );
  }
}

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outlined,
            size: 64,
            color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Meu Perfil',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Veja suas estatísticas e conquistas',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.profile);
            },
            icon: const Icon(Icons.person),
            label: const Text('Ver Perfil'),
          ),
        ],
      ),
    );
  }
}
