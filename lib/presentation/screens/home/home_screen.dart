import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/routes.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../widgets/flame/home_background_game.dart';
import '../../widgets/journey_map/journey_map_widget.dart';
import '../../widgets/profile/achievement_grid.dart';
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

  void switchToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.duoTheme;
    return Scaffold(
      backgroundColor: theme.bgDark,
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
      bottomNavigationBar: DuoNavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
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
  static const String _selectedAvatarKey = 'selected_avatar';

  final _authRepository = AuthRepositoryImpl();

  String _userName = 'Estudante';
  String _userEmoji = '🎓';
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

    // Load avatar emoji
    final selectedAvatarId =
        prefs.getString(_selectedAvatarKey) ?? 'avatar_default';
    String userEmoji = '🎓';
    for (final avatar in DuoAvatars.all) {
      if (avatar['id'] == selectedAvatarId) {
        userEmoji = avatar['emoji'] as String;
        break;
      }
    }

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
      _userEmoji = userEmoji;
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
      return const Center(
          child: CircularProgressIndicator(color: DuoColors.green));
    }

    final theme = context.duoTheme;

    return SizedBox.expand(
      child: Container(
        color: theme.bgDark,
        child: Stack(
          children: [
            // Flame animated background with theme colors
            Positioned.fill(
              child: GameWidget(
                game: HomeBackgroundGame(
                  primaryColor: theme.gradientColors.isNotEmpty
                      ? theme.gradientColors[1]
                      : DuoColors.green,
                ),
              ),
            ),
            // Content
            RefreshIndicator(
              color: DuoColors.green,
              backgroundColor: theme.bgCard,
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gamified User Header
                    DuoUserHeader(
                      username: _userName,
                      emoji: _userEmoji,
                      level: _level,
                      xp: _xp,
                      xpToNext: _xpToNextLevel,
                      coins: _coins,
                      onCoinsTap: () {},
                    ),
                    const SizedBox(height: 20),
                    // Daily streak card
                    DuoDailyStreakCard(
                      streak: _currentStreak,
                      isClaimed: _dailyRewardClaimed,
                      onClaim: _dailyRewardClaimed ? null : _claimDailyReward,
                    ),
                    const SizedBox(height: 20),
                    // Progress section
                    _buildProgressSection(),
                    const SizedBox(height: 20),
                    // Quick actions
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    // Recent activity section
                    Text(
                      'Atividade Recente',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                        fontSize: 18,
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
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    final theme = context.duoTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.bgCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up_rounded, color: theme.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Progresso por Unidade',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._progressByUnit.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${(entry.value * 100).toInt()}%',
                          style: const TextStyle(
                            color: DuoColors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    DuoProgressBar(
                      progress: entry.value,
                      color: _getColorForUnit(entry.key),
                      height: 8,
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Color _getColorForUnit(String unit) {
    switch (unit) {
      case 'Números':
        return DuoColors.green;
      case 'Álgebra':
        return DuoColors.blue;
      case 'Geometria':
        return DuoColors.purple;
      case 'Grandezas':
        return DuoColors.orange;
      case 'Estatística':
        return DuoColors.yellow;
      default:
        return DuoColors.green;
    }
  }

  Widget _buildQuickActions() {
    // Get home screen state to switch tabs
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();

    return Row(
      children: [
        Expanded(
          child: _GradientActionButton(
            icon: Icons.play_arrow_rounded,
            label: 'Começar',
            gradientColors: const [DuoColors.green, Color(0xFF3DA35D)],
            onTap: () {
              // Navigate to Journey Map tab (index 1)
              homeState?.switchToTab(1);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GradientActionButton(
            icon: Icons.emoji_events_rounded,
            label: 'Ranking',
            gradientColors: const [DuoColors.yellow, Color(0xFFFFAD1F)],
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.leaderboard),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GradientActionButton(
            icon: Icons.settings_rounded,
            label: 'Config',
            gradientColors: const [DuoColors.blue, Color(0xFF4B7BE5)],
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.settings),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivityList() {
    final theme = context.duoTheme;
    // Show placeholder if no activity
    if (_xp == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.bgCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DuoColors.gray.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.play_arrow_rounded, color: DuoColors.gray),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comece sua jornada!',
                    style: TextStyle(
                        color: theme.textPrimary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Complete sua primeira lição',
                    style: TextStyle(color: theme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.bgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DuoColors.green.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: DuoColors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lição Completada',
                  style: TextStyle(
                      color: theme.textPrimary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Continue estudando!',
                  style: TextStyle(color: theme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: DuoColors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '+$_xp XP',
              style: const TextStyle(
                color: DuoColors.green,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gradient Quick Action Button for home screen (Duolingo style)
class _GradientActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _GradientActionButton({
    required this.icon,
    required this.label,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
              ),
            ),
          ],
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
  String? _previewTheme; // Theme being previewed (not saved)
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
    final selectedAvatar =
        prefs.getString(_selectedAvatarKey) ?? 'avatar_default';
    final selectedTheme = prefs.getString(_selectedThemeKey) ?? 'theme_system';

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
    // Update global theme provider
    DuoThemeProvider.of(context)?.selectTheme(themeId);
  }

  bool _isItemPurchased(String itemId) => _purchasedItems.contains(itemId);

  @override
  void dispose() {
    // Clear preview when leaving shop
    DuoThemeProvider.of(context)?.clearPreview();
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
      setState(() => _previewTheme = null); // Clear preview
      DuoThemeProvider.of(context)?.clearPreview();
      _showSuccessSnackbar('Tema aplicado!');
    } else {
      _showPurchaseDialog(id, theme['name'] as String, price);
    }
  }

  void _toggleThemePreview(Map<String, dynamic> theme) {
    final id = theme['id'] as String;
    final themeProvider = DuoThemeProvider.of(context);

    if (_previewTheme == id) {
      // Turn off preview
      setState(() => _previewTheme = null);
      themeProvider?.clearPreview();
      _showInfoSnackbar('Preview desativado');
    } else {
      // Turn on preview
      setState(() => _previewTheme = id);
      themeProvider?.setPreviewTheme(id);
      _showInfoSnackbar('Preview ativado! Compre para manter permanentemente.');
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

    final theme = context.duoTheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            Text('Comprar $name?', style: TextStyle(color: theme.textPrimary)),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DuoCoinIcon(size: 24),
            const SizedBox(width: 8),
            Text(
              '$price moedas',
              style: TextStyle(color: theme.textPrimary, fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Cancelar', style: TextStyle(color: theme.textSecondary)),
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

              // Clear preview and auto-select
              setState(() => _previewTheme = null);
              DuoThemeProvider.of(context)?.clearPreview();
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

  void _showInfoSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.visibility, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: DuoColors.purple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
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

    final theme = context.duoTheme;

    return Container(
      color: theme.bgDark,
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
                    color: theme.bgCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.store_rounded, color: theme.accent),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loja',
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Personalize sua experiência',
                      style: TextStyle(
                        color: theme.textSecondary,
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
            icons: const [
              Icons.face_rounded,
              Icons.palette_rounded,
              Icons.bolt_rounded
            ],
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
    final isDark = context.isDuoThemeDark;
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
        final isSystem = theme['isSystem'] == true;

        // Get colors from the appropriate variant (light or dark)
        final variant = isDark ? 'dark' : 'light';
        final variantData = theme[variant] as Map<String, dynamic>;
        final colors = [
          Color(variantData['bgDark'] as int),
          Color(variantData['bgCard'] as int),
          Color(variantData['accent'] as int),
        ];

        final isPurchased = _isItemPurchased(id);
        return DuoThemeCard(
          id: id,
          name: isSystem
              ? 'Padrão (${isDark ? "Escuro" : "Claro"})'
              : theme['name'] as String,
          price: theme['price'] as int,
          colors: colors,
          isPurchased: isPurchased,
          isSelected: _selectedTheme == id || _previewTheme == id,
          isPreview: _previewTheme == id,
          onTap: () => _handleThemeTap(theme),
          onPreview: isPurchased ? null : () => _toggleThemePreview(theme),
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

/// Embedded Profile content - Duolingo Style
class _ProfilePlaceholder extends StatefulWidget {
  const _ProfilePlaceholder();

  @override
  State<_ProfilePlaceholder> createState() => _ProfilePlaceholderState();
}

class _ProfilePlaceholderState extends State<_ProfilePlaceholder>
    with SingleTickerProviderStateMixin {
  static const String _selectedAvatarKey = 'selected_avatar';
  static const String _purchasedItemsKey = 'purchased_items';

  late TabController _tabController;
  final _authRepository = AuthRepositoryImpl();

  String _username = 'Estudante';
  String _avatarEmoji = '🎓';
  String? _avatarId;
  String _avatarRarity = 'common';
  int _avatarColor = 0xFF58CC02;
  int _level = 1;
  int _streak = 0;
  int _totalXp = 0;
  int _achievementsCount = 0;
  int _totalQuestions = 0;
  int _correctQuestions = 0;
  Set<String> _purchasedAvatars = {};
  Map<String, double> _progressByUnit = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUser = _authRepository.currentUser;

    // Load purchased avatars
    final purchasedList = prefs.getStringList(_purchasedItemsKey) ?? [];
    final purchasedAvatars = <String>{};
    for (final item in purchasedList) {
      if (item.startsWith('avatar_')) purchasedAvatars.add(item);
    }
    // Free avatars are always available
    for (final avatar in DuoAvatars.all) {
      if (avatar['price'] == 0) purchasedAvatars.add(avatar['id'] as String);
    }

    // Load selected avatar
    final selectedAvatarId =
        prefs.getString(_selectedAvatarKey) ?? 'avatar_default';
    String emoji = '🎓';
    String rarity = 'common';
    int color = 0xFF58CC02;
    for (final avatar in DuoAvatars.all) {
      if (avatar['id'] == selectedAvatarId) {
        emoji = avatar['emoji'] as String;
        rarity = avatar['rarity'] as String;
        color = avatar['color'] as int;
        break;
      }
    }

    if (mounted) {
      setState(() {
        _username = currentUser?.displayName ??
            prefs.getString('user_name') ??
            'Estudante';
        _avatarEmoji = emoji;
        _avatarId = selectedAvatarId;
        _avatarRarity = rarity;
        _avatarColor = color;
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
        _purchasedAvatars = purchasedAvatars;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectAvatar(Map<String, dynamic> avatar) async {
    final prefs = await SharedPreferences.getInstance();
    final id = avatar['id'] as String;
    await prefs.setString(_selectedAvatarKey, id);
    setState(() {
      _avatarId = id;
      _avatarEmoji = avatar['emoji'] as String;
      _avatarRarity = avatar['rarity'] as String;
      _avatarColor = avatar['color'] as int;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Avatar atualizado!'),
          ],
        ),
        backgroundColor: DuoColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showAvatarSelector() {
    showDialog(
      context: context,
      builder: (ctx) => DuoAvatarSelectionDialog(
        currentAvatarId: _avatarId,
        purchasedAvatars: _purchasedAvatars,
        onSelect: _selectAvatar,
      ),
    );
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
      return const Center(
          child: CircularProgressIndicator(color: DuoColors.green));
    }

    final theme = context.duoTheme;

    return Container(
      color: theme.bgDark,
      child: NestedScrollView(
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
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: DuoColors.purple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.person_rounded,
                              color: DuoColors.purple, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Meu Perfil',
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DuoIconButton(
                          icon: Icons.settings_rounded,
                          color: theme.bgCard,
                          onPressed: () => Navigator.of(context)
                              .pushNamed(AppRoutes.settings),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Avatar and user info
                    DuoProfileAvatar(
                      emoji: _avatarEmoji,
                      level: _level,
                      username: _username,
                      colorValue: _avatarColor,
                      rarity: _avatarRarity,
                      onTap: _showAvatarSelector,
                    ),
                    const SizedBox(height: 24),
                    // Quick stats
                    Row(
                      children: [
                        Expanded(
                          child: DuoQuickStat(
                            icon: Icons.local_fire_department_rounded,
                            value: '$_streak',
                            label: 'Sequência',
                            color: DuoColors.orange,
                          ),
                        ),
                        Expanded(
                          child: DuoQuickStat(
                            icon: Icons.star_rounded,
                            value: '$_totalXp',
                            label: 'XP Total',
                            color: DuoColors.yellow,
                          ),
                        ),
                        Expanded(
                          child: DuoQuickStat(
                            icon: Icons.emoji_events_rounded,
                            value: '$_achievementsCount',
                            label: 'Conquistas',
                            color: DuoColors.purple,
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
              delegate: _DuoTabBarDelegate(
                theme.bgDark,
                DuoTabBar(
                  tabs: const ['Estatísticas', 'Conquistas'],
                  icons: const [
                    Icons.bar_chart_rounded,
                    Icons.emoji_events_rounded
                  ],
                  selectedIndex: _tabController.index,
                  onTabSelected: (index) {
                    _tabController.animateTo(index);
                  },
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
                  DuoStatCard(title: 'Questões Respondidas', stats: {
                    'Total': '$_totalQuestions',
                    'Corretas': '$_correctQuestions',
                    'Taxa de Acerto': _calculateAccuracy()
                  }),
                  const SizedBox(height: 16),
                  DuoStatCard(title: 'Progresso por Unidade', stats: {
                    for (final entry in _progressByUnit.entries)
                      entry.key: '${(entry.value * 100).toInt()}%'
                  }),
                  const SizedBox(height: 16),
                  DuoStatCard(title: 'Informações Gerais', stats: {
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
      ),
    );
  }
}

class _DuoTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Color bgColor;
  final Widget _tabBar;
  _DuoTabBarDelegate(this.bgColor, this._tabBar);

  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_DuoTabBarDelegate oldDelegate) =>
      oldDelegate.bgColor != bgColor;
}
