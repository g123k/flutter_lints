// test_reflective_loader requires `test_` prefixed method names.
// ignore_for_file: non_constant_identifier_names, always_specify_types

// ignore: implementation_imports, the expected diagnostic types are not exported
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:daad_lints/src/fixes/replace_with_media_query_accessor.dart';
import 'package:daad_lints/src/rules/avoid_media_query_of.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'utils/flutter_stub.dart';
import 'utils/rule_tester.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidMediaQueryOfTest);
    defineReflectiveTests(AvoidMediaQueryOfWithoutWidthOfTest);
  });
}

/// A `build` method running [statements], in a library importing
/// `package:flutter/widgets.dart`.
String _build(String statements) =>
    '''
import 'package:flutter/widgets.dart';

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
$statements
    return const Widget();
  }
}
''';

@reflectiveTest
class AvoidMediaQueryOfTest extends RuleTest {
  @override
  void setUp() {
    rule = AvoidMediaQueryOf();
    createFix = ReplaceWithMediaQueryAccessor.new;
    super.setUp();
  }

  /// A diagnostic on the [n]th (0-based) occurrence of [call] in [code].
  ExpectedDiagnostic _lint(
    String code,
    String call, {
    int n = 0,
    List<Pattern> messageContainsAll = const <Pattern>[],
  }) {
    int offset = -1;
    for (int i = 0; i <= n; i++) {
      offset = code.indexOf(call, offset + 1);
    }
    return lint(offset, call.length, messageContainsAll: messageContainsAll);
  }

  Future<void> test_of_property() async {
    String code = _build('''
    Size a = MediaQuery.of(context).size;
    double b = MediaQuery.of(context).padding.top;
''');
    await assertDiagnostics(code, [
      _lint(
        code,
        'MediaQuery.of(context)',
        messageContainsAll: ["'MediaQuery.of'"],
      ),
      _lint(code, 'MediaQuery.of(context)', n: 1),
    ]);
  }

  Future<void> test_maybeOf_property() async {
    String code = _build('''
    Size? a = MediaQuery.maybeOf(context)?.size;
''');
    await assertDiagnostics(code, [
      _lint(
        code,
        'MediaQuery.maybeOf(context)',
        messageContainsAll: ["'MediaQuery.maybeOf'"],
      ),
    ]);
  }

  Future<void> test_outsideBuild() async {
    const String code = r'''
import 'package:flutter/widgets.dart';

double width(BuildContext context) => MediaQuery.of(context).size.width;

class W extends StatefulWidget {
  @override
  State<W> createState() => _WState();
}

class _WState extends State<W> {
  void didChangeDependencies() {
    Size size = MediaQuery.of(context).size;
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''';
    await assertDiagnostics(code, [
      _lint(code, 'MediaQuery.of(context)'),
      _lint(code, 'MediaQuery.of(context)', n: 1),
    ]);
  }

  Future<void> test_prefixedImport() async {
    const String code = r'''
import 'package:flutter/widgets.dart' as w;

w.Size size(w.BuildContext context) => w.MediaQuery.of(context).size;
''';
    await assertDiagnostics(code, [_lint(code, 'w.MediaQuery.of(context)')]);
  }

  Future<void> test_typedefAlias() async {
    const String code = r'''
import 'package:flutter/widgets.dart';

typedef MQ = MediaQuery;

Size size(BuildContext context) => MQ.of(context).size;
''';
    await assertDiagnostics(code, [_lint(code, 'MQ.of(context)')]);
  }

  Future<void> test_exemptedMethods() async {
    await assertNoDiagnostics(
      _build('''
    MediaQueryData a = MediaQuery.of(context).copyWith(size: const Size(1.0, 1.0));
    MediaQueryData b = MediaQuery.of(context).removePadding(removeTop: true);
    MediaQueryData? c = MediaQuery.maybeOf(context)?.copyWith();
    MediaQueryData? d = MediaQuery.maybeOf(context)?.removePadding();
    MediaQueryData Function({Size? size}) e = MediaQuery.of(context).copyWith;
'''),
    );
  }

  Future<void> test_dedicatedAccessor() async {
    await assertNoDiagnostics(
      _build('''
    Size a = MediaQuery.sizeOf(context);
    EdgeInsets? b = MediaQuery.maybePaddingOf(context);
'''),
    );
  }

