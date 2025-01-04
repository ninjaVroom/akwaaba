import 'package:flutter/material.dart';

import '../data/demo_repo.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'drawer.dart';
import 'events.dart';
import 'history.dart';

enum _Filter { all, male, female, disabled }

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final _selected = <String>{};
  var _query = '';
  var _filter = _Filter.all;

  List<Member> get _visible => repo.members.where((m) {
    final q = _query.toLowerCase();
    final hit = m.name.toLowerCase().contains(q) || m.id.toLowerCase().contains(q) || m.group.toLowerCase().contains(q);
    return hit &&
        switch (_filter) {
          _Filter.all => true,
          _Filter.male => m.gender == Gender.male,
          _Filter.female => m.gender == Gender.female,
          _Filter.disabled => !m.enabled,
        };
  }).toList();

  void _toast(String s) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(s)));

  Iterable<Member> get _picked => repo.members.where((m) => _selected.contains(m.id));

  void _bulk(bool enable) {
    if (_selected.isEmpty) return _toast('Select members first');
    repo.setEnabled(_picked, enable);
    _toast('${_selected.length} selected member${_selected.length == 1 ? '' : 's'} ${enable ? 'enabled' : 'disabled'}');
    setState(_selected.clear);
  }

  Future<void> _delete() async {
    if (_selected.isEmpty) return _toast('Select members first');
    final n = _selected.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete selected members?'),
        content: Text('$n member${n == 1 ? '' : 's'} will be removed from this demo until you reload the page.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Ak.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    repo.delete(_picked);
    setState(_selected.clear);
    _toast('$n member${n == 1 ? '' : 's'} deleted');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Members')),
      body: ListenableBuilder(
        listenable: repo,
        builder: (context, _) {
          final all = repo.members;
          final visible = _visible;
          final allSelected = visible.isNotEmpty && visible.every((m) => _selected.contains(m.id));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(child: SearchField(onChanged: (v) => setState(() => _query = v))),
                  PopupMenuButton<_Filter>(
                    tooltip: 'Filter members',
                    icon: Icon(_filter == _Filter.all ? Icons.filter_alt_outlined : Icons.filter_alt, color: Ak.primary),
                    initialValue: _filter,
                    onSelected: (f) => setState(() => _filter = f),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: _Filter.all, child: Text('All members')),
                      PopupMenuItem(value: _Filter.male, child: Text('Males')),
                      PopupMenuItem(value: _Filter.female, child: Text('Females')),
                      PopupMenuItem(value: _Filter.disabled, child: Text('Disabled accounts')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Stat('Total', '${all.length}'),
                  Stat('Males', '${all.where((m) => m.gender == Gender.male).length}'),
                  Stat('Females', '${all.where((m) => m.gender == Gender.female).length}'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: allSelected,
                    onChanged: (v) => setState(() {
                      final ids = visible.map((m) => m.id);
                      v! ? _selected.addAll(ids) : _selected.removeAll(ids);
                    }),
                  ),
                  const Expanded(child: Text('Select All', maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Material(
                    color: Ak.dangerTint,
                    borderRadius: BorderRadius.circular(8),
                    child: IconButton(
                      tooltip: 'Delete selected',
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline, color: Ak.danger),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Pill('Enable', color: Ak.success, height: 36, onTap: () => _bulk(true)),
                  const SizedBox(width: 8),
                  Pill('Disable', color: Colors.black, height: 36, onTap: () => _bulk(false)),
                ],
              ),
              if (_selected.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: Text('${_selected.length} selected', style: const TextStyle(fontSize: 12, color: Ak.muted)),
                ),
              const SizedBox(height: 12),
              if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No members match.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Ak.muted),
                  ),
                ),
              for (final m in visible) ...[
                _MemberTile(
                  m,
                  selected: _selected.contains(m.id),
                  onSelect: (v) => setState(() => v ? _selected.add(m.id) : _selected.remove(m.id)),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile(this.m, {required this.selected, required this.onSelect});
  final Member m;
  final bool selected;
  final ValueChanged<bool> onSelect;

  @override
  Widget build(BuildContext context) {
    return AkCard(
      padding: const EdgeInsets.fromLTRB(4, 6, 12, 12),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MemberDetailScreen(m))),
      child: Opacity(
        opacity: m.enabled ? 1 : 0.55,
        child: Row(
          children: [
            Checkbox(value: selected, onChanged: (v) => onSelect(v!)),
            Avatar(m.initials, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ContactIcons(m),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          m.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Ak.ink),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Ak.primary),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        m.enabled ? m.id : '${m.id}, disabled',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF444444)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          m.group,
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF444444)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MemberDetailScreen extends StatelessWidget {
  const MemberDetailScreen(this.m, {super.key, this.self = false});
  final Member m;
  final bool self;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(self ? 'Profile' : 'Member Details')),
      drawer: self ? const AppDrawer(current: '/profile') : null,
      body: ListenableBuilder(
        listenable: repo,
        builder: (context, _) {
          final records = [for (var i = 0; i < 3; i++) ...repo.history(m, DateTime(repo.today.year, repo.today.month - i))];
          final present = records.where((r) => r.status != AttendanceStatus.absent).length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AkCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Avatar(m.initials, size: 88),
                    const SizedBox(height: 12),
                    Text(m.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${m.id}, ${m.group}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Ak.muted),
                    ),
                    const SizedBox(height: 8),
                    ContactIcons(m, spread: false),
                    if (!self) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Pill(
                            m.enabled ? 'Enabled ✓' : 'Enable',
                            color: Ak.success,
                            height: 36,
                            onTap: m.enabled ? null : () => repo.setEnabled([m], true),
                          ),
                          const SizedBox(width: 10),
                          Pill(
                            m.enabled ? 'Disable' : 'Disabled ✓',
                            color: Colors.black,
                            height: 36,
                            onTap: m.enabled ? () => repo.setEnabled([m], false) : null,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AkCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Profile Information', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    for (final (k, v) in [
                      ('Gender', m.gender == Gender.male ? 'Male' : 'Female'),
                      ('Phone', m.phone),
                      ('Email', m.email),
                      ('Branch', m.branch),
                      ('Account', m.enabled ? 'Active' : 'Disabled'),
                    ])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          children: [
                            Text(k, style: const TextStyle(color: Ak.muted, fontSize: 13)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                v,
                                textAlign: TextAlign.end,
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AkCard(
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Attendance Summary, last 3 months',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Stat('Sessions', '${records.length}'),
                        Stat('Present', '$present', color: Ak.success),
                        Stat('Absent', '${records.length - present}', color: Ak.danger),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: Pill(
                        'View Full Attendance Log',
                        color: Ak.neutral,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryScreen(member: self ? null : m)));
                        },
                      ),
                    ),
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
