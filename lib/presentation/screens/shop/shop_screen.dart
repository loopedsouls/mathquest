import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/shop/duolingo_design_system.dart';
import '../../widgets/shop/gamified_shop_widgets.dart';
import '../../widgets/shop/coins_display.dart';

/// Professional Gamified Shop screen - Duolingo style with premium UX
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
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
  String? _previewTheme;
  bool _isLoading = true;

  late List<ShopItem> _avatars;
  late List<ShopItem> _themes;
  late List<ShopItem> _powerups;

  // Category info
  final List<_CategoryInfo> _categories = [
    _CategoryInfo(
      title: 'Avatares',
      subtitle: 'Expresse sua personalidade',
      icon: Icons.face_rounded,
      color: DuoColors.blue,
    ),
    _CategoryInfo(
      title: 'Temas',
      subtitle: 'Personalize sua interface',
      icon: Icons.palette_rounded,
      color: DuoColors.purple,
    ),
    _CategoryInfo(
      title: 'Power-ups',
      subtitle: 'Impulsione seu aprendizado',
      icon: Icons.bolt_rounded,
      color: DuoColors.orange,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadUserData();
  }

  void _initializeItems() {
    _avatars = DuoAvatars.all.map((data) {
      return ShopItem.fromAvatarData(
        data,
        isPurchased: _purchasedItems.contains(data['id']) || data['price'] == 0,
      );
    }).toList();

    _themes = DuoThemes.all.map((data) {
      return ShopItem.fromThemeData(
        data,
        isPurchased: _purchasedItems.contains(data['id']) || data['price'] == 0,
      );
    }).toList();

    _powerups = DuoPowerUps.all.map((data) {
      return ShopItem.fromPowerUpData(
        Map<String, dynamic>.from(data),
        isPurchased: false,
      );
    }).toList();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final coins = prefs.getInt(_userCoinsKey) ?? 500;
    final purchasedList = prefs.getStringList(_purchasedItemsKey) ?? [];
    final selectedAvatar = prefs.getString(_selectedAvatarKey) ?? 'avatar_default';
    final selectedTheme = prefs.getString(_selectedThemeKey) ?? 'theme_dark';

    final allPurchased = {...purchasedList};
    for (final avatar in DuoAvatars.all) {
      if (avatar['price'] == 0) allPurchased.add(avatar['id']);
    }
    for (final theme in DuoThemes.all) {
      if (theme['price'] == 0) allPurchased.add(theme['id']);
    }

    setState(() {
      _userCoins = coins;
      _purchasedItems = allPurchased;
      _selectedAvatar = selectedAvatar;
      _selectedTheme = selectedTheme;
      _initializeItems();
      _isLoading = false;
    });
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

  void _handleAvatarTap(ShopItem item) {
    if (_isItemPurchased(item.id)) {
      _selectAvatar(item.id);
      _showSuccessSnackbar('Avatar selecionado!');
    } else {
      _showPurchaseDialog(item);
    }
  }

  void _handleThemeTap(ShopItem item) {
    if (_isItemPurchased(item.id)) {
      _selectTheme(item.id);
      setState(() => _previewTheme = null);
      _showSuccessSnackbar('Tema aplicado!');
    } else {
      _showPurchaseDialog(item);
    }
  }

  void _toggleThemePreview(ShopItem item) {
    if (_previewTheme == item.id) {
      setState(() => _previewTheme = null);
      _showInfoSnackbar('Preview desativado');
    } else {
      setState(() => _previewTheme = item.id);
      _showInfoSnackbar('Preview ativado! Compre para manter.');
    }
  }

  void _handlePowerUpTap(ShopItem item) => _showPurchaseDialog(item);

  void _showPurchaseDialog(ShopItem item) {
    showDialog(
      context: context,
      builder: (context) => PurchaseConfirmationDialog(
        item: item,
        userCoins: _userCoins,
        onConfirm: () => _completePurchase(item),
      ),
    );
  }

  Future<void> _completePurchase(ShopItem item) async {
    if (_userCoins < item.price) {
      _showErrorSnackbar('Moedas insuficientes!');
      return;
    }

    final newCoins = _userCoins - item.price;
    await _savePurchase(item.id, newCoins);

    setState(() {
      _userCoins = newCoins;
      _previewTheme = null;
      _initializeItems();
    });

    _showSuccessSnackbar('${item.name} comprado! 🎉');

    if (item.category == ShopCategory.avatar) {
      _selectAvatar(item.id);
    } else if (item.category == ShopCategory.theme) {
      _selectTheme(item.id);
    }
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: DuoColors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: DuoColors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showInfoSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.visibility_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: DuoColors.purple,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.duoTheme;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.bgDark,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: DuoColors.green),
              const SizedBox(height: 16),
              Text(
                'Carregando loja...',
                style: TextStyle(color: theme.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme),
            _buildCategoryTabs(theme),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAvatarsSection(theme),
                  _buildThemesSection(theme),
                  _buildPowerUpsSection(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(DuoThemeColors theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: theme.bgCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: Back button + Title + Coins
          Row(
            children: [
              _buildBackButton(theme),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.store_rounded, color: DuoColors.green, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Loja',
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Personalize sua experiência',
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _buildCoinsCard(theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(DuoThemeColors theme) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.bgElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.textSecondary.withValues(alpha: 0.1),
          ),
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          color: theme.textPrimary,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildCoinsCard(DuoThemeColors theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DuoColors.yellow.withValues(alpha: 0.15),
            DuoColors.orange.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DuoColors.yellow.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DuoCoinIcon(size: 26),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Saldo',
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$_userCoins',
                style: const TextStyle(
                  color: DuoColors.yellow,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(DuoThemeColors theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: theme.bgCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: List.generate(3, (index) {
            final isSelected = _tabController.index == index;
            final category = _categories[index];
            
            return Expanded(
              child: GestureDetector(
                onTap: () => _tabController.animateTo(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected ? category.color : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: category.color.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        category.icon,
                        size: 20,
                        color: isSelected ? Colors.white : theme.textSecondary,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category.title,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(_CategoryInfo category, int itemCount, int ownedCount, DuoThemeColors theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            category.color.withValues(alpha: 0.15),
            category.color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: category.color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(category.icon, color: category.color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.subtitle,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$ownedCount de $itemCount ${category.title.toLowerCase()}',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Progress indicator
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  value: itemCount > 0 ? ownedCount / itemCount : 0,
                  strokeWidth: 4,
                  backgroundColor: theme.bgElevated,
                  valueColor: AlwaysStoppedAnimation(category.color),
                ),
              ),
              Text(
                '${((ownedCount / itemCount) * 100).round()}%',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarsSection(DuoThemeColors theme) {
    final ownedCount = _avatars.where((a) => _isItemPurchased(a.id)).length;
    
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildSectionHeader(_categories[0], _avatars.length, ownedCount, theme),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = _avatars[index];
                return DuoShopCard(
                  id: item.id,
                  name: item.name,
                  description: item.description,
                  price: item.price,
                  emoji: item.emoji ?? '😊',
                  color: item.colorValue ?? 0xFF58CC02,
                  rarity: item.rarity ?? 'common',
                  isPurchased: _isItemPurchased(item.id),
                  isSelected: _selectedAvatar == item.id,
                  onTap: () => _handleAvatarTap(item),
                );
              },
              childCount: _avatars.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildThemesSection(DuoThemeColors theme) {
    final ownedCount = _themes.where((t) => _isItemPurchased(t.id)).length;
    
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildSectionHeader(_categories[1], _themes.length, ownedCount, theme),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = _themes[index];
                final colors = item.themeColors ?? [0xFF131F24, 0xFF1A2B33, 0xFF233640];
                final isPurchased = _isItemPurchased(item.id);
                return DuoThemeCard(
                  id: item.id,
                  name: item.name,
                  price: item.price,
                  colors: colors.map((c) => Color(c)).toList(),
                  isPurchased: isPurchased,
                  isSelected: _selectedTheme == item.id || _previewTheme == item.id,
                  isPreview: _previewTheme == item.id,
                  onTap: () => _handleThemeTap(item),
                  onPreview: isPurchased ? null : () => _toggleThemePreview(item),
                );
              },
              childCount: _themes.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildPowerUpsSection(DuoThemeColors theme) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildSectionHeader(_categories[2], _powerups.length, 0, theme),
        ),
        // Info card about power-ups
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DuoColors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DuoColors.blue.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: DuoColors.blue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Power-ups são consumíveis e podem ser usados durante as lições.',
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = _powerups[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DuoPowerUpCard(
                    id: item.id,
                    name: item.name,
                    description: item.description,
                    price: item.price,
                    icon: item.powerupIcon ?? Icons.bolt_rounded,
                    colorValue: item.colorValue ?? 0xFFFF9600,
                    onTap: () => _handlePowerUpTap(item),
                  ),
                );
              },
              childCount: _powerups.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

/// Category info helper class
class _CategoryInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  _CategoryInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
