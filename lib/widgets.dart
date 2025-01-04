import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/models.dart';
import 'theme.dart';

// ---- Formatting ---------------------------------------------------------------

String fmtTime(DateTime? t) => t == null ? 'N/A' : DateFormat('h:mm a').format(t);
String fmtTod(TimeOfDay t) => DateFormat('h:mm a').format(DateTime(2000, 1, 1, t.hour, t.minute));
String fmtDate(DateTime d) => DateFormat('EEE, MMM d, y').format(d);

// ---- Brand --------------------------------------------------------------------

/// The supplied Akwaaba pin (assets/img/logo.png, cropped to the pin).
class AkLogo extends StatelessWidget {
  const AkLogo({super.key, this.size = 96});
  final double size;

  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/img/logo.png', width: size, height: size * 1.26, semanticLabel: 'Akwaaba logo');
}

/// Pin, wordmark and slogan, from the supplied full logo.
class Brand extends StatelessWidget {
  const Brand({super.key, this.logo = 96});
  final double logo;

  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/img/logo_full.png', height: logo * 1.9, semanticLabel: "Akwaaba, Let's Go Digital");
}

class DemoFooter extends StatelessWidget {
  const DemoFooter({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 20),
    child: Text(
      'Portfolio reconstruction, demo data only',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12, color: Ak.muted),
    ),
  );
}

// ---- Surfaces -------------------------------------------------------------------

class AkCard extends StatelessWidget {
  const AkCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.color});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: color ?? Ak.surface, borderRadius: BorderRadius.circular(Ak.radius), boxShadow: Ak.shadow),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(Ak.radius),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, required this.color, this.onTap, this.textColor = Colors.white, this.height = 44});
  final String label;
  final Color color, textColor;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          disabledBackgroundColor: const Color(0xFFBDBDBD),
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          minimumSize: const Size(48, 36),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// The orange, black-text, 12px-radius button from the auth screens.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton(this.label, {super.key, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 50,
    child: FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: Ak.primary,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    ),
  );
}

class Avatar extends StatelessWidget {
  const Avatar(this.initials, {super.key, this.size = 56});
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: const BoxDecoration(color: Ak.tint, shape: BoxShape.circle),
    child: Text(
      initials,
      style: TextStyle(fontSize: size * 0.3, fontWeight: FontWeight.w700, color: Ak.primary),
    ),
  );
}

/// Icon + text on the left, text (optionally with icon) on the right. The core row of every card.
class MetaRow extends StatelessWidget {
  const MetaRow({super.key, this.icon, required this.left, this.right, this.rightIcon, this.style});
  final IconData? icon, rightIcon;
  final String left;
  final String? right;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final s = style ?? const TextStyle(fontSize: 13, color: Ak.muted);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: Ak.primary), const SizedBox(width: 6)],
          Expanded(
            child: Text(left, style: s, overflow: TextOverflow.ellipsis),
          ),
          if (right != null) ...[
            if (rightIcon != null) ...[Icon(rightIcon, size: 16, color: Ak.primary), const SizedBox(width: 6)],
            Text(right!, style: s),
          ],
        ],
      ),
    );
  }
}

/// Title, date, times, span and recurrence: shared by Home, Events and Agenda.
class MeetingHeader extends StatelessWidget {
  const MeetingHeader(this.o, {super.key, this.showVenue = false});
  final Occurrence o;
  final bool showVenue;

  @override
  Widget build(BuildContext context) {
    final m = o.meeting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          m.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Ak.ink),
        ),
        const SizedBox(height: 6),
        MetaRow(icon: Icons.calendar_month_outlined, left: fmtDate(o.date), right: 'Span: ${m.spanDays} Day(s)'),
        MetaRow(
          icon: Icons.alarm,
          left: '${fmtTod(m.start)} – ${fmtTod(m.end)}',
          right: m.weekly ? 'Recurring Weekly' : 'Non-Recurring',
        ),
        if (showVenue) MetaRow(icon: Icons.place_outlined, left: m.venue),
      ],
    );
  }
}

class Stat extends StatelessWidget {
  const Stat(this.label, this.value, {super.key, this.color = Ak.ink});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Ak.ink),
        ),
      ],
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
    child: Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Ak.ink),
    ),
  );
}

// ---- Contact ------------------------------------------------------------------

class ContactIcons extends StatelessWidget {
  const ContactIcons(this.m, {super.key, this.spread = true});
  final Member m;
  final bool spread;

  @override
  Widget build(BuildContext context) {
    final digits = m.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final buttons = [
      _icon(Icons.mark_email_unread_outlined, Ak.primary, 'Email ${m.name}', Uri(scheme: 'mailto', path: m.email)),
      _icon(Icons.call_outlined, Ak.link, 'Call ${m.name}', Uri(scheme: 'tel', path: m.phone.replaceAll(' ', ''))),
      _icon(Icons.chat_outlined, Ak.whatsapp, 'WhatsApp ${m.name}', Uri.parse('https://wa.me/$digits')),
    ];
    return Row(
      mainAxisAlignment: spread ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
      children: spread
          ? buttons
          : [for (final b in buttons) Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: b)],
    );
  }

  Widget _icon(IconData i, Color c, String tip, Uri uri) => IconButton(
    tooltip: tip,
    visualDensity: VisualDensity.compact,
    icon: Icon(i, color: c, size: 22),
    onPressed: () => launchUrl(uri),
  );
}

// ---- Auth form ------------------------------------------------------------------

class AuthField extends StatelessWidget {
  const AuthField({super.key, required this.icon, required this.hint, this.obscure = false, this.controller, this.keyboard});
  final IconData icon;
  final String hint;
  final bool obscure;
  final TextEditingController? controller;
  final TextInputType? keyboard;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Icon(icon, color: Ak.primary, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboard,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF666666))),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Ak.primary, width: 2)),
            ),
          ),
        ),
      ],
    ),
  );
}

/// White top with the brand, dark rounded card at the bottom. Login, sign up, forgot password.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.card, this.logo = 96, this.back = false});
  final Widget card;
  final double logo;
  final bool back;

  @override
  Widget build(BuildContext context) {
    // No AppBar here, so set dark status-bar icons ourselves (they were white on white).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, c) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: back ? const BackButton(color: Colors.black) : const SizedBox(height: 48),
                      ),
                      Brand(logo: logo),
                      const SizedBox(height: 28),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                          decoration: const BoxDecoration(
                            color: Ak.dark,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          child: card,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TextLinkRow extends StatelessWidget {
  const TextLinkRow(this.lead, this.link, this.onTap, {super.key});
  final String lead, link;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(lead, style: const TextStyle(color: Ak.lightText, fontSize: 15)),
      TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(foregroundColor: Ak.primary, padding: const EdgeInsets.symmetric(horizontal: 4)),
        child: Text(link, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    ],
  );
}

// ---- Confirmation ----------------------------------------------------------------

/// The single-card result screen from the Figma set (outside premises, reset requested, account preview).
class ConfirmScreen extends StatelessWidget {
  const ConfirmScreen({
    super.key,
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
    this.icon = Icons.check,
  });
  final String title, body, action;
  final VoidCallback onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: AkCard(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Column(
              children: [
                Icon(icon, size: 36, color: Ak.primary),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Ak.muted, height: 1.4),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: Pill(action, color: Ak.primary, textColor: Colors.black, onTap: onAction),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
