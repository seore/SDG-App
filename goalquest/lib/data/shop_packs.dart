import 'package:flutter/material.dart';

class ShopPacks {
  final String id;              
  final String title;
  final String description;
  final String productId;       
  final int sdgNumber;
  final IconData icon;

  /// Rewards are earned through play: a level or a streak to reach.
  final RewardUnlock unlock;

  const ShopPacks({
    required this.id,            
    required this.title,
    required this.description,
    required this.productId,       
    required this.sdgNumber,
    required this.icon,
    required this.unlock,
  });
}

enum UnlockType { level, streak }

class RewardUnlock {
  final UnlockType type;
  final int value;
  const RewardUnlock.level(this.value) : type = UnlockType.level;
  const RewardUnlock.streak(this.value) : type = UnlockType.streak;

  String get label =>
      type == UnlockType.level ? 'Reach level $value' : 'Keep a $value-day streak';
}

const List<ShopPacks> kShopPacks = [
  ShopPacks(
    id: 'cosmetic_ocean_frame',
    title: 'Ocean Wave Frame',
    description: 'A blue water-themed frame for ocean protectors.',
    productId: 'cosmetic_ocean_frame',
    sdgNumber: 14,
    icon: Icons.water,
    unlock: RewardUnlock.level(3),
  ),
  ShopPacks(
    id: 'cosmetic_sunrise_frame',
    title: 'Sunrise Blaze Frame',
    description: 'A warm golden-orange frame inspired by the sunrise.',
    productId: 'cosmetic_sunrise_frame',
    sdgNumber: 7,
    icon: Icons.wb_sunny_outlined,
    unlock: RewardUnlock.level(5),
  ),
  ShopPacks(
    id: 'cosmetic_star_badge',
    title: 'Star Achiever Badge',
    description: 'A golden badge beside your avatar.',
    productId: 'cosmetic_star_badge',
    sdgNumber: 4,
    icon: Icons.star,
    unlock: RewardUnlock.streak(7),
  ),
  ShopPacks(
    id: 'cosmetic_heart_badge',
    title: 'Kindness Badge',
    description: 'A heart badge showing your positive energy.',
    productId: 'cosmetic_heart_badge',
    sdgNumber: 3,
    icon: Icons.favorite,
    unlock: RewardUnlock.streak(3),
  ),
  ShopPacks(
    id: 'cosmetic_lightning_frame',
    title: 'Lightning Frame',
    description: 'Electric neon frame for high achievers.',
    productId: 'cosmetic_lightning_frame',
    sdgNumber: 9,
    icon: Icons.flash_on,
    unlock: RewardUnlock.level(8),
  ),
  ShopPacks(
    id: 'cosmetic_gold_frame',
    title: 'Gold Frame',
    description: 'A luxury golden frame that stands out.',
    productId: 'cosmetic_gold_frame',
    sdgNumber: 10,
    icon: Icons.circle,
    unlock: RewardUnlock.level(12),
  ),
  ShopPacks(
    id: 'cosmetic_eco_frame',
    title: 'Eco Profile Frame',
    description: 'Unlock a glowing green SDG frame for your profile avatar.',
    productId: 'cosmetic_eco_frame', // match App Store IAP id later
    sdgNumber: 13,
    icon: Icons.eco,
    unlock: RewardUnlock.level(2),
  ),
  ShopPacks(
    id: 'dlc_trash_advanced',
    title: 'Trash Sorter: Advanced Pack',
    description: 'More trash items, new bins and bigger XP rewards in Trash Sorter.',
    productId: 'dlc_trash_advanced',
    sdgNumber: 12,
    icon: Icons.recycling,
    unlock: RewardUnlock.level(4),
  ),
  ShopPacks(
    id: 'dlc_water_city',
    title: 'Water Guardian: City Stories',
    description: 'Extra city levels with tougher water-saving choices.',
    productId: 'dlc_water_city',
    sdgNumber: 6,
    icon: Icons.water_drop_outlined,
    unlock: RewardUnlock.level(6),
  ),
];