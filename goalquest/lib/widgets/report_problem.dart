import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/content_report_service.dart';
import '../theme/app_theme.dart';

/// A small "Report a problem" link that opens [showReportProblemSheet].
class ReportProblemButton extends StatelessWidget {
  final String type;
  final String id;
  final String subject;

  const ReportProblemButton({super.key, required this.type, required this.id, required this.subject});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () => showReportProblemSheet(context, type: type, id: id, subject: subject),
        icon: Icon(Icons.flag_outlined, size: 16, color: AppColors.textSecondary),
        label: Text('Report a problem', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ),
    );
  }
}

Future<void> showReportProblemSheet(
  BuildContext context, {
  required String type,
  required String id,
  required String subject,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ReportSheet(type: type, id: id, subject: subject),
  );
}

class _ReportSheet extends StatefulWidget {
  final String type;
  final String id;
  final String subject;
  const _ReportSheet({required this.type, required this.id, required this.subject});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  ReportReason? _reason;
  final _message = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final reason = _reason;
    if (reason == null) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ContentReportService.instance.report(
        type: widget.type,
        id: widget.id,
        reason: reason,
        message: _message.text,
      );
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Thanks! Our content team will take a look.')));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not send. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Report a problem', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(widget.subject, style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              RadioGroup<ReportReason>(
                groupValue: _reason,
                onChanged: (v) => setState(() => _reason = v),
                child: Column(
                  children: [
                    for (final r in ReportReason.values)
                      RadioListTile<ReportReason>(
                        value: r,
                        title: Text(r.label),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _message,
                maxLength: 1000,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'What should it say? (optional)',
                  helperText: "Teachers: tell us the correct fact or a source if you have one.",
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: _reason == null || _sending ? null : _send,
                child: Text(_sending ? 'Sending…' : 'Send report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
