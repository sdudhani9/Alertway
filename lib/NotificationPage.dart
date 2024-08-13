import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
final List<String> notifications;

NotificationPage({required this.notifications});

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Notifications'),
    ),
    body: ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(notifications[index]),
        );
      },
    ),
  );
}
}
