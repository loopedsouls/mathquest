import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/shop/duolingo_design_system.dart';
import '../../widgets/shop/gamified_shop_widgets.dart';
import '../../widgets/shop/coins_display.dart';

/// Gamified Shop screen - Duolingo style
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
  String? _previewTheme; // Theme being previewed (not saved)
  bool _isLoading = true;

  // Shop items from Duolingo design system
  late List<ShopItem> _avatars;
  late List<ShopItem> _themes;
  late List<ShopItem> _powerups;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadUserData();
  }

  void _initializeItems() {
    // Initialize avatars from DuoAvatars
    _avatars = DuoAvatars.all.map((data) {
      return ShopItem.fromAvatarData(
        data,
        isPurchased: _purchasedItems.contains(data['id']) || data['price'] == 0,
      );
    }).toList();

    // Initialize themes from DuoThemes
    _themes = DuoThemes.all.map((data) {
      return ShopItem.fromThemeData(
        data,
        isPurchased: _purchasedItems.contains(data['id']) || data['price'] == 0,
      );
    }).toList();

    // Initialize power-ups from DuoPowerUps
    _powerups = DuoPowerUps.all.map((data) {
      return ShopItem.fromPowerUpData(
        Map<String, dynamic>.from(data),
        isPurchased: false, // Power-ups are consumable
      );
    }).toList();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final coins = prefs.getInt(_userCoinsKey) ?? 500; // Start with 500 coins
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

  bool _isItemPurchased(String itemId) {
    return _purchasedItems.contains(itemId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleAvatarTap(ShopItem item) {
    if (_isItemPurchased(item.id)) {
      // Select this avatar
      _selectAvatar(item.id);
      _showSuccessSnackbar('Avatar selecionado!');
    } else {
      _showPurchaseDialog(item);
    }
  }

  void _handleThemeTap(ShopItem item) {
    if (_isItemPurchased(item.id)) {
      // Select this theme (permanent)
      _selectTheme(item.id);
      setState(() => _previewTheme = null); // Clear preview
      _showSuccessSnackbar('Tema aplicado!');
    } else {
      _showPurchaseDialog(item);
    }
  }

  void _toggleThemePreview(ShopItem item) {
    if (_previewTheme == item.id) {
      // Turn off preview
      setState(() => _previewTheme = null);
      _showInfoSnackbar('Preview desativado');
    } else {
      // Turn on preview
      setState(() => _previewTheme = item.id);
      _showInfoSnackbar('Preview ativado! Compre para manter permanentemente.');
    }
  }

  void _handlePowerUpTap(ShopItem item) {
    _showPurchaseDialog(item);
  }

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
      _previewTheme = null; // Clear preview on purchase
      _initializeItems(); // Refresh items
    });

    _showSuccessSnackbar('${item.name} comprado! 🎉');

    // Auto-select if it's an avatar or theme
    if (item.category == ShopCategory.avatar) {
      _selectAvatar(item.id);
    } else if (item.category == ShopCategory.theme) {
      _selectTheme(item.id);
    }
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
      return const Scaffold(
        backgroundColor: DuoColors.bgDark,
        body: Center(
          child: CircularProgressIndicator(color: DuoColors.green),
        ),
      );
    }

    return Scaffold(
      backgroundColor: DuoColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            _buildAppBar(),
            // Tab Bar
            _buildTabBar(),
            const SizedBox(height: 16),
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
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Back button
          DuoIconButton(
            icon: Icons.arrow_back_rounded,
            color: DuoColors.bgCard,
            size: 44,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Loja',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Personalize sua experiência',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Coins display
          CoinsDisplay(coins: _userCoins, showLabel: true),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return DuoTabBar(
      tabs: const ['Avatares', 'Temas', 'Power-ups'],
      icons: const [Icons.face_rounded, Icons.palette_rounded, Icons.bolt_rounded],
      selectedIndex: _tabController.index,
      onTabSelected: (index) {
        _tabController.animateTo(index);
      },
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
      itemCount: _avatars.length,
      itemBuilder: (context, index) {
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
      itemCount: _themes.length,
      itemBuilder: (context, index) {
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
    );
  }

  Widget _buildPowerUpsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _powerups.length,
      itemBuilder: (context, index) {
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
    );
  }
}
