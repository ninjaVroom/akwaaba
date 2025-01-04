import 'package:flutter/material.dart';

import 'models.dart';

/// In-memory demo data. Everything resets on reload; nothing leaves the device.
class DemoRepo extends ChangeNotifier {
  DemoRepo({DateTime? today}) : today = DateUtils.dateOnly(today ?? DateTime.now()) {
    _seedKiosk();
  }

  final DateTime today;
  static const org = 'Harbour Youth Collective';

  Role role = Role.member;
  bool insidePremises = true;

  late final Member me = members.firstWhere((m) => m.id == 'HYC-104');

  final List<Member> members = [
    for (final (i, row) in _people.indexed)
      Member(
        id: row.$1 == 'Kwesi Mensah' ? 'HYC-104' : 'HYC-${i + 1}',
        name: row.$1,
        gender: row.$2,
        phone: '+233 24 555 ${(140 + i).toString().padLeft(4, '0')}',
        group: _groups[i % _groups.length],
        branch: _branches[i % _branches.length],
        enabled: i % 11 != 9, // a couple of disabled accounts so the state is visible
      ),
  ];

  late final List<Meeting> meetings = [
    Meeting(
      id: 'workshop',
      title: 'Entrepreneurship Workshop',
      type: MeetingType.event,
      date: today,
      start: const TimeOfDay(hour: 9, minute: 0),
      end: const TimeOfDay(hour: 17, minute: 0),
      agenda: const [
        AgendaItem(TimeOfDay(hour: 9, minute: 0), 'Registration and opening prayer', 'Main auditorium'),
        AgendaItem(TimeOfDay(hour: 10, minute: 30), 'Bookkeeping and tax for small businesses', 'Facilitator: Mensah Bonsu'),
        AgendaItem(TimeOfDay(hour: 13, minute: 0), 'Lunch and networking', 'Courtyard'),
        AgendaItem(TimeOfDay(hour: 14, minute: 0), 'Pitch practice and grant review', 'Breakout rooms A and B'),
      ],
    ),
    Meeting(
      id: 'assembly',
      title: 'General Assembly',
      type: MeetingType.meeting,
      date: _weekdayOnOrAfter(DateUtils.addDaysToDate(today, -120), DateTime.friday),
      start: const TimeOfDay(hour: 8, minute: 30),
      end: const TimeOfDay(hour: 16, minute: 30),
      weekly: true,
      venue: 'Harbour Youth Hall, Tema',
      agenda: const [
        AgendaItem(TimeOfDay(hour: 8, minute: 30), 'Roll call', 'All branches'),
        AgendaItem(TimeOfDay(hour: 9, minute: 0), 'Branch reports', 'Zone leads'),
        AgendaItem(TimeOfDay(hour: 11, minute: 0), 'Programme updates', 'Programme office'),
      ],
    ),
    Meeting(
      id: 'office',
      title: 'Office Work',
      type: MeetingType.meeting,
      date: _weekdayOnOrAfter(DateUtils.addDaysToDate(today, -120), DateTime.tuesday),
      start: const TimeOfDay(hour: 9, minute: 0),
      end: const TimeOfDay(hour: 17, minute: 0),
      weekly: true,
      venue: 'Tema Central Branch',
    ),
    Meeting(
      id: 'zone1',
      title: 'Zone 1 Branch Meeting',
      type: MeetingType.meeting,
      date: _weekdayOnOrAfter(DateUtils.addDaysToDate(today, -120), DateTime.sunday),
      start: const TimeOfDay(hour: 18, minute: 0),
      end: const TimeOfDay(hour: 20, minute: 0),
      weekly: true,
      venue: 'Community 1 Centre, Tema',
      agenda: const [
        AgendaItem(TimeOfDay(hour: 18, minute: 0), 'Opening and attendance', 'Zone secretary'),
        AgendaItem(TimeOfDay(hour: 18, minute: 30), 'Dues and welfare', 'Treasurer'),
      ],
    ),
    Meeting(
      id: 'textiles',
      title: 'Apparel & Textiles Training',
      type: MeetingType.event,
      date: DateUtils.addDaysToDate(today, 5),
      start: const TimeOfDay(hour: 9, minute: 0),
      end: const TimeOfDay(hour: 15, minute: 0),
      spanDays: 3,
      venue: 'Ashaiman Skills Centre',
    ),
    Meeting(
      id: 'forum',
      title: 'Youth Entrepreneurship Forum',
      type: MeetingType.event,
      date: DateUtils.addDaysToDate(today, 12),
      start: const TimeOfDay(hour: 10, minute: 0),
      end: const TimeOfDay(hour: 14, minute: 0),
      venue: 'Accra International Conference Centre',
    ),
  ];

