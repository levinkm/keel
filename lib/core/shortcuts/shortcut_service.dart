import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keel/features/settings/domain/repositories/settings_repository.dart';

class ShortcutDef {
  final String id;
  final String label;
  final String group;
  final String defaultKey;
  final String currentKey;

  const ShortcutDef({
    required this.id,
    required this.label,
    required this.group,
    required this.defaultKey,
    required this.currentKey,
  });

  factory ShortcutDef.defaults({
    required String id,
    required String label,
    required String group,
    required String defaultKey,
    String? currentKey,
  }) => ShortcutDef(
        id: id, label: label, group: group,
        defaultKey: defaultKey, currentKey: currentKey ?? defaultKey,
      );

  ShortcutDef copyWith({String? currentKey}) => ShortcutDef(
        id: id, label: label, group: group,
        defaultKey: defaultKey, currentKey: currentKey ?? this.currentKey,
      );

  SingleActivator get activator => _parse(currentKey);
  bool get isModified => currentKey != defaultKey;

  String get displayKey => _display(currentKey);
  String get defaultDisplayKey => _display(defaultKey);

  static SingleActivator _parse(String key) {
    final parts = key.toLowerCase().split('+');
    final meta = parts.contains('meta');
    final shift = parts.contains('shift');
    final alt = parts.contains('alt');
    final control = parts.contains('control');
    return SingleActivator(
      _keyFromString(parts.last),
      meta: meta, shift: shift, alt: alt, control: control,
    );
  }

  static String serialise(SingleActivator a) {
    final parts = <String>[];
    if (a.meta) parts.add('meta');
    if (a.shift) parts.add('shift');
    if (a.alt) parts.add('alt');
    if (a.control) parts.add('control');
    parts.add(_stringFromKey(a.trigger));
    return parts.join('+');
  }

  static String _display(String key) {
    final parts = key.toLowerCase().split('+');
    final buf = StringBuffer();
    if (parts.contains('meta')) buf.write('\u2318');
    if (parts.contains('shift')) buf.write('\u21e7');
    if (parts.contains('alt')) buf.write('\u2325');
    if (parts.contains('control')) buf.write('\u2303');
    final k = parts.last;
    buf.write(k.length == 1 ? k.toUpperCase() : k);
    return buf.toString();
  }

  static LogicalKeyboardKey _keyFromString(String s) => switch (s) {
    '1' => LogicalKeyboardKey.digit1,
    '2' => LogicalKeyboardKey.digit2,
    '3' => LogicalKeyboardKey.digit3,
    '4' => LogicalKeyboardKey.digit4,
    '5' => LogicalKeyboardKey.digit5,
    '6' => LogicalKeyboardKey.digit6,
    '7' => LogicalKeyboardKey.digit7,
    '8' => LogicalKeyboardKey.digit8,
    '9' => LogicalKeyboardKey.digit9,
    '0' => LogicalKeyboardKey.digit0,
    '[' => LogicalKeyboardKey.bracketLeft,
    ']' => LogicalKeyboardKey.bracketRight,
    ',' => LogicalKeyboardKey.comma,
    'q' => LogicalKeyboardKey.keyQ,
    'w' => LogicalKeyboardKey.keyW,
    'e' => LogicalKeyboardKey.keyE,
    'r' => LogicalKeyboardKey.keyR,
    't' => LogicalKeyboardKey.keyT,
    'y' => LogicalKeyboardKey.keyY,
    'u' => LogicalKeyboardKey.keyU,
    'i' => LogicalKeyboardKey.keyI,
    'o' => LogicalKeyboardKey.keyO,
    'p' => LogicalKeyboardKey.keyP,
    'a' => LogicalKeyboardKey.keyA,
    's' => LogicalKeyboardKey.keyS,
    'd' => LogicalKeyboardKey.keyD,
    'f' => LogicalKeyboardKey.keyF,
    'g' => LogicalKeyboardKey.keyG,
    'h' => LogicalKeyboardKey.keyH,
    'j' => LogicalKeyboardKey.keyJ,
    'k' => LogicalKeyboardKey.keyK,
    'l' => LogicalKeyboardKey.keyL,
    'z' => LogicalKeyboardKey.keyZ,
    'x' => LogicalKeyboardKey.keyX,
    'c' => LogicalKeyboardKey.keyC,
    'v' => LogicalKeyboardKey.keyV,
    'b' => LogicalKeyboardKey.keyB,
    'n' => LogicalKeyboardKey.keyN,
    'm' => LogicalKeyboardKey.keyM,
    _ => LogicalKeyboardKey.keyA,
  };

  static String _stringFromKey(LogicalKeyboardKey k) {
    final map = <LogicalKeyboardKey, String>{
      LogicalKeyboardKey.digit1: '1', LogicalKeyboardKey.digit2: '2',
      LogicalKeyboardKey.digit3: '3', LogicalKeyboardKey.digit4: '4',
      LogicalKeyboardKey.digit5: '5', LogicalKeyboardKey.digit6: '6',
      LogicalKeyboardKey.digit7: '7', LogicalKeyboardKey.digit8: '8',
      LogicalKeyboardKey.digit9: '9', LogicalKeyboardKey.digit0: '0',
      LogicalKeyboardKey.bracketLeft: '[', LogicalKeyboardKey.bracketRight: ']',
      LogicalKeyboardKey.comma: ',',
    };
    if (map.containsKey(k)) return map[k]!;
    final label = k.keyLabel.toLowerCase();
    return label.isNotEmpty ? label : 'a';
  }
}

