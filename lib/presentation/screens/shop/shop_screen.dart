import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/shop/shop_item_card.dart';
import '../../widgets/shop/coins_display.dart';

/// Shop screen - Buy items with coins
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  static const String _userCoinsKey = 'user_coins';
  static const String _purchasedItemsKey = 'purchased_items';

  late TabController _tabController;
  int _userCoins = 0;
  Set<String> _purchasedItems = {};
  bool _isLoading = true;

  // Shop items
  late List<ShopItem> _avatars;
  late List<ShopItem> _themes;
  late List<ShopItem> _powerups;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeItems();
    _loadUserData();
  }

  void _initializeItems() {
    _avatars = [
      ShopItem(
        id: 'avatar_1',
        name: 'Astronauta',
        description: 'Um avatar espacial',
        price: 100,
        imageAsset: 'assets/avatars/astronaut.png',
        category: ShopCategory.avatar,
      ),
      ShopItem(
        id: 'avatar_2',
        name: 'Cientista',
        description: 'Avatar de cientista',
        price: 150,
        imageAsset: 'assets/avatars/scientist.png',
        category: ShopCategory.avatar,
      ),
      ShopItem(
        id: 'avatar_3',
        name: 'Super-herói',
        description: 'Avatar de super-herói',
        price: 200,
        imageAsset: 'assets/avatars/superhero.png',
        category: ShopCategory.avatar,
      ),
    ];

    _themes = [
      ShopItem(
        id: 'theme_1',
        name: 'Tema Escuro',
        description: 'Modo escuro elegante',
        price: 0,
        imageAsset: 'assets/themes/dark.png',
        category: ShopCategory.theme,
      ),
      ShopItem(
        id: 'theme_2',
        name: 'Tema Oceano',
        description: 'Tons de azul',
        price: 100,
        imageAsset: 'assets/themes/ocean.png',
        category: ShopCategory.theme,
      ),
      ShopItem(
        id: 'theme_3',
        name: 'Tema Floresta',
        description: 'Tons de verde',
        price: 100,
        imageAsset: 'assets/themes/forest.png',
        category: ShopCategory.theme,
      ),
    ];

    _powerups = [
      ShopItem(
        id: 'powerup_1',
        name: 'Dica Extra',
        description: '+1 dica por lição',
        price: 50,
        imageAsset: 'assets/powerups/hint.png',
        category: ShopCategory.powerup,
      ),
      ShopItem(
        id: 'powerup_2',
        name: 'Tempo Extra',
        description: '+10 segundos por questão',
        price: 75,
        imageAsset: 'assets/powerups/time.png',
        category: ShopCategory.powerup,
      ),
      ShopItem(
        id: 'powerup_3',
        name: 'Segunda Chance',
        description: 'Pode tentar novamente',
        price: 100,
        imageAsset: 'assets/powerups/retry.png',
        category: ShopCategory.powerup,
      ),
    ];
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final coins = prefs.getInt(_userCoinsKey) ?? 0;
    final purchasedList = prefs.getStringList(_purchasedItemsKey) ?? ['theme_1']; // Dark theme is free

    setState(() {
      _userCoins = coins;
      _purchasedItems = purchasedList.toSet();
      _isLoading = false;
    });
  }

  Future<void> _savePurchase(String itemId, int newCoins) async {
    final prefs = await SharedPreferences.getInstance();
    _purchasedItems.add(itemId);
    await prefs.setStringList(_purchasedItemsKey, _purchasedItems.toList());
    await prefs.setInt(_userCoinsKey, newCoins);
  }

  bool _isItemPurchased(String itemId) {
    return _purchasedItems.contains(itemId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _purchaseItem(ShopItem item) {
    final isPurchased = _isItemPurchased(item.id);
    
    if (isPurchased) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você já possui este item!')),
      );
      return;
    }

    if (_userCoins < item.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Moedas insuficientes!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Comprar ${item.name}?'),
        content: Text('Custo: ${item.price} moedas'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newCoins = _userCoins - item.price;
              await _savePurchase(item.id, newCoins);
              
              setState(() {
                _userCoins = newCoins;
              });
              
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.name} comprado com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Comprar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loja')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loja'),
        actions: [
          CoinsDisplay(coins: _userCoins),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.face), text: 'Avatares'),
            Tab(icon: Icon(Icons.palette), text: 'Temas'),
            Tab(icon: Icon(Icons.bolt), text: 'Power-ups'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildItemGrid(_avatars),
          _buildItemGrid(_themes),
          _buildItemGrid(_powerups),
        ],
      ),
    );
  }

  Widget _buildItemGrid(List<ShopItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ShopItemCard(
          item: ShopItem(
            id: item.id,
            name: item.name,
            description: item.description,
            price: item.price,
            imageAsset: item.imageAsset,
            category: item.category,
            isPurchased: _isItemPurchased(item.id),
          ),
          userCoins: _userCoins,
          onPurchase: () => _purchaseItem(item),
        );
      },
    );
  }
}

/// Data class for shop items
class ShopItem {
  final String id;
  final String name;
  final String description;
  final int price;
  final String imageAsset;
  final ShopCategory category;
  final bool isPurchased;

  ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageAsset,
    required this.category,
    this.isPurchased = false,
  });
}

enum ShopCategory { avatar, theme, powerup }
