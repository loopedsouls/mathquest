import 'package:flutter/material.dart';
import 'duolingo_design_system.dart';

/// Shop item category enum
enum ShopCategory { avatar, theme, powerup }

/// Data class for shop items
class ShopItem {
  final String id;
  final String name;
  final String description;
  final int price;
  final String? imageAsset;
  final String? emoji;
  final int? colorValue;
  final String? rarity;
  final ShopCategory category;
  final bool isPurchased;
  final List<int>? themeColors;
  final IconData? powerupIcon;

  ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageAsset,
    this.emoji,
    this.colorValue,
    this.rarity,
    required this.category,
    this.isPurchased = false,
    this.themeColors,
    this.powerupIcon,
  });

  /// Create avatar from DuoAvatars data
  factory ShopItem.fromAvatarData(Map<String, dynamic> data, {bool isPurchased = false}) {
    return ShopItem(
      id: data['id'],
      name: data['name'],
      description: _getAvatarDescription(data['rarity']),
      price: data['price'],
      emoji: data['emoji'],
      colorValue: data['color'],
      rarity: data['rarity'],
      category: ShopCategory.avatar,
      isPurchased: isPurchased,
    );
  }

  /// Create theme from DuoThemes data
  factory ShopItem.fromThemeData(Map<String, dynamic> data, {bool isPurchased = false}) {
    return ShopItem(
      id: data['id'],
      name: data['name'],
      description: 'Tema ${data['name']}',
      price: data['price'],
      themeColors: List<int>.from(data['colors']),
      category: ShopCategory.theme,
      isPurchased: isPurchased,
    );
  }

  /// Create powerup from DuoPowerUps data
  factory ShopItem.fromPowerUpData(Map<String, dynamic> data, {bool isPurchased = false, int quantity = 0}) {
    return ShopItem(
      id: data['id'],
      name: data['name'],
      description: data['description'],
      price: data['price'],
      powerupIcon: data['icon'],
      colorValue: data['color'],
      category: ShopCategory.powerup,
      isPurchased: isPurchased,
    );
  }

  static String _getAvatarDescription(String? rarity) {
    switch (rarity) {
      case 'rare':
        return 'Avatar raro';
      case 'epic':
        return 'Avatar épico';
      case 'legendary':
        return 'Avatar lendário';
      default:
        return 'Avatar comum';
    }
  }
}

/// Gamified shop item card widget - Duolingo style
class ShopItemCard extends StatelessWidget {
  final ShopItem item;
  final int userCoins;
  final VoidCallback onPurchase;
  final bool isSelected;

  const ShopItemCard({
    super.key,
    required this.item,
    required this.userCoins,
    required this.onPurchase,
    this.isSelected = false,
  });

  bool get _canAfford => userCoins >= item.price;

  @override
  Widget build(BuildContext context) {
    switch (item.category) {
      case ShopCategory.avatar:
        return _buildAvatarCard();
      case ShopCategory.theme:
        return _buildThemeCard();
      case ShopCategory.powerup:
        return _buildPowerUpCard();
    }
  }

  Widget _buildAvatarCard() {
    return DuoShopCard(
      id: item.id,
      name: item.name,
      description: item.description,
      price: item.price,
      emoji: item.emoji ?? '😊',
      color: item.colorValue ?? 0xFF58CC02,
      rarity: item.rarity ?? 'common',
      isPurchased: item.isPurchased,
      isSelected: isSelected,
      onTap: onPurchase,
    );
  }

  Widget _buildThemeCard() {
    final colors = item.themeColors ?? [0xFF131F24, 0xFF1A2B33, 0xFF233640];
    return DuoThemeCard(
      id: item.id,
      name: item.name,
      price: item.price,
      colors: colors.map((c) => Color(c)).toList(),
      isPurchased: item.isPurchased,
      isSelected: isSelected,
      onTap: onPurchase,
    );
  }

  Widget _buildPowerUpCard() {
    return DuoPowerUpCard(
      id: item.id,
      name: item.name,
      description: item.description,
      price: item.price,
      icon: item.powerupIcon ?? Icons.bolt_rounded,
      colorValue: item.colorValue ?? 0xFFFF9600,
      onTap: onPurchase,
    );
  }
}

/// Gamified coins display - Duolingo style
class GamifiedCoinsDisplay extends StatelessWidget {
  final int coins;
  final bool compact;

  const GamifiedCoinsDisplay({
    super.key,
    required this.coins,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DuoCoinIcon(size: 20),
          const SizedBox(width: 4),
          Text(
            '$coins',
            style: const TextStyle(
              color: DuoColors.yellow,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      );
    }
    return DuoCoinDisplay(coins: coins);
  }
}

/// Empty state for shop
class ShopEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const ShopEmptyState({
    super.key,
    this.message = 'Nenhum item disponível',
    this.icon = Icons.shopping_bag_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: DuoColors.grayLight,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: DuoColors.grayLight,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// Purchase confirmation dialog - Duolingo style
class PurchaseConfirmationDialog extends StatelessWidget {
  final ShopItem item;
  final int userCoins;
  final VoidCallback onConfirm;

  const PurchaseConfirmationDialog({
    super.key,
    required this.item,
    required this.userCoins,
    required this.onConfirm,
  });

  bool get _canAfford => userCoins >= item.price;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: DuoColors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Item preview
            if (item.category == ShopCategory.avatar)
              DuoAvatar(
                emoji: item.emoji,
                backgroundColor: Color(item.colorValue ?? 0xFF58CC02),
                borderColor: Color(item.colorValue ?? 0xFF58CC02).withValues(alpha: 0.7),
                size: 100,
                rarity: item.rarity,
              )
            else if (item.category == ShopCategory.powerup)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Color(item.colorValue ?? 0xFFFF9600),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.powerupIcon ?? Icons.bolt_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              )
            else
              Container(
                width: 100,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: (item.themeColors ?? [0xFF131F24, 0xFF1A2B33])
                        .map((c) => Color(c))
                        .toList(),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            const SizedBox(height: 16),
            // Item name
            Text(
              item.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Item description
            Text(
              item.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Price section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DuoColors.bgElevated,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Custo:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      const DuoCoinIcon(size: 24),
                      const SizedBox(width: 8),
                      Text(
                        '${item.price}',
                        style: const TextStyle(
                          color: DuoColors.yellow,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Balance section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _canAfford 
                    ? DuoColors.green.withValues(alpha: 0.2)
                    : DuoColors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _canAfford ? DuoColors.green : DuoColors.red,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _canAfford ? 'Saldo após compra:' : 'Saldo atual:',
                    style: TextStyle(
                      color: _canAfford ? DuoColors.green : DuoColors.red,
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    children: [
                      const DuoCoinIcon(size: 20),
                      const SizedBox(width: 6),
                      Text(
                        _canAfford 
                            ? '${userCoins - item.price}'
                            : '$userCoins',
                        style: TextStyle(
                          color: _canAfford ? DuoColors.green : DuoColors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!_canAfford) ...[
              const SizedBox(height: 8),
              Text(
                'Você precisa de mais ${item.price - userCoins} moedas',
                style: const TextStyle(
                  color: DuoColors.red,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: DuoButton(
                    text: 'Cancelar',
                    color: DuoColors.gray,
                    height: 48,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DuoButton(
                    text: 'Comprar',
                    color: _canAfford ? DuoColors.green : DuoColors.gray,
                    height: 48,
                    disabled: !_canAfford,
                    onPressed: _canAfford
                        ? () {
                            Navigator.pop(context);
                            onConfirm();
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
