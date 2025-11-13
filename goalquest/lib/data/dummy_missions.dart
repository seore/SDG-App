import '../models/mission.dart';

final List<Mission> dummyMissions = [
  Mission(
    id: 'm1',
    title: 'Unplug devices for 1 hour',
    description:
        'Save electricity by unplugging devices that are not in use for at least one hour today.',
    sdg: 'SDG 7: Affordable & Clean Energy',
    xp: 20,
  ),
  Mission(
    id: 'm2',
    title: 'Keep a reusable bottle with you',
    description:
        'Avoid using plastic bottles today. Carry a reusable one instead.',
    sdg: 'SDG 12: Responsible Consumption',
    xp: 25,
  ),
  Mission(
    id: 'm3',
    title: 'Share a positive message about equality',
    description:
        'Post or tell someone about the importance of gender equality.',
    sdg: 'SDG 5: Gender Equality',
    xp: 15,
  ),
  Mission(
    id: 'm4',
    title: 'Recycle 3 items today',
    description:
        'Find 3 recyclable items in your home and prepare them for recycling.',
    sdg: 'SDG 13: Climate Action',
    xp: 20,
  ),
  Mission(
    id: 'm5',
    title: 'Drink only clean, safe water today',
    description:
        'Track your water intake and make sure to use clean drinking water.',
    sdg: 'SDG 6: Clean Water & Sanitation',
    xp: 10,
  ),
];
