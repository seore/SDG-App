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

  factory LiveMissionCompletion.fromMap(Map<String, dynamic> map) {
    final createdRaw = map['created_at'];

    DateTime createdAt;
    if (createdRaw is String) {
      createdAt = DateTime.parse(createdRaw);
    } else if (createdRaw is DateTime) {
      createdAt = createdRaw;
    } else {
      createdAt = DateTime.now();
    }

    return LiveMissionCompletion(
      id: map['id'].toString(),
      userName: (map['user_name'] ?? 'Someone').toString(),
      missionId: (map['mission_id'] ?? '').toString(),
      missionTitle: (map['mission_title'] ?? '').toString(),
      sdgNumber: (map['sdg_number'] ?? 0) as int,
      xp: (map['xp'] ?? 0) as int,
      lat: map['lat'] != null ? (map['lat'] as num).toDouble() : null,
      lng: map['lng'] != null ? (map['lng'] as num).toDouble() : null,
      createdAt: createdAt,
    );
  }
}

class LiveStory {
  final String id;
  final String userName;
  final String message;
  final int? sdgNumber;
  final String? photoUrl;
  final DateTime createdAt;

  LiveStory({
    required this.id,
    required this.userName,
    required this.message,
    this.sdgNumber,
    this.photoUrl,
    required this.createdAt,
  });

  factory LiveStory.fromMap(Map<String, dynamic> map) {
    final createdRaw = map['created_at'];

    DateTime createdAt;
    if (createdRaw is String) {
      createdAt = DateTime.parse(createdRaw);
    } else if (createdRaw is DateTime) {
      createdAt = createdRaw;
    } else {
      createdAt = DateTime.now();
    }

    return LiveStory(
      id: map['id'].toString(),
      userName: (map['user_name'] ?? 'Someone').toString(),
      message: (map['message'] ?? '').toString(),
      sdgNumber: map['sdg_number'] as int?,
      photoUrl: map['photo_url'] as String?,
      createdAt: createdAt,
    );
  }
}

class LiveDataService {
  LiveDataService._internal();
  static final LiveDataService instance = LiveDataService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<List<LiveMissionCompletion>> get completionsStream {
    return _supabase
        .from('mission_completions')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map(
          (rows) => rows
              .map((row) =>
                  LiveMissionCompletion.fromMap(row as Map<String, dynamic>))
              .toList(),
        );
  }

  Stream<List<LiveStory>> get storiesStream {
    return _supabase
        .from('stories')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map(
          (rows) =>
              rows.map((row) => LiveStory.fromMap(row as Map<String, dynamic>))
                  .toList(),
        );
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
      throw Exception('You must be logged in to complete missions.');
    }

    await _supabase.from('mission_completions').insert({
      'user_id': user.id, 
      'user_name': userName,
      'mission_id': missionId,
      'mission_title': missionTitle,
      'sdg_number': sdgNumber,
      'xp': xp,
      'lat': lat,
      'lng': lng,
    });
  }

  Future<void> addStory({
    required String userName,
    required String message,
    int? sdgNumber,
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
