import 'package:flutter/material.dart';

import '../../../../core/widgets/app_empty_view.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const AppEmptyView(
        icon: Icons.notifications_none_outlined,
        title: 'All Caught Up!',
        message: 'You have no new notifications. You will be alerted when someone messages you, assigns a bug, or invites you to an organization.',
      ),
    );
  }
}
