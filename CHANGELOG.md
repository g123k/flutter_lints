## 1.0.0 (30/10/2026)

Initial release: an analyzer plugin for Dart `^3.13.2`, enabled with `plugins: daad_lints: ^1.0.0` in `analysis_options.yaml`.

Twelve rules, all enabled by default and reported as `warning`:

- `avoid_edge_insets_only`, `avoid_alignment`, `avoid_positioned`: use the directional equivalent (quick fix).
- `super_key_last`: `super.key` is the last constructor parameter (quick fix).
- `prefer_double_literals`: `10.0`, not `10`, where a `double` is expected (quick fix).
- `dispose_after_build`: `dispose()` after `build()` in a `State` (quick fix).
- `field_ordering`: `static const` / `static final`, other `static`, `final` instance, other instance fields (quick fix).
- `avoid_repeated_of_context`: one `Theme.of(context)` per `build` (quick fix).
- `avoid_hardcoded_strings`: a string literal passed to a widget, an `InlineSpan`, an `InputDecoration`, a `BottomNavigationBarItem` or a `DropdownMenuEntry` belongs in the localization files (no fix).
- `french_no_break_space`, `french_straight_apostrophe`, `french_hyphen_only`: French typography of the generated `*_fr.dart` localization files (no fix).

Escape hatches: `diagnostics: <rule>: false | info | warning | error` in the plugin section, `// ignore: daad_lints/<rule>` and `// ignore_for_file: daad_lints/<rule>`.
