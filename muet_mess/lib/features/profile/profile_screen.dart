import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/route_names.dart';
import '../../core/theme/app_tokens.dart';
import '../../models/student_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/layout_widgets.dart';
import '../../widgets/common/motion.dart';
import '../../widgets/common/user_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = auth.user;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final tokens = context.tokens;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : ContentList(
              maxWidth: 640,
              children: [
                FadeSlideIn(
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: tokens.heroGradient),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: tokens.onHero.withValues(alpha: 0.5), width: 2)),
                        child: UserAvatar(name: user.name, radius: 34),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(user.name, style: text.titleLarge?.copyWith(color: tokens.onHero)),
                          const SizedBox(height: 2),
                          Text('@${user.username}', style: text.bodyMedium?.copyWith(color: tokens.onHero.withValues(alpha: 0.8))),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: tokens.onHero.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(99)),
                            child: Text(
                              user.role.name[0].toUpperCase() + user.role.name.substring(1),
                              style: text.labelMedium?.copyWith(color: tokens.onHero),
                            ),
                          ),
                        ]),
                      ),
                    ]),
                  ),
                ),
                if (user is Student) ...[
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    index: 1,
                    child: Card(
                      child: Column(children: [
                        ListTile(
                          leading: const Icon(Icons.badge_outlined),
                          title: const Text('Roll number'),
                          trailing: Text(user.rollNumber, style: text.titleSmall),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.meeting_room_outlined),
                          title: const Text('Room'),
                          trailing: Text(user.roomNumber ?? '-', style: text.titleSmall),
                        ),
                      ]),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                FadeSlideIn(
                  index: 2,
                  child: Card(
                    child: SwitchListTile(
                      secondary: Icon(themeProvider.mode == ThemeMode.dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
                      title: const Text('Dark mode'),
                      subtitle: const Text('Easier on the eyes at night'),
                      value: themeProvider.mode == ThemeMode.dark,
                      onChanged: (_) => themeProvider.toggle(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                FadeSlideIn(
                  index: 3,
                  child: Card(
                    child: ListTile(
                      leading: Icon(Icons.logout, color: scheme.error),
                      title: Text('Log out', style: TextStyle(color: scheme.error, fontWeight: FontWeight.w700)),
                      onTap: () async {
                        final ok = await confirmDialog(
                          context,
                          title: 'Log out?',
                          message: 'You will need to sign in again to see your ledger.',
                          confirmLabel: 'Log out',
                          destructive: true,
                        );
                        if (!ok) return;
                        await auth.logout();
                        if (context.mounted) context.go(RouteNames.login);
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
