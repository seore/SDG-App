// Exports all learning content to build/content_review.csv for teacher review.
// Run from goalquest/:  flutter test tool/export_content.dart
// (It runs under the test runner because the content uses Flutter types.)
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goalquest/data/quiz_questions.dart';
import 'package:goalquest/data/sdg_data.dart';

String _csv(Object? v) {
  final s = (v ?? '').toString();
  return '"${s.replaceAll('"', '""')}"';
}

void main() {
  test('export content for review', () {
    final missions = (jsonDecode(File('assets/content/missions.json').readAsStringSync())['missions'] as List)
        .cast<Map<String, dynamic>>();
    final rows = <List<Object?>>[
      ['type', 'id', 'sdg', 'title', 'text', 'answer / estimate', 'basis', 'reviewer', 'status', 'notes'],
      for (final g in sdgGoals)
        [
          'lesson', g.number, g.number, g.shortTitle,
          [g.everydayExplanation, g.example, g.actions].whereType<String>().join('\n\n'),
          '', '', '', '', '',
        ],
      for (final m in missions)
        [
          'mission', m['id'], m['sdgNumber'], m['title'], m['description'],
          m['impact'] == null ? '' : '${m['impact']['amount']} ${m['impact']['metric']}',
          m['impact']?['basis'] ?? '', '', '', '',
        ],
      for (final (i, q) in sdgQuizQuestions.indexed)
        [
          'quiz', 'q${i + 1}', q.sdgNumber, q.question,
          [for (final (j, o) in q.options.indexed) '${String.fromCharCode(65 + j)}) $o'].join('\n'),
          q.options[q.correctIndex], '', '', '', '',
        ],
    ];
    final out = File('build/content_review.csv')..createSync(recursive: true);
    // BOM so Excel opens UTF-8 (≈, CO₂) correctly.
    out.writeAsStringSync('﻿${rows.map((r) => r.map(_csv).join(',')).join('\r\n')}\r\n');
    // ignore: avoid_print
    print('Wrote ${rows.length - 1} items to ${out.path}');
  });
}
