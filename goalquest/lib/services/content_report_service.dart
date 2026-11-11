import 'api_client.dart';
import 'demo_mode.dart';

enum ReportReason {
  inaccurate('inaccurate', 'Something is wrong'),
  outOfDate('out_of_date', 'Out of date'),
  unclear('unclear', 'Hard to understand'),
  notAgeAppropriate('not_age_appropriate', 'Not suitable for young people'),
  other('other', 'Something else');

  final String id;
  final String label;
  const ReportReason(this.id, this.label);
}

/// Sends content problems (from learners or teachers) to the review queue.
class ContentReportService {
  ContentReportService._();
  static final instance = ContentReportService._();

  /// [type] is one of lesson, mission, quiz, target or impact.
  Future<void> report({
    required String type,
    required String id,
    required ReportReason reason,
    String? message,
  }) async {
    if (DemoMode.enabled) return;
    await ApiClient.instance.post('/content/reports', {
      'content_type': type,
      'content_id': id,
      'reason': reason.id,
      if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
    });
  }
}
