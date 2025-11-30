import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/routes.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../widgets/flame/home_background_game.dart';
import '../../widgets/home/daily_streak_card.dart';
import '../../widgets/home/progress_overview_card.dart';
import '../../widgets/home/quick_actions.dart';
import '../../widgets/home/user_stats_header.dart';
import '../../widgets/journey_map/journey_map_widget.dart';
import '../../widgets/profile/achievement_grid.dart';
import '../../widgets/profile/stats_card.dart';
import '../../widgets/profile/avatar_display.dart';
import '../../widgets/shop/duolingo_design_system.dart';
import '../../widgets/shop/coins_display.dart';

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
            JourneyMapWidget(),
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
    final userName =
        currentUser?.displayName ?? prefs.getString('user_name') ?? 'Estudante';

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
    for (final unit in [
      'Números',
      'Álgebra',
      'Geometria',
      'Grandezas',
      'Estatística'
    ]) {
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

    return Stack(
      children: [
        // Flame animated background
        Positioned.fill(
          child: GameWidget(
            game: HomeBackgroundGame(
              primaryColor: Theme.of(context).primaryColor,
            ),
          ),
        ),
        // Content
        RefreshIndicator(
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
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 12),
                // Recent activity list
                _buildRecentActivityList(),
              ],
            ),
          ),
        ),
      ],
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

/// Embedded Shop content - Duolingo style
class _ShopPlaceholder extends StatefulWidget {
  const _ShopPlaceholder();

  @override
  State<_ShopPlaceholder> createState() => _ShopPlaceholderState();
}

class _ShopPlaceholderState extends State<_ShopPlaceholder>
    with SingleTickerProviderStateMixin {
  static const String _userCoinsKey = 'user_coins';
  static const String _purchasedItemsKey = 'purchased_items';
  static const String _selectedAvatarKey = 'selected_avatar';
  static const String _selectedThemeKey = 'selected_theme';

  late TabController _tabController;
  int _userCoins = 0;
  Set<String> _purchasedItems = {};
  String? _selectedAvatar;
  String? _selectedTheme;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final coins = prefs.getInt(_userCoinsKey) ?? 500;
    final purchasedList = prefs.getStringList(_purchasedItemsKey) ?? [];
    final selectedAvatar = prefs.getString(_selectedAvatarKey) ?? 'avatar_default';
    final selectedTheme = prefs.getString(_selectedThemeKey) ?? 'theme_dark';

    // Free items are always purchased
    final allPurchased = {...purchasedList};
    for (final avatar in DuoAvatars.all) {
      if (avatar['price'] == 0) allPurchased.add(avatar['id']);
    }
    for (final theme in DuoThemes.all) {
      if (theme['price'] == 0) allPurchased.add(theme['id']);
    }

    if (mounted) {
      setState(() {
        _userCoins = coins;
        _purchasedItems = allPurchased;
        _selectedAvatar = selectedAvatar;
        _selectedTheme = selectedTheme;
        _isLoading = false;
      });
    }
  }

  Future<void> _savePurchase(String itemId, int newCoins) async {
    final prefs = await SharedPreferences.getInstance();
    _purchasedItems.add(itemId);
    await prefs.setStringList(_purchasedItemsKey, _purchasedItems.toList());
    await prefs.setInt(_userCoinsKey, newCoins);
  }

  Future<void> _selectAvatar(String avatarId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedAvatarKey, avatarId);
    setState(() => _selectedAvatar = avatarId);
  }

  Future<void> _selectTheme(String themeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedThemeKey, themeId);
    setState(() => _selectedTheme = themeId);
  }

  bool _isItemPurchased(String itemId) => _purchasedItems.contains(itemId);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleAvatarTap(Map<String, dynamic> avatar) {
    final id = avatar['id'] as String;
    final price = avatar['price'] as int;
    
    if (_isItemPurchased(id)) {
      _selectAvatar(id);
      _showSuccessSnackbar('Avatar selecionado!');
    } else {
      _showPurchaseDialog(id, avatar['name'] as String, price);
    }
  }

  void _handleThemeTap(Map<String, dynamic> theme) {
    final id = theme['id'] as String;
    final price = theme['price'] as int;
    
    if (_isItemPurchased(id)) {
      _selectTheme(id);
      _showSuccessSnackbar('Tema aplicado!');
    } else {
      _showPurchaseDialog(id, theme['name'] as String, price);
    }
  }

  void _handlePowerUpTap(Map<String, dynamic> powerup) {
    _showPurchaseDialog(
      powerup['id'] as String,
      powerup['name'] as String,
      powerup['price'] as int,
    );
  }

  void _showPurchaseDialog(String id, String name, int price) {
    if (_userCoins < price) {
      _showErrorSnackbar('Moedas insuficientes!');
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DuoColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Comprar $name?', style: const TextStyle(color: Colors.white)),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DuoCoinIcon(size: 24),
            const SizedBox(width: 8),
            Text(
              '$price moedas',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: DuoColors.gray)),
          ),
          DuoButton(
            text: 'Comprar',
            color: DuoColors.green,
            onPressed: () async {
              final newCoins = _userCoins - price;
              await _savePurchase(id, newCoins);
              setState(() => _userCoins = newCoins);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _showSuccessSnackbar('$name comprado! 🎉');
              
              // Auto-select
              if (id.startsWith('avatar_')) _selectAvatar(id);
              if (id.startsWith('theme_')) _selectTheme(id);
            },
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: DuoColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: DuoColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: DuoColors.green),
      );
    }

    return Container(
      color: DuoColors.bgDark,
      child: Column(
        children: [
          // Header with coins
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: DuoColors.bgCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.store_rounded, color: DuoColors.green),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Loja',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Personalize sua experiência',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                CoinsDisplay(coins: _userCoins, showLabel: true),
              ],
            ),
          ),
          // Tab Bar
          DuoTabBar(
            tabs: const ['Avatares', 'Temas', 'Power-ups'],
            icons: const [Icons.face_rounded, Icons.palette_rounded, Icons.bolt_rounded],
            selectedIndex: _tabController.index,
            onTabSelected: (index) {
              _tabController.animateTo(index);
            },
          ),
          const SizedBox(height: 12),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAvatarsGrid(),
                _buildThemesGrid(),
                _buildPowerUpsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: DuoAvatars.all.length,
      itemBuilder: (context, index) {
        final avatar = DuoAvatars.all[index];
        final id = avatar['id'] as String;
        return DuoShopCard(
          id: id,
          name: avatar['name'] as String,
          description: avatar['description'] as String? ?? '',
          price: avatar['price'] as int,
          emoji: avatar['emoji'] as String,
          color: avatar['color'] as int,
          rarity: avatar['rarity'] as String,
          isPurchased: _isItemPurchased(id),
          isSelected: _selectedAvatar == id,
          onTap: () => _handleAvatarTap(avatar),
        );
      },
    );
  }

  Widget _buildThemesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: DuoThemes.all.length,
      itemBuilder: (context, index) {
        final theme = DuoThemes.all[index];
        final id = theme['id'] as String;
        final colors = (theme['colors'] as List).cast<int>().map((c) => Color(c)).toList();
        return DuoThemeCard(
          id: id,
          name: theme['name'] as String,
          price: theme['price'] as int,
          colors: colors,
          isPurchased: _isItemPurchased(id),
          isSelected: _selectedTheme == id,
          onTap: () => _handleThemeTap(theme),
        );
      },
    );
  }

  Widget _buildPowerUpsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: DuoPowerUps.all.length,
      itemBuilder: (context, index) {
        final powerup = DuoPowerUps.all[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DuoPowerUpCard(
            id: powerup['id'] as String,
            name: powerup['name'] as String,
            description: powerup['description'] as String,
            price: powerup['price'] as int,
            icon: powerup['icon'] as IconData,
            colorValue: powerup['color'] as int,
            onTap: () => _handlePowerUpTap(powerup),
          ),
        );
      },
    );
  }
}

