# daad_lints

[![pub package](https://img.shields.io/pub/v/daad_lints.svg)](https://pub.dev/packages/daad_lints)

An [analyzer plugin](https://dart.dev/tools/analyzer-plugins) for Flutter apps.

| Rule | Checks | Quick fix |
|------|--------|-----------|
| `avoid_edge_insets_only` | `EdgeInsets.only`, `EdgeInsetsGeometry.only`, `.only(...)` | `EdgeInsetsDirectional.only` / `.directional(...)` |
| `avoid_alignment` | `Alignment.topLeft`, `.topLeft` | `AlignmentDirectional.topStart`, `.topStart` |
| `avoid_positioned` | `Positioned(...)` | `PositionedDirectional(...)` |
| `super_key_last` | `const A({super.key, this.a})` | `const A({this.a, super.key})` |
| `prefer_double_literals` | `SizedBox(height: 10)`, `double a = -1` | `SizedBox(height: 10.0)`, `double a = -1.0` |
| `dispose_after_build` | `dispose()` declared before `build()` in a `State` | moves `dispose()` to the end of the class |
| `field_ordering` | fields out of order | sorts them |
| `avoid_repeated_of_context` | `Theme.of(context)` twice in `build` | a local `theme` variable |
| `avoid_media_query_of` | `MediaQuery.of(context).size`, `MediaQuery.maybeOf(context)?.padding` | `MediaQuery.sizeOf(context)`, `MediaQuery.maybePaddingOf(context)` |
| `avoid_hardcoded_strings` | `Text('Hello')`, `Tooltip(message: 'Save')` | none |
| `french_no_break_space` 🥖 | `'Bonjour !'`, `'Prix : 5 €'` (regular or no space before `?` `!` `;` `:` `€`) | none |
| `french_straight_apostrophe` 🥖 | `'l’été'` (typographic apostrophe U+2019) | none |
| `french_hyphen_only` 🥖 | `'Lun — Ven'` (em dash U+2014, en dash U+2013) | none |

🥖 Only in the generated French localization files (`*_fr.dart`): fix the `.arb`, then regenerate.

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

## Rules

### `avoid_edge_insets_only`

`left` / `right` do not flip in right-to-left layouts: use `start` / `end`.

```dart
// BAD
padding: const EdgeInsets.only(left: 8.0, right: 16.0),
padding: const .only(bottom: 12.0),

// GOOD
padding: const EdgeInsetsDirectional.only(start: 8.0, end: 16.0),
padding: const .directional(bottom: 12.0),
```

Quick fix: replaces the constructor and renames the arguments.

### `avoid_alignment`

`AlignmentDirectional` follows the text direction, `Alignment` does not.

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

Not reported: `Alignment.lerp` and the centered values (`.center`, `.topCenter`, `.bottomCenter`).

Quick fix: replaces the class and the member.

### `avoid_positioned`

`PositionedDirectional` takes `start` / `end` instead of `left` / `right`.

```dart
// BAD
Positioned(left: 8.0, top: 0.0, child: child)

// GOOD
PositionedDirectional(start: 8.0, top: 0.0, child: child)
```

Not reported: `Positioned.fill`, `.directional`, `.fromRect` and `.fromRelativeRect`.

Quick fix: replaces the constructor and renames the arguments.

### `super_key_last`

`super.key` comes last.

```dart
// BAD
const MaskedValue({super.key, this.color = kPurple});

// GOOD
const MaskedValue({this.color = kPurple, super.key});
```

Not reported: `required super.key` and a positional `super.key`.

Quick fix: moves `super.key` last.

### `prefer_double_literals`

`10.0`, not `10`, where a `double` is expected.

```dart
// BAD
const SizedBox(height: 10),
double opacity = 1;

// GOOD
const SizedBox(height: 10.0),
double opacity = 1.0;
```

Disable `prefer_int_literals`: it says the opposite.

Quick fix: appends `.0`.

### `dispose_after_build`

In a `State`, `dispose()` goes after `build()`.

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

Quick fix: moves `dispose()` to the end of the class.

### `field_ordering`

Fields order: `static const` / `static final`, other `static`, `final`, then the others.

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

Quick fix: sorts the fields, when they are not mixed with other members.

### `avoid_repeated_of_context`

Each `Theme.of(context)` walks the widget tree: in `build`, read it once.

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

Not reported: calls in closures or `assert`s, and `MediaQuery` (see [`avoid_media_query_of`](#avoid_media_query_of)).

Quick fix: extracts the call into a local variable.

### `avoid_media_query_of`

`MediaQuery.of(context)` rebuilds the widget when any `MediaQuery` property changes (eg: on each frame of the keyboard animation). The dedicated accessors only depend on what they read.

```dart
// BAD
final double width = MediaQuery.of(context).size.width;
final EdgeInsets? padding = MediaQuery.maybeOf(context)?.padding;

// GOOD
final double width = MediaQuery.widthOf(context);
final EdgeInsets? padding = MediaQuery.maybePaddingOf(context);
```

Not reported: `copyWith`, `removePadding`, `removeViewInsets`, `removeViewPadding`, `removeDisplayFeatures` and `applyDisplayCornerRadii` on the result. To check that a `MediaQuery` exists, use `MediaQuery.maybeSizeOf(context) != null`.

Quick fix: replaces the call with the accessor (`.size.width` → `MediaQuery.widthOf(context)`). Not offered when the whole object is used. Without a `MediaQuery` ancestor, `textScalerOf`, `platformBrightnessOf`, `highContrastOf`, `onOffSwitchLabelsOf`, `boldTextOf` and `supportsAnnounceOf` return a default value where `MediaQuery.of` throws.

### `avoid_hardcoded_strings`

A string literal passed directly to a widget, a `TextSpan`, an `InputDecoration`, a `BottomNavigationBarItem` or a `DropdownMenuEntry` is never translated: move it to the localization files.

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

Not reported: literals without a letter (`'42'`), identifiers, paths and URLs (`user_id`, `logo.png`), technical parameters (`restorationId`, `Hero` tag), variables and constants, `'key'.tr()`, and test files.

No quick fix: it depends on your localization setup.

### 🇫🇷 `french_no_break_space`

A regular space lets the sign wrap alone to the next line.

| Sign | Expected before it | Code point |
|------|--------------------|------------|
| `?` `!` `;` | narrow no-break space | U+202F |
| `:` | no-break space | U+00A0 |
| `€` after an amount (`5 €`, `$price €`) | no-break space | U+00A0 |
| apostrophe | straight `'` | U+0027 (not U+2019) |
| dash | hyphen `-` | U+002D (not U+2014, U+2013) |

```dart
// BAD
'Bonjour !'
'Prix : 5 €'

// GOOD
'Bonjour !'
'Prix : 5 €'
```

### 🇫🇷 `french_straight_apostrophe`

One apostrophe for the whole app: the straight one.

```dart
// BAD
'l’été'

// GOOD
"l'été"
```

### 🇫🇷 `french_hyphen_only`

One dash for the whole app: the hyphen.

```dart
// BAD
'Lun — Ven'

// GOOD
'Lun-Ven'
```

## Configuration

Every rule is a `warning`, tuned in `diagnostics` (`false`, `info`, `warning`, `error`):

```yaml
plugins:
  daad_lints:
    version: ^1.0.0
    diagnostics:
      field_ordering: false
      avoid_hardcoded_strings: info
      french_no_break_space: error
```
