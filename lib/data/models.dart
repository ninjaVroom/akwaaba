import 'package:flutter/material.dart';

enum Role { member, admin }

enum Gender { male, female }

enum MeetingType { event, meeting }

enum ClockStage { idle, clockedIn, onBreak, resumed, clockedOut }

enum AttendanceStatus { present, late, absent }

class Member {
  Member({
    required this.id,
    required this.name,
    required this.gender,
    required this.phone,
    required this.group,
    required this.branch,
    this.enabled = true,
  });

  final String id, name, phone, group, branch;
  final Gender gender;
  bool enabled;

  String get initials => name.split(' ').where((p) => p.isNotEmpty).take(2).map((p) => p[0]).join();
  String get email => '${name.split(' ').first.toLowerCase()}.${name.split(' ').last.toLowerCase()}@example.com';
}

class AgendaItem {
  const AgendaItem(this.time, this.title, this.note);
  final TimeOfDay time;
  final String title, note;
}

class Meeting {
  const Meeting({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.start,
    required this.end,
    this.spanDays = 1,
    this.weekly = false,
    this.venue = 'Tema Innovation Hub',
    this.agenda = const [],
  });

  final String id, title, venue;
  final MeetingType type;

  /// First occurrence. For weekly meetings only the weekday matters.
  final DateTime date;
  final TimeOfDay start, end;
  final int spanDays;
  final bool weekly;
  final List<AgendaItem> agenda;

  bool occursOn(DateTime day) {
    final d = DateUtils.dateOnly(day);
    if (weekly) return d.weekday == date.weekday && !d.isBefore(DateUtils.dateOnly(date));
    final first = DateUtils.dateOnly(date);
    return !d.isBefore(first) && d.isBefore(DateUtils.addDaysToDate(first, spanDays));
  }
}

/// Wall-clock time on a day. Built from parts, so it stays right on daylight-saving change days.
DateTime atTime(DateTime day, TimeOfDay t, {int plusMinutes = 0}) =>
    DateTime(day.year, day.month, day.day, t.hour, t.minute + plusMinutes);

/// One concrete date of a meeting (a weekly meeting has many).
class Occurrence {
  const Occurrence(this.meeting, this.date);
  final Meeting meeting;
  final DateTime date;
  String get key => '${meeting.id}@${date.toIso8601String().substring(0, 10)}';
}

class ClockRecord {
  DateTime? inAt, breakAt, resumeAt, outAt;

  ClockStage get stage => outAt != null
      ? ClockStage.clockedOut
      : resumeAt != null
      ? ClockStage.resumed
      : breakAt != null
      ? ClockStage.onBreak
      : inAt != null
      ? ClockStage.clockedIn
      : ClockStage.idle;

  /// The state machine: idle → in → break → resumed → out. Returns false once finished.
  bool advance(DateTime now) {
    switch (stage) {
      case ClockStage.idle:
        inAt = now;
      case ClockStage.clockedIn:
        breakAt = now;
      case ClockStage.onBreak:
        resumeAt = now;
      case ClockStage.resumed:
        outAt = now;
      case ClockStage.clockedOut:
        return false;
    }
    return true;
  }

  /// Clock out straight from "in" without taking a break.
  void clockOut(DateTime now) {
    if (inAt != null && outAt == null && stage != ClockStage.onBreak) outAt = now;
  }
}

class AttendanceRecord {
  const AttendanceRecord(this.occurrence, this.clock, this.status);
  final Occurrence occurrence;
  final ClockRecord clock;
  final AttendanceStatus status;
}
