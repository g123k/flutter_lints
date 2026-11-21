// test_reflective_loader requires `test_` prefixed method names.
// ignore_for_file: non_constant_identifier_names, always_specify_types

// ignore: implementation_imports, the compile error codes have no public export
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
// ignore: implementation_imports, ExpectedDiagnostic is not exported
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart'
    show ExpectedDiagnostic;
import 'package:daad_lints/src/fixes/add_explicit_call.dart';
import 'package:daad_lints/src/rules/prefer_explicit_call.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'utils/rule_tester.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferExplicitCallTest);
  });
}

@reflectiveTest
class PreferExplicitCallTest extends RuleTest {
  @override
  void setUp() {
    rule = PreferExplicitCall();
    createFix = AddExplicitCall.new;
    super.setUp();
  }

  /// A diagnostic on [callee], at its first occurrence between [before] and
  /// [after].
  ExpectedDiagnostic _callee(
    String code,
    String callee, {
    String before = '',
    String after = '',
  }) {
    int index = code.indexOf('$before$callee$after');
    expect(index, isNonNegative, reason: '$before$callee$after not found');
    return lint(index + before.length, callee.length);
  }

  Future<void> test_namedValues() async {
    newFile('$testPackageLibPath/other.dart', r"""
void Function() topLevelCb = () {};
""");
    const String code = r"""
import 'other.dart' as p;

typedef Cb = void Function(int);

class W {
  W(this.onTap);

  static void Function() staticCb = () {};

  final void Function() onTap;

  void Function() get g => onTap;

  void run(Cb cb) {
    Cb lv = cb;
    cb(1);
    lv(2);
    onTap();
    this.onTap();
    g();
  }
}

class S extends W {
  S(super.onTap);

  void sup() {
    super.onTap();
  }
}

void use(W w) {
  w.onTap();
  w.g();
  W.staticCb();
  p.topLevelCb();
}
""";
    await assertDiagnostics(code, [
      _callee(code, 'cb', before: '    '),
      _callee(code, 'lv', before: '    '),
      _callee(code, 'onTap', before: '    '),
      _callee(code, 'this.onTap', before: '    '),
      _callee(code, 'g', before: '    '),
      _callee(code, 'super.onTap', before: '    '),
      _callee(code, 'w.onTap'),
      _callee(code, 'w.g'),
      _callee(code, 'W.staticCb'),
      _callee(code, 'p.topLevelCb'),
    ]);
  }

  Future<void> test_otherCallees() async {
    const String code = r"""
class W {
  void Function()? onTap;
}

void Function() getH() => () {};

void run(
  List<void Function(int)> hs,
  void Function(int) a,
  void Function(int)? b,
  void Function(int)? n,
  W? w,
  (void Function(), {void Function() a}) r,
  String Function() f,
) {
  hs[0](4);
  getH()();
  (b ?? a)(5);
  n!(6);
  w?.onTap!();
  r.a();
  r.$1();
  print('${f()}');
}
""";
    await assertDiagnostics(code, [
      _callee(code, 'hs[0]'),
      _callee(code, 'getH()', before: '  '),
      _callee(code, '(b ?? a)'),
      _callee(code, 'n!'),
      _callee(code, 'w?.onTap!'),
      _callee(code, 'r.a'),
      _callee(code, r'r.$1'),
      _callee(code, 'f', before: r'${'),
    ]);
  }

  Future<void> test_anyType() async {
    const String code = r"""
class V {
  void call(String s) {}

  void self() {
    this('y');
  }
}

extension on int {
  void call(int x) {}
}

void run(Function f, dynamic d, V v) {
  f();
  d();
  v('x');
  1(2);
}
""";
    await assertDiagnostics(code, [
      _callee(code, 'this'),
      _callee(code, 'f', before: '  ', after: '()'),
      _callee(code, 'd', before: '  ', after: '()'),
      _callee(code, 'v', before: '  ', after: '('),
      _callee(code, '1', before: '  ', after: '('),
    ]);
  }

  Future<void> test_typeArguments() async {
    const String code = r"""
void run(T Function<T>(T) gen) {
  gen<int>(1);
}
""";
    await assertDiagnostics(code, [_callee(code, 'gen', before: '  ')]);
  }

