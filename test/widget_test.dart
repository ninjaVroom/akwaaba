import 'package:akwaaba_demo/data/demo_repo.dart';
import 'package:akwaaba_demo/data/models.dart';
import 'package:akwaaba_demo/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clock state machine: idle → in → break → resumed → out', () {
    final r = ClockRecord();
    final t = DateTime(2026, 11, 6, 9);
    expect(r.stage, ClockStage.idle);
    for (final s in [ClockStage.clockedIn, ClockStage.onBreak, ClockStage.resumed, ClockStage.clockedOut]) {
      expect(r.advance(t), isTrue);
      expect(r.stage, s);
    }
    expect(r.advance(t), isFalse);
  });

  test('geofence refuses clock-in when outside', () {
    final repo = DemoRepo(today: DateTime(2026, 11, 6));
    final o = repo.todays.first;
    repo.setInside(false);
    expect(repo.advance(o), isFalse);
    expect(repo.clockFor(o).stage, ClockStage.idle);
    repo.setInside(true);
    expect(repo.advance(o), isTrue);
    expect(repo.clockFor(o).stage, ClockStage.clockedIn);
  });

  test('weekly meetings recur and history is stable', () {
    final repo = DemoRepo(today: DateTime(2026, 11, 6)); // a Friday
    expect(repo.todays.map((o) => o.meeting.id), containsAll(['workshop', 'assembly']));
    expect(repo.upcoming().where((o) => o.meeting.id == 'assembly').length, 3);
    final a = repo.history(repo.me, DateTime(2026, 10)).map((r) => r.status).toList();
    final b = repo.history(repo.me, DateTime(2026, 10)).map((r) => r.status).toList();
    expect(a, isNotEmpty);
    expect(a, b);
  });

  test('kiosk seeds are never in the future and share my record with Home', () {
    final repo = DemoRepo();
    final now = DateTime.now();
    expect(repo.recentKiosk.every((row) => !row.$2.inAt!.isAfter(now)), isTrue);
    expect(repo.recentKiosk.any((row) => row.$1 == repo.me), isFalse); // not clocked in yet
    repo.advance(repo.todays.first);
    expect(repo.kioskFor(repo.me).inAt, repo.clockFor(repo.todays.first).inAt);
    expect(repo.recentKiosk.first.$1, repo.me);
  });

  test('history status matches the clock-in time (incl. daylight-saving days)', () {
    final repo = DemoRepo(today: DateTime(2026, 11, 9));
    for (final month in [DateTime(2026, 9), DateTime(2026, 10), DateTime(2026, 11)]) {
      for (final rec in repo.history(repo.members[1], month)) {
        if (rec.status == AttendanceStatus.absent) continue;
        final cutoff = atTime(rec.occurrence.date, rec.occurrence.meeting.start, plusMinutes: 5);
        expect(rec.clock.inAt!.isAfter(cutoff), rec.status == AttendanceStatus.late, reason: rec.occurrence.key);
        expect(DateUtils.isSameDay(rec.clock.inAt, rec.occurrence.date), isTrue, reason: rec.occurrence.key);
      }
    }
  });

  test('history is identical across app launches (no per-run hash seed)', () {
    // Pinned: with Object.hash these would differ from run to run.
    final repo = DemoRepo(today: DateTime(2026, 11, 9));
    final got = [
      for (final r in repo.history(repo.me, DateTime(2026, 10))) '${r.occurrence.key} ${r.status.name} ${r.clock.inAt}',
    ];
    expect(got.take(3).toList(), _pinned);
  });

  test('delete never removes the signed-in user', () {
    final repo = DemoRepo();
    final n = repo.members.length;
    repo.delete([repo.me, repo.members.first]);
    expect(repo.members.length, n - 1);
    expect(repo.members, contains(repo.me));
  });

  testWidgets('login as admin, clock in, open members', (tester) async {
    repo = DemoRepo();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AkwaabaApp(initialRoute: '/login'));
    await tester.tap(find.text('Admin'));
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('AKWAABA'), findsOneWidget);
    await tester.tap(find.text('Clock In').first);
    await tester.pump();
    expect(find.text('Break'), findsWidgets);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.text('Public Clocking'), findsOneWidget);
    await tester.tap(find.text('Members'));
    await tester.pumpAndSettle();
    expect(find.text('Select All'), findsOneWidget);
  });
}

const _pinned = [
  'assembly@2026-10-30 present 2026-10-30 08:25:00.000',
  'office@2026-10-27 present 2026-10-27 08:43:00.000',
  'zone1@2026-10-25 present 2026-10-25 18:00:00.000',
];
