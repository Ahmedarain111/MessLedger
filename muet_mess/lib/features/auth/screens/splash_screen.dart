import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../widgets/common/brand_widgets.dart';
import '../../../widgets/common/motion.dart';

/// Splash / landing screen shown before login.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final onHero = context.tokens.onHero;
    return Scaffold(
      body: BrandBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const FadeSlideIn(child: Center(child: BrandLogo(size: 96))),
                  const SizedBox(height: 28),
                  FadeSlideIn(
                    index: 1,
                    child: Text(
                      'Hostel Mess Khata',
                      textAlign: TextAlign.center,
                      style: text.headlineMedium?.copyWith(color: onHero),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeSlideIn(
                    index: 2,
                    child: Text(
                      'Eat now, settle later — a transparent mess ledger for every student and manager.',
                      textAlign: TextAlign.center,
                      style: text.bodyLarge?.copyWith(color: onHero.withValues(alpha: 0.82)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FadeSlideIn(
                    index: 3,
                    child: Text(
                      'Mehran UET, Jamshoro',
                      textAlign: TextAlign.center,
                      style: text.labelMedium?.copyWith(color: onHero.withValues(alpha: 0.65), letterSpacing: 0.4),
                    ),
                  ),
                  const SizedBox(height: 36),
                  FadeSlideIn(
                    index: 4,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: onHero,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () => context.go(RouteNames.login),
                      child: const Text('Log in'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    index: 5,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: onHero,
                        side: BorderSide(color: onHero.withValues(alpha: 0.5)),
                      ),
                      onPressed: () => context.go(RouteNames.registerStudent),
                      child: const Text('Create account'),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    AppConstants.appName,
                    textAlign: TextAlign.center,
                    style: text.labelSmall?.copyWith(color: onHero.withValues(alpha: 0.5)),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
