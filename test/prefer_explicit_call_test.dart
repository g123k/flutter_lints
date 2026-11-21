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
      _callee(code, 'cb', after: '(1)'),
      _callee(code, 'lv', after: '(2)'),
      _callee(code, 'onTap', before: ' ', after: '()'),
      _callee(code, 'this.onTap', after: '()'),
      _callee(code, 'g', after: '()'),
      _callee(code, 'super.onTap', after: '()'),
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
  void Function() onPress = () {};
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
  w?.onPress();
  r.a();
  r.$1();
  print('${f()}');
}
""";
    await assertDiagnostics(code, [
      _callee(code, 'hs[0]'),
      _callee(code, 'getH()', after: '()'),
      _callee(code, '(b ?? a)'),
      _callee(code, 'n!'),
      _callee(code, 'w?.onTap!'),
      _callee(code, 'w?.onPress'),
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
    await assertDiagnostics(code, [_callee(code, 'gen', after: '<int>')]);
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
    const String closure = '() {\n    return 1;\n  }';
    const String code = 'int run() {\n  (() {})();\n  return $closure();\n}\n';
    await assertDiagnostics(code, [
      _callee(code, '(() {})'),
      _callee(code, closure),
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
      _callee(code, 'h()', after: '()()'),
      _callee(code, 'h()()', after: '()'),
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
      [_callee(code, 'cb', after: '(1)')],
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

  void run(
    void Function(int) cb,
    void Function(int)? n,
    T Function<T>(T) gen,
    dynamic d,
  ) {
    cb.call(1);
    n?.call(1);
    gen.call<int>(1);
    print(1);
    top();
    void local() {}
    local();
    m();
    this.m();
    W.sm();
    W();
    p.fn();
    int.parse('1');
    d.foo();
    print('$cb()');
  }
}

class S extends W {
  void sup() {
    super.m();
  }
}

void top() {}
""");
  }

  Future<void> test_invalidCallee() async {
    const String code = r"""
void Function() h() => () {};

void run(void Function()? onDone) {
  String x = 'a';
  x();
  h()()();
  onDone();
}
""";
    await assertDiagnostics(code, [
      error(diag.invocationOfNonFunctionExpression, code.indexOf('x()'), 1),
      _callee(code, 'h()', after: '()()'),
      error(diag.useOfVoidResult, code.indexOf('h()()()'), 'h()()'.length),
      error(
        diag.uncheckedInvocationOfNullableValue,
        code.indexOf('onDone()'),
        'onDone'.length,
      ),
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
      (testFilePath, [_callee(code, 'cb', after: '(1)')]),
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

  /// The fixed code of each callee shape compiles: `.call` never needs
  /// parentheses around the callee.
  Future<void> test_fix_calleeShapes() async {
    const String declarations = r"""
class W {
  void Function(int) onSel = (int x) {};
}

extension on int {
  void call(int x) {}
}

void Function() getH() => () {};

void run(
  List<void Function(int)> hs,
  void Function(int) a,
  void Function(int)? b,
  void Function(int)? n,
  W? m,
  (void Function(),) r,
  String Function() f,
  dynamic d,
) {
""";
    const Map<String, String> fixes = <String, String>{
      'hs[0](4);': 'hs[0].call(4);',
      'getH()();': 'getH().call();',
      '(b ?? a)(5);': '(b ?? a).call(5);',
      'n!(6);': 'n!.call(6);',
      'm?..onSel(1);': 'm?..onSel.call(1);',
      r'r.$1();': r'r.$1.call();',
      r"print('${f()}');": r"print('${f.call()}');",
      'd();': 'd.call();',
      '1(2);': '1.call(2);',
      '(() {})();': '(() {}).call();',
      'print(() { return 1; }());': 'print(() { return 1; }.call());',
    };
    for (MapEntry<String, String> fix in fixes.entries) {
      await assertFix(
        '$declarations  ${fix.key}\n}\n',
        '$declarations  ${fix.value}\n}\n',
      );
    }
  }

  Future<void> test_fix_thisAndSuper() async {
    await assertFix(
      r"""
class V {
  void call(String s) {}

  void self() {
    this('y');
  }
}
""",
      r"""
class V {
  void call(String s) {}

  void self() {
    this.call('y');
  }
}
""",
    );
    await assertFix(
      r"""
class W {
  void Function() onTap = () {};
}

class S extends W {
  void sup() {
    super.onTap();
  }
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
