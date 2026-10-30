// test_reflective_loader requires `test_` prefixed method names.
// ignore_for_file: non_constant_identifier_names, always_specify_types

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:daad_lints/src/fixes/replace_with_directional.dart';
import 'package:daad_lints/src/rules/avoid_edge_insets_only.dart';
import 'package:daad_lints/src/rules/directional_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'utils/rule_tester.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidEdgeInsetsOnlyTest);
  });
}

@reflectiveTest
class AvoidEdgeInsetsOnlyTest extends RuleTest {
  @override
  void setUp() {
    rule = AvoidEdgeInsetsOnly();
    createFix = ({required CorrectionProducerContext context}) =>
        ReplaceWithDirectional(rule as DirectionalRule, context: context);
    super.setUp();
  }

  Future<void> test_edgeInsetsOnly() async {
    const String code = r'''
import 'package:flutter/painting.dart';

EdgeInsetsGeometry insets = EdgeInsets.only(left: 1.0);
''';
    await assertDiagnostics(code, [
      lint(code.indexOf('EdgeInsets.only'), 'EdgeInsets.only'.length),
    ]);
  }

  Future<void> test_edgeInsetsOnly_const() async {
    const String code = r'''
import 'package:flutter/painting.dart';

const EdgeInsetsGeometry insets = EdgeInsets.only(right: 1.0);
''';
    await assertDiagnostics(code, [
      lint(code.indexOf('EdgeInsets.only'), 'EdgeInsets.only'.length),
    ]);
  }

  Future<void> test_edgeInsetsOnly_prefixed() async {
    const String code = r'''
import 'package:flutter/painting.dart' as p;

p.EdgeInsetsGeometry insets = p.EdgeInsets.only(top: 1.0);
''';
    await assertDiagnostics(code, [
      lint(code.indexOf('p.EdgeInsets.only'), 'p.EdgeInsets.only'.length),
    ]);
  }

  Future<void> test_edgeInsetsGeometryOnly() async {
    const String code = r'''
import 'package:flutter/painting.dart';

EdgeInsetsGeometry insets = EdgeInsetsGeometry.only(top: 1.0);
''';
    await assertDiagnostics(code, [
      lint(
        code.indexOf('EdgeInsetsGeometry.only'),
        'EdgeInsetsGeometry.only'.length,
      ),
    ]);
  }

  Future<void> test_dotShorthand() async {
    const String code = r'''
import 'package:flutter/widgets.dart';

Widget widget = Padding(padding: .only(left: 1.0));
''';
    await assertDiagnostics(code, [
      lint(code.indexOf('.only'), '.only'.length),
    ]);
  }

  Future<void> test_edgeInsetsAll() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';

EdgeInsets insets = EdgeInsets.all(1.0);
''');
  }

  Future<void> test_edgeInsetsDirectional() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget widget = Padding(padding: .directional(start: 1.0));
EdgeInsetsGeometry insets = EdgeInsetsDirectional.only(start: 1.0);
''');
  }

  Future<void> test_otherClassNamedEdgeInsets() async {
    await assertNoDiagnostics(r'''
class EdgeInsets {
  const EdgeInsets.only({double left = 0.0});
}

EdgeInsets insets = EdgeInsets.only(left: 1.0);
''');
  }

  Future<void> test_fix() async {
    await assertFix(
      r'''
import 'package:flutter/painting.dart';

const EdgeInsetsGeometry insets = EdgeInsets.only(left: 1.0, top: 2.0, right: 3.0);
''',
      r'''
import 'package:flutter/painting.dart';

const EdgeInsetsGeometry insets = EdgeInsetsDirectional.only(start: 1.0, top: 2.0, end: 3.0);
''',
    );
  }

  Future<void> test_fix_prefixed() async {
    await assertFix(
      r'''
import 'package:flutter/painting.dart' as p;

p.EdgeInsetsGeometry insets = p.EdgeInsets.only(left: 1.0);
''',
      r'''
import 'package:flutter/painting.dart' as p;

p.EdgeInsetsGeometry insets = p.EdgeInsetsDirectional.only(start: 1.0);
''',
    );
  }

  Future<void> test_fix_dotShorthand() async {
    await assertFix(
      r'''
import 'package:flutter/widgets.dart';

Widget widget = Padding(padding: .only(left: 1.0, right: 2.0));
''',
      r'''
import 'package:flutter/widgets.dart';

Widget widget = Padding(padding: .directional(start: 1.0, end: 2.0));
''',
    );
  }

  Future<void> test_fixAll() async {
    await assertFixAll(
      r'''
import 'package:flutter/widgets.dart';

EdgeInsetsGeometry a = EdgeInsets.only(left: 1.0);
Widget b = Padding(padding: .only(right: 2.0));
EdgeInsetsGeometry c = EdgeInsetsGeometry.only(left: 3.0, top: 4.0);
''',
      r'''
import 'package:flutter/widgets.dart';

EdgeInsetsGeometry a = EdgeInsetsDirectional.only(start: 1.0);
Widget b = Padding(padding: .directional(end: 2.0));
EdgeInsetsGeometry c = EdgeInsetsGeometry.directional(start: 3.0, top: 4.0);
''',
    );
  }
}