  // ---- Meetings -------------------------------------------------------------

  List<Occurrence> occurrencesOn(DateTime day) => [
    for (final m in meetings)
      if (m.occursOn(day)) Occurrence(m, DateUtils.dateOnly(day)),
  ];

  List<Occurrence> get todays => occurrencesOn(today);

  /// Upcoming occurrences, one card per meeting date (multi-day events once, on their first day).
  List<Occurrence> upcoming({int days = 21}) => [
    for (var i = 0; i < days; i++)
      for (final o in occurrencesOn(DateUtils.addDaysToDate(today, i)))
        if (o.meeting.weekly || DateUtils.isSameDay(o.date, o.meeting.date) || i == 0) o,
  ];

  // ---- Clocking (the signed-in user) --------------------------------------------

  final Map<String, ClockRecord> _myClock = {};

  ClockRecord clockFor(Occurrence o) => _myClock.putIfAbsent(o.key, ClockRecord.new);

  /// Returns false when clocking in is refused because the user is outside the geofence.
  bool advance(Occurrence o, {DateTime? now}) {
    final r = clockFor(o);
    if (r.stage == ClockStage.idle && !insidePremises) return false;
    r.advance(now ?? DateTime.now());
    notifyListeners();
    return true;
  }

  void clockOut(Occurrence o, {DateTime? now}) {
    clockFor(o).clockOut(now ?? DateTime.now());
    notifyListeners();
  }

  void setInside(bool v) {
    insidePremises = v;
    notifyListeners();
  }

  // ---- Public clocking kiosk ------------------------------------------------------

  final Map<String, ClockRecord> kiosk = {};

  /// Two colleagues clocked in shortly before the app opened, so times are never in the future.
  void _seedKiosk() {
    final now = DateTime.now();
    final t = atTime(today, TimeOfDay.fromDateTime(now));
    DateTime ago(int m) {
      final d = t.subtract(Duration(minutes: m));
      return d.isBefore(today) ? today : d;
    }

    kiosk['HYC-1'] = ClockRecord()..inAt = ago(21);
    kiosk['HYC-2'] = ClockRecord()..inAt = ago(14);
  }

  /// The signed-in member shares one record between Home and the kiosk for today's session.
  ClockRecord kioskFor(Member m) {
    final s = todays.firstOrNull;
    if (m == me && s != null) return clockFor(s);
    return kiosk.putIfAbsent(m.id, ClockRecord.new);
  }

  void kioskAdvance(Member m, {bool out = false}) {
    final r = kioskFor(m);
    out ? r.clockOut(DateTime.now()) : r.advance(DateTime.now());
    notifyListeners();
  }

  /// Most recent first.
  List<(Member, ClockRecord)> get recentKiosk {
    final rows = [
      for (final m in [me, ...members.where((m) => m != me && kiosk.containsKey(m.id))])
        if (kioskFor(m).inAt != null) (m, kioskFor(m)),
    ];
    rows.sort((a, b) => b.$2.inAt!.compareTo(a.$2.inAt!));
    return rows;
  }

  // ---- Members (admin) ------------------------------------------------------------

  Member? byId(String id) => members.where((m) => m.id.toLowerCase() == id.toLowerCase()).firstOrNull;

  void setEnabled(Iterable<Member> ms, bool enabled) {
    for (final m in ms) {
      m.enabled = enabled;
    }
    notifyListeners();
  }

  void delete(Iterable<Member> ms) {
    final ids = ms.map((m) => m.id).toSet()..remove(me.id); // never delete the signed-in user
    members.removeWhere((m) => ids.contains(m.id));
    notifyListeners();
  }

  // ---- History ---------------------------------------------------------------

