import 'package:flutter/material.dart';

import '../data/sdg_data.dart';
import '../services/live_data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/motion.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Community',
      body: StreamBuilder<List<LiveStory>>(
        stream: LiveDataService.instance.storiesStream,
        builder: (context, snapshot) {
          final Widget content;

          if (snapshot.hasError) {
            content = const _StateView(
              icon: Icons.cloud_off_rounded,
              title: "Couldn't load stories",
              message: 'Check your connection and try again.',
            );
          } else if (!snapshot.hasData) {
            content = const _LoadingList();
          } else if (snapshot.data!.isEmpty) {
            content = const _StateView(
              icon: Icons.forum_outlined,
              title: 'No stories yet',
              message:
                  'Complete a mission to share your first story with the community.',
            );
          } else {
            // Newest first.
            final stories = [...snapshot.data!]
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            content = ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              itemCount: stories.length,
              itemBuilder: (context, i) => ContentWidth(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: FadeSlideIn(
                    delay: Duration(milliseconds: (i < 6 ? i : 6) * 50),
                    child: _StoryCard(story: stories[i]),
                  ),
                ),
              ),
            );
          }

          return AnimatedSwitcher(
            duration: AppDurations.medium,
            child: KeyedSubtree(
              key: ValueKey(content.runtimeType),
              child: content,
            ),
          );
        },
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final LiveStory story;
  const _StoryCard({required this.story});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sdg =
        story.sdgNumber != null ? getSdgByNumber(story.sdgNumber!) : null;
    final hasPhoto = story.photoUrl != null && story.photoUrl!.isNotEmpty;
    final name = story.userName.trim().isEmpty ? 'Someone' : story.userName;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primarySoft,
                  child: Text(
                    name[0].toUpperCase(),
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _timeAgo(story.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (story.verified) ...[
                  Tooltip(
                    message: 'Photo checked and verified',
                    child: Icon(Icons.verified_rounded, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 6),
                ],
                if (sdg != null)
                  PillChip(label: 'SDG ${sdg.number}', color: sdg.color),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Text(
              story.message,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
          if (hasPhoto)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.network(
                    story.photoUrl!,
                    semanticLabel: 'Photo shared by ${story.userName}',
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                            ? child
                            : Container(color: AppColors.surfaceMuted),
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surfaceMuted,
                      alignment: Alignment.center,
                      child: Icon(Icons.broken_image_outlined,
                          color: AppColors.textTertiary),
                    ),
                  ),
                ),
              ),
            ),
          if (sdg != null) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: sdg.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      sdg.shortTitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Placeholder cards shown while stories load.
class _LoadingList extends StatefulWidget {
  const _LoadingList();

  @override
  State<_LoadingList> createState() => _LoadingListState();
}

class _LoadingListState extends State<_LoadingList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(6),
          ),
        );

    return FadeTransition(
      opacity: Tween(begin: 0.5, end: 1.0).animate(_shimmer),
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          for (var i = 0; i < 3; i++)
            ContentWidth(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.surfaceMuted,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              bar(110, 12),
                              const SizedBox(height: 6),
                              bar(60, 10),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      bar(double.infinity, 12),
                      const SizedBox(height: 8),
                      bar(200, 12),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _StateView({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTile(icon: icon, color: AppColors.textSecondary, size: 56),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

String _timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
