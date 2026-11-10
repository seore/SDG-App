import 'api_client.dart';
import 'demo_mode.dart';
import 'impact_service.dart';
import 'mission_catalog.dart';
import 'profile_service.dart';

/// Reports missions and games to the server, which decides the XP.
/// In demo mode everything is computed locally instead.
class ActivityService {
  ActivityService._();
  static final ActivityService instance = ActivityService._();

  final _api = ApiClient.instance;

  Future<XpAward> completeMission(
    String missionId, {
    double? lat,
    double? lng,
    String? photoKey,
  }) async {
    final mission = MissionCatalogService.instance.byId(missionId);
    final XpAward award;
    if (DemoMode.enabled) {
      award = ProfileService.instance.awardLocally(mission?.xp ?? 0);
    } else {
      final json = await _api.post('/missions/$missionId/complete', {
        'lat': lat,
        'lng': lng,
        'photo_key': photoKey,
      });
      award = ProfileService.instance.applyServerAward(json as Map<String, dynamic>);
    }
    if (mission?.impactMetric case final metric?) {
      ImpactService.instance.addLocal(metric, mission!.impactAmount);
    }
    return award;
  }

  /// [score] and [total] are reported; the server applies the game's XP rule
  /// and daily cap. [localXp] is only used in demo mode.
  Future<XpAward> completeGame({
    required String gameId,
    required int score,
    required int total,
    required int localXp,
    int? sdgNumber,
  }) async {
    if (DemoMode.enabled) return ProfileService.instance.awardLocally(localXp);
    final json = await _api.post('/games/complete', {
      'game_id': gameId,
      'score': score,
      'total': total,
      if (sdgNumber != null) 'sdg_number': sdgNumber,
    });
    return ProfileService.instance.applyServerAward(json as Map<String, dynamic>);
  }

  /// Uploads a mission photo; returns its storage key, or null when photo
  /// storage isn't configured on the server.
  Future<String?> uploadMissionPhoto(List<int> jpegBytes) async {
    if (DemoMode.enabled) return null;
    try {
      final json = await _api.post('/uploads/mission-photo') as Map<String, dynamic>;
      await _api.putBytes(
        json['upload_url'] as String,
        jpegBytes,
        json['content_type'] as String,
      );
      return json['key'] as String;
    } on ApiException catch (e) {
      if (e.code == 'storage_disabled') return null;
      rethrow;
    }
  }
}
