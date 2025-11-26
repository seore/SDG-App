import 'package:flutter/material.dart';

class ShopPacks {
  final String id;              
  final String title;
  final String description;
  final String productId;       
  final int sdgNumber;
  final IconData icon;
  final int priceCents;

  const ShopPacks({
    required this.id,            
    required this.title,
    required this.description,
    required this.productId,       
    required this.sdgNumber,
    required this.icon,
    required this.priceCents,
  });
}

const List<ShopPacks> kShopPacks = [
  ShopPacks(
    id: 'cosmetic_eco_frame',
    title: 'Eco Profile Frame',
    description: 'Unlock a glowing green SDG frame for your profile avatar.',
    productId: 'cosmetic_eco_frame', // match App Store IAP id later
    sdgNumber: 13,
    icon: Icons.eco,
    priceCents: 199,
  ),
  ShopPacks(
    id: 'dlc_trash_advanced',
    title: 'Trash Sorter: Advanced Pack',
    description: 'More trash items, new bins and bigger XP rewards in Trash Sorter.',
    productId: 'dlc_trash_advanced',
    sdgNumber: 12,
    icon: Icons.recycling,
    priceCents: 299,
  ),
  ShopPacks(
    id: 'dlc_water_city',
    title: 'Water Guardian: City Stories',
    description: 'Extra city levels with tougher water-saving choices.',
    productId: 'dlc_water_city',
    sdgNumber: 6,
    icon: Icons.water_drop_outlined,
    priceCents: 299,
  ),
];