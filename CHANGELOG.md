## 1.3.0 (21/11/2026)

### Added

- `prefer_explicit_call`: reports a call to a function value (a callback, a function-typed variable, field or getter) written without `.call`: `onChanged(value)` is written `onChanged.call(value)` (quick fix). Enabled by default: upgrading reports new warnings, which fail CI runs using `--fatal-warnings` until fixed, ignored or disabled (`diagnostics: prefer_explicit_call: false`).
  - Migration: a Flutter codebase gets one warning per callback call, and `dart fix` does not run plugin fixes, so the fix goes through "fix all in file", file by file.

## 1.2.0 (21/11/2026)

### Added

- `prefer_ellipsis_character`: reports three dots (`...`) in a string literal, to be written as the ellipsis character `…` (U+2026) (quick fix). Enabled by default: upgrading reports new warnings, which fail CI runs using `--fatal-warnings` until fixed, ignored or disabled (`diagnostics: prefer_ellipsis_character: false`).

### Changed

- Files with an intl `code generated via` header (the `messages_*.dart` files of intl / intl_utils) are now treated as generated: the rules that skip generated files no longer report them.

## 1.1.0 (31/10/2026)

### Added

- `avoid_media_query_of`: `MediaQuery.of(context)` / `MediaQuery.maybeOf(context)` rebuild the widget when any `MediaQueryData` property changes; use the dedicated accessor (`MediaQuery.sizeOf`, `MediaQuery.maybePaddingOf`...) (quick fix). Enabled by default: upgrading reports new warnings, which fail CI runs using `--fatal-warnings` until fixed, ignored or disabled (`diagnostics: avoid_media_query_of: false`).

### Changed

- `avoid_repeated_of_context` no longer reports `MediaQuery.of` / `maybeOf`, left to `avoid_media_query_of`: the `// ignore: daad_lints/avoid_repeated_of_context` comments on them become unnecessary. With `avoid_media_query_of` disabled, repeated `MediaQuery.of` calls are reported by neither rule.

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
