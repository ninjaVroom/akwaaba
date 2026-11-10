# Akwaaba

Samuel Vroom

A Flutter attendance and membership demo. Members clock in, take breaks and check their attendance history. Administrators manage members and use a shared clocking kiosk.

## Case study

Attendance records had to agree across several screens. Clocking in on the home screen needed to appear at the kiosk. A break needed to count as part of the same session. The app keeps those actions in one clock record, with a fixed sequence from clock-in to clock-out.

The member view shows meetings, upcoming events and monthly attendance. The administrator view adds member search, account controls and the public kiosk. Both views use the same in-memory repository. The organisation and people are fictional.

Recurring meetings are expanded into dated occurrences. Historical attendance is generated from the member and occurrence IDs, so the same record returns the same result after a restart. The tests check that behaviour, along with clock transitions, the simulated location boundary and the administrator flow.

This is a reconstruction and a working interface demo. Sign-in accepts demo details; the location check is a switch, and state resets when the app reloads. There is no connected attendance server or production authentication.

## Run locally

Install Flutter with Dart compatible with `pubspec.yaml`.

```sh
flutter pub get
flutter run -d chrome
flutter test
```

Choose Member or Admin on the login screen and use any details. Try clocking in, taking a break, opening attendance history and finding the same record in Public Clocking. On a wide screen, the demo sits inside a phone frame.

## Source

`lib/data/` holds the models and demo repository. `lib/screens/` holds the member, administrator and kiosk screens. `test/` contains the existing unit and widget checks. Platform folders and the assets needed to run the app are included.

## Prototype

Figma prototype link pending.
