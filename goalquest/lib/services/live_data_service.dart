import 'dart:async';

import 'api_client.dart';

class LiveMissionCompletion {
  final String id;

  /// True when the signed-in user completed this (the server never exposes
  /// other people's user ids).
  final bool isMine;
  final String userName;
  final String missionId;
  final String missionTitle;
  final int sdgNumber;
  final int xp;
  final DateTime createdAt;

  /// Rounded to ~1 km by the server for privacy.
  final double? lat;
  final double? lng;

  LiveMissionCompletion({
    required this.id,
    required this.isMine,
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
    return LiveMissionCompletion(
      id: map['id'].toString(),
      isMine: (map['is_mine'] as bool?) ?? false,
      userName: (map['user_name'] ?? 'Someone').toString(),
      missionId: (map['mission_id'] ?? '').toString(),
      missionTitle: (map['mission_title'] ?? '').toString(),
      sdgNumber: (map['sdg_number'] ?? 0) as int,
      xp: (map['xp'] ?? 0) as int,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
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
    return LiveStory(
      id: map['id'].toString(),
      userName: (map['user_name'] ?? 'Someone').toString(),
      message: (map['message'] ?? '').toString(),
      sdgNumber: map['sdg_number'] as int?,
      photoUrl: map['photo_url'] as String?,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }
}

/// Map, impact and community feeds. Neon has no realtime push for Dart, so
/// these poll the API while a screen is listening.
class LiveDataService {
  LiveDataService._internal();
  static final LiveDataService instance = LiveDataService._internal();

  static const pollInterval = Duration(seconds: 15);

  Stream<List<LiveMissionCompletion>> get completionsStream => _poll(
        '/feed/completions',
        (json) => ((json as Map)['completions'] as List)
            .map((r) => LiveMissionCompletion.fromMap(r as Map<String, dynamic>))
            .toList(),
      );

  Stream<List<LiveStory>> get storiesStream => _poll(
        '/feed/stories',
        (json) => ((json as Map)['stories'] as List)
            .map((r) => LiveStory.fromMap(r as Map<String, dynamic>))
            .toList(),
      );

  /// Emits immediately, then every [pollInterval] while listened to. Errors
  /// are only surfaced if no data has been delivered yet.
  Stream<T> _poll<T>(String path, T Function(dynamic json) parse) {
    late StreamController<T> controller;
    Timer? timer;
    var delivered = false;

    Future<void> tick() async {
      try {
        final data = parse(await ApiClient.instance.get(path));
        if (!controller.isClosed) controller.add(data);
        delivered = true;
      } catch (e) {
        if (!delivered && !controller.isClosed) controller.addError(e);
      }
    }

    controller = StreamController<T>(
      onListen: () {
        tick();
        timer = Timer.periodic(pollInterval, (_) => tick());
      },
      onCancel: () => timer?.cancel(),
    );
    return controller.stream;
  }
}
