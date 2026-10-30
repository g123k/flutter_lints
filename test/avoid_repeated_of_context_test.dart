// test_reflective_loader requires `test_` prefixed method names.
// ignore_for_file: non_constant_identifier_names, always_specify_types

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
// ignore: implementation_imports, the expected diagnostic types are not exported
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:daad_lints/src/fixes/extract_of_context.dart';
import 'package:daad_lints/src/rules/avoid_repeated_of_context.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'utils/rule_tester.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidRepeatedOfContextTest);
  });
}

/// The offset of the [n]th (0-based) occurrence of [pattern] in [code].
int _nth(String code, String pattern, int n) {
  int offset = -1;
  for (int i = 0; i <= n; i++) {
    offset = code.indexOf(pattern, offset + 1);
  }
  return offset;
}

@reflectiveTest
class AvoidRepeatedOfContextTest extends RuleTest {
  @override
  void setUp() {
    rule = AvoidRepeatedOfContext();
    createFix = ExtractOfContext.new;
    super.setUp();
  }

  /// The diagnostics of a group: one on each listed occurrence of [call],
  /// pointing at the other ones.
  List<ExpectedDiagnostic> _group(
    String code,
    String call,
    List<int> occurrences, {
    List<Pattern> messageContainsAll = const <Pattern>[],
  }) => <ExpectedDiagnostic>[
    for (int occurrence in occurrences)
      lint(
        _nth(code, call, occurrence),
        call.length,
        messageContainsAll: messageContainsAll,
        contextMessages: <ExpectedContextMessage>[
          for (int other in occurrences)
            if (other != occurrence)
              contextMessage(
                getFile(testFilePath),
                _nth(code, call, other),
                call.length,
              ),
        ],
      ),
  ];

  Future<void> test_statelessWidget() async {
    const String code = r'''
import 'package:flutter/material.dart';

class A extends StatelessWidget {
  const A({super.key});

  @override
  Widget build(BuildContext context) {
    bool a = Theme.of(context).useMaterial3;
    bool b = Theme.of(context).useMaterial3;
    return const Widget();
  }
}
''';
    const String call = 'Theme.of(context)';
    await assertDiagnostics(
      code,
      _group(code, call, [0, 1], messageContainsAll: ["'Theme.of'"]),
    );
  }

  Future<void> test_state_threeCalls() async {
    const String code = r'''
import 'package:flutter/material.dart';

class W extends StatefulWidget {
  const W({super.key});

  @override
  State<W> createState() => _WState();
}

class _WState extends State<W> {
  @override
  Widget build(BuildContext context) {
    double a = MediaQuery.of(context).devicePixelRatio;
    double b = MediaQuery.of(context).devicePixelRatio;
    double c = MediaQuery.of(context).devicePixelRatio;
    return const Widget();
  }
}
''';
    const String call = 'MediaQuery.of(context)';
    await assertDiagnostics(code, _group(code, call, [0, 1, 2]));
  }

  Future<void> test_extraParameter_renamedContext() async {
    const String code = r'''
import 'package:flutter/material.dart';

class Ref {}

abstract class ConsumerWidget extends Widget {
  Widget build(BuildContext context, Ref ref);
}

class A extends ConsumerWidget {
  @override
  Widget build(BuildContext ctx, Ref ref) {
    bool a = Theme.of(ctx).useMaterial3;
    bool b = Theme.of(ctx).useMaterial3;
    return const Widget();
  }
}
''';
    await assertDiagnostics(code, _group(code, 'Theme.of(ctx)', [0, 1]));
  }

  Future<void> test_differentGroups() async {
    const String code = r'''
import 'package:flutter/material.dart';

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ThemeData a = Theme.of(context);
    ThemeData? b = Theme.maybeOf(context);
    MediaQueryData c = MediaQuery.of(context);
    NavigatorState d = Navigator.of(context);
    NavigatorState e = Navigator.of(context, rootNavigator: true);
    NavigatorState f = Navigator.of(context, rootNavigator: true);
    return const Widget();
  }
}
''';
    const String call = 'Navigator.of(context, rootNavigator: true)';
    await assertDiagnostics(code, _group(code, call, [0, 1]));
  }

