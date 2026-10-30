// test_reflective_loader requires `test_` prefixed method names.
// ignore_for_file: non_constant_identifier_names, always_specify_types

import 'package:analyzer/error/error.dart';
// ignore: implementation_imports, the parser codes have no public export
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:daad_lints/src/rules/french_straight_apostrophe.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'utils/french_rule_tester.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FrenchStraightApostropheTest);
  });
}

/// Also tests the behaviour shared by every French typography rule (file
/// targeting, string decoding, generated files, `type=lint` escape).
@reflectiveTest
class FrenchStraightApostropheTest extends FrenchRuleTest {
  @override
  void setUp() {
    rule = FrenchStraightApostrophe();
    super.setUp();
  }

  void test_code() {
    // Not a lint: gen-l10n's `type=lint` ignore must not silence the rule.
    expect(FrenchStraightApostrophe.code.type, DiagnosticType.STATIC_WARNING);
    expect(FrenchStraightApostrophe.code.severity, DiagnosticSeverity.WARNING);
  }

  Future<void> test_apostrophe() async {
    const String code = r'''
String a = 'l’été';
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(code.indexOf('’'), 1),
    ]);
  }

  Future<void> test_apostrophe_escape() async {
    const String code = r'''
String a = 'l\u2019été';
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(code.indexOf(r'\u2019'), 6),
    ]);
  }

  Future<void> test_apostrophe_twice() async {
    const String code = r'''
String a = 'l’été d’hier';
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(code.indexOf('’'), 1),
      lint(code.lastIndexOf('’'), 1),
    ]);
  }

  Future<void> test_doubleQuoted() async {
    const String code = r'''
String a = "l’été";
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(code.indexOf('’'), 1),
    ]);
  }

  Future<void> test_multiLine() async {
    const String code = r"""
String a = '''
L’été
''';
""";
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(code.indexOf('’'), 1),
    ]);
  }

  Future<void> test_adjacentStrings() async {
    const String code = r'''
String a = 'Bonjour ' 'l’ami';
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(code.indexOf('’'), 1),
    ]);
  }

  Future<void> test_interpolation() async {
    const String code = r'''
String a(String name) => 'l’ami $name';
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(code.indexOf('’'), 1),
    ]);
  }

  Future<void> test_rawString() async {
    const String code = r'''
String a = r'l’été';
String b = r'l\u2019été';
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(code.indexOf('’'), 1),
    ]);
  }

  Future<void> test_regionalFiles() async {
    const String code = r'''
String a = 'l’été';
''';
    for (String name in [
      'app_localizations_fr_FR.dart',
      'app_localizations_fr_CA.dart',
      'messages_fr_ca.dart',
    ]) {
      await assertDiagnosticsInNewFile('$testPackageLibPath/l10n/$name', code, [
        lint(code.indexOf('’'), 1),
      ]);
    }
  }

  Future<void> test_partFile() async {
    String libraryPath = '$testPackageLibPath/l10n/app_localizations.dart';
    const String code = r'''
part of 'app_localizations.dart';

String a = 'l’été';
''';
    newFile(libraryPath, r'''
part 'app_localizations_fr.dart';

String b = 'l’été';
''');
    newFile(frenchFilePath, code);
    await assertDiagnosticsInUnits([
      (libraryPath, []),
      (frenchFilePath, [lint(code.indexOf('’'), 1)]),
    ]);
  }

  Future<void> test_generatedFile_header() async {
    const String code = r'''
// GENERATED CODE - DO NOT MODIFY BY HAND

String a = 'l’été';
''';
    await assertDiagnosticsInNewFile(
      '$testPackageLibPath/generated/intl/messages_fr.dart',
      code,
      [lint(code.indexOf('’'), 1)],
    );
  }

  Future<void> test_ignoreForFile_typeLint() async {
    const String code = r'''
// ignore_for_file: type=lint

String a = 'l’été';
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(code.indexOf('’'), 1),
    ]);
  }

  Future<void> test_ignoreForFile_name() async {
    await assertDiagnosticsInNewFile(frenchFilePath, r'''
// ignore_for_file: french_straight_apostrophe

String a = 'l’été';
''', []);
  }

  Future<void> test_escapedBackslash() async {
    await assertDiagnosticsInNewFile(frenchFilePath, r'''
String a = 'l\\u2019été';
''', []);
  }

  Future<void> test_surrogatePair() async {
    const String code = r'''
String a = '😀’';
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(code.indexOf('’'), 1),
    ]);
  }

  Future<void> test_astralEscape() async {
    const String code = r'''
String a = '\u{1F600}’';
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(code.indexOf('’'), 1),
    ]);
  }

  Future<void> test_straightApostrophe() async {
    await assertDiagnosticsInNewFile(frenchFilePath, r'''
String a = 'l\'été';
String b = "l'été";
''', []);
  }

  Future<void> test_otherFiles() async {
    const String code = r'''
String a = 'l’été';
''';
    List<String> paths = [
      '$testPackageLibPath/l10n/app_localizations_en.dart',
      '$testPackageLibPath/refresh_widget.dart',
      '$testPackageLibPath/date_fr_helpers.dart',
      '$testPackageLibPath/date_fr_util.dart',
      '$testPackageLibPath/calendar_fr_view.dart',
      '$testPackageLibPath/app_fr.g.dart',
    ];
    for (String path in paths) {
      newFile(path, code);
    }
    await assertDiagnosticsInUnits([for (String path in paths) (path, [])]);
  }

  Future<void> test_malformedEscape() async {
    const String code = r'''
String a = '\u{12 l’été';
String b = '\u12 l’été';
String c = '\xZ l’été';
String d = '\u{110000} l’été';
''';
    List<int> apostrophes = <int>[
      for (int i = code.indexOf('’'); i != -1; i = code.indexOf('’', i + 1)) i,
    ];
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      error(diag.invalidUnicodeEscapeUBracket, code.indexOf(r'\u{12'), 6),
      error(diag.invalidUnicodeEscapeUNoBracket, code.indexOf(r'\u12'), 4),
      error(diag.invalidHexEscape, code.indexOf(r'\xZ'), 2),
      error(diag.invalidCodePoint, code.indexOf(r'\u{110000}'), 9),
      for (int offset in apostrophes) lint(offset, 1),
    ]);
  }
}
