// test_reflective_loader requires `test_` prefixed method names.
// ignore_for_file: non_constant_identifier_names, always_specify_types

import 'package:daad_lints/src/rules/french_hyphen_only.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'utils/french_rule_tester.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FrenchHyphenOnlyTest);
  });
}

@reflectiveTest
class FrenchHyphenOnlyTest extends FrenchRuleTest {
  @override
  void setUp() {
    rule = FrenchHyphenOnly();
    super.setUp();
  }

  Future<void> test_emDash() async {
    const String code = r'''
String a = 'Lun — Ven';
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(code.indexOf('—'), 1, messageContainsAll: ['Em dash (U+2014)']),
    ]);
  }

  Future<void> test_enDash() async {
    const String code = r'''
String a = 'Lun – Ven';
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(code.indexOf('–'), 1, messageContainsAll: ['En dash (U+2013)']),
    ]);
  }

  Future<void> test_emDash_escape() async {
    const String code = r'''
String a = 'Lun \u2014 Ven';
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(
        code.indexOf(r'\u2014'),
        6,
        messageContainsAll: ['Em dash (U+2014)'],
      ),
    ]);
  }

  Future<void> test_enDash_bracedEscape() async {
    const String code = r'''
String a = 'Lun \u{2013} Ven';
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(
        code.indexOf(r'\u{2013}'),
        8,
        messageContainsAll: ['En dash (U+2013)'],
      ),
    ]);
  }

  Future<void> test_twoDashes() async {
    const String code = r'''
String a = 'Lun — Ven – Sam';
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(code.indexOf('—'), 1),
      lint(code.indexOf('–'), 1),
    ]);
  }

  Future<void> test_hyphen() async {
    await assertDiagnosticsInNewFile(frenchFilePath, r'''
String a = 'Lun-Ven';
String b = 'Lun - Ven';
''', []);
  }

  Future<void> test_otherDashes() async {
    await assertDiagnosticsInNewFile(frenchFilePath, r'''
String a = 'Lun\u2011Ven';
String b = '\u2212 5';
''', []);
  }

  Future<void> test_otherFile() async {
    await assertDiagnosticsInNewFile(
      '$testPackageLibPath/l10n/app_localizations_en.dart',
      r'''
String a = 'Mon — Fri';
''',
      [],
    );
  }
}
