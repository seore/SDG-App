import 'package:flutter/material.dart';

import '../services/stats_service.dart';

/// An achievement earned by reaching [target] on one of the user's stats.
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int target;
  final String unit;
  final int Function(UserStats s) metric;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.target,
    required this.unit,
    required this.metric,
  });

  int current(UserStats s) => metric(s);
  bool earned(UserStats s) => metric(s) >= target;
  double progress(UserStats s) => (metric(s) / target).clamp(0.0, 1.0);
}

const _teal = Color(0xFF0F766E);
const _amber = Color(0xFFB45309);
const _red = Color(0xFFDC2626);
const _violet = Color(0xFF7C3AED);
const _blue = Color(0xFF0369A1);
const _green = Color(0xFF15803D);
const _pink = Color(0xFFBE185D);

int _xp(UserStats s) => s.xp;
int _bestStreak(UserStats s) => s.bestStreak;
int _missions(UserStats s) => s.missions;
int _missionGoals(UserStats s) => s.missionGoals;
int _lessons(UserStats s) => s.lessonsRead;
int _quizRounds(UserStats s) => s.quizRounds;
int _perfect(UserStats s) => s.perfectQuizzes;
int _games(UserStats s) => s.distinctGames;
int _stories(UserStats s) => s.stories;
int _photos(UserStats s) => s.verifiedPhotos;
int _teams(UserStats s) => s.teams;
int _mastered(UserStats s) => s.goalsMastered;
int _stars(UserStats s) => s.stars;
int _challenges(UserStats s) => s.challengesCompleted;

/// All achievements, roughly in the order people earn them.
const List<Achievement> achievements = [
  Achievement(id: 'first_steps', title: 'First steps', description: 'Earn your first XP.',
      icon: Icons.flag_rounded, color: _teal, target: 1, unit: 'XP', metric: _xp),
  Achievement(id: 'first_mission', title: 'First mission', description: 'Complete a mission.',
      icon: Icons.task_alt_rounded, color: _teal, target: 1, unit: 'missions', metric: _missions),
  Achievement(id: 'first_lesson', title: 'Curious mind', description: 'Read a goal lesson.',
      icon: Icons.menu_book_rounded, color: _blue, target: 1, unit: 'lessons', metric: _lessons),
  Achievement(id: 'streak_3', title: '3-day streak', description: 'Be active three days in a row.',
      icon: Icons.local_fire_department_rounded, color: _amber, target: 3, unit: 'days', metric: _bestStreak),
  Achievement(id: 'perfect_quiz', title: 'Perfect score', description: 'Answer every question in a quiz round correctly.',
      icon: Icons.verified_rounded, color: _violet, target: 1, unit: 'perfect rounds', metric: _perfect),
  Achievement(id: 'team_player', title: 'Team player', description: 'Join or create a team.',
      icon: Icons.groups_rounded, color: _blue, target: 1, unit: 'teams', metric: _teams),
  Achievement(id: 'storyteller', title: 'Storyteller', description: 'Share a story with the community.',
      icon: Icons.campaign_rounded, color: _pink, target: 1, unit: 'stories', metric: _stories),
  Achievement(id: 'streak_7', title: '7-day streak', description: 'Be active a whole week in a row.',
      icon: Icons.whatshot_rounded, color: _red, target: 7, unit: 'days', metric: _bestStreak),
  Achievement(id: 'missions_10', title: 'Regular', description: 'Complete 10 missions.',
      icon: Icons.checklist_rounded, color: _teal, target: 10, unit: 'missions', metric: _missions),
  Achievement(id: 'explorer', title: 'Explorer', description: 'Complete missions for 5 different goals.',
      icon: Icons.explore_rounded, color: _green, target: 5, unit: 'goals', metric: _missionGoals),
  Achievement(id: 'game_explorer', title: 'Game explorer', description: 'Play all 5 games.',
      icon: Icons.sports_esports_rounded, color: _violet, target: 5, unit: 'games', metric: _games),
  Achievement(id: 'quiz_10', title: 'Quiz regular', description: 'Play 10 quiz rounds.',
      icon: Icons.quiz_rounded, color: _violet, target: 10, unit: 'rounds', metric: _quizRounds),
  Achievement(id: 'verified_3', title: 'Seen it, done it', description: 'Get 3 mission photos verified.',
      icon: Icons.photo_camera_rounded, color: _pink, target: 3, unit: 'photos', metric: _photos),
  Achievement(id: 'xp_500', title: '500 XP', description: 'Earn 500 XP in total.',
      icon: Icons.star_rounded, color: _amber, target: 500, unit: 'XP', metric: _xp),
  Achievement(id: 'mastered_1', title: 'Goal master', description: 'Earn all three stars on one goal.',
      icon: Icons.workspace_premium_rounded, color: _amber, target: 1, unit: 'goals', metric: _mastered),
  Achievement(id: 'challenge_1', title: 'Month champion', description: 'Complete a monthly challenge.',
      icon: Icons.emoji_events_rounded, color: _amber, target: 1, unit: 'challenges', metric: _challenges),
  Achievement(id: 'scholar', title: 'Scholar', description: 'Read all 17 goal lessons.',
      icon: Icons.school_rounded, color: _blue, target: 17, unit: 'lessons', metric: _lessons),
  Achievement(id: 'missions_50', title: 'Changemaker', description: 'Complete 50 missions.',
      icon: Icons.volunteer_activism_rounded, color: _green, target: 50, unit: 'missions', metric: _missions),
  Achievement(id: 'xp_1000', title: '1,000 XP', description: 'Earn 1,000 XP in total.',
      icon: Icons.military_tech_rounded, color: _blue, target: 1000, unit: 'XP', metric: _xp),
  Achievement(id: 'streak_30', title: '30-day streak', description: 'Be active 30 days in a row.',
      icon: Icons.bolt_rounded, color: _violet, target: 30, unit: 'days', metric: _bestStreak),
  Achievement(id: 'all_rounder', title: 'All-rounder', description: 'Complete missions for all 17 goals.',
      icon: Icons.public_rounded, color: _green, target: 17, unit: 'goals', metric: _missionGoals),
  Achievement(id: 'stars_51', title: 'Global citizen', description: 'Earn all 51 goal stars.',
      icon: Icons.auto_awesome_rounded, color: _amber, target: 51, unit: 'stars', metric: _stars),
];
