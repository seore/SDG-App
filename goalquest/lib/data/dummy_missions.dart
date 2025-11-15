import '../models/mission.dart';

final List<Mission> dummyMissions = [
   Mission(
    id: 'm_unplug',
    title: 'Unplug for 1 Hour',
    description:
        'Turn off and unplug non-essential devices for one hour today.',
    sdg: 'SDG 7: Affordable & Clean Energy',
    xp: 20,
  ),
  Mission(
    id: 'm_lights_off_evening',
    title: 'Lights Off Evening',
    description:
        'Use lights only in rooms you are inside for an entire evening.',
    sdg: 'SDG 7: Affordable & Clean Energy',
    xp: 20,
  ),
  Mission(
    id: 'm_walk_instead',
    title: 'Walk or Cycle Instead',
    description:
        'Replace one short car ride with walking, cycling, or public transport today.',
    sdg: 'SDG 13: Climate Action',
    xp: 30,
  ),
  Mission(
    id: 'm_fan_not_ac',
    title: 'Choose a Fan Over AC',
    description:
        'Use a fan or natural ventilation instead of air conditioning for at least two hours.',
    sdg: 'SDG 13: Climate Action',
    xp: 25,
  ),

  Mission(
    id: 'm_reusable_bottle',
    title: 'Use a Reusable Bottle',
    description:
        'Avoid all single-use plastic bottles today by using a reusable bottle.',
    sdg: 'SDG 12: Responsible Consumption & Production',
    xp: 20,
  ),
  Mission(
    id: 'm_trash_sorter',
    title: 'Sort 5 Waste Items',
    description:
        'Find 5 items and sort them correctly into recycling, compost, or trash.',
    sdg: 'SDG 12: Responsible Consumption & Production',
    xp: 25,
  ),
  Mission(
    id: 'm_no_impulse_buy',
    title: 'No Impulse Buys',
    description:
        'Avoid unnecessary online or in-store purchases for the entire day.',
    sdg: 'SDG 12: Responsible Consumption & Production',
    xp: 20,
  ),
  Mission(
    id: 'm_fix_item',
    title: 'Fix or Repurpose an Item',
    description:
        'Repair or creatively reuse something you were planning to throw away.',
    sdg: 'SDG 12: Responsible Consumption & Production',
    xp: 30,
  ),
  Mission(
    id: 'm_meat_free_meal',
    title: 'Eat a Plant-Based Meal',
    description:
        'Have at least one fully plant-based meal today.',
    sdg: 'SDG 12: Responsible Consumption & Production',
    xp: 25,
  ),

  Mission(
    id: 'm_short_shower',
    title: 'Shorter Shower Challenge',
    description:
        'Reduce your shower time by at least 3 minutes to save water.',
    sdg: 'SDG 6: Clean Water & Sanitation',
    xp: 20,
  ),
  Mission(
    id: 'm_turn_off_tap',
    title: 'Turn Off the Tap',
    description:
        'Brush your teeth while keeping the tap off except when rinsing.',
    sdg: 'SDG 6: Clean Water & Sanitation',
    xp: 15,
  ),
  Mission(
    id: 'm_check_leaks',
    title: 'Check for Leaks',
    description:
        'Inspect your home for dripping taps or leaks and report them if found.',
    sdg: 'SDG 6: Clean Water & Sanitation',
    xp: 25,
  ),

  Mission(
    id: 'm_screen_break',
    title: 'Screen Break Day',
    description:
        'Take three 10-minute breaks away from screens today.',
    sdg: 'SDG 3: Good Health & Well-being',
    xp: 15,
  ),
  Mission(
    id: 'm_move_20min',
    title: 'Move for 20 Minutes',
    description:
        'Do at least 20 minutes of physical activity—walking, stretching, dancing, anything!',
    sdg: 'SDG 3: Good Health & Well-being',
    xp: 20,
  ),
  Mission(
    id: 'm_check_in',
    title: 'Check In on Someone',
    description:
        'Reach out to someone and ask how they are really doing today.',
    sdg: 'SDG 3: Good Health & Well-being',
    xp: 20,
  ),

  Mission(
    id: 'm_teach_one_thing',
    title: 'Teach One SDG',
    description:
        'Explain one Sustainable Development Goal to a friend or family member.',
    sdg: 'SDG 4: Quality Education',
    xp: 25,
  ),
  Mission(
    id: 'm_focus_study',
    title: '25-Min Focus Session',
    description:
        'Spend 25 distraction-free minutes learning something new.',
    sdg: 'SDG 4: Quality Education',
    xp: 20,
  ),
  Mission(
    id: 'm_equality_post',
    title: 'Equality Shoutout',
    description:
        'Share a positive message about equality or inclusion.',
    sdg: 'SDG 5: Gender Equality',
    xp: 20,
  ),
  Mission(
    id: 'm_include_someone',
    title: 'Include Someone New',
    description:
        'Invite someone who is often left out to join a game, call, or activity.',
    sdg: 'SDG 10: Reduced Inequalities',
    xp: 15,
  ),

  Mission(
    id: 'm_cleanup',
    title: 'Pick Up 5 Pieces of Litter',
    description:
        'Pick up at least 5 pieces of litter in a safe public space.',
    sdg: 'SDG 11: Sustainable Cities & Communities',
    xp: 30,
  ),
  Mission(
    id: 'm_positive_comment',
    title: 'Positive Comments Only',
    description:
        'Only leave positive, kind, or constructive comments online today.',
    sdg: 'SDG 16: Peace, Justice & Strong Institutions',
    xp: 20,
  ),
  Mission(
    id: 'm_gratitude_note',
    title: 'Send a Gratitude Note',
    description:
        'Thank a teacher, driver, cleaner, or community worker today.',
    sdg: 'SDG 11: Sustainable Cities & Communities',
    xp: 25,
  ),

  Mission(
    id: 'm_nature_walk',
    title: 'Go on a Nature Walk',
    description:
        'Spend at least 15 minutes outside observing nature. Note or photo what you see.',
    sdg: 'SDG 15: Life on Land',
    xp: 20,
  ),
  Mission(
    id: 'm_no_litter_water',
    title: 'Protect Local Water',
    description:
        'Ensure you leave no waste near water areas. Pick up safe litter if possible.',
    sdg: 'SDG 14: Life Below Water',
    xp: 25,
  ),
  Mission(
    id: 'm_plant_something',
    title: 'Plant Something',
    description:
        'Plant a seed, plant, or help care for one—even indoors.',
    sdg: 'SDG 15: Life on Land',
    xp: 30,
  ),

  Mission(
    id: 'm_join_challenge',
    title: 'Do a Mission With Someone',
    description:
        'Invite a friend or family member to complete a mission with you.',
    sdg: 'SDG 17: Partnerships for the Goals',
    xp: 20,
  ),
  Mission(
    id: 'm_share_mission',
    title: 'Share Your Action',
    description:
        'Share or write about one action you took today and why it matters.',
    sdg: 'SDG 17: Partnerships for the Goals',
    xp: 20,
  ),
];
