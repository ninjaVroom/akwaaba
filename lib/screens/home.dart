import 'package:flutter/material.dart';

import '../data/demo_repo.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'drawer.dart';
import 'events.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AKWAABA')),
      drawer: const AppDrawer(current: '/home'),
      body: ListenableBuilder(
        listenable: repo,
        builder: (context, _) {
          final me = repo.me;
          final admin = repo.role == Role.admin;
          final todays = repo.todays;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            children: [
              AkCard(
                padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                child: Column(
                  children: [
                    Avatar(me.initials, size: 88),
                    const SizedBox(height: 12),
                    Text(
                      me.name,
                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: Ak.ink),
                    ),
                    const SizedBox(height: 4),
                    Text('ID: ${me.id}', style: const TextStyle(fontSize: 16, color: Color(0xFF333333))),
                    const SizedBox(height: 4),
                    Text(admin ? '${DemoRepo.org}, Admin' : DemoRepo.org, style: const TextStyle(fontSize: 12, color: Ak.muted)),
                  ],
                ),
              ),
              const SectionTitle("Today's Attendance"),
              if (todays.isEmpty)
                const AkCard(
                  child: Text('No meetings scheduled for today.', style: TextStyle(color: Ak.muted)),
                ),
              for (final o in todays) ...[AttendanceCard(o), const SizedBox(height: 14)],
              if (admin)
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/members'),
                    style: TextButton.styleFrom(foregroundColor: Ak.primary),
                    child: const Text('Manage Members'),
                  ),
                ),
              const DemoFooter(),
            ],
          );
        },
      ),
    );
  }
}

/// The Today's Attendance card with the clock state machine.
class AttendanceCard extends StatelessWidget {
  const AttendanceCard(this.o, {super.key});
  final Occurrence o;

  @override
  Widget build(BuildContext context) {
    final r = repo.clockFor(o);

    void advance() {
      if (!repo.advance(o)) Navigator.push(context, MaterialPageRoute(builder: (_) => const OutsideScreen()));
    }

    final List<Widget> actions = switch (r.stage) {
      ClockStage.idle => [
        Pill('Clock In', color: Ak.success, onTap: advance),
        Pill(
          'Outside premises',
          color: Colors.black,
          onTap: () {
            repo.setInside(false);
            advance();
          },
        ),
      ],
      ClockStage.clockedIn => [
        Pill('Break', color: Ak.success, onTap: advance),
        Pill('Clock Out', color: Ak.primary, textColor: Colors.black, onTap: () => repo.clockOut(o)),
      ],
      ClockStage.onBreak => [Pill('Resume', color: Ak.success, onTap: advance)],
      ClockStage.resumed => [Pill('Clock Out', color: Ak.primary, textColor: Colors.black, onTap: advance)],
      ClockStage.clockedOut => [Pill('View History', color: Ak.success, onTap: () => Navigator.pushNamed(context, '/history'))],
    };

    return AkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MeetingHeader(o),
          const SizedBox(height: 8),
          MetaRow(icon: Icons.alarm, left: 'IN: ${fmtTime(r.inAt)}', right: 'OUT: ${fmtTime(r.outAt)}', rightIcon: Icons.alarm),
          MetaRow(
            icon: Icons.alarm,
            left: 'Break: ${fmtTime(r.breakAt)}',
            right: 'Resume: ${fmtTime(r.resumeAt)}',
            rightIcon: Icons.alarm,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final (i, a) in actions.indexed) ...[if (i > 0) const SizedBox(width: 12), Expanded(child: a)],
            ],
          ),
          const SizedBox(height: 12),
          Pill(
            'Agenda',
            color: Ak.neutral,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AgendaScreen(o))),
          ),
        ],
      ),
    );
  }
}

class OutsideScreen extends StatelessWidget {
  const OutsideScreen({super.key});

  @override
  Widget build(BuildContext context) => ConfirmScreen(
    icon: Icons.home_work_outlined,
    title: 'Outside premises',
    body: 'You must be within the premises to clock in. This demo simulates your location; no GPS data is collected.',
    action: "I'm back inside",
    onAction: () {
      repo.setInside(true);
      Navigator.pop(context);
    },
  );
}
