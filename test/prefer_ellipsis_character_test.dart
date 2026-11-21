// test_reflective_loader requires `test_` prefixed method names.
// ignore_for_file: non_constant_identifier_names, always_specify_types

import 'package:daad_lints/src/fixes/replace_with_ellipsis.dart';
import 'package:daad_lints/src/rules/prefer_ellipsis_character.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'utils/rule_tester.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferEllipsisCharacterTest);
  });
}

/// The offset right after [before] in [code].
int _after(String code, String before) => code.indexOf(before) + before.length;

@reflectiveTest
class PreferEllipsisCharacterTest extends RuleTest {
  @override
  void setUp() {
    rule = PreferEllipsisCharacter();
    createFix = ReplaceWithEllipsis.new;
    super.setUp();
  }

  Future<void> test_reported() async {
    const String code = r"""
String a = 'Chargement...';
String b = "Loading...";
String c = '...';
String d = '''...''';
String e = r'a...';
""";
    await assertDiagnostics(code, [
      lint(_after(code, "'Chargement"), 3),
      lint(_after(code, '"Loading'), 3),
      lint(_after(code, "c = '"), 3),
      lint(_after(code, "d = '''"), 3),
      lint(_after(code, "r'a"), 3),
    ]);
  }

  Future<void> test_interpolation() async {
    const String code = r"""
int count = 1;
int x = 2;
String a = '$count...';
String b = '...$x';
String c = '${x}...';
String d = '$x...$x';
String e = 'a' '$x...';
""";
    await assertDiagnostics(code, [
      lint(_after(code, r"'$count"), 3),
      lint(_after(code, "b = '"), 3),
      lint(_after(code, r'${x}'), 3),
      lint(_after(code, r"d = '$x"), 3),
      lint(_after(code, r"'a' '$x"), 3),
    ]);
  }

  Future<void> test_offsetsAfterEscapes() async {
    const String code = r"""
String a = '\n...';
String b = '\\...';
String c = 'é...';
String d = '😀...';
""";
    await assertDiagnostics(code, [
      lint(_after(code, r"'\n"), 3),
      lint(_after(code, r"'\\"), 3),
      lint(_after(code, "'é"), 3),
      lint(_after(code, "'😀"), 3),
    ]);
  }

  Future<void> test_escapes() async {
    const String code = r"""
String a = '\x2e\u{2e}.';
""";
    await assertDiagnostics(code, [lint(code.indexOf(r'\x2e'), 11)]);
  }

  Future<void> test_twoRuns() async {
    const String code = r"""
String a = 'a... b...';
""";
    await assertDiagnostics(code, [
      lint(_after(code, "'a"), 3),
      lint(_after(code, '... b'), 3),
    ]);
  }

  Future<void> test_testFile() async {
    const String code = r"""
String a = 'Chargement...';
""";
    await assertDiagnosticsInNewFile(
      '$testPackageRootPath/test/a_test.dart',
      code,
      [lint(_after(code, "'Chargement"), 3)],
    );
  }

  Future<void> test_userRegExpClass() async {
    const String code = r"""
class RegExp {
  RegExp(String pattern);
}

RegExp a = RegExp('a...b');
""";
    await assertDiagnostics(code, [lint(_after(code, "'a"), 3)]);
  }

  Future<void> test_otherDartCoreConstructor() async {
    const String code = r"""
Exception a = Exception('Chargement...');
""";
    await assertDiagnostics(code, [lint(_after(code, "'Chargement"), 3)]);
  }

  Future<void> test_notReported() async {
    await assertNoDiagnostics(r"""
String x = 'x';
String a = '..';
String b = '....';
String c = '......';
String d = '. . .';
String e = 'Chargement…';
String f = 'Chargement\u2026';
String g = '.$x..';
String h = 'a.' '..';
String i = r'\x2e..';
""");
  }

  Future<void> test_regExp() async {
    await assertNoDiagnostics(r"""
RegExp a = RegExp(r'a...b');
// ignore: unnecessary_new
RegExp b = new RegExp('...');
RegExp c = RegExp('...', multiLine: true);
""");
  }

  Future<void> test_regExp_dotShorthand() async {
    await assertNoDiagnostics(r"""
RegExp a = .new(r'...');
""");
  }

  Future<void> test_regExp_prefixed() async {
    await assertNoDiagnostics(r"""
import 'dart:core' as core;

core.RegExp a = core.RegExp(r'a...b');
""");
  }

  Future<void> test_regExp_stringParts() async {
    await assertNoDiagnostics(r"""
String p = 'p';
RegExp a = RegExp('a' '...');
RegExp b = RegExp('$p...');
""");
  }

  Future<void> test_directives_import() async {
    newFile('$testPackageLibPath/a...b.dart', r'''
int value = 1;
''');
    newFile('$testPackageLibPath/c...d.dart', r'''
int value = 2;
''');
    await assertNoDiagnostics(r"""
import 'a...b.dart' if (dart.library.io) 'c...d.dart';

export 'a...b.dart';

int copy = value;
""");
  }

  Future<void> test_directives_part() async {
    String libraryPath = '$testPackageLibPath/x...y.dart';
    String partPath = '$testPackageLibPath/a...b.dart';
    newFile(libraryPath, r'''
part 'a...b.dart';
''');
    newFile(partPath, r'''
part of 'x...y.dart';
''');
    await assertDiagnosticsInUnits([(libraryPath, []), (partPath, [])]);
  }

  Future<void> test_typeLintIgnored() async {
    await assertNoDiagnostics(r"""
// ignore_for_file: type=lint

String a = 'Chargement...';
""");
  }

  Future<void> test_generatedFile_suffix() async {
    String path = '$testPackageLibPath/a.g.dart';
    newFile(path, r"""
String a = 'Chargement...';
""");
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_generatedFile_header() async {
    await assertNoDiagnostics(r"""
// GENERATED CODE - DO NOT MODIFY BY HAND

String a = 'Chargement...';
""");
  }

  Future<void> test_generatedFile_intlHeader() async {
    await assertNoDiagnostics(r"""
// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart

String a = 'Chargement...';
""");
  }

  Future<void> test_generatedFile_part() async {
    const String code = r"""
part 'test.g.dart';

String a = 'Chargement...';
""";
    String partPath = '$testPackageLibPath/test.g.dart';
    newFile(testFilePath, code);
    newFile(partPath, r"""
part of 'test.dart';

String b = 'Loading...';
""");
    await assertDiagnosticsInUnits([
      (testFilePath, [lint(_after(code, "'Chargement"), 3)]),
      (partPath, []),
    ]);
  }

  Future<void> test_fix() async {
    await assertFix(
      r"""
String a = 'Chargement...';
""",
      r"""
String a = 'Chargement…';
""",
    );
  }

  Future<void> test_fix_escapes() async {
    await assertFix(
      r"""
String a = '\x2e..';
""",
      r"""
String a = '…';
""",
    );
  }

  Future<void> test_fixAll() async {
    await assertFixAll(
      r"""
String a = 'Chargement...';
String b = 'a... b...';
String c = r'Wait...';
int count = 1;
String d = '$count...';
""",
      r"""
String a = 'Chargement…';
String b = 'a… b…';
String c = r'Wait…';
int count = 1;
String d = '$count…';
""",
    );
  }
}