  Future<void> test_genericTypeArguments() async {
    const String code = r'''
import 'package:flutter/widgets.dart';

class Provider {
  static T of<T>(BuildContext context) => throw Exception();
}

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    int a = Provider.of<int>(context);
    String b = Provider.of<String>(context);
    int c = Provider.of<int>(context);
    return const Widget();
  }
}
''';
    const String call = 'Provider.of<int>(context)';
    await assertDiagnostics(code, _group(code, call, [0, 1]));
  }

  Future<void> test_conditionalsAndCollections() async {
    const String code = r'''
import 'package:flutter/material.dart';

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<bool> values = <bool>[
      if (Theme.of(context).useMaterial3) true,
      for (int i = 0; i < 2; i++) Theme.of(context).useMaterial3,
    ];
    return const Widget();
  }
}
''';
    const String call = 'Theme.of(context)';
    await assertDiagnostics(code, _group(code, call, [0, 1]));
  }

  Future<void> test_notCounted() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    assert(Theme.of(context).useMaterial3);
    void Function() onTap = () => Navigator.of(context).pop();
    void pop() => Navigator.of(context).pop();
    Navigator.of(context).pop();
    bool a = Theme.of(context).useMaterial3;
    return const Widget();
  }
}
''');
  }

  Future<void> test_shadowedContext() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    bool a = Theme.of(context).useMaterial3;
    {
      BuildContext context = this.context;
      bool b = Theme.of(context).useMaterial3;
    }
    return const Widget();
  }

  BuildContext get context => throw Exception();
}
''');
  }

  Future<void> test_notABuildMethod() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

Widget build(BuildContext context) {
  bool a = Theme.of(context).useMaterial3;
  bool b = Theme.of(context).useMaterial3;
  return const Widget();
}

class A {
  Widget _buildHeader(BuildContext context) {
    bool a = Theme.of(context).useMaterial3;
    bool b = Theme.of(context).useMaterial3;
    return const Widget();
  }

}
''');
  }

  Future<void> test_fix() async {
    await assertFix(
      r'''
import 'package:flutter/material.dart';

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Reads the theme
    bool a = Theme.of(context).useMaterial3;
    return Widget(key: Key('${a && Theme.of(context).useMaterial3}'));
  }
}
''',
      r'''
import 'package:flutter/material.dart';

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Reads the theme
    final ThemeData theme = Theme.of(context);
    bool a = theme.useMaterial3;
    return Widget(key: Key('${a && theme.useMaterial3}'));
  }
}
''',
    );
  }

  Future<void> test_fix_maybeOf() async {
    await assertFix(
      r'''
import 'package:flutter/material.dart';

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double? a = MediaQuery.maybeOf(context)?.devicePixelRatio;
    double? b = MediaQuery.maybeOf(context)?.devicePixelRatio;
    return Widget(key: Key('$a$b'));
  }
}
''',
      r'''
import 'package:flutter/material.dart';

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final MediaQueryData? mediaQuery = MediaQuery.maybeOf(context);
    double? a = mediaQuery?.devicePixelRatio;
    double? b = mediaQuery?.devicePixelRatio;
    return Widget(key: Key('$a$b'));
  }
}
''',
    );
  }

  Future<void> test_fix_typeArgumentName() async {
    await assertFix(
      r'''
import 'package:flutter/widgets.dart';

class _CartModel {
  int count = 0;
}

class Provider {
  static T of<T>(BuildContext context) => throw Exception();
}

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    int a = Provider.of<_CartModel>(context).count;
    int b = Provider.of<_CartModel>(context).count;
    return Widget(key: Key('$a$b'));
  }
}
''',
      r'''
import 'package:flutter/widgets.dart';

class _CartModel {
  int count = 0;
}

class Provider {
  static T of<T>(BuildContext context) => throw Exception();
}

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final _CartModel cartModel = Provider.of<_CartModel>(context);
    int a = cartModel.count;
    int b = cartModel.count;
    return Widget(key: Key('$a$b'));
  }
}
''',
    );
  }

  Future<void> test_fix_insideIf() async {
    await assertFix(
      r'''
