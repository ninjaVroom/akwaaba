import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/demo_repo.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'drawer.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.member});

  /// Null means the signed-in user.
  final Member? member;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late DateTime _month = DateTime(repo.today.year, repo.today.month);

  @override
  Widget build(BuildContext context) {
    final m = widget.member ?? repo.me;
    final mine = widget.member == null;
    final months = [for (var i = 0; i < 3; i++) DateTime(repo.today.year, repo.today.month - i)];
    final records = repo.history(m, _month);
    int count(AttendanceStatus s) => records.where((r) => r.status == s).length;

    return Scaffold(
      appBar: AppBar(title: Text(mine ? 'My Attendance' : 'Attendance Log')),
      drawer: mine ? const AppDrawer(current: '/history') : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AkCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Monthly Summary', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                          if (!mine) Text('${m.name}, ${m.id}', style: const TextStyle(fontSize: 12, color: Ak.muted)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Ak.bg, borderRadius: BorderRadius.circular(20)),
                      child: DropdownButton<DateTime>(
                        value: _month,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.keyboard_arrow_down, color: Ak.primary),
                        items: [
                          for (final mo in months) DropdownMenuItem(value: mo, child: Text(DateFormat('MMMM y').format(mo))),
                        ],
                        onChanged: (v) => setState(() => _month = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Stat('Present', '${count(AttendanceStatus.present)}', color: Ak.success),
                    Stat('Late', '${count(AttendanceStatus.late)}', color: Ak.primary),
                    Stat('Absent', '${count(AttendanceStatus.absent)}', color: Ak.danger),
                  ],
                ),
              ],
            ),
          ),
          const SectionTitle('Attendance Records'),
          if (records.isEmpty)
            const AkCard(
              child: Text('No attendance recorded this month.', style: TextStyle(color: Ak.muted)),
            ),
          for (final r in records) ...[_RecordCard(r), const SizedBox(height: 12)],
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard(this.r);
  final AttendanceRecord r;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (r.status) {
      AttendanceStatus.present => ('Present', Ak.success),
      AttendanceStatus.late => ('Late', Ak.primary),
      AttendanceStatus.absent => ('Absent', Ak.danger),
    };
    final c = r.clock;
    return AkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(r.occurrence.meeting.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          MetaRow(
            icon: Icons.calendar_month_outlined,
            left: fmtDate(r.occurrence.date),
            right: r.occurrence.meeting.weekly ? 'Recurring Weekly' : 'Non-Recurring',
          ),
          MetaRow(icon: Icons.alarm, left: 'IN: ${fmtTime(c.inAt)}', right: 'OUT: ${fmtTime(c.outAt)}', rightIcon: Icons.alarm),
          if (c.breakAt != null)
            MetaRow(
              icon: Icons.alarm,
              left: 'Break: ${fmtTime(c.breakAt)}',
              right: 'Resume: ${fmtTime(c.resumeAt)}',
              rightIcon: Icons.alarm,
            ),
        ],
      ),
    );
  }
}
