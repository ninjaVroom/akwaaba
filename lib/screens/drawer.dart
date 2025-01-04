import 'package:flutter/material.dart';

import '../data/demo_repo.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.current});
  final String current;

  @override
  Widget build(BuildContext context) {
    final admin = repo.role == Role.admin;
    final me = repo.me;

    Widget item(IconData icon, String label, String route, {Color iconColor = Ak.primary}) {
      final on = route == current;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: ListTile(
          selected: on,
          selectedTileColor: Ak.tint,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(icon, color: iconColor),
          title: Text(
            label,
            style: TextStyle(fontSize: 15, fontWeight: on ? FontWeight.w700 : FontWeight.w500, color: on ? Ak.primary : Ak.ink),
          ),
          onTap: () {
            Navigator.pop(context);
            if (route == '/login') {
              Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
            } else if (!on) {
              // Top-level destinations replace each other; Home stays at the root.
              route == '/home'
                  ? Navigator.popUntil(context, ModalRoute.withName('/home'))
                  : Navigator.pushNamedAndRemoveUntil(context, route, ModalRoute.withName('/home'));
            }
          },
        ),
      );
    }

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Ak.primary,
            padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                  padding: const EdgeInsets.all(2),
                  child: Avatar(me.initials, size: 64),
                ),
                const SizedBox(height: 12),
                Text(
                  me.name,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.black),
                ),
                const SizedBox(height: 2),
                Text('ID: ${me.id}', style: const TextStyle(fontSize: 14, color: Ak.ink)),
                Text(DemoRepo.org, style: const TextStyle(fontSize: 12, color: Ak.ink)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: Ak.dark, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    admin ? 'Admin' : 'Member',
                    style: const TextStyle(color: Ak.primary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                item(Icons.home_outlined, 'Home', '/home'),
                item(Icons.event_outlined, 'Events & Meetings', '/events'),
                item(Icons.history, 'My Attendance', '/history'),
                if (admin) ...[
                  const Divider(color: Ak.line, indent: 16, endIndent: 16),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 8, 24, 4),
                    child: Text('Administration', style: TextStyle(fontSize: 12, color: Color(0xFF777777))),
                  ),
                  item(Icons.groups_outlined, 'Members', '/members'),
                  item(Icons.tablet_android_outlined, 'Public Clocking', '/kiosk'),
                ],
                const Divider(color: Ak.line, indent: 16, endIndent: 16),
                item(Icons.account_circle_outlined, 'Profile', '/profile'),
                item(Icons.logout, 'Logout', '/login', iconColor: Ak.danger),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Akwaaba v2.5.3, demo reconstruction', style: TextStyle(fontSize: 11, color: Color(0xFF888888))),
          ),
        ],
      ),
    );
  }
}
