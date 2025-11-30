import 'package:flutter/material.dart';
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
  late TabController _tabController;
  int _userCoins = 250; // TODO: Get from provider

  // Sample shop items - TODO: Load from repository
  final List<ShopItem> _avatars = [
    const ShopItem(
      id: 'avatar_1',
      name: 'Astronauta',
      description: 'Um avatar espacial',
      price: 100,
      imageAsset: 'assets/avatars/astronaut.png',
      category: ShopCategory.avatar,
      isPurchased: true,
    ),
    const ShopItem(
      id: 'avatar_2',
      name: 'Cientista',
      description: 'Avatar de cientista',
      price: 150,
      imageAsset: 'assets/avatars/scientist.png',
      category: ShopCategory.avatar,
      isPurchased: false,
    ),
    const ShopItem(
      id: 'avatar_3',
      name: 'Super-herói',
      description: 'Avatar de super-herói',
      price: 200,
      imageAsset: 'assets/avatars/superhero.png',
      category: ShopCategory.avatar,
      isPurchased: false,
    ),
  ];

  final List<ShopItem> _themes = [
    const ShopItem(
      id: 'theme_1',
      name: 'Tema Escuro',
      description: 'Modo escuro elegante',
      price: 0,
      imageAsset: 'assets/themes/dark.png',
      category: ShopCategory.theme,
      isPurchased: true,
    ),
    const ShopItem(
      id: 'theme_2',
      name: 'Tema Oceano',
      description: 'Tons de azul',
      price: 100,
      imageAsset: 'assets/themes/ocean.png',
      category: ShopCategory.theme,
      isPurchased: false,
    ),
    const ShopItem(
      id: 'theme_3',
      name: 'Tema Floresta',
      description: 'Tons de verde',
      price: 100,
      imageAsset: 'assets/themes/forest.png',
      category: ShopCategory.theme,
      isPurchased: false,
    ),
  ];

  final List<ShopItem> _powerups = [
    const ShopItem(
      id: 'powerup_1',
      name: 'Dica Extra',
      description: '+1 dica por lição',
      price: 50,
      imageAsset: 'assets/powerups/hint.png',
      category: ShopCategory.powerup,
      isPurchased: false,
    ),
    const ShopItem(
      id: 'powerup_2',
      name: 'Tempo Extra',
      description: '+10 segundos por questão',
      price: 75,
      imageAsset: 'assets/powerups/time.png',
      category: ShopCategory.powerup,
      isPurchased: false,
    ),
    const ShopItem(
      id: 'powerup_3',
      name: 'Segunda Chance',
      description: 'Pode tentar novamente',
      price: 100,
      imageAsset: 'assets/powerups/retry.png',
      category: ShopCategory.powerup,
      isPurchased: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _purchaseItem(ShopItem item) {
    if (item.isPurchased) {
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
            onPressed: () {
              setState(() {
                _userCoins -= item.price;
                // TODO: Mark item as purchased
              });
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
        return ShopItemCard(
          item: items[index],
          userCoins: _userCoins,
          onPurchase: () => _purchaseItem(items[index]),
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

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageAsset,
    required this.category,
    required this.isPurchased,
  });
}

enum ShopCategory { avatar, theme, powerup }