/// Embedded Profile content
class _ProfilePlaceholder extends StatefulWidget {
  const _ProfilePlaceholder();

  @override
  State<_ProfilePlaceholder> createState() => _ProfilePlaceholderState();
}

class _ProfilePlaceholderState extends State<_ProfilePlaceholder>
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
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUser = _authRepository.currentUser;

    if (mounted) {
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
        final unlockedAchievements =
            prefs.getStringList('unlocked_achievements') ?? [];
        _achievementsCount = unlockedAchievements.length;
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
  }

  @override
  void dispose() {
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
      return const Center(child: CircularProgressIndicator());
    }

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header with settings
                  Row(
                    children: [
                      const Icon(Icons.person, size: 28),
                      const SizedBox(width: 12),
                      Text('Perfil',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () =>
                            Navigator.of(context).pushNamed(AppRoutes.settings),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Avatar and user info
                  AvatarDisplay(
                      avatarUrl: _avatarUrl,
                      level: _level,
                      username: _username),
                  const SizedBox(height: 24),
                  // Quick stats
                  Row(
                    children: [
                      Expanded(
                          child: _QuickStat(
                              icon: Icons.local_fire_department,
                              value: '$_streak',
                              label: 'Sequência',
                              color: Colors.orange)),
                      Expanded(
                          child: _QuickStat(
                              icon: Icons.star,
                              value: '$_totalXp',
                              label: 'XP Total',
                              color: Colors.amber)),
                      Expanded(
                          child: _QuickStat(
                              icon: Icons.emoji_events,
                              value: '$_achievementsCount',
                              label: 'Conquistas',
                              color: Colors.purple)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Estatísticas'),
                  Tab(text: 'Conquistas')
                ],
              ),
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                StatsCard(title: 'Questões Respondidas', stats: {
                  'Total': '$_totalQuestions',
                  'Corretas': '$_correctQuestions',
                  'Taxa de Acerto': _calculateAccuracy()
                }),
                const SizedBox(height: 16),
                StatsCard(title: 'Progresso por Unidade', stats: {
                  for (final entry in _progressByUnit.entries)
                    entry.key: '${(entry.value * 100).toInt()}%'
                }),
                const SizedBox(height: 16),
                StatsCard(title: 'Informações Gerais', stats: {
                  'Nível': '$_level',
                  'XP Total': '$_totalXp',
                  'Sequência Atual': '$_streak dias'
                }),
              ],
            ),
          ),
          const AchievementGrid(),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _QuickStat(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey[600])),
      ],
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _TabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
        color: Theme.of(context).scaffoldBackgroundColor, child: _tabBar);
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}
