import 'package:flutter/material.dart';
import '../../screens/shop/shop_screen.dart';

/// Shop item card widget
class ShopItemCard extends StatelessWidget {
  final ShopItem item;
  final int userCoins;
  final VoidCallback onPurchase;

  const ShopItemCard({
    super.key,
    required this.item,
    required this.userCoins,
    required this.onPurchase,
  });

  bool get _canAfford => userCoins >= item.price;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onPurchase,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Item image placeholder
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: item.isPurchased
                        ? Colors.green.withValues(alpha: 0.1)
                        : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      _getCategoryIcon(),
                      size: 48,
                      color: item.isPurchased
                          ? Colors.green
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Item name
              Text(
                item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Price or owned badge
              if (item.isPurchased)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Adquirido',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.monetization_on,
                      size: 16,
                      color: _canAfford ? Colors.amber : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.price}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _canAfford ? Colors.amber : Colors.grey,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (item.category) {
      case ShopCategory.avatar:
        return Icons.face;
      case ShopCategory.theme:
        return Icons.palette;
      case ShopCategory.powerup:
        return Icons.bolt;
    }
  }
}
