import 'package:flutter/material.dart';
import '../data/sdg_data.dart';

int? extractSdgNumber(String sdgLabel) {
  final match = RegExp(r'SDG\s+(\d+)').firstMatch(sdgLabel);
  if (match != null) {
    return int.tryParse(match.group(1)!);
  }
  return null;
}

IconData iconForSdg(int sdgNumber) {
  switch (sdgNumber) {
    case 1:
      return Icons.volunteer_activism;
    case 2:
      return Icons.restaurant;
    case 3:
      return Icons.favorite;
    case 4:
      return Icons.school;
    case 5:
      return Icons.wc;
    case 6:
      return Icons.water_drop;
    case 7:
      return Icons.bolt;
    case 8:
      return Icons.work;
    case 9:
      return Icons.engineering;
    case 10:
      return Icons.group;
    case 11:
      return Icons.location_city;
    case 12:
      return Icons.recycling;
    case 13:
      return Icons.cloud;
    case 14:
      return Icons.waves;
    case 15:
      return Icons.park;
    case 16:
      return Icons.balance;
    case 17:
      return Icons.handshake;
    default:
      return Icons.public;
  }
}
