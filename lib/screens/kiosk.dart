import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/demo_repo.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'events.dart';

/// v2.5.0 public clocking: one shared device, staff look themselves up and clock in or out.
class KioskScreen extends StatefulWidget {
  const KioskScreen({super.key});

  @override
  State<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends State<KioskScreen> {
  final _search = TextEditingController(text: 'HYC-2');
  late Timer _tick;
  var _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _tick.cancel();
    _search.dispose();
    super.dispose();
  }

  void _act(Member m, String label, {bool out = false}) {
    repo.kioskAdvance(m, out: out);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label recorded for ${m.name} at ${fmtTime(DateTime.now())}')));
  }

  @override
  Widget build(BuildContext context) {
    final session = repo.todays.firstOrNull;
    final q = _search.text.trim().toLowerCase();
    final exact = repo.byId(q);
    final matches = q.isEmpty || exact != null
        ? <Member>[]
        : repo.members.where((m) => m.name.toLowerCase().contains(q) || m.id.toLowerCase().contains(q)).take(5).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Public Clocking')),
      body: ListenableBuilder(
        listenable: repo,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AkCard(
              color: Ak.dark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shared kiosk mode, ${DemoRepo.org}',
                    style: TextStyle(color: Ak.primary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('hh:mm:ss a').format(_now),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Ak.success, borderRadius: BorderRadius.circular(12)),
                        child: const Text(
                          'Geofence verified',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    session == null
                        ? 'No active session today'
                        : 'Active session: ${session.meeting.title} (${fmtTod(session.meeting.start)} – ${fmtTod(session.meeting.end)})',
                    style: const TextStyle(color: Ak.lightText, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SearchField(controller: _search, hint: 'Enter your ID or name', onChanged: (_) => setState(() {})),
            for (final m in matches)
              ListTile(
                leading: Avatar(m.initials, size: 36),
                title: Text(m.name),
                subtitle: Text(m.id),
                onTap: () => setState(() => _search.text = m.id),
              ),
            const SizedBox(height: 14),
            if (exact != null) _staffCard(exact),
            if (q.isNotEmpty && exact == null && matches.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No staff member with that ID or name.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Ak.muted),
                ),
              ),
            const SectionTitle('Recently Clocked In'),
            for (final (m, r) in repo.recentKiosk.take(5)) ...[
              AkCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                onTap: () => setState(() => _search.text = m.id),
                child: Row(
                  children: [
                    Avatar(m.initials, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('${m.name} (${m.id})', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Text(
                      r.outAt != null ? 'OUT: ${fmtTime(r.outAt)}' : 'IN: ${fmtTime(r.inAt)}',
                      style: TextStyle(color: r.outAt != null ? Ak.muted : Ak.success, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _staffCard(Member m) {
    final r = repo.kioskFor(m);
    final buttons = switch (r.stage) {
      ClockStage.idle => [Pill('Clock In', color: Ak.success, onTap: () => _act(m, 'Clock in'))],
      ClockStage.clockedIn => [
        Pill('Break', color: Ak.success, onTap: () => _act(m, 'Break')),
        Pill('Clock Out', color: Ak.primary, textColor: Colors.black, onTap: () => _act(m, 'Clock out', out: true)),
      ],
      ClockStage.onBreak => [Pill('Resume', color: Ak.success, onTap: () => _act(m, 'Resume'))],
      ClockStage.resumed => [Pill('Clock Out', color: Ak.primary, textColor: Colors.black, onTap: () => _act(m, 'Clock out'))],
      ClockStage.clockedOut => [const Pill('Done for today', color: Ak.neutral)],
    };
    return AkCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Avatar(m.initials, size: 60),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                    Text('ID: ${m.id}, ${m.group}', style: const TextStyle(fontSize: 12, color: Ak.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!m.enabled)
            const Text('This account is disabled. Ask an admin to enable it.', style: TextStyle(color: Ak.danger))
          else ...[
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
                for (final (i, b) in buttons.indexed) ...[if (i > 0) const SizedBox(width: 8), Expanded(child: b)],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