  Future<void> test_tearOffAndDocReference() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

/// Reads [MediaQuery.of] once.
MediaQueryData Function(BuildContext) read = MediaQuery.of;
''');
  }

  Future<void> test_customMediaQuery() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart' hide MediaQuery;

abstract final class MediaQuery {
  static MediaQueryData of(BuildContext context) => const MediaQueryData();
}

Size size(BuildContext context) => MediaQuery.of(context).size;
''');
  }

  Future<void> test_generatedPart() async {
    const String code = r'''
import 'package:flutter/widgets.dart';

part 'generated.dart';

Size a(BuildContext context) => MediaQuery.of(context).size;
''';
    String partPath = '$testPackageLibPath/generated.dart';
    newFile(testFilePath, code);
    newFile(partPath, r'''
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test.dart';

Size b(BuildContext context) => MediaQuery.of(context).size;
''');
    await assertDiagnosticsInUnits([
      (testFilePath, [_lint(code, 'MediaQuery.of(context)')]),
      (partPath, []),
    ]);
  }

  Future<void> test_fix_property() async {
    await assertFix(
      _build('''
    Size a = MediaQuery.of(context).size;
'''),
      _build('''
    Size a = MediaQuery.sizeOf(context);
'''),
      fixArguments: ['sizeOf'],
    );
    await assertFix(
      _build('''
    Size a = MediaQuery.of(context)?.size;
'''),
      _build('''
    Size a = MediaQuery.sizeOf(context);
'''),
    );
  }

  Future<void> test_fix_furtherAccess() async {
    await assertFix(
      _build('''
    double a = MediaQuery.of(context).padding.top;
'''),
      _build('''
    double a = MediaQuery.paddingOf(context).top;
'''),
      fixArguments: ['paddingOf'],
    );
  }

  Future<void> test_fix_sizeWidth() async {
    await assertFix(
      _build('''
    double a = MediaQuery.of(context).size.width;
'''),
      _build('''
    double a = MediaQuery.widthOf(context);
'''),
      fixArguments: ['widthOf'],
    );
  }

  Future<void> test_fix_sizeOtherMember() async {
    await assertFix(
      _build('''
    double a = MediaQuery.of(context).size.shortestSide;
'''),
      _build('''
    double a = MediaQuery.sizeOf(context).shortestSide;
'''),
    );
  }

  Future<void> test_fix_maybeOf() async {
    await assertFix(
      _build('''
    EdgeInsets? a = MediaQuery.maybeOf(context)?.padding;
'''),
      _build('''
    EdgeInsets? a = MediaQuery.maybePaddingOf(context);
'''),
      fixArguments: ['maybePaddingOf'],
    );
  }

  Future<void> test_fix_maybeOf_sizeWidth() async {
    await assertFix(
      _build('''
    double? a = MediaQuery.maybeOf(context)?.size.width;
'''),
      _build('''
    double? a = MediaQuery.maybeWidthOf(context);
'''),
      fixArguments: ['maybeWidthOf'],
    );
  }

  Future<void> test_fix_maybeOf_continuation() async {
    await assertFix(
      _build('''
    double? a = MediaQuery.maybeOf(context)?.padding.top;
'''),
      _build('''
    double? a = MediaQuery.maybePaddingOf(context)?.top;
'''),
    );
    await assertFix(
      _build('''
    int? a = MediaQuery.maybeOf(context)?.size.width.round();
'''),
      _build('''
    int? a = MediaQuery.maybeWidthOf(context)?.round();
'''),
    );
    await assertFix(
      _build('''
    double? a = MediaQuery.maybeOf(context)?.size.shortestSide;
'''),
      _build('''
    double? a = MediaQuery.maybeSizeOf(context)?.shortestSide;
'''),
    );
  }

  Future<void> test_fix_prefixedImport() async {
    await assertFix(
      r'''
import 'package:flutter/widgets.dart' as w;

w.Size size(w.BuildContext context) => w.MediaQuery.of(context).size;
''',
      r'''
import 'package:flutter/widgets.dart' as w;

w.Size size(w.BuildContext context) => w.MediaQuery.sizeOf(context);
''',
    );
  }

  Future<void> test_fix_typedefAlias() async {
    await assertFix(
      r'''
import 'package:flutter/widgets.dart';

typedef MQ = MediaQuery;

Size size(BuildContext context) => MQ.of(context).size;
''',
      r'''
import 'package:flutter/widgets.dart';

typedef MQ = MediaQuery;

Size size(BuildContext context) => MQ.sizeOf(context);
''',
    );
  }

  Future<void> test_fix_noOfSuffix() async {
    await assertFix(
      _build('''
    bool a = MediaQuery.of(context).supportsShowingSystemContextMenu;
'''),
      _build('''
    bool a = MediaQuery.supportsShowingSystemContextMenu(context);
'''),
      fixArguments: ['supportsShowingSystemContextMenu'],
    );
  }

  Future<void> test_fix_insideExempted() async {
    await assertFix(
      _build('''
    MediaQueryData a = MediaQuery.of(context).copyWith(size: MediaQuery.of(context).size);
'''),
      _build('''
    MediaQueryData a = MediaQuery.of(context).copyWith(size: MediaQuery.sizeOf(context));
'''),
    );
  }

  Future<void> test_noFix_wholeObject() async {
    await assertNoFix(r'''
import 'package:flutter/widgets.dart';

Object use(MediaQueryData data) => data;

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final MediaQueryData data = MediaQuery.of(context);
    Object b = use(MediaQuery.of(context));
    return const Widget();
  }
}
''');
  }

  Future<void> test_noFix_noAccessor() async {
    await assertNoFix(r'''
import 'package:flutter/widgets.dart';

extension on MediaQueryData {
  double get width => size.width;
}

class A extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double a = MediaQuery.of(context).textScaleFactor;
    double? b = MediaQuery.of(context).letterSpacingOverride;
    double c = MediaQuery.of(context).width;
    return const Widget();
  }
}
''');
  }

  Future<void> test_noFix_unsupportedShapes() async {
    await assertNoFix(
      _build('''
    Size a = MediaQuery.maybeOf(context)!.size;
    Size b = (MediaQuery.of(context)).size;
    MediaQueryData c = MediaQuery.of(context)..size;
    String d = MediaQuery.of(context).toString();
    EdgeInsets? e = MediaQuery.maybeOf(context)?.padding!;
    EdgeInsets? f = MediaQuery.maybeOf(context)?.padding?..top;
'''),
    );
  }

  Future<void> test_fixAll() async {
    await assertFixAll(
      _build('''
    Size a = MediaQuery.of(context).size;
    EdgeInsets b = MediaQuery.of(context).padding;
    MediaQueryData c = MediaQuery.of(context);
'''),
      _build('''
    Size a = MediaQuery.sizeOf(context);
    EdgeInsets b = MediaQuery.paddingOf(context);
    MediaQueryData c = MediaQuery.of(context);
'''),
    );
  }
}

