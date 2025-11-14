import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class LiveMissionCompletion {
  final String userName;
  final String missionTitle;
  final int sdgNumber;
  final DateTime timestamp;
  final double? lat;
  final double? lng;

  LiveMissionCompletion({
    required this.userName,
    required this.missionTitle,
    required this.sdgNumber,
    required this.timestamp,
    this.lat,
    this.lng,
  });
}

class CommunityStory {
  final String userName;
  final String message;
  final int? sdgNumber;
  final DateTime createdAt;

  CommunityStory({
    required this.userName,
    required this.message,
    this.sdgNumber,
    required this.createdAt,
  });
}

class LiveDataService {
  static final LiveDataService instance = LiveDataService._internal();
  LiveDataService._internal() {
    _listenToCompletions();
    _listenToStories();
  }

  final _supabase = Supabase.instance.client;

  final _completionsController =
      StreamController<List<LiveMissionCompletion>>.broadcast();
  final _storiesController =
      StreamController<List<CommunityStory>>.broadcast();

  final List<LiveMissionCompletion> _completions = [];
  final List<CommunityStory> _stories = [];

  Stream<List<LiveMissionCompletion>> get completionsStream =>
      _completionsController.stream;

  Stream<List<CommunityStory>> get storiesStream =>
      _storiesController.stream;

  // Called when user completes a mission
  Future<void> addCompletion({
    required String userName,
    required String missionTitle,
    required int sdgNumber,
    required int xp,
    double? lat,
    double? lng,
  }) async {
    await _supabase.from('mission_completions').insert({
      'user_id': null, // later: real auth user id
      'mission_id': null, // optional for now
      'sdg_number': sdgNumber,
      'xp': xp,
      'lat': lat,
      'lng': lng,
      'city': null,
      'country': null,
    });

    // Local optimistic update (shows instantly)
    final completion = LiveMissionCompletion(
      userName: userName,
      missionTitle: missionTitle,
      sdgNumber: sdgNumber,
      timestamp: DateTime.now(),
      lat: lat,
      lng: lng,
    );
    _completions.insert(0, completion);
    _completionsController.add(List.unmodifiable(_completions));
  }

  Future<void> addStory({
    required String userName,
    required String message,
    int? sdgNumber,
  }) async {
    await _supabase.from('stories').insert({
      'user_name': userName,
      'message': message,
      'sdg_number': sdgNumber,
    });

    final story = CommunityStory(
      userName: userName,
      message: message,
      sdgNumber: sdgNumber,
      createdAt: DateTime.now(),
    );
    _stories.insert(0, story);
    _storiesController.add(List.unmodifiable(_stories));
  }

  void _listenToCompletions() {
    _supabase
        .channel('public:mission_completions')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mission_completions',
          callback: (payload) async {
            final record = payload.newRecord;
            final sdg = record['sdg_number'] as int;
            final xp = record['xp'] as int;
            // We don’t have mission title here, so we just show generic text
            final completion = LiveMissionCompletion(
              userName: 'Someone',
              missionTitle: 'Completed a mission (+$xp XP)',
              sdgNumber: sdg,
              timestamp: DateTime.parse(record['created_at'] as String),
              lat: (record['lat'] as num?)?.toDouble(),
              lng: (record['lng'] as num?)?.toDouble(),
            );
            _completions.insert(0, completion);
            _completionsController.add(List.unmodifiable(_completions));
          },
        )
        .subscribe();
  }

  void _listenToStories() {
    _supabase
        .channel('public:stories')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'stories',
          callback: (payload) {
            final record = payload.newRecord;
            final story = CommunityStory(
              userName: (record['user_name'] as String?) ?? 'Someone',
              message: record['message'] as String,
              sdgNumber: record['sdg_number'] as int?,
              createdAt: DateTime.parse(record['created_at'] as String),
            );
            _stories.insert(0, story);
            _storiesController.add(List.unmodifiable(_stories));
          },
        )
        .subscribe();
  }
}
