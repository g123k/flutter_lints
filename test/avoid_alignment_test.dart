// test_reflective_loader requires `test_` prefixed method names.
// ignore_for_file: non_constant_identifier_names, always_specify_types

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:daad_lints/src/fixes/replace_with_directional.dart';
import 'package:daad_lints/src/rules/avoid_alignment.dart';
import 'package:daad_lints/src/rules/directional_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'utils/rule_tester.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidAlignmentTest);
  });
}

@reflectiveTest
class AvoidAlignmentTest extends RuleTest {
  @override
  void setUp() {
    rule = AvoidAlignment();
    createFix = ({required CorrectionProducerContext context}) =>
        ReplaceWithDirectional(rule as DirectionalRule, context: context);
    super.setUp();
  }

  Future<void> test_constructor() async {
    const String code = r'''
import 'package:flutter/painting.dart';

AlignmentGeometry alignment = Alignment(1.0, 0.0);
''';
    await assertDiagnostics(code, [
      lint(code.indexOf('Alignment('), 'Alignment'.length),
    ]);
  }

  Future<void> test_staticField() async {
    const String code = r'''
import 'package:flutter/painting.dart';

AlignmentGeometry alignment = Alignment.topLeft;
''';
    await assertDiagnostics(code, [
      lint(code.indexOf('Alignment.topLeft'), 'Alignment.topLeft'.length),
    ]);
  }

  Future<void> test_staticField_center() async {
    const String code = r'''
import 'package:flutter/painting.dart';

AlignmentGeometry alignment = Alignment.center;
''';
    await assertDiagnostics(code, [
      lint(code.indexOf('Alignment.center'), 'Alignment.center'.length),
    ]);
  }

  Future<void> test_staticField_prefixed() async {
    const String code = r'''
import 'package:flutter/painting.dart' as p;

p.AlignmentGeometry alignment = p.Alignment.topLeft;
''';
    await assertDiagnostics(code, [
      lint(code.indexOf('p.Alignment.topLeft'), 'p.Alignment.topLeft'.length),
    ]);
  }

  Future<void> test_geometry() async {
    const String code = r'''
import 'package:flutter/painting.dart';

AlignmentGeometry a = AlignmentGeometry.topLeft;
AlignmentGeometry b = AlignmentGeometry.xy(1.0, 0.0);
''';
    await assertDiagnostics(code, [
      lint(
        code.indexOf('AlignmentGeometry.topLeft'),
        'AlignmentGeometry.topLeft'.length,
      ),
      lint(code.indexOf('AlignmentGeometry.xy'), 'AlignmentGeometry.xy'.length),
    ]);
  }

  Future<void> test_dotShorthand() async {
    const String code = r'''
import 'package:flutter/widgets.dart';

Widget a = Align(alignment: .topLeft);
Widget b = Align(alignment: .xy(1.0, 0.0));
''';
    await assertDiagnostics(code, [
      lint(code.indexOf('.topLeft'), '.topLeft'.length),
      lint(code.indexOf('.xy'), '.xy'.length),
    ]);
  }

  Future<void> test_directional() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

AlignmentGeometry a = AlignmentDirectional.topStart;
AlignmentGeometry b = AlignmentDirectional(1.0, 0.0);
Widget c = Align(alignment: .topStart);
Widget d = Align(alignment: .center);
Widget e = Align(alignment: .directional(1.0, 0.0));
''');
  }

  Future<void> test_lerp() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';

Alignment? alignment = Alignment.lerp(null, null, 0.5);
''');
  }

  Future<void> test_docComment() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';

/// Unlike [Alignment.topLeft].
AlignmentGeometry alignment = AlignmentDirectional.topStart;
''');
  }

  Future<void> test_fix_constructor() async {
    await assertFix(
      r'''
import 'package:flutter/painting.dart';

const AlignmentGeometry alignment = Alignment(1.0, 0.0);
''',
      r'''
import 'package:flutter/painting.dart';

const AlignmentGeometry alignment = AlignmentDirectional(1.0, 0.0);
''',
    );
  }

  Future<void> test_fix_staticField() async {
    await assertFix(
      r'''
import 'package:flutter/painting.dart';

AlignmentGeometry alignment = Alignment.topLeft;
''',
      r'''
import 'package:flutter/painting.dart';

AlignmentGeometry alignment = AlignmentDirectional.topStart;
''',
    );
  }

  Future<void> test_fix_staticField_prefixed() async {
    await assertFix(
      r'''
import 'package:flutter/painting.dart' as p;

p.AlignmentGeometry alignment = p.Alignment.center;
''',
      r'''
import 'package:flutter/painting.dart' as p;

p.AlignmentGeometry alignment = p.AlignmentDirectional.center;
''',
    );
  }

  Future<void> test_fix_dotShorthand() async {
    await assertFix(
      r'''
import 'package:flutter/widgets.dart';

Widget widget = Align(alignment: .topLeft);
''',
      r'''
import 'package:flutter/widgets.dart';

Widget widget = Align(alignment: .topStart);
''',
    );
  }

  Future<void> test_fix_dotShorthand_xy() async {
    await assertFix(
      r'''
import 'package:flutter/widgets.dart';

Widget widget = Align(alignment: .xy(1.0, 0.0));
''',
      r'''
import 'package:flutter/widgets.dart';

Widget widget = Align(alignment: .directional(1.0, 0.0));
''',
    );
  }
}