/// Against a Flutter version without `MediaQuery.widthOf` / `maybeWidthOf`.
@reflectiveTest
class AvoidMediaQueryOfWithoutWidthOfTest extends RuleTest {
  @override
  Map<String, String> get flutterFiles => <String, String>{
    ...flutterStubFiles,
    'lib/src/widgets/media_query.dart': r'''
import '../painting/basic_types.dart';
import 'framework.dart';

class MediaQueryData {
  const MediaQueryData({this.size = const Size(0.0, 0.0)});

  final Size size;
}

abstract final class MediaQuery {
  static MediaQueryData of(BuildContext context) => const MediaQueryData();

  static MediaQueryData? maybeOf(BuildContext context) => null;

  static Size sizeOf(BuildContext context) => of(context).size;

  static Size? maybeSizeOf(BuildContext context) => maybeOf(context)?.size;
}
''',
  };

  @override
  void setUp() {
    rule = AvoidMediaQueryOf();
    createFix = ReplaceWithMediaQueryAccessor.new;
    super.setUp();
  }

  Future<void> test_fix_sizeWidth_fallback() async {
    await assertFix(
      _build('''
    double a = MediaQuery.of(context).size.width;
'''),
      _build('''
    double a = MediaQuery.sizeOf(context).width;
'''),
      fixArguments: ['sizeOf'],
    );
  }

  Future<void> test_fix_maybeOf_sizeWidth_fallback() async {
    await assertFix(
      _build('''
    double? a = MediaQuery.maybeOf(context)?.size.width;
'''),
      _build('''
    double? a = MediaQuery.maybeSizeOf(context)?.width;
'''),
    );
  }
}
