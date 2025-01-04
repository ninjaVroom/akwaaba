import 'dart:async';

import 'package:flutter/material.dart';

import '../data/demo_repo.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Colors.white,
    body: Center(child: Brand(logo: 120)),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Pre-filled for reviewers; any credentials are accepted.
  final _user = TextEditingController(text: 'kwesi.mensah@example.com');
  final _pass = TextEditingController(text: 'demo1234');
  Role _role = repo.role;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      card: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RoleTabs(value: _role, onChanged: (r) => setState(() => _role = r)),
          const SizedBox(height: 28),
          AuthField(icon: Icons.person, hint: 'Email or Phone', controller: _user, keyboard: TextInputType.emailAddress),
          AuthField(icon: Icons.lock, hint: 'Password', obscure: true, controller: _pass),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/forgot'),
              style: TextButton.styleFrom(foregroundColor: Ak.link),
              child: const Text('Forgot Password ?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            'Login',
            onTap: () {
              repo.role = _role;
              Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
            },
          ),
          const SizedBox(height: 16),
          TextLinkRow("Don't have an account?", 'Sign up now', () => Navigator.pushNamed(context, '/signup')),
        ],
      ),
    );
  }
}

class _RoleTabs extends StatelessWidget {
  const _RoleTabs({required this.value, required this.onChanged});
  final Role value;
  final ValueChanged<Role> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(Role r, String label) {
      final on = r == value;
      return Expanded(
        child: Semantics(
          selected: on,
          button: true,
          child: Material(
            color: on ? Ak.tab : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onChanged(r),
              child: SizedBox(
                height: 48,
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: on ? Ak.primary : Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(children: [tab(Role.member, 'Member'), const SizedBox(width: 12), tab(Role.admin, 'Admin')]);
  }
}

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      logo: 64,
      back: true,
      card: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Create Account',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Join your organisation on Akwaaba',
            textAlign: TextAlign.center,
            style: TextStyle(color: Ak.lightText, fontSize: 13),
          ),
          const SizedBox(height: 16),
          const AuthField(icon: Icons.person, hint: 'Full Name'),
          const AuthField(icon: Icons.apartment, hint: 'Organisation Code (e.g. HYC)'),
          const AuthField(icon: Icons.phone, hint: 'Phone Number (+233 ...)', keyboard: TextInputType.phone),
          const AuthField(icon: Icons.email, hint: 'Email Address', keyboard: TextInputType.emailAddress),
          const AuthField(icon: Icons.lock, hint: 'Password', obscure: true),
          const AuthField(icon: Icons.lock, hint: 'Confirm Password', obscure: true),
          const SizedBox(height: 12),
          PrimaryButton(
            'Sign Up',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConfirmScreen(
                    title: 'Account preview',
                    body: 'Demo only. No account was created.\nUse Login to explore the member flow.',
                    action: 'Back to Login',
                    onAction: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          TextLinkRow('Already have an account?', 'Login', () => Navigator.pop(context)),
        ],
      ),
    );
  }
}

class ForgotScreen extends StatelessWidget {
  const ForgotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      back: true,
      card: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Forgot Password ?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          const Text(
            'Enter your registered email or phone number (+233) and we will send you a code to reset your password.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFBDBDBD), fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 28),
          const AuthField(icon: Icons.mail, hint: 'Email or Phone'),
          const SizedBox(height: 20),
          PrimaryButton(
            'Send Reset Code',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConfirmScreen(
                    title: 'Reset code requested',
                    body: 'Demo only. No code was sent.\nUse Login to continue exploring.',
                    action: 'Back to Login',
                    onAction: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          TextLinkRow('Remember your password?', 'Back to Login', () => Navigator.pop(context)),
        ],
      ),
    );
  }
}
