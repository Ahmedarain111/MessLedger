import 'package:flutter/material.dart';

import '../../../widgets/common/info_screen.dart';

/// Student registration is not available via the app.
/// Users are created by the admin through the seed script.
/// This screen shows a message and a way back to login.
class StudentRegisterScreen extends StatelessWidget {
  const StudentRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoScreen(
      appBarTitle: 'Student Registration',
      title: 'Registration not available',
      message: 'Student accounts are created by the mess manager. '
          'Please contact your mess manager to get your credentials.',
    );
  }
}
