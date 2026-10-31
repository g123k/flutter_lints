# AGENTS.md

This file guides coding agents working in this repository.

## Project overview

`daad_lints` is an [analyzer plugin](https://dart.dev/tools/analyzer-plugins) (`lib/main.dart`) published on pub.dev, with custom Flutter lint rules and their quick fixes. Client projects enable it in the top-level `plugins:` section of their `analysis_options.yaml` (see `README.md`). It ships no lint set: adopters keep their own.

The minimum SDK is the one in `pubspec.yaml` (currently Dart `^3.13.2`). The package itself only depends on `analyzer`, but `example/` is a Flutter app: `dart pub get` at the root resolves it too, so the Flutter SDK (with its Dart SDK) is needed to work on the repository.

## Commands

```bash
dart test                                            # the rule tests (analyzer_testing) and the utility tests
dart analyze lib test                                # static analysis of the plugin
dart format lib test                                 # formatting
cd example && dart analyze                           # the plugin diagnostics on a sample app
dart pub publish --dry-run                           # the pub.dev checks (LICENSE, description, example, file list)
```

`.github/workflows/ci.yml` runs them on every push and pull request, plus a job on the newest resolvable dependencies (`dart pub upgrade`), because the test base imports private files of `analyzer_plugin` and `analyzer_testing` (see `test/utils/rule_tester.dart` below).

- Rule tests use [`analyzer_testing`](https://pub.dev/packages/analyzer_testing) and `test_reflective_loader`: test methods must start with `test_`. The pure utilities of `lib/src/utils` have plain `test()` unit tests in `test/utils/*_test.dart`, and `test/example_test.dart` analyzes `example/` with the real Flutter SDK (skipped when `flutter` is not on the PATH).
- `example/` reports diagnostics on purpose: each rule has at least one triggering case there.
- The analysis server caches the built plugin: restart it (or the IDE's Dart analysis server) before trusting the result in `example/`, and after any change to a `plugins:` section.
- `dart fix` does not run the plugin fixes: they are only applied from the IDE (quick fix or "fix all in file").
- `print` does not work inside a plugin: write to a log file, or check the analyzer diagnostics pages when the plugin crashes.

## Architecture

- `lib/main.dart`: the entry point (the top-level `plugin` variable). Every rule is registered there with `registry.registerWarningRule` (enabled by default, unlike `registerLintRule`), and its fix with `registry.registerFixForRule` (the French typography rules and `avoid_hardcoded_strings` have no fix).
- `lib/src/rules`: one `AnalysisRule` subclass per rule, with its `static const` diagnostic code (`LintCode`, or `FrenchTextCode` for the French typography rules).
- `lib/src/fixes`: one `ResolvedCorrectionProducer` per quick fix.
- `lib/src/utils/generated_files.dart`: `isGeneratedUnit`, used by rules to skip generated files.
- `lib/src/utils/flutter_elements.dart`: `isFlutterClass` (a class of the Flutter SDK, by name) and `isMediaQueryCall` (a `MediaQuery.of` / `maybeOf` call), shared by `avoid_media_query_of`, its fix and `avoid_repeated_of_context`.
- `lib/src/utils/member_source_range.dart`: the source range of a class member with the comments that move along with it, used by the fixes that move members.
- `lib/src/utils/string_decoder.dart`: `decodeStringLiteral`, the content of a string literal decoded into code points (escapes and surrogate pairs included) with their source range, used by the French typography rules. It never throws: a malformed escape is kept as is.
- `DirectionalRule` / `DirectionalMapping` (`lib/src/rules/directional_rule.dart`): the base of the "use the directional equivalent" rules (`avoid_alignment`, `avoid_edge_insets_only`, `avoid_positioned`), all fixed by `ReplaceWithDirectional`. They do not skip generated files.
- `FrenchTextRule` / `FrenchTextCode` (`lib/src/rules/french_text_rule.dart`): the base of the French typography rules (`french_no_break_space`, `french_straight_apostrophe`, `french_hyphen_only`), on the string literals of the `*_fr.dart` / `*_fr_<REGION>.dart` localization files. The base class targets the file (the verdict is cached per unit), decodes the literal with `decodeStringLiteral` into a `FrenchText` and calls `check`. `FrenchTextCode` is not a `LintCode` (see its dartdoc: gen-l10n's `type=lint` ignore). Other rules are standalone `AnalysisRule` subclasses.
- `AvoidHardcodedStrings` (`lib/src/rules/avoid_hardcoded_strings.dart`): a string literal passed to a Flutter widget, `InlineSpan` or allow-listed holder constructor. The class allow list, the declared-type gate, the parameter deny lists and the content heuristics are documented in its dartdoc; the README only summarizes them.
- `test/utils/flutter_stub.dart`: a minimal `flutter` package, with only the APIs the rules depend on. Extend it when a rule needs more.
- `test/utils/rule_tester.dart`: `RuleTest`, the base class of the rule tests, with `assertFix` (the fixed code must compile; its optional `fixArguments` checks the arguments of the fix label), `assertNoFix` (its optional `count` checks the number of diagnostics), `assertFixAll` and `assertDiagnosticsInNewFile`. Set `rule` and `createFix` (eg: `createFix = MoveSuperKeyLast.new;`) in `setUp`. Override `flutterFiles` to test against another version of the Flutter stub (eg: without an API). `assertFixAll` relies on `ChangeBuilderImpl` (`analyzer_plugin/src`) and `assertDiagnosticsInNewFile` on `ExpectedDiagnostic` (`analyzer_testing/src`): check them first when upgrading these packages. `test/utils/french_rule_tester.dart`: `FrenchRuleTest`, the base of the French typography rule tests, with `frenchFilePath`.

## Adding a rule

Every new rule must come with its tests (step 6) and a case in the `example` project (step 8): a rule without both is not finished.

1. Check that no official linter rule already covers it: if one does, document it in the README instead of writing a rule.
2. Write the rule in `lib/src/rules`, severity `WARNING`.
3. Write its fix in `lib/src/fixes`, overriding `fixKind`, `multiFixKind` and `applicability` (`CorrectionApplicability.acrossSingleFile`): without the last two, "fix all in file" is never offered. In a fix-all, every fix is computed on the original source into one change: a fix must not rely on an insertion another diagnostic's fix would duplicate. To name a computed value in the fix label, keep the `FixKind`s `const` with a `{0}` placeholder and return the value from `fixArguments`, set during `compute` (eg: `ReplaceWithMediaQueryAccessor`).
4. Skip generated files: check `isGeneratedUnit(context.currentUnit)` in the visitor, before reporting. Never return early from `registerNodeProcessors`: it runs once per library, before `context.currentUnit` is set, and generated files are often `part` files.
5. Register the rule and its fix in `lib/main.dart`.
6. Add `test/<rule>_test.dart` (mandatory), extending `RuleTest`: reported and not-reported cases, `assertFix`, `assertNoFix` where the fix does nothing, `assertFixAll` (2+ diagnostics), and a generated `part` file not reported (`assertDiagnosticsInUnits`).
7. Add a row to the rules table of `README.md`, and a short `###` section under "Rules": a one-line motivation, a BAD / GOOD snippet, then one line each for "Not reported" (only what a user would expect to be reported) and the quick fix. Edge cases belong in the dartdoc and the tests, not in the README.
8. Add a triggering case to `example/lib/main.dart` (mandatory), and check that `cd example && dart analyze` reports the rule.
9. Add a `CHANGELOG.md` entry, bump the version in `pubspec.yaml`, and run `dart pub publish --dry-run`.

### Rules without a fix

`avoid_hardcoded_strings` has no fix (step 3): extracting the string into the localization files depends on the project's l10n setup (gen-l10n, easy_localization...), and the README documents the recommended calls instead.

### French typography rules

The `FrenchTextRule` subclasses depart from the steps above:

- Step 3: no fix. The `.arb` file is the place to fix, the generated file is overwritten.
- Step 4: never check `isGeneratedUnit`: the generated per-locale files are the only place where the plugin sees the French strings.
- Step 6: the "generated `part` not reported" test becomes "a `GENERATED CODE` unit reported". The shared behaviour (file targeting, decoding, `type=lint` escape) is tested once, in `test/french_straight_apostrophe_test.dart`; a new rule only tests its own characters.
- Step 8: the triggering cases live in `example/lib/l10n/app_localizations_fr.dart` (a hand-written mimic of the gen-l10n output, with its `type=lint` header), not in `example/lib/main.dart`.

## Code style

### Imports

`directives_ordering` is enabled: `dart:` imports first, then `package:` imports in alphabetical order (so `package:analyzer` before `package:daad_lints`), then relative imports, each group sorted. `dart fix --apply` sorts them.

### Comments

- Always in English.
- `//` comments only for something counter-intuitive (a non-obvious constraint, a workaround, the reason behind a choice), never restating the code.
- Never cite when or where a decision was made: the comment gives the reason itself, the history belongs in the plan, the commit message or the merge request.
- `///` dartdoc is allowed on classes, rules and public members.

### Constructors: `super.key` last

`super.key` is always the last constructor parameter. Enforced by the `super_key_last` rule.

```dart
const MaskedValue({this.color = kPurple, this.squareSize = 6.0, super.key});
```

### Field ordering

Class members go below the constructor, in this order:

1. `static const` and `static final` fields
2. other `static` fields (mutable or `late`)
3. `final` instance fields (`late final` included)
4. other instance fields (mutable or `late`)

The order between fields is enforced by the `field_ordering` rule; the position relative to the constructor is not checked.

```dart
class AvoidPositioned extends DirectionalRule {
  AvoidPositioned() : super(...);

  static const LintCode code = LintCode(...);

  @override
  LintCode get diagnosticCode => code;
}
```

### Dart 3.10 dot-shorthand syntax

Use `.member` when the target type can be inferred. Quick fixes keep the shorthand form (`alignment: .topLeft` becomes `alignment: .topStart`).

```dart
// Preferred
padding: const .only(bottom: 12.0),

// Avoid
padding: const EdgeInsets.only(bottom: 12.0),
```

### `double` literals: always include the decimal part

Write `10.0`, not `10`, wherever a `double` is expected. Enforced by the `prefer_double_literals` rule.

```dart
// Preferred
const SizedBox(height: 10.0),

// Avoid
const SizedBox(height: 10),
```
