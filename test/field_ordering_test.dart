// test_reflective_loader requires `test_` prefixed method names.
// ignore_for_file: non_constant_identifier_names, always_specify_types

import 'package:daad_lints/src/fixes/sort_fields.dart';
import 'package:daad_lints/src/rules/field_ordering.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'utils/rule_tester.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldOrderingTest);
  });
}

@reflectiveTest
class FieldOrderingTest extends RuleTest {
  @override
  void setUp() {
    rule = FieldOrdering();
    createFix = SortFields.new;
    super.setUp();
  }

  Future<void> test_finalBeforeStatic() async {
    const String code = r'''
class A {
  final int f = 0;
  static const int s = 0;
}
''';
    await assertDiagnostics(code, [lint(code.indexOf('s ='), 1)]);
  }

  Future<void> test_mutableStaticBeforeStaticFinal() async {
    const String code = r'''
class A {
  static int t = 0;
  static final int s = 0;
}
''';
    await assertDiagnostics(code, [lint(code.indexOf('s ='), 1)]);
  }

  Future<void> test_mutableBeforeFinal() async {
    const String code = r'''
class A {
  int m = 0;
  final int f = 0;
}
''';
    await assertDiagnostics(code, [lint(code.indexOf('f ='), 1)]);
  }

  Future<void> test_lateFinalIsFinal() async {
    const String code = r'''
class A {
  late int l = 0;
  late final int f = 0;
}
''';
    await assertDiagnostics(code, [lint(code.indexOf('f ='), 1)]);
  }

  Future<void> test_staticLateIsStatic() async {
    const String code = r'''
class A {
  final int f = 0;
  static late int s = 0;
}
''';
    await assertDiagnostics(code, [lint(code.indexOf('s ='), 1)]);
  }

  Future<void> test_staticLateFinalIsStaticFinal() async {
    const String code = r'''
class A {
  static int t = 0;
  static late final int s = 0;
}
''';
    await assertDiagnostics(code, [lint(code.indexOf('s ='), 1)]);
  }

  Future<void> test_oneDiagnosticPerClass() async {
    const String code = r'''
class A {
  int m = 0;
  final int f = 0;
  static int s = 0;
}
''';
    await assertDiagnostics(code, [lint(code.indexOf('f ='), 1)]);
  }

  Future<void> test_enumAndMixin() async {
    const String code = r'''
enum E {
  a, b;

  final int f = 0;
  static const int s = 0;
}

mixin M {
  int m = 0;
  static int t = 0;
}
''';
    await assertDiagnostics(code, [
      lint(code.indexOf('s ='), 1),
      lint(code.indexOf('t ='), 1),
    ]);
  }

  Future<void> test_ordered() async {
    await assertNoDiagnostics(r'''
abstract class A {
  A(this.f);

  static const int s = 0;
  static final int u = 0;
  static late final int v = 0;

  static int t = 0;
  static late int w = 0;

  final int f;
  final int g = 0, h = 1;
  abstract final int i;
  late final int l = 0;

  int m = 0;
  late int n = 0;

  void method() {}
}
''');
  }

  Future<void> test_fix() async {
    await assertFix(
      r'''
class A {
  A(this.f);

  int m = 0;
  late final int l = 0;
  static int t = 0;
  static const int s = 0;

  final int f;
  final int g = 0, h = 1;
  static final int u = 0;

  void method() {}
}
''',
      r'''
class A {
  A(this.f);

  static const int s = 0;
  static final int u = 0;

  static int t = 0;

  late final int l = 0;
  final int f;
  final int g = 0, h = 1;

  int m = 0;

  void method() {}
}
''',
    );
  }

  Future<void> test_fix_sameGroupNotAdjacent() async {
    await assertFix(
      r'''
class A {
  static const int s = 0;

  final int f = 0;

  static final int u = 0;
}
''',
      r'''
class A {
  static const int s = 0;
  static final int u = 0;

  final int f = 0;
}
''',
    );
  }

  Future<void> test_fix_attachedComments() async {
    await assertFix(
      r'''
class A {
  // The counter
  // ignore: prefer_final_fields
  int m = 0;

  /// The factor
  @Deprecated('use g')
  final int f = 0;
}
''',
      r'''
class A {
  /// The factor
  @Deprecated('use g')
  final int f = 0;

  // The counter
  // ignore: prefer_final_fields
  int m = 0;
}
''',
    );
  }

  Future<void> test_fix_enum() async {
    await assertFix(
      r'''
enum E {
  a, b;

  final int f = 0;
  static const int s = 0;
}
''',
      r'''
enum E {
  a, b;

  static const int s = 0;

  final int f = 0;
}
''',
    );
  }

  Future<void> test_fix_mixin() async {
    await assertFix(
      r'''
mixin M {
  int m = 0;
  static int s = 0;
}
''',
      r'''
mixin M {
  static int s = 0;

  int m = 0;
}
''',
    );
  }

  Future<void> test_fix_trailingComments() async {
    await assertFix(
      r'''
class A {
  int m = 0; // The counter
  final int f = 0; // The factor
}
''',
      r'''
class A {
  final int f = 0; // The factor

  int m = 0; // The counter
}
''',
    );
  }

  Future<void> test_noFix_blockCommentBetweenFields() async {
    await assertNoFix(r'''
class A {
  int m = 0;
  /* Shared by the fields below */
  final int f = 0;
}
''');
  }

  Future<void> test_noFix_fieldsMixedWithMembers() async {
    await assertNoFix(r'''
class A {
  final int f = 0;

  void method() {}

  static const int s = 0;
}
''');
  }

  Future<void> test_fixAll() async {
    await assertFixAll(
      r'''
class A {
  final int f = 0;
  static const int s = 0;
}

class B {
  int m = 0;
  final int g = 0;
}
''',
      r'''
class A {
  static const int s = 0;

  final int f = 0;
}

class B {
  final int g = 0;

  int m = 0;
}
''',
    );
  }

  Future<void> test_generatedFile_part() async {
    const String code = r'''
part 'test.g.dart';

class A {
  final int f = 0;
  static const int s = 0;
}
''';
    String partPath = '$testPackageLibPath/test.g.dart';
    newFile(testFilePath, code);
    newFile(partPath, r'''
part of 'test.dart';

class B {
  final int f = 0;
  static const int s = 0;
}
''');
    await assertDiagnosticsInUnits([
      (testFilePath, [lint(code.indexOf('s ='), 1)]),
      (partPath, []),
    ]);
  }
}
