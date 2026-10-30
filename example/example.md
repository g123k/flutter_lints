# daad_lints example

The `example/` app enables the plugin and reports every rule at least once: run `dart analyze` inside it to see them. In your own project, the `analysis_options.yaml` is:

```yaml
include: package:flutter_lints/flutter.yaml

plugins:
  daad_lints: ^1.0.0
```

## What the rules report

A hardcoded user-facing string (`lib/main.dart`):

```dart
Text('Hello')
```

```text
warning - lib/main.dart:91:20 - Hardcoded string passed to 'Text'. Try using a localized string instead. - avoid_hardcoded_strings
```

A non-directional padding, fixed from the IDE (`lib/main.dart`):

```dart
Padding(padding: EdgeInsets.only(top: 18.0, left: 10.0, right: 11.0), child: child)
```

```text
warning - lib/main.dart:24:20 - Avoid 'EdgeInsets.only', use 'EdgeInsetsDirectional.only' instead. Try replacing with 'EdgeInsetsDirectional.only' ('left' becomes 'start' and 'right' becomes 'end'). - avoid_edge_insets_only
```

A French typography error in a generated localization file (`lib/l10n/app_localizations_fr.dart`):

```dart
String hello(String name) => 'Bonjour $name !';
```

```text
warning - lib/l10n/app_localizations_fr.dart:13:46 - '!' must be preceded by a narrow no-break space (U+202F), found a regular space (U+0020). Fix the string in the .arb source file and regenerate (a generated file is overwritten), or here when the file is hand-written. - french_no_break_space
```

Every rule, with its BAD / GOOD snippets and what it does not report, is documented in the [README](https://pub.dev/packages/daad_lints#rules).
