# daad_lints

[![pub package](https://img.shields.io/pub/v/daad_lints.svg)](https://pub.dev/packages/daad_lints)

An [analyzer plugin](https://dart.dev/tools/analyzer-plugins) with twelve lint rules for Flutter apps and packages: directional widgets for right-to-left layouts, member ordering, repeated `of(context)` calls, French typography in the generated localization files, and hardcoded user-facing strings. Eight rules come with a quick fix, also available as "fix all in file". Every rule is reported as a `warning` and can be tuned or disabled per project.

| Rule | Checks | Quick fix |
|------|--------|-----------|
| `avoid_edge_insets_only` | `EdgeInsets.only`, `EdgeInsetsGeometry.only`, `.only(...)` | `EdgeInsetsDirectional.only` / `.directional(...)` |
| `avoid_alignment` | `Alignment(x, y)`, `Alignment.topLeft`…, `AlignmentGeometry.xy` / `.topLeft`… | `AlignmentDirectional(start, y)`, `AlignmentDirectional.topStart`…, `.directional` / `.topStart`… |
| `avoid_positioned` | `Positioned(...)` | `PositionedDirectional(...)` |
| `super_key_last` | `const A({super.key, this.a})` | `const A({this.a, super.key})` |
| `prefer_double_literals` | `SizedBox(height: 10)`, `double a = -1` | `SizedBox(height: 10.0)`, `double a = -1.0` |
| `dispose_after_build` | `dispose()` declared before `build()` in a `State` | moves `dispose()` to the end of the class |
| `field_ordering` | fields out of order | sorts them: `static const` / `static final`, other `static`, `final` instance, other instance fields |
| `avoid_repeated_of_context` | `Theme.of(context)` called twice in `build` | `final ThemeData theme = Theme.of(context);`, then `theme` |
| `avoid_hardcoded_strings` | `Text('Hello')`, `Tooltip(message: 'Save')` | none |
| `french_no_break_space` | `'Bonjour !'`, `'Prix : 5 €'` (regular or no space before `?` `!` `;` `:` `€`) | none |
| `french_straight_apostrophe` | `'l’été'` (typographic apostrophe U+2019) | none |
| `french_hyphen_only` | `'Lun — Ven'` (em dash U+2014, en dash U+2013) | none |

## Installation

Add the package to your dev dependencies:

```bash
dart pub add dev:daad_lints
```

Enable the plugin in the top-level `plugins` section of your `analysis_options.yaml`:

```yaml
plugins:
  daad_lints: ^1.0.0
```

Then restart the Dart analysis server (in VS Code: "Dart: Restart Analysis Server"; in IntelliJ / Android Studio: the Dart Analysis tool window's restart button). The analysis server caches the built plugin: restart it after any change to the `plugins` section and after a package upgrade.

- The `plugins` section is **not inherited through `include:`**: in a workspace or a melos repository, every package that should be analyzed declares its own `plugins` section.
- Analyzer plugins need Dart 3.10 or later; the package itself requires Dart `^3.13.2` (see `pubspec.yaml`).

## Rules

### `avoid_edge_insets_only`

Left and right paddings do not flip in right-to-left layouts (Arabic, Hebrew): `EdgeInsetsDirectional` uses `start` / `end` and follows the text direction.

```dart
// BAD
padding: const EdgeInsets.only(left: 8.0, right: 16.0),
padding: const .only(bottom: 12.0),

// GOOD
padding: const EdgeInsetsDirectional.only(start: 8.0, end: 16.0),
padding: const .directional(bottom: 12.0),
```

Quick fix: replaces the constructor and renames the arguments (`left` → `start`, `right` → `end`). Dot shorthands (`.only(...)`) keep their shorthand form (`.directional(...)`).

### `avoid_alignment`

`Alignment` is anchored to the left and right edges, `AlignmentDirectional` to the start and end edges.

```dart
// BAD
alignment: Alignment.topLeft,
alignment: const Alignment(-1.0, 0.0),
alignment: .topLeft,

// GOOD
alignment: AlignmentDirectional.topStart,
alignment: const AlignmentDirectional(-1.0, 0.0),
alignment: .topStart,
```

Not reported: `Alignment.lerp` (no directional equivalent) and the direction-agnostic `AlignmentGeometry` members (`.center`, `.topCenter`, `.bottomCenter`).

Quick fix: replaces the class and the member name, keeping the dot-shorthand form.

### `avoid_positioned`

`Positioned` takes `left` / `right`; `PositionedDirectional` takes `start` / `end`.

```dart
// BAD
Positioned(left: 8.0, top: 0.0, child: child)

// GOOD
PositionedDirectional(start: 8.0, top: 0.0, child: child)
```

Not reported: `Positioned.fill`, `Positioned.directional`, `Positioned.fromRect` and `Positioned.fromRelativeRect` (no directional equivalent).

Quick fix: replaces the constructor and renames the arguments.

### `super_key_last`

`super.key` always comes last, so that the parameters a reader cares about come first.

```dart
// BAD
const MaskedValue({super.key, this.color = kPurple});

// GOOD
const MaskedValue({this.color = kPurple, super.key});
```

Not reported: `required super.key` (it would conflict with `always_put_required_named_parameters_first`) and a positional `super.key`.

Quick fix: moves `super.key` to the end of the parameter list.

### `prefer_double_literals`

A `double` written as an integer literal reads like an `int`: `10.0` says what it is.

```dart
// BAD
const SizedBox(height: 10),
double opacity = 1;

// GOOD
const SizedBox(height: 10.0),
double opacity = 1.0;
```

Not reported: integer literals typed `int`, `num`, `Object` or `dynamic` (`x * 2`), and hexadecimal literals (`0x10.0` is not valid Dart).

This rule contradicts the official `prefer_int_literals` rule: keep `prefer_int_literals` disabled when this rule is on.

Quick fix: appends `.0`.

### `dispose_after_build`

In a `State`, `dispose()` reads better at the end of the class, after `build()`, mirroring the lifecycle.

```dart
// BAD
class _MyState extends State<My> {
  @override
  void dispose() { ... }

  @override
  Widget build(BuildContext context) { ... }
}

// GOOD
class _MyState extends State<My> {
  @override
  Widget build(BuildContext context) { ... }

  @override
  void dispose() { ... }
}
```

Generated files are not reported.

Quick fix: moves `dispose()` to the end of the class, with its comments and annotations.

### `field_ordering`

Fields go in this order: `static const` and `static final` fields, other `static` fields, `final` instance fields (`late final` included), then other instance fields.

```dart
// BAD
class Counter {
  Counter(this.start);

  final int start;
  static const int max = 10;
}

// GOOD
class Counter {
  Counter(this.start);

  static const int max = 10;

  final int start;
}
```

Not reported: the position of the fields relative to the constructor and the methods; generated files.

Quick fix: sorts the fields. Not offered when the fields are mixed with other members (methods, getters, constructors): move them together first.

### `avoid_repeated_of_context`

Each `Theme.of(context)` (or any static `of` / `maybeOf`) walks the widget tree again: in `build`, read it once into a local variable.

```dart
// BAD
Widget build(BuildContext context) {
  final Color primary = Theme.of(context).primaryColor;
  final TextStyle? body = Theme.of(context).textTheme.bodyMedium;
  ...
}

// GOOD
Widget build(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  final Color primary = theme.primaryColor;
  final TextStyle? body = theme.textTheme.bodyMedium;
  ...
}
```

Not reported: accessors other than `of` / `maybeOf` (`MediaQuery.sizeOf`), calls using another context (a nested `Builder`'s), calls inside closures or `assert`s (they do not run on each build), and generated files. Each repeated call is reported, with the others as context messages.

Quick fix: extracts the call into a local variable at the top of `build`. Not offered for an expression-bodied `build` (`=> ...`), or when the variable name is already used in `build`.

### `avoid_hardcoded_strings`

User-facing text belongs in the localization files: a string literal written in a widget constructor is never translated, and the French typography rules cannot check it.

The rule reports a string literal (simple, adjacent, raw or interpolated) passed **directly** to the constructor of:

- a Flutter `Widget` (any subclass, your own widgets and third-party ones included);
- an `InlineSpan` (`TextSpan`…);
- `InputDecoration`, `BottomNavigationBarItem` and `DropdownMenuEntry`, which are not widgets but hold user-visible strings.

Only the arguments of a parameter declared `String` or `String?` are considered: a generic `T value` (`DropdownMenuItem<String>(value: 'us')`) or an `Object tag` (`Hero(tag: 'avatar')`) is not. The technical `String` parameters are skipped by name: `restorationId`, `identifier` (`Semantics`) and `semanticsIdentifier` (`Text`) on any class, since app widgets forward them; `name`, `package` (`Image.asset`) and `src` (`Image.network`) on Flutter's own classes only, so your `ProfileHeader(name: 'Guest')` is still reported. `semanticsLabel` / `semanticLabel` are reported: screen readers read them.

A literal without any letter (`'42'`, `''`, `' - '`, `'v1.2.3'`) is not reported. A literal with no whitespace is treated as an identifier, a path, a URL or a file name, and not reported, when it contains `_`, a `/` `:` `#` followed by a non-space character, or a `.` between two letters or digits (`user_id`, `a/b`, `https://example.com`, `#tag`, `logo.png`).

```dart
// BAD
Text('Hello')
Text('Hello $name')
Tooltip(message: 'Save', child: icon)
TextField(decoration: InputDecoration(hintText: 'Email'))
MyButton(label: 'Save')
Text('Close', semanticsLabel: 'Close dialog')  // two diagnostics

// GOOD
Text(context.l10n.hello)
Text(AppLocalizations.of(context).hello)
Text('hello').tr()                              // easy_localization
Text('42')
Image.asset('assets/logo.png')
Hero(tag: 'avatar', child: avatar)
Text(title)
```

Not reported: a string that comes from a variable, a constant, a concatenation (`'Hello ' + name`), a method call (`'hello'.toUpperCase()`) or a constructor default value (`{this.label = 'Save'}`), a `Text('key').tr()` / `.plural()` call (easy_localization translates it in place), a nested widget's own literal (`ElevatedButton(child: Text('OK'))` reports the `Text` only), generated files, and test files (`test/`, `integration_test/`, `test_driver/`, `testing/`, or any `*_test.dart`).

Accepted false negatives: `'e.g.'` (a `.` between two letters) and other dotted abbreviations. Accepted false positives: `'OK'`, `'Yes'` and English brand names are reported like any other word.

No quick fix: extracting the string depends on the project's localization setup. Use `context.l10n.key` / `AppLocalizations.of(context).key` with `flutter gen-l10n`, or `'key'.tr()` with easy_localization.

### `french_no_break_space`

French typography puts a narrow no-break space (U+202F) before `?` `!` `;`, and a no-break space (U+00A0) before `:` and before `€` after an amount. A regular space lets the sign wrap to the next line alone.

```dart
// BAD
'Bonjour !'
'Prix : 5 €'

// GOOD
'Bonjour !'
'Prix : 5 €'
```

Not reported: a sign followed by a letter, a digit, `/` or `=` (`HH:mm`, `10:30`, `https://…`, `?param=value`, `!=`), a sign at the start of a string (`'?'`, `': '`, separators joined at runtime), a `:` ending a string right before a placeholder (`'$h:$m'`, `'Total :$amount'`), the second sign of `?!` / `!!!`, and `€` not preceded by an amount (`'€'`, `'Prix en €'`, `'5 k€'`). Regional French files (`*_fr_CA.dart`, `super('fr_CA')`) are skipped: their spacing rules differ.

Known false positives, accepted: `:)`, HTML entities (`&nbsp;!`), number patterns (`#,##0.00 €`), English brand names (`Yahoo!`).

No quick fix: see [French texts](#french-texts).

### `french_straight_apostrophe`

The typographic apostrophe (U+2019) and the straight one (U+0027) look alike and get mixed in the same app: this rule standardizes on the straight apostrophe.

```dart
// BAD
'l’été'

// GOOD
"l'été"
```

No quick fix: see [French texts](#french-texts).

### `french_hyphen_only`

Em dashes (U+2014) and en dashes (U+2013) get mixed with hyphens in the same app: this rule standardizes on the hyphen.

```dart
// BAD
'Lun — Ven'

// GOOD
'Lun-Ven'
```

Not reported: the non-breaking hyphen (U+2011) and the minus sign (U+2212). A lone `'—'` placeholder is an accepted false positive.

No quick fix: see [French texts](#french-texts).

## Configuration

Every rule is enabled by default and reported as a `warning`. Rules are tuned in the `diagnostics` map of the plugin's section. `true` / `false` is the form documented on dart.dev; `info` / `warning` / `error` are supported by the analyzer today (not yet documented on dart.dev; tested with Dart 3.13):

```yaml
plugins:
  daad_lints:
    version: ^1.0.0
    diagnostics:
      field_ordering: false
      avoid_hardcoded_strings: info
      french_no_break_space: error
```

A diagnostic can be ignored in place, with the plugin name as prefix:

```dart
// ignore: daad_lints/avoid_hardcoded_strings
Text('Hello')
```

Or for a whole file: `// ignore_for_file: daad_lints/avoid_hardcoded_strings`.

`prefer_int_literals` must stay disabled when `prefer_double_literals` is on: the two contradict each other.

### Adopting on an existing app

`flutter analyze` treats warnings as fatal, and a large app gets one `avoid_hardcoded_strings` warning per hardcoded string. To adopt gradually:

- start with `avoid_hardcoded_strings: info` (or `false`), and promote it to `warning` once the screens are migrated;
- exclude the widgetbook, stories and debug screens with `analyzer: exclude:` (`lib/widgetbook/**`);
- put `// ignore_for_file: daad_lints/avoid_hardcoded_strings` at the top of a screen under migration;
- a design-system package with English defaults disables the rule in its own `plugins` section.

Per-rule path exclusions are not supported.

## French texts

The three `french_*` rules check the French typography of the **generated per-locale localization files**: any `*_fr.dart` or `*_fr_<REGION>.dart` file, with a two-letter or three-digit region (`app_localizations_fr.dart` from `flutter gen-l10n`, `messages_fr.dart` / `messages_fr_FR.dart` from `intl_utils` / `intl_translation`, hand-written ones included).
The `.arb` files are the source of truth, but an analyzer plugin only sees Dart files: fix the string in the `.arb` file, then regenerate (`flutter gen-l10n`). There is no quick fix, the generated file would be overwritten.
Not supported: slang's `*.g.dart` output and runtime JSON loaders (the strings never reach a Dart file).

Prerequisites:

- The generated files must live under `lib/` (gen-l10n `synthetic-package: false`, the current default): a `.dart_tool/` output is never analyzed.
- When the generated files are gitignored, generate them before `dart analyze` in CI.
- Do not exclude them: `analyzer: exclude: [lib/l10n/**]` or `lib/generated/**` silences the rules without any error.
- A `plugins:` section is not inherited through `include:`: each package owning `.arb` files needs its own.

| Sign | Expected before it | Code point |
|------|--------------------|------------|
| `?` `!` `;` | narrow no-break space | U+202F |
| `:` | no-break space | U+00A0 |
| `€` after an amount (`5 €`, `$price €`) | no-break space | U+00A0 |
| apostrophe | straight `'` | U+0027 (not U+2019) |
| dash | hyphen `-` | U+002D (not U+2014, U+2013) |

Regional French (`fr_CA`, `fr_CH`…) has its own spacing rules: `french_no_break_space` skips the `*_fr_CA.dart` files and the gen-l10n regional classes (`super('fr_CA')`) of a `_fr.dart` file. `fr` and `fr_FR` are checked. The apostrophe and hyphen rules apply everywhere.

In the `.arb` file, type the characters as JSON escapes: `"hello": "Bonjour {name} !"`, `"price": "Prix : {amount} €"` (the generator decodes them).
With gen-l10n's `use-escaping: true`, a straight `'` must be doubled in the `.arb` (`"l''été"`).
In VS Code, `editor.unicodeHighlight.invisibleCharacters` shows the no-break spaces; the diagnostic message names the found character anyway, as U+00A0 and U+202F look identical.

Adoption: the rules are enabled by default, and can turn CI red on a large `_fr.dart` file. Lower a severity or disable a rule in the `plugins` section:

```yaml
plugins:
  daad_lints:
    version: ^1.0.0
    diagnostics:
      french_no_break_space: info
      french_hyphen_only: false
```

Or ignore a rule in the generated files through gen-l10n's `header` option in `l10n.yaml`: `header: "// ignore_for_file: daad_lints/french_no_break_space"`.

## Troubleshooting

- **The quick fixes do not run with `dart fix`**: `dart fix` does not run plugin fixes. Apply them from the IDE, as a quick fix or "fix all in file".
- **A change has no effect**: the analysis server caches the built plugin. Restart it after any change to the `plugins` section and after upgrading the package.
- **No diagnostic at all**: the plugin did not load. Check the Dart SDK (`^3.13.2`), restart the analysis server, then open the analyzer diagnostics page (VS Code: "Dart: Open Analyzer Diagnostics") for the plugin's error.
- **`avoid_hardcoded_strings` misses a string**: it only looks at literals written directly in a constructor call. Variables, constants, concatenations, method results and default values are never followed.

## Development

```bash
dart test                      # the rule tests (analyzer_testing)
dart analyze lib test          # static analysis of the plugin
cd example && dart analyze     # the plugin diagnostics on the sample app
dart pub publish --dry-run     # the pub.dev checks
```

- The plugin entry point is `lib/main.dart` (the top-level `plugin` variable). Rules live in `lib/src/rules`, quick fixes in `lib/src/fixes`.
- The `example` app enables the plugin from the local path: run `dart analyze` inside it to see every rule reported at least once. It is a Flutter app, and `dart pub get` at the root resolves it too: the Flutter SDK is needed to work on the repository, even though the plugin itself only depends on `analyzer`.
- `print` does not work inside a plugin: write to a log file, or check the analyzer diagnostics page when the plugin crashes.
- Coding agents and contributors adding a rule: see `AGENTS.md`.
