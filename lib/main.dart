import 'package:flutter/material.dart';

import 'data/demo_repo.dart';
import 'screens/auth.dart';
import 'screens/events.dart';
import 'screens/history.dart';
import 'screens/home.dart';
import 'screens/kiosk.dart';
import 'screens/members.dart';
import 'theme.dart';

void main() => runApp(const AkwaabaApp());

class AkwaabaApp extends StatelessWidget {
  const AkwaabaApp({super.key, this.initialRoute = '/'});
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Akwaaba (reconstruction)',
      debugShowCheckedModeBanner: false,
      theme: akTheme(),
      initialRoute: initialRoute,
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignUpScreen(),
        '/forgot': (_) => const ForgotScreen(),
        '/home': (_) => const HomeScreen(),
        '/events': (_) => const EventsScreen(),
        '/history': (_) => const HistoryScreen(),
        '/members': (_) => const MembersScreen(),
        '/kiosk': (_) => const KioskScreen(),
        '/profile': (_) => MemberDetailScreen(repo.me, self: true),
      },
      builder: (context, child) => PhoneFrame(child: child!),
    );
  }
}

/// On wide screens (the web build) the app sits in a 390×844 phone with a caption beside it.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.size.width < 600) return child;

    final h = (mq.size.height - 48).clamp(560.0, 844.0);
    final phone = Container(
      width: 390 + 20,
      height: h + 20,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFF1B1B1B), borderRadius: BorderRadius.circular(48)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(38),
        child: MediaQuery(
          data: mq.copyWith(
            size: Size(390, h),
            padding: const EdgeInsets.only(top: 24),
            viewPadding: const EdgeInsets.only(top: 24),
          ),
          child: child,
        ),
      ),
    );

    return ColoredBox(
      color: const Color(0xFF1F2235),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8A04C), Color(0xFF1F2235)],
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              phone,
              if (mq.size.width >= 1000) ...[
                const SizedBox(width: 56),
                const SizedBox(
                  width: 340,
                  child: DefaultTextStyle(
                    style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Akwaaba', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, height: 1.1)),
                        SizedBox(height: 12),
                        Text('A reconstruction of the HR and attendance app I built in Flutter in 2022–23.'),
                        SizedBox(height: 12),
                        Text(
                          'Log in as Member or Admin with any details. Clock in, take a break, browse meetings, '
                          'manage members and try the shared kiosk.',
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Demo data only. Fictional organisation and people.',
                          style: TextStyle(color: Color(0xFFDDDDDD), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