  /// Past attendance for [m] in the month containing [month]. Deterministic per member and date,
  /// plus today's live record for the signed-in user.
  List<AttendanceRecord> history(Member m, DateTime month) {
    final out = <AttendanceRecord>[];
    final first = DateTime(month.year, month.month);
    final last = DateTime(month.year, month.month + 1, 0);
    for (var d = last; !d.isBefore(first); d = DateUtils.addDaysToDate(d, -1)) {
      if (d.isAfter(today)) continue;
      for (final o in occurrencesOn(d)) {
        if (DateUtils.isSameDay(d, today)) {
          final live = m == me ? _myClock[o.key] : kiosk[m.id];
          if (live?.inAt != null) out.add(AttendanceRecord(o, live!, _statusFor(o, live)));
          continue;
        }
        out.add(_synth(m, o));
      }
    }
    return out;
  }

  AttendanceRecord _synth(Member m, Occurrence o) {
    // FNV-1a: Object.hash is seeded per run, so it would reshuffle history on every launch.
    final seed = '${m.id}|${o.key}'.codeUnits.fold(0x811c9dc5, (h, c) => ((h ^ c) * 0x01000193) & 0x7fffffff);
    final roll = seed % 12;
    if (roll == 0) return AttendanceRecord(o, ClockRecord(), AttendanceStatus.absent);
    final late = roll <= 2;
    final start = atTime(o.date, o.meeting.start);
    final end = atTime(o.date, o.meeting.end);
    final r = ClockRecord()
      ..inAt = start.add(Duration(minutes: late ? 10 + seed % 20 : -(seed % 18)))
      ..outAt = end.add(Duration(minutes: seed % 9 - 4));
    if (end.difference(start).inHours >= 4) {
      final mid = start.add(Duration(minutes: end.difference(start).inMinutes ~/ 2));
      r
        ..breakAt = mid
        ..resumeAt = mid.add(Duration(minutes: 30 + seed % 20));
    }
    return AttendanceRecord(o, r, late ? AttendanceStatus.late : AttendanceStatus.present);
  }

  AttendanceStatus _statusFor(Occurrence o, ClockRecord r) {
    final start = atTime(o.date, o.meeting.start, plusMinutes: 5);
    return r.inAt!.isAfter(start) ? AttendanceStatus.late : AttendanceStatus.present;
  }

  static DateTime _weekdayOnOrAfter(DateTime d, int weekday) =>
      DateUtils.addDaysToDate(DateUtils.dateOnly(d), (weekday - d.weekday) % 7);
}

const _groups = [
  'Apparel and Textiles',
  'Youth in Entrepreneurship',
  'Digital Skills & ICT',
  'Agribusiness',
  'Beauty and Cosmetology',
];

const _branches = ['Tema Central Branch', 'Accra Central Branch', 'Ashaiman Branch'];

// Fictional people. Ghanaian names, no real individuals.
const _people = [
  ('Ama Osei Bonsu', Gender.female),
  ('Kofi Boateng', Gender.male),
  ('Abena Owusu', Gender.female),
  ('Yaw Darko', Gender.male),
  ('Akosua Asantewaa', Gender.female),
  ('Kwame Agyeman', Gender.male),
  ('Efua Quaye', Gender.female),
  ('Kojo Antwi', Gender.male),
  ('Adwoa Sarpong', Gender.female),
  ('Kwabena Ofori', Gender.male),
  ('Esi Ankrah', Gender.female),
  ('Nana Yeboah', Gender.male),
  ('Afia Konadu', Gender.female),
  ('Kwaku Frimpong', Gender.male),
  ('Yaa Amponsah', Gender.female),
  ('Fiifi Mensah', Gender.male),
  ('Akua Addo', Gender.female),
  ('Selorm Agbeko', Gender.male),
  ('Dzifa Kpodo', Gender.female),
  ('Ekow Arthur', Gender.male),
  ('Naa Adjeley Tetteh', Gender.female),
  ('Nii Armah Lartey', Gender.male),
  ('Mansa Opoku', Gender.female),
  ('Kwesi Mensah', Gender.male),
  ('Delali Ahiable', Gender.female),
  ('Kobina Essien', Gender.male),
  ('Aba Wilson', Gender.female),
  ('Edem Kumah', Gender.male),
  ('Serwaa Badu', Gender.female),
  ('Paa Kwesi Amoah', Gender.male),
];

/// App-wide demo state. Replaced in tests; a page reload starts fresh.
DemoRepo repo = DemoRepo();
