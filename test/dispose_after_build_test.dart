// test_reflective_loader requires `test_` prefixed method names.
// ignore_for_file: non_constant_identifier_names, always_specify_types

import 'package:daad_lints/src/fixes/move_dispose_to_end.dart';
import 'package:daad_lints/src/rules/dispose_after_build.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'utils/rule_tester.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DisposeAfterBuildTest);
  });
}

const String _widget = r'''
import 'package:flutter/widgets.dart';

class W extends StatefulWidget {
  const W({super.key});

  @override
  State<W> createState() => _WState();
}
''';

@reflectiveTest
class DisposeAfterBuildTest extends RuleTest {
  @override
  void setUp() {
    rule = DisposeAfterBuild();
    createFix = MoveDisposeToEnd.new;
    super.setUp();
  }

  Future<void> test_disposeBeforeBuild() async {
    const String code =
        '''
$_widget
class _WState extends State<W> {
  @override
  void dispose() {}

  @override
  Widget build(BuildContext context) => const Widget();
}
''';
    await assertDiagnostics(code, [lint(code.indexOf('dispose'), 7)]);
  }

  Future<void> test_intermediateState() async {
    const String code =
        '''
$_widget
abstract class BaseState<T extends StatefulWidget> extends State<T> {}

class _WState extends BaseState<W> {
  @override
  void dispose() {}

  @override
  Widget build(BuildContext context) => const Widget();
}
''';
    await assertDiagnostics(code, [lint(code.indexOf('dispose'), 7)]);
  }

  Future<void> test_disposeAfterBuild() async {
    await assertNoDiagnostics('''
$_widget
class _WState extends State<W> {
  @override
  Widget build(BuildContext context) => const Widget();

  @override
  void dispose() {}

  void reset() {}
}
''');
  }

  Future<void> test_disposeOrBuildOnly() async {
    await assertNoDiagnostics('''
$_widget
abstract class BaseState<T extends StatefulWidget> extends State<T> {
  @override
  void dispose() {}
}

class _WState extends State<W> {
  @override
  Widget build(BuildContext context) => const Widget();
}
''');
  }

  Future<void> test_notAState() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Controller {
  void dispose() {}

  Widget build(BuildContext context) => const Widget();
}
''');
  }

  Future<void> test_otherClassNamedState() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

abstract class State<T> {}

class _WState extends State<int> {
  void dispose() {}

  Widget build(BuildContext context) => const Widget();
}
''');
  }

  Future<void> test_fix() async {
    await assertFix(
      '''
$_widget
class _WState extends State<W> {
  @override
  void initState() {}

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Widget();

  void reset() {}
}
''',
      '''
$_widget
class _WState extends State<W> {
  @override
  void initState() {}

  @override
  Widget build(BuildContext context) => const Widget();

  void reset() {}

  @override
  void dispose() {
    super.dispose();
  }
}
''',
    );
  }

  Future<void> test_fix_attachedComments() async {
    await assertFix(
      '''
$_widget
class _WState extends State<W> {
  // Not attached

  // Releases the resources
  // ignore: unnecessary_overrides
  /// Doc comment
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
      '''
$_widget
class _WState extends State<W> {
  // Not attached

  @override
  Widget build(BuildContext context) => const Widget();

  // Releases the resources
  // ignore: unnecessary_overrides
  /// Doc comment
  @override
  void dispose() {
    super.dispose();
  }
}
''',
    );
  }

  Future<void> test_fix_trailingComments() async {
    await assertFix(
      '''
$_widget
class _WState extends State<W> {
  @override
  void dispose() {} // Nothing to release

  @override
  Widget build(BuildContext context) => const Widget(); // The view
}
''',
      '''
$_widget
class _WState extends State<W> {
  @override
  Widget build(BuildContext context) => const Widget(); // The view

  @override
  void dispose() {} // Nothing to release
}
''',
    );
  }

  Future<void> test_fixAll() async {
    await assertFixAll(
      '''
$_widget
class _WState extends State<W> {
  @override
  void dispose() {}

  @override
  Widget build(BuildContext context) => const Widget();
}

class _OtherState extends State<W> {
  @override
  void dispose() {}

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
      '''
$_widget
class _WState extends State<W> {
  @override
  Widget build(BuildContext context) => const Widget();

  @override
  void dispose() {}
}

class _OtherState extends State<W> {
  @override
  Widget build(BuildContext context) => const Widget();

  @override
  void dispose() {}
}
''',
    );
  }

  Future<void> test_generatedFile_part() async {
    const String code = r'''
import 'package:flutter/widgets.dart';

part 'test.g.dart';

class W extends StatefulWidget {
  const W({super.key});

  @override
  State<W> createState() => _WState();
}

class _WState extends State<W> {
  @override
  void dispose() {}

  @override
  Widget build(BuildContext context) => const Widget();
}
''';
    String partPath = '$testPackageLibPath/test.g.dart';
    newFile(testFilePath, code);
    newFile(partPath, r'''
part of 'test.dart';

class OtherState extends State<W> {
  @override
  void dispose() {}

  @override
  Widget build(BuildContext context) => const Widget();
}
''');
    await assertDiagnosticsInUnits([
      (testFilePath, [lint(code.indexOf('dispose'), 7)]),
      (partPath, []),
    ]);
  }
}
