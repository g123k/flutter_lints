// test_reflective_loader requires `test_` prefixed method names.
// ignore_for_file: non_constant_identifier_names, always_specify_types

import 'package:daad_lints/src/fixes/add_decimal_part.dart';
import 'package:daad_lints/src/rules/prefer_double_literals.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'utils/rule_tester.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferDoubleLiteralsTest);
  });
}

@reflectiveTest
class PreferDoubleLiteralsTest extends RuleTest {
  @override
  void setUp() {
    rule = PreferDoubleLiterals();
    createFix = AddDecimalPart.new;
    super.setUp();
  }

  Future<void> test_variable() async {
    const String code = r'''
double a = 1;
double? b = 2;
''';
    await assertDiagnostics(code, [
      lint(code.indexOf('1'), 1),
      lint(code.indexOf('2'), 1),
    ]);
  }

  Future<void> test_argument() async {
    const String code = r'''
import 'package:flutter/painting.dart';

const EdgeInsets insets = EdgeInsets.all(8);
''';
    await assertDiagnostics(code, [lint(code.indexOf('8'), 1)]);
  }

  Future<void> test_listLiteral() async {
    const String code = r'''
List<double> values = <double>[1, 2.0];
''';
    await assertDiagnostics(code, [lint(code.indexOf('1'), 1)]);
  }

  Future<void> test_defaultValue() async {
    const String code = r'''
void f({double value = 3}) {}
''';
    await assertDiagnostics(code, [lint(code.indexOf('3'), 1)]);
  }

  Future<void> test_negative() async {
    const String code = r'''
const double a = -1;
''';
    await assertDiagnostics(code, [lint(code.indexOf('1'), 1)]);
  }

  Future<void> test_notDouble() async {
    await assertNoDiagnostics(r'''
int a = 1;
num b = 2;
Object c = 3;
dynamic d = 4;
double e = 5.0;
double f(double x) => x * 2;
''');
  }

  Future<void> test_hexadecimal() async {
    await assertNoDiagnostics(r'''
double a = 0x10;
double b = 0XFF;
''');
  }

  Future<void> test_fix() async {
    await assertFix(
      r'''
const double a = 1_000;
''',
      r'''
const double a = 1_000.0;
''',
    );
  }

  Future<void> test_fix_negative() async {
    await assertFix(
      r'''
const double a = -1;
''',
      r'''
const double a = -1.0;
''',
    );
  }

  Future<void> test_fixAll() async {
    await assertFixAll(
      r'''
import 'package:flutter/painting.dart';

const EdgeInsets insets = EdgeInsets.only(left: 1, top: 2);
List<double> values = <double>[3, 4.0, 5];
''',
      r'''
import 'package:flutter/painting.dart';

const EdgeInsets insets = EdgeInsets.only(left: 1.0, top: 2.0);
List<double> values = <double>[3.0, 4.0, 5.0];
''',
    );
  }

  Future<void> test_generatedFile_suffix() async {
    String path = '$testPackageLibPath/a.freezed.dart';
    newFile(path, r'''
double a = 1;
''');
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_generatedFile_header() async {
    await assertNoDiagnostics(r'''
// coverage:ignore-file
// Generated code - do not modify by hand

double a = 1;
''');
  }

  Future<void> test_generatedFile_part() async {
    const String code = r'''
part 'test.g.dart';

double a = 1;
''';
    String partPath = '$testPackageLibPath/test.g.dart';
    newFile(testFilePath, code);
    newFile(partPath, r'''
part of 'test.dart';

double b = 2;
''');
    await assertDiagnosticsInUnits([
      (testFilePath, [lint(code.indexOf('1'), 1)]),
      (partPath, []),
    ]);
  }
}
