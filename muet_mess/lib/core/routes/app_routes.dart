import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/manager_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/navigation/app_shell.dart';
import '../../widgets/common/notifications_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/student_register_screen.dart';
import '../../features/auth/screens/manager_register_screen.dart';
import '../../features/student/student_shell.dart';
import '../../features/manager/manager_shell.dart';
import '../../features/menu/student_menu_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/entries/entry_detail_screen.dart';
import '../../features/entries/dispute_screen.dart';
import '../../features/entries/entry_form_screen.dart';
import '../../features/manager/manager_students_screen.dart';
import '../../features/manager/student_ledger_screen.dart';
import '../../features/manager/payment_screen.dart';
import 'route_names.dart';

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(AuthProvider auth) {
    auth.addListener(notifyListeners);
  }
}

/// Role-aware router with guards so students cannot reach manager
/// screens and vice versa.
class AppRouter {
  static GoRouter build(AuthProvider auth) {
    return GoRouter(
      initialLocation: RouteNames.splash,
      refreshListenable: _AuthRefresh(auth),
      redirect: (context, state) {
        final path = state.uri.path;
        final isPublic = path == RouteNames.splash ||
            path == RouteNames.login ||
            path == RouteNames.registerStudent ||
            path == RouteNames.registerManager;
        if (!auth.isAuthenticated) {
          return isPublic ? null : RouteNames.login;
        }
        if (isPublic) {
          return auth.isManager ? RouteNames.managerDashboard : RouteNames.studentHome;
        }
        if (auth.isStudent && path.startsWith('/manager')) return RouteNames.studentHome;
        if (auth.isManager && path.startsWith('/student')) return RouteNames.managerDashboard;
        return null;
      },
      routes: [
        GoRoute(path: RouteNames.splash, builder: (_, __) => const SplashScreen()),
        GoRoute(path: RouteNames.login, builder: (_, __) => const LoginScreen()),
        GoRoute(path: RouteNames.registerStudent, builder: (_, __) => const StudentRegisterScreen()),
        GoRoute(path: RouteNames.registerManager, builder: (_, __) => const ManagerRegisterScreen()),
        ShellRoute(
          builder: (context, state, child) => _Shell(child: child, uri: state.uri.path),
          routes: [
            // Student routes
            GoRoute(path: RouteNames.studentHome, builder: (_, __) => const StudentShell(initialIndex: 0)),
            GoRoute(path: RouteNames.studentKhata, builder: (_, __) => const StudentShell(initialIndex: 1)),
            GoRoute(path: RouteNames.studentKhatas, builder: (_, __) => const StudentShell(initialIndex: 1)),
            GoRoute(path: RouteNames.studentEnterMeal, builder: (_, __) => const StudentShell(initialIndex: 2)),
            GoRoute(path: RouteNames.studentMenu, builder: (_, __) => const StudentMenuScreen()),
            GoRoute(path: RouteNames.studentNotifications, builder: (_, __) => const NotificationsScreen()),
            GoRoute(path: RouteNames.studentProfile, builder: (_, __) => const ProfileScreen()),
            GoRoute(path: RouteNames.studentPayments, builder: (_, __) => const StudentShell(initialIndex: 1)),
            GoRoute(
              path: RouteNames.studentMeal,
              builder: (_, state) => EntryDetailScreen(id: state.pathParameters['id']!),
            ),
            GoRoute(
              path: RouteNames.studentMealDispute,
              builder: (_, state) => DisputeScreen(id: state.pathParameters['id']!),
            ),

            // Manager routes
            GoRoute(path: RouteNames.managerDashboard, builder: (_, __) => const ManagerShell(initialIndex: 0)),
            GoRoute(path: RouteNames.managerApprovals, builder: (_, __) => const ManagerShell(initialIndex: 1)),
            GoRoute(path: RouteNames.managerStudents, builder: (_, __) => const ManagerStudentsScreen()),
            GoRoute(path: RouteNames.managerPayments, builder: (_, __) => const ManagerShell(initialIndex: 2)),
            GoRoute(path: RouteNames.managerMenu, builder: (_, __) => const ManagerShell(initialIndex: 3)),
            GoRoute(path: RouteNames.managerReports, builder: (_, __) => const ManagerShell(initialIndex: 0)),
            GoRoute(path: RouteNames.managerNotifications, builder: (_, __) => const NotificationsScreen()),
            GoRoute(path: RouteNames.managerProfile, builder: (_, __) => const ProfileScreen()),
            GoRoute(
              path: '/manager/students/:id',
              builder: (_, state) => StudentLedgerScreen(studentId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: '/manager/student/:id',
              builder: (_, state) => StudentLedgerScreen(studentId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: '/manager/students/:id/khata',
              builder: (_, state) => StudentLedgerScreen(studentId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: '/manager/student/:id/khata',
              builder: (_, state) => StudentLedgerScreen(studentId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: '/manager/students/:id/payment',
              builder: (_, state) => PaymentScreen(studentId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: '/manager/student/:id/payment',
              builder: (_, state) => PaymentScreen(studentId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: RouteNames.managerMeal,
              builder: (_, state) => EntryDetailScreen(id: state.pathParameters['id']!),
            ),
            GoRoute(
              path: RouteNames.managerEntryNew,
              builder: (_, __) => const EntryFormScreen(isManager: true),
            ),
            GoRoute(
              path: '/entries/:id',
              builder: (_, state) => EntryDetailScreen(id: state.pathParameters['id']!),
            ),
            GoRoute(
              path: '/entries/:id/dispute',
              builder: (_, state) => DisputeScreen(id: state.pathParameters['id']!),
            ),
            GoRoute(
              path: '/entries/:id/edit',
              builder: (_, state) => EntryFormScreen(isManager: true, editId: state.pathParameters['id']),
            ),
          ],
        ),
      ],
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child, required this.uri});

  final Widget child;
  final String uri;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      return child;
    }
    final destinations = user is Manager
        ? const [
            Destination(label: 'Home', icon: Icons.home_outlined, route: RouteNames.managerDashboard),
            Destination(label: 'Students', icon: Icons.people_outlined, route: RouteNames.managerStudents),
            Destination(label: 'Approvals', icon: Icons.fact_check_outlined, route: RouteNames.managerApprovals),
            Destination(label: 'Payments', icon: Icons.payments_outlined, route: RouteNames.managerPayments),
            Destination(label: 'Menu', icon: Icons.restaurant_menu, route: RouteNames.managerMenu),
          ]
        : const [
            Destination(label: 'Home', icon: Icons.home_outlined, route: RouteNames.studentHome),
            Destination(label: 'Add Entry', icon: Icons.add_circle_outline, route: RouteNames.studentEnterMeal),
            Destination(label: 'Records', icon: Icons.receipt_long_outlined, route: RouteNames.studentKhata),
            Destination(label: 'Menu', icon: Icons.restaurant_menu, route: RouteNames.studentMenu),
            Destination(label: 'Notifications', icon: Icons.notifications_outlined, route: RouteNames.studentNotifications),
            Destination(label: 'Profile', icon: Icons.person_outline, route: RouteNames.studentProfile),
          ];
    return AppShell(
      child: child,
      destinations: destinations,
      currentRoute: uri,
      user: user,
      onGo: (route) => context.go(route),
    );
  }
}