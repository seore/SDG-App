import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class LiveMissionCompletion {
  final String id;
  final String userName;
  final String missionId;
  final String missionTitle;
  final int sdgNumber;
  final int xp;
  final DateTime createdAt;
  final double? lat;
  final double? lng;

  LiveMissionCompletion({
    required this.id,
    required this.userName,
    required this.missionId,
    required this.missionTitle,
    required this.sdgNumber,
    required this.xp,
    required this.createdAt,
    this.lat,
    this.lng,
  });
}

class CommunityStory {
  final String id;
  final String userName;
  final String message;
  final int? sdgNumber;
  final DateTime createdAt;
  final String? photoUrl;

  CommunityStory({
    required this.id,
    required this.userName,
    required this.message,
    this.sdgNumber,
    required this.createdAt,
    this.photoUrl,
  });
}

class LiveDataService {
  LiveDataService._internal();
  static final LiveDataService instance = LiveDataService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  final _completionsController =
      StreamController<List<LiveMissionCompletion>>.broadcast();
  final _storiesController =
      StreamController<List<CommunityStory>>.broadcast();

  List<LiveMissionCompletion> _completions = [];
  List<CommunityStory> _stories = [];

  Stream<List<LiveMissionCompletion>> get completionsStream =>
      _completionsController.stream;
  Stream<List<CommunityStory>> get storiesStream =>
      _storiesController.stream;

  Future<void> init() async {
    await _loadInitialData();
    _listenToCompletions();
    _listenToStories();
  }

  Future<void> _loadInitialData() async {
    final completionsData = await _supabase
        .from('mission_completions')
        .select()
        .order('created_at', ascending: false)
        .limit(100);

    _completions = (completionsData as List)
        .map((row) => LiveMissionCompletion(
              id: row['id'].toString(),
              userName: row['user_name'] as String? ?? 'Someone',
              missionId: row['mission_id'] as String? ?? '',
              missionTitle: row['mission_title'] as String,
              sdgNumber: row['sdg_number'] as int? ?? 0,
              xp: row['xp'] as int? ?? 0,
              createdAt: DateTime.parse(row['created_at'] as String),
              lat: (row['lat'] as num?)?.toDouble(),
              lng: (row['lng'] as num?)?.toDouble(),
            ))
        .toList();

    final storiesData = await _supabase
        .from('stories')
        .select()
        .order('created_at', ascending: false)
        .limit(100);

    _stories = (storiesData as List)
        .map((row) => CommunityStory(
              id: row['id'].toString(),
              userName: row['user_name'] as String? ?? 'Someone',
              message: row['message'] as String,
              sdgNumber: row['sdg_number'] as int?,
              createdAt: DateTime.parse(row['created_at'] as String),
              photoUrl: row['photo_url'] as String?,
            ))
        .toList();

    _completionsController.add(List.unmodifiable(_completions));
    _storiesController.add(List.unmodifiable(_stories));
  }

  void _listenToCompletions() {
    _supabase
        .channel('public:mission_completions')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mission_completions',
          callback: (payload) {
            final row = payload.newRecord;
            final completion = LiveMissionCompletion(
              id: row['id'].toString(),
              userName: row['user_name'] as String? ?? 'Someone',
              missionId: row['mission_id'] as String? ?? '',
              missionTitle: row['mission_title'] as String,
              sdgNumber: row['sdg_number'] as int? ?? 0,
              xp: row['xp'] as int? ?? 0,
              createdAt: DateTime.parse(row['created_at'] as String),
              lat: (row['lat'] as num?)?.toDouble(),
              lng: (row['lng'] as num?)?.toDouble(),
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
            final row = payload.newRecord;
            final story = CommunityStory(
              id: row['id'].toString(),
              userName: row['user_name'] as String? ?? 'Someone',
              message: row['message'] as String,
              sdgNumber: row['sdg_number'] as int?,
              createdAt: DateTime.parse(row['created_at'] as String),
              photoUrl: row['photo_url'] as String?,
            );
            _stories.insert(0, story);
            _storiesController.add(List.unmodifiable(_stories));
          },
        )
        .subscribe();
  }

  Future<void> addCompletion({
    required String userName,
    required String missionId,
    required String missionTitle,
    required int sdgNumber,
    required int xp,
    double? lat,
    double? lng,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      // No logged-in user = RLS will always fail.
      throw Exception('You must be logged in to complete missions.');
    }

    await _supabase.from('mission_completions').insert({
      'user_id': user.id,          // ✅ MUST be set for RLS policy
      'user_name': userName,
      'mission_id': missionId,
      'mission_title': missionTitle,
      'sdg_number': sdgNumber,
      'xp': xp,
      'lat': lat,
      'lng': lng,
    });
  }

  /// 🔹 Add a community story (photo + short message)
  Future<void> addStory({
    required String userName,
    required String message,
    required int sdgNumber,
    String? photoUrl,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('You must be logged in to post stories.');
    }

    await _supabase.from('stories').insert({
      'user_id': user.id,
      'user_name': userName,
      'message': message,
      'sdg_number': sdgNumber,
      'photo_url': photoUrl,
    });
  }
}
