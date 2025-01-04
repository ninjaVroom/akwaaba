import 'package:flutter/material.dart';

import '../data/demo_repo.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'drawer.dart';

enum _Kind { all, events, meetings }

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  var _kind = _Kind.all;
  var _query = '';
  var _recurringOnly = false;
  var _days = 21;

  @override
  Widget build(BuildContext context) {
    final list = repo.upcoming(days: _days).where((o) {
      final m = o.meeting;
      if (_kind == _Kind.events && m.type != MeetingType.event) return false;
      if (_kind == _Kind.meetings && m.type != MeetingType.meeting) return false;
      if (_recurringOnly && !m.weekly) return false;
      return m.title.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming Events & Meetings')),
      drawer: const AppDrawer(current: '/events'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AkCard(
            padding: EdgeInsets.zero,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                shape: const Border(),
                iconColor: Ak.primary,
                collapsedIconColor: Ak.primary,
                title: const Text('Filter Options', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: Ak.primary,
                    title: const Text('Recurring only'),
                    value: _recurringOnly,
                    onChanged: (v) => setState(() => _recurringOnly = v),
                  ),
                  Row(
                    children: [
                      const Expanded(child: Text('Show the next')),
                      DropdownButton<int>(
                        value: _days,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 7, child: Text('7 days')),
                          DropdownMenuItem(value: 21, child: Text('3 weeks')),
                          DropdownMenuItem(value: 60, child: Text('2 months')),
                        ],
                        onChanged: (v) => setState(() => _days = v!),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SearchField(onChanged: (v) => setState(() => _query = v)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Ak.line),
            ),
            child: RadioGroup<_Kind>(
              groupValue: _kind,
              onChanged: (v) => setState(() => _kind = v!),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final (k, label) in [(_Kind.all, 'All'), (_Kind.events, 'Events'), (_Kind.meetings, 'Meetings')])
                    InkWell(
                      onTap: () => setState(() => _kind = k),
                      child: Row(
                        children: [
                          Radio<_Kind>(value: k),
                          Text(label, style: const TextStyle(fontSize: 15)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Nothing matches these filters.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Ak.muted),
              ),
            ),
          for (final o in list) ...[
            AkCard(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AgendaScreen(o))),
              child: MeetingHeader(o),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.onChanged, this.hint = 'Search', this.controller});
  final ValueChanged<String> onChanged;
  final String hint;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: const Icon(Icons.search),
      filled: true,
      fillColor: Ak.field,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Ak.primary),
      ),
    ),
  );
}

class AgendaScreen extends StatelessWidget {
  const AgendaScreen(this.o, {super.key});
  final Occurrence o;

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(o.date, repo.today);
    return Scaffold(
      appBar: AppBar(title: const Text('Meeting Agenda')),
      body: ListenableBuilder(
        listenable: repo,
        builder: (context, _) {
          final inside = repo.insidePremises;
          final stage = repo.clockFor(o).stage;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AkCard(child: MeetingHeader(o, showVenue: true)),
              const SizedBox(height: 14),
              AkCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Premises Geofence', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        ),
                        Text(
                          inside ? 'Inside' : 'Outside',
                          style: TextStyle(color: inside ? Ak.success : Ak.danger, fontWeight: FontWeight.w600),
                        ),
                        Switch(
                          value: inside,
                          activeThumbColor: Colors.white,
                          activeTrackColor: Ak.success,
                          onChanged: repo.setInside,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(height: 170, child: CustomPaint(painter: _MapPainter(inside))),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(inside ? Icons.check_circle : Icons.error_outline, size: 18, color: inside ? Ak.success : Ak.danger),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            inside ? 'Inside premises, 42 m from centre (150 m radius)' : 'Outside premises, 310 m from centre',
                            style: const TextStyle(fontSize: 13, color: Ak.muted),
                          ),
                        ),
                      ],
                    ),
                    if (isToday && stage == ClockStage.idle) ...[
                      const SizedBox(height: 12),
                      Pill(
                        'Clock In',
                        color: Ak.success,
                        onTap: () {
                          if (repo.advance(o)) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('Clocked in to ${o.meeting.title}')));
                          } else {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text('You must be within the premises to clock in.')));
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 4),
                    const Text('Schematic map, not a real location.', style: TextStyle(fontSize: 11, color: Ak.neutral)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AkCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Agenda Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    if (o.meeting.agenda.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('No agenda has been published for this meeting yet.', style: TextStyle(color: Ak.muted)),
                      ),
                    for (final (i, a) in o.meeting.agenda.indexed) ...[
                      if (i > 0) const Divider(color: Color(0xFFEEEEEE), height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 76,
                              child: Text(
                                fmtTod(a.time),
                                style: const TextStyle(color: Ak.primary, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(a.note, style: const TextStyle(fontSize: 12, color: Ak.muted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter(this.inside);
  final bool inside;

  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFEFF5EC));
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 8;
    for (var x = 30.0; x < s.width; x += 70) {
      canvas.drawLine(Offset(x, 0), Offset(x + 20, s.height), road);
    }
    for (var y = 25.0; y < s.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(s.width, y - 10), road);
    }
    final c = s.center(Offset.zero);
    canvas.drawCircle(c, 56, Paint()..color = Ak.success.withValues(alpha: 0.22));
    canvas.drawCircle(
      c,
      56,
      Paint()
        ..color = Ak.success
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(c, 9, Paint()..color = Ak.primary);
    final me = inside ? c + const Offset(18, 14) : c + const Offset(110, 52);
    canvas.drawCircle(me, 9, Paint()..color = Colors.white);
    canvas.drawCircle(me, 6, Paint()..color = Ak.link);
  }

  @override
  bool shouldRepaint(_MapPainter old) => old.inside != inside;
}