  Future<void> test_cascade() async {
    const String code = r"""
class W {
  void Function() onTap = () {};
  void Function(int) onSel = (int x) {};
}

void run(W w, W? m) {
  w..onTap();
  m?..onSel(1);
}
""";
    await assertDiagnostics(code, [
      _callee(code, '..onTap', before: 'w'),
      _callee(code, '?..onSel', before: 'm'),
    ]);
  }

  Future<void> test_closure() async {
    const String code = r"""
int run() {
  (() {})();
  return () {
    return 1;
  }();
}
""";
    int start = code.indexOf('() {\n    return');
    await assertDiagnostics(code, [
      _callee(code, '(() {})'),
      lint(start, code.indexOf('}();') + 1 - start),
    ]);
  }

  Future<void> test_nested() async {
    const String code = r"""
void Function() Function() h() => () => () {};

void run() {
  h()()();
}
""";
    await assertDiagnostics(code, [
      _callee(code, 'h()', before: '  '),
      _callee(code, 'h()()', before: '  '),
    ]);
  }

  Future<void> test_testFile() async {
    const String code = r"""
void run(void Function(int) cb) {
  cb(1);
}
""";
    await assertDiagnosticsInNewFile(
      '$testPackageRootPath/test/a_test.dart',
      code,
      [_callee(code, 'cb', before: '  ')],
    );
  }

  Future<void> test_notReported() async {
    newFile('$testPackageLibPath/other.dart', r"""
void fn() {}
""");
    await assertNoDiagnostics(r"""
import 'other.dart' as p;

class W {
  W();

  static void sm() {}

  void m() {}

  void run(void Function(int) cb, void Function(int)? n) {
    cb.call(1);
    n?.call(1);
    print(1);
    top();
    void local() {}
    local();
    m();
    W.sm();
    W();
    p.fn();
    int.parse('1');
    print('$cb()');
  }
}

void top() {}
""");
  }

  Future<void> test_invalidCallee() async {
    const String code = r"""
void Function() h() => () {};

void run() {
  String x = 'a';
  x();
  h()()();
}
""";
    await assertDiagnostics(code, [
      error(diag.invocationOfNonFunctionExpression, code.indexOf('x()'), 1),
      _callee(code, 'h()', before: '  '),
      error(diag.useOfVoidResult, code.indexOf('h()()()'), 5),
    ]);
  }

  Future<void> test_generatedFile_part() async {
    const String code = r"""
part 'test.g.dart';

void run(void Function(int) cb) {
  cb(1);
}
""";
    String partPath = '$testPackageLibPath/test.g.dart';
    newFile(testFilePath, code);
    newFile(partPath, r"""
part of 'test.dart';

void other(void Function(int) cb) {
  cb(2);
}
""");
    await assertDiagnosticsInUnits([
      (testFilePath, [_callee(code, 'cb', before: '  ')]),
      (partPath, []),
    ]);
  }

  Future<void> test_fix() async {
    await assertFix(
      r"""
void run(void Function(int) cb) {
  cb(1);
}
""",
      r"""
void run(void Function(int) cb) {
  cb.call(1);
}
""",
    );
  }

  Future<void> test_fix_typeArguments() async {
    await assertFix(
      r"""
void run(T Function<T>(T) gen) {
  gen<int>(1);
}
""",
      r"""
void run(T Function<T>(T) gen) {
  gen.call<int>(1);
}
""",
    );
  }

  Future<void> test_fix_cascade() async {
    await assertFix(
      r"""
class W {
  void Function() onTap = () {};
}

void run(W w) {
  w..onTap();
}
""",
      r"""
class W {
  void Function() onTap = () {};
}

void run(W w) {
  w..onTap.call();
}
""",
    );
  }

  Future<void> test_fix_comment() async {
    await assertFix(
      r"""
void run(void Function(int) cb) {
  cb /* c */ (1);
}
""",
      r"""
void run(void Function(int) cb) {
  cb.call /* c */ (1);
}
""",
    );
  }

  Future<void> test_fixAll() async {
    await assertFixAll(
      r"""
class W {
  void Function() onTap = () {};
}

class S extends W {
  void sup() {
    super.onTap();
  }
}

void Function() Function() h() => () => () {};

void run(int Function(int) f, int Function(int) g) {
  h()()();
  f(g(1));
}
""",
      r"""
class W {
  void Function() onTap = () {};
}

class S extends W {
  void sup() {
    super.onTap.call();
  }
}

void Function() Function() h() => () => () {};

void run(int Function(int) f, int Function(int) g) {
  h().call().call();
  f.call(g.call(1));
}
""",
    );
  }
}
