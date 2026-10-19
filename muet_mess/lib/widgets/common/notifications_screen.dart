import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import 'layout_widgets.dart';
import 'motion.dart';
import 'skeleton.dart';

/// Shared notifications screen for both roles.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().load(context.read<AuthProvider>().user!.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NotificationProvider>();
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: notes.unread == 0
                ? null
                : () => context.read<NotificationProvider>().markAllRead(context.read<AuthProvider>().user!.id),
            child: const Text('Mark all read'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notes.loading
          ? const ListSkeleton(itemHeight: 78)
          : notes.items.isEmpty
              ? const EmptyState(
                  title: "You're all caught up",
                  message: 'Approvals, payments and updates to your entries will show up here.',
                  icon: Icons.notifications_none,
                )
              : ContentList(
                  maxWidth: 760,
                  children: [
                    for (var i = 0; i < notes.items.length; i++)
                      Builder(builder: (context) {
                        final n = notes.items[i];
                        final (IconData icon, Color color) = n.title.contains('approved')
                            ? (Icons.check_circle, tokens.success)
                            : n.title.contains('updated')
                                ? (Icons.edit, tokens.warning)
                                : n.title.contains('Payment')
                                    ? (Icons.payments, tokens.success)
                                    : (Icons.notifications, tokens.info);
                        return FadeSlideIn(
                          index: i,
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            color: n.isRead ? null : scheme.primaryContainer.withValues(alpha: 0.35),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(13)),
                                  child: Icon(icon, color: color, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(children: [
                                      Expanded(
                                        child: Text(
                                          n.title,
                                          style: text.titleSmall?.copyWith(fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800),
                                        ),
                                      ),
                                      if (!n.isRead)
                                        Container(width: 8, height: 8, decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle)),
                                    ]),
                                    const SizedBox(height: 3),
                                    Text(n.message, style: text.bodyMedium),
                                    const SizedBox(height: 4),
                                    Text(AppDateUtils.dateTime(n.createdAt), style: text.bodySmall),
                                  ]),
                                ),
                              ]),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
    );
  }
}