import 'package:flutter/material.dart';

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (context is Object) {
      bool a = Theme.of(context).useMaterial3;
      return Widget(key: Key('${a && Theme.of(context).useMaterial3}'));
    }
    return const Widget();
  }
}
''',
      r'''
import 'package:flutter/material.dart';

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (context is Object) {
      final ThemeData theme = Theme.of(context);
      bool a = theme.useMaterial3;
      return Widget(key: Key('${a && theme.useMaterial3}'));
    }
    return const Widget();
  }
}
''',
    );
  }

  Future<void> test_fix_importPrefix() async {
    await assertFix(
      r'''
import 'package:flutter/material.dart' as m;

class A extends m.StatelessWidget {
  @override
  m.Widget build(m.BuildContext context) {
    bool a = m.Theme.of(context).useMaterial3;
    return m.Widget(key: m.Key('${a && m.Theme.of(context).useMaterial3}'));
  }
}
''',
      r'''
import 'package:flutter/material.dart' as m;

class A extends m.StatelessWidget {
  @override
  m.Widget build(m.BuildContext context) {
    final m.ThemeData theme = m.Theme.of(context);
    bool a = theme.useMaterial3;
    return m.Widget(key: m.Key('${a && theme.useMaterial3}'));
  }
}
''',
    );
  }

  Future<void> test_inferredTypeArguments() async {
    const String code = r'''
import 'package:flutter/widgets.dart';

class Provider {
  static T of<T>(BuildContext context) => throw Exception();
}

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    int a = Provider.of(context);
    String b = Provider.of(context);
    int c = Provider.of(context);
    return Widget(key: Key('$a$b$c'));
  }
}
''';
    const String call = 'Provider.of(context)';
    await assertDiagnostics(code, _group(code, call, [0, 2]));
  }

  Future<void> test_switchExpression() async {
    const String code = r'''
import 'package:flutter/material.dart';

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    bool a = switch (Theme.of(context).useMaterial3) {
      true => Theme.of(context).useMaterial3,
      false => false,
    };
    return Widget(key: Key('$a'));
  }
}
''';
    const String call = 'Theme.of(context)';
    await assertDiagnostics(code, _group(code, call, [0, 1]));
  }

  Future<void> test_unqualifiedOf() async {
    const String code = r'''
import 'package:flutter/widgets.dart';

class Scope extends StatelessWidget {
  static int of(BuildContext context) => 0;

