import 'package:flutter/material.dart';

import '../../../widgets/common/info_screen.dart';

/// Manager registration is not available via the app.
/// Users are created by the admin through the seed script.
/// This screen shows a message and a way back to login.
class ManagerRegisterScreen extends StatelessWidget {
  const ManagerRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoScreen(
      appBarTitle: 'Manager Registration',
      title: 'Registration not available',
      message: 'Manager accounts are created by the system administrator. '
          'Please contact your administrator to get your credentials.',
    );
  }
}
