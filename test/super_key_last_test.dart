// test_reflective_loader requires `test_` prefixed method names.
// ignore_for_file: non_constant_identifier_names, always_specify_types

import 'package:daad_lints/src/fixes/move_super_key_last.dart';
import 'package:daad_lints/src/rules/super_key_last.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'utils/rule_tester.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperKeyLastTest);
  });
}

@reflectiveTest
class SuperKeyLastTest extends RuleTest {
  @override
  void setUp() {
    rule = SuperKeyLast();
    createFix = MoveSuperKeyLast.new;
    super.setUp();
  }

  Future<void> test_first() async {
    const String code = r'''
import 'package:flutter/widgets.dart';

class A extends Widget {
  const A({super.key, this.a});

  final int? a;
}
''';
    await assertDiagnostics(code, [
      lint(code.indexOf('super.key'), 'super.key'.length),
    ]);
  }

  Future<void> test_middle() async {
    const String code = r'''
import 'package:flutter/widgets.dart';

class A extends Widget {
  const A(this.a, {this.b, super.key, required this.c});

  final int a;
  final int? b;
  final int c;
}
''';
    await assertDiagnostics(code, [
      lint(code.indexOf('super.key'), 'super.key'.length),
    ]);
  }

  Future<void> test_last() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class A extends Widget {
  const A({this.a, super.key});
  const A.only({super.key}) : a = null;

  final int? a;
}
''');
  }

  Future<void> test_required() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class A extends Widget {
  const A({required super.key, this.a});

  final int? a;
}
''');
  }

  Future<void> test_positional() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class P {
  const P([this.key]);

  final Key? key;
}

class A extends P {
  const A(super.key, this.a);

  final int a;
}

class B extends P {
  const B([super.key, this.b]);

  final int? b;
}
''');
  }

  Future<void> test_otherForms() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class A extends Widget {
  const A({Key? key, this.a}) : super(key: key);
  factory A.create({Key? key, int? a}) => A(key: key, a: a);

  final int? a;
}

class B {
  const B({this.key, this.b});

  final Key? key;
  final int? b;
}
''');
  }

  Future<void> test_fix_singleLine() async {
    await assertFix(
      r'''
import 'package:flutter/widgets.dart';

class A extends Widget {
  const A({super.key, this.a, this.b});

  final int? a;
  final int? b;
}
''',
      r'''
import 'package:flutter/widgets.dart';

class A extends Widget {
  const A({this.a, this.b, super.key});

  final int? a;
  final int? b;
}
''',
    );
  }

  Future<void> test_fix_singleLine_trailingComma() async {
    await assertFix(
      r'''
import 'package:flutter/widgets.dart';

class A extends Widget {
  const A({super.key, this.a,});

  final int? a;
}
''',
      r'''
import 'package:flutter/widgets.dart';

class A extends Widget {
  const A({this.a, super.key,});

  final int? a;
}
''',
    );
  }

  Future<void> test_fix_multiLine_noTrailingComma() async {
    await assertFix(
      r'''
import 'package:flutter/widgets.dart';

class A extends Widget {
  const A(
    this.a, {
    super.key,
    required this.b
  });

  final int a;
  final int b;
}
''',
      r'''
import 'package:flutter/widgets.dart';

class A extends Widget {
  const A(
    this.a, {
    required this.b,
    super.key
  });

  final int a;
  final int b;
}
''',
    );
  }

  Future<void> test_fix_multiLine_trailingComma() async {
    await assertFix(
      r'''
import 'package:flutter/widgets.dart';

class A extends Widget {
  const A({
    super.key,
    this.a,
    this.b,
  });

  final int? a;
  final int? b;
}
''',
      r'''
import 'package:flutter/widgets.dart';

class A extends Widget {
  const A({
    this.a,
    this.b,
    super.key,
  });

  final int? a;
  final int? b;
}
''',
    );
  }

  Future<void> test_fix_keepsMetadataCommentsAndDefaultValue() async {
    await assertFix(
      r'''
import 'package:flutter/widgets.dart';

class A extends Widget {
  const A({
    // The key
    @Deprecated('use b') super.key = const Key('a'),
    this.a,
  });

  final int? a;
}
''',
      r'''
import 'package:flutter/widgets.dart';

class A extends Widget {
  const A({
    this.a,
    // The key
    @Deprecated('use b') super.key = const Key('a'),
  });

  final int? a;
}
''',
    );
  }

  Future<void> test_noFix_trailingComment() async {
    await assertNoFix(r'''
import 'package:flutter/widgets.dart';

class A extends Widget {
  const A({
    super.key, // The key
    this.a,
  });

  final int? a;
}
''');
  }

  Future<void> test_noFix_lastParameterComment() async {
    await assertNoFix(r'''
import 'package:flutter/widgets.dart';

class A extends Widget {
  const A({
    super.key,
    this.a, // The value
  });

  final int? a;
}
''');
  }

  Future<void> test_fix_commentAfterList() async {
    await assertFix(
      r'''
import 'package:flutter/widgets.dart';

class A extends Widget {
  const A({super.key, this.url = 'http://a'}); // A widget

  final String url;
}
''',
      r'''
import 'package:flutter/widgets.dart';

class A extends Widget {
  const A({this.url = 'http://a', super.key}); // A widget

  final String url;
}
''',
    );
  }

  Future<void> test_fixAll() async {
    await assertFixAll(
      r'''
import 'package:flutter/widgets.dart';

class A extends Widget {
  const A({super.key, this.a});
  const A.named({super.key, this.a, this.b});

  final int? a;
  final int? b;
}
''',
      r'''
import 'package:flutter/widgets.dart';

class A extends Widget {
  const A({this.a, super.key});
  const A.named({this.a, this.b, super.key});

  final int? a;
  final int? b;
}
''',
    );
  }

  Future<void> test_generatedFile_suffix() async {
    String path = '$testPackageLibPath/a.g.dart';
    newFile(path, r'''
import 'package:flutter/widgets.dart';

class A extends Widget {
  const A({super.key, this.a});

  final int? a;
}
''');
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_generatedFile_header() async {
    await assertNoDiagnostics(r'''
// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:flutter/widgets.dart';

class A extends Widget {
  const A({super.key, this.a});

  final int? a;
}
''');
  }

  Future<void> test_generatedFile_part() async {
    const String code = r'''
import 'package:flutter/widgets.dart';

part 'test.g.dart';

class A extends Widget {
  const A({super.key, this.a});

  final int? a;
}
''';
    String partPath = '$testPackageLibPath/test.g.dart';
    newFile(testFilePath, code);
    newFile(partPath, r'''
part of 'test.dart';

class B extends Widget {
  const B({super.key, this.b});

  final int? b;
}
''');
    await assertDiagnosticsInUnits([
      (testFilePath, [lint(code.indexOf('super.key'), 'super.key'.length)]),
      (partPath, []),
    ]);
  }
}