class ShortcutService {
  ShortcutService._();
  static final ShortcutService instance = ShortcutService._();

  static const _prefix = 'shortcut_';

  final ValueNotifier<List<ShortcutDef>> shortcuts = ValueNotifier(_buildDefaults());

  SettingsRepository? _repo;

  static List<ShortcutDef> _buildDefaults() => [
    ShortcutDef.defaults(id: 'nav_dashboard',    label: 'Dashboard',       group: 'Navigation', defaultKey: 'meta+1'),
    ShortcutDef.defaults(id: 'nav_networth',     label: 'Net Worth',       group: 'Navigation', defaultKey: 'meta+2'),
    ShortcutDef.defaults(id: 'nav_budget',       label: 'Budget',          group: 'Navigation', defaultKey: 'meta+3'),
    ShortcutDef.defaults(id: 'nav_transactions', label: 'Transactions',    group: 'Navigation', defaultKey: 'meta+4'),
    ShortcutDef.defaults(id: 'nav_accounts',     label: 'Accounts',        group: 'Navigation', defaultKey: 'meta+5'),
    ShortcutDef.defaults(id: 'nav_income',       label: 'Income',          group: 'Navigation', defaultKey: 'meta+6'),
    ShortcutDef.defaults(id: 'nav_loans',        label: 'Loans',           group: 'Navigation', defaultKey: 'meta+7'),
    ShortcutDef.defaults(id: 'nav_projects',     label: 'Projects',        group: 'Navigation', defaultKey: 'meta+8'),
    ShortcutDef.defaults(id: 'nav_assets',       label: 'Assets',          group: 'Navigation', defaultKey: 'meta+9'),
    ShortcutDef.defaults(id: 'nav_prev',         label: 'Previous section',group: 'Navigation', defaultKey: 'meta+['),
    ShortcutDef.defaults(id: 'nav_next',         label: 'Next section',    group: 'Navigation', defaultKey: 'meta+]'),
    ShortcutDef.defaults(id: 'go_transactions',  label: 'Transactions',    group: 'Quick Jump', defaultKey: 'meta+t'),
    ShortcutDef.defaults(id: 'go_budget',        label: 'Budget',          group: 'Quick Jump', defaultKey: 'meta+b'),
    ShortcutDef.defaults(id: 'go_loans',         label: 'Loans',           group: 'Quick Jump', defaultKey: 'meta+l'),
    ShortcutDef.defaults(id: 'go_reports',       label: 'Reports',         group: 'Quick Jump', defaultKey: 'meta+shift+r'),
    ShortcutDef.defaults(id: 'go_projections',   label: 'Projections',     group: 'Quick Jump', defaultKey: 'meta+shift+j'),
    ShortcutDef.defaults(id: 'go_settings',      label: 'Settings',        group: 'Quick Jump', defaultKey: 'meta+,'),
    ShortcutDef.defaults(id: 'toggle_privacy',   label: 'Toggle privacy mode', group: 'Privacy & Security', defaultKey: 'meta+shift+p'),
    ShortcutDef.defaults(id: 'lock_app',         label: 'Lock Keel',       group: 'Privacy & Security', defaultKey: 'meta+shift+l'),
  ];

  Future<void> init(SettingsRepository repo) async {
    _repo = repo;
    final result = await repo.getAll();
    result.fold((_) {}, (all) {
      final updated = _buildDefaults().map((def) {
        final saved = all['$_prefix${def.id}'];
        return saved != null ? def.copyWith(currentKey: saved) : def;
      }).toList();
      shortcuts.value = updated;
    });
  }

  Future<void> update(String id, SingleActivator activator) async {
    final serialised = ShortcutDef.serialise(activator);
    shortcuts.value = shortcuts.value
        .map((d) => d.id == id ? d.copyWith(currentKey: serialised) : d)
        .toList();
    await _repo?.set('$_prefix$id', serialised);
  }

  Future<void> reset(String id) async {
    final def = shortcuts.value.firstWhere((d) => d.id == id);
    shortcuts.value = shortcuts.value
        .map((d) => d.id == id ? d.copyWith(currentKey: d.defaultKey) : d)
        .toList();
    await _repo?.set('$_prefix$id', def.defaultKey);
  }

  Future<void> resetAll() async {
    shortcuts.value = _buildDefaults();
    for (final d in shortcuts.value) {
      await _repo?.set('$_prefix${d.id}', d.defaultKey);
    }
  }

  ShortcutDef? find(String id) =>
      shortcuts.value.cast<ShortcutDef?>().firstWhere((d) => d?.id == id, orElse: () => null);
}
