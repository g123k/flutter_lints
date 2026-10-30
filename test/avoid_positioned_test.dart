// test_reflective_loader requires `test_` prefixed method names.
// ignore_for_file: non_constant_identifier_names, always_specify_types

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:daad_lints/src/fixes/replace_with_directional.dart';
import 'package:daad_lints/src/rules/avoid_positioned.dart';
import 'package:daad_lints/src/rules/directional_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'utils/rule_tester.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidPositionedTest);
  });
}

@reflectiveTest
class AvoidPositionedTest extends RuleTest {
  @override
  void setUp() {
    rule = AvoidPositioned();
    createFix = ({required CorrectionProducerContext context}) =>
        ReplaceWithDirectional(rule as DirectionalRule, context: context);
    super.setUp();
  }

  Future<void> test_constructor() async {
    const String code = r'''
import 'package:flutter/widgets.dart';

Widget widget = Positioned(left: 1.0, child: Widget());
''';
    await assertDiagnostics(code, [
      lint(code.indexOf('Positioned('), 'Positioned'.length),
    ]);
  }

  Future<void> test_allowed() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget a = PositionedDirectional(start: 1.0, child: Widget());
Widget c = Positioned.fill(left: 1.0, child: Widget());
Widget b = Positioned.directional(
  textDirection: TextDirection.rtl,
  start: 1.0,
  child: Widget(),
);
''');
  }

  Future<void> test_fix_constructor() async {
    await assertFix(
      r'''
import 'package:flutter/widgets.dart';

Widget widget = Positioned(left: 1.0, top: 2.0, right: 3.0, child: Widget());
''',
      r'''
import 'package:flutter/widgets.dart';

Widget widget = PositionedDirectional(start: 1.0, top: 2.0, end: 3.0, child: Widget());
''',
    );
  }

  Future<void> test_fix_const() async {
    await assertFix(
      r'''
import 'package:flutter/widgets.dart';

const Widget widget = Positioned(right: 3.0, child: Widget());
''',
      r'''
import 'package:flutter/widgets.dart';

const Widget widget = PositionedDirectional(end: 3.0, child: Widget());
''',
    );
  }
}