  @override
  Widget build(BuildContext context) {
    int a = of(context) + of(context);
    return Widget(key: Key('$a'));
  }
}
''';
    await assertDiagnostics(
      code,
      _group(
        code,
        'of(context)',
        [0, 1],
        messageContainsAll: ["'of' is called"],
      ),
    );
  }

  Future<void> test_staticBuild() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

class A {
  static Widget build(BuildContext context) {
    bool a = Theme.of(context).useMaterial3;
    return Widget(key: Key('${a && Theme.of(context).useMaterial3}'));
  }
}
''');
  }

  Future<void> test_fix_inferredTypeArgument() async {
    await assertFix(
      r'''
import 'package:flutter/widgets.dart';

class CartModel {
  int count = 0;
}

class Provider {
  static T of<T>(BuildContext context) => throw Exception();
}

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    CartModel a = Provider.of(context);
    CartModel b = Provider.of(context);
    return Widget(key: Key('${a.count}${b.count}'));
  }
}
''',
      r'''
import 'package:flutter/widgets.dart';

class CartModel {
  int count = 0;
}

class Provider {
  static T of<T>(BuildContext context) => throw Exception();
}

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CartModel cartModel = Provider.of(context);
    CartModel a = cartModel;
    CartModel b = cartModel;
    return Widget(key: Key('${a.count}${b.count}'));
  }
}
''',
    );
  }

  Future<void> test_fix_differentBranches() async {
    await assertFix(
      r'''
import 'package:flutter/material.dart';

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (context is Object) {
      return Widget(key: Key('${Theme.of(context).useMaterial3}'));
    } else {
      return Widget(key: Key('${Theme.of(context).useMaterial3}'));
    }
  }
}
''',
      r'''
import 'package:flutter/material.dart';

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (context is Object) {
      return Widget(key: Key('${theme.useMaterial3}'));
    } else {
      return Widget(key: Key('${theme.useMaterial3}'));
    }
  }
}
''',
    );
  }

  Future<void> test_fix_memberAccessAndLabelNotCollisions() async {
    await assertFix(
      r'''
import 'package:flutter/material.dart';

class Settings {
  bool theme = true;
}

Widget app({required bool theme}) => const Widget();

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    bool a = Theme.of(context).useMaterial3 && Settings().theme;
    return app(theme: a && Theme.of(context).useMaterial3);
  }
}
''',
      r'''
import 'package:flutter/material.dart';

class Settings {
  bool theme = true;
}

Widget app({required bool theme}) => const Widget();

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    bool a = theme.useMaterial3 && Settings().theme;
    return app(theme: a && theme.useMaterial3);
  }
}
''',
    );
  }

  Future<void> test_noFix_nameCollision() async {
    await assertNoFix(r'''
import 'package:flutter/material.dart';

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    bool theme = Theme.of(context).useMaterial3;
    return Widget(key: Key('${theme && Theme.of(context).useMaterial3}'));
  }
}
''');
  }

  Future<void> test_noFix_unprefixedOf() async {
    // The variable would be named `of`, which the calls themselves use.
    await assertNoFix(r'''
import 'package:flutter/material.dart';

class A extends StatelessWidget {
  const A({super.key});

  static ThemeData of(BuildContext context) => Theme.of(context);

  @override
  Widget build(BuildContext context) {
    bool a = of(context).useMaterial3;
    bool b = of(context).useMaterial3;
    return const Widget();
  }
}
''');
  }

  Future<void> test_noFix_expressionBody() async {
    await assertNoFix(r'''
import 'package:flutter/material.dart';

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Widget(
    key: Key('${Theme.of(context).useMaterial3}${Theme.of(context).useMaterial3}'),
  );
}
''');
  }

  Future<void> test_fixAll_twoGroupsInOneBlock() async {
    await assertFixAll(
      r'''
import 'package:flutter/material.dart';

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String a = '${Theme.of(context).useMaterial3}${MediaQuery.of(context).devicePixelRatio}';
    String b = '${Theme.of(context).useMaterial3}${MediaQuery.of(context).devicePixelRatio}';
    return Widget(key: Key(a + b));
  }
}
''',
      r'''
import 'package:flutter/material.dart';

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    String a = '${theme.useMaterial3}${mediaQuery.devicePixelRatio}';
    String b = '${theme.useMaterial3}${mediaQuery.devicePixelRatio}';
    return Widget(key: Key(a + b));
  }
}
''',
    );
  }

  Future<void> test_fixAll_sameNameInTwoGroups() async {
    await assertFixAll(
      r'''
import 'package:flutter/widgets.dart';

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.of(context).pop();
    Navigator.of(context, rootNavigator: true).pop();
    Navigator.of(context, rootNavigator: true).pop();
    return const Widget();
  }
}
''',
      r'''
import 'package:flutter/widgets.dart';

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final NavigatorState navigator = Navigator.of(context);
    navigator.pop();
    navigator.pop();
    Navigator.of(context, rootNavigator: true).pop();
    Navigator.of(context, rootNavigator: true).pop();
    return const Widget();
  }
}
''',
    );
  }

  Future<void> test_generatedFile_part() async {
    const String code = r'''
import 'package:flutter/material.dart';

part 'test.g.dart';

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).useMaterial3 && Theme.of(context).useMaterial3) {}
    return const Widget();
  }
}
''';
    String partPath = '$testPackageLibPath/test.g.dart';
    newFile(testFilePath, code);
    newFile(partPath, r'''
part of 'test.dart';

class B extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).useMaterial3 && Theme.of(context).useMaterial3) {}
    return const Widget();
  }
}
''');
    const String call = 'Theme.of(context)';
    await assertDiagnosticsInUnits([
      (testFilePath, _group(code, call, [0, 1])),
      (partPath, []),
    ]);
  }
}
