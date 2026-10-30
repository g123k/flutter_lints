// test_reflective_loader requires `test_` prefixed method names.
// ignore_for_file: non_constant_identifier_names, always_specify_types

import 'package:daad_lints/src/rules/avoid_hardcoded_strings.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'utils/rule_tester.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidHardcodedStringsTest);
  });
}

@reflectiveTest
class AvoidHardcodedStringsTest extends RuleTest {
  @override
  void setUp() {
    rule = AvoidHardcodedStrings();
    super.setUp();
  }

  // Reported

  Future<void> test_text() async {
    const String code = r'''
import 'package:flutter/material.dart';

Widget w = Text('Hello');
''';
    await assertDiagnostics(code, [
      lint(
        code.indexOf("'Hello'"),
        "'Hello'".length,
        messageContainsAll: ["'Text'"],
      ),
    ]);
  }

  Future<void> test_interpolation() async {
    const String code = r'''
import 'package:flutter/material.dart';

String name = 'x';
Widget w = Text('Hello $name');
''';
    await assertDiagnostics(code, [
      lint(code.indexOf("'Hello \$name'"), "'Hello \$name'".length),
    ]);
  }

  Future<void> test_adjacentStrings() async {
    const String code = r'''
import 'package:flutter/material.dart';

Widget w = Text('Hel' 'lo');
''';
    await assertDiagnostics(code, [
      lint(code.indexOf("'Hel' 'lo'"), "'Hel' 'lo'".length),
    ]);
  }

  Future<void> test_rawMultiline() async {
    const String code = """
import 'package:flutter/material.dart';

Widget w = Text(r'''raw multi
line''');
""";
    const String literal = "r'''raw multi\nline'''";
    await assertDiagnostics(code, [
      lint(code.indexOf(literal), literal.length),
    ]);
  }

  Future<void> test_tooltip() async {
    const String code = r'''
import 'package:flutter/material.dart';

Widget w = Tooltip(message: 'Save');
''';
    await assertDiagnostics(code, [
      lint(
        code.indexOf("'Save'"),
        "'Save'".length,
        messageContainsAll: ["'Tooltip'"],
      ),
    ]);
  }

  Future<void> test_textSpan() async {
    const String code = r'''
import 'package:flutter/painting.dart';

InlineSpan s = TextSpan(text: 'Terms');
''';
    await assertDiagnostics(code, [
      lint(
        code.indexOf("'Terms'"),
        "'Terms'".length,
        messageContainsAll: ["'TextSpan'"],
      ),
    ]);
  }

  Future<void> test_textRich_nestedSpan() async {
    const String code = r'''
import 'package:flutter/material.dart';

Widget w = Text.rich(TextSpan(children: [TextSpan(text: 'a word')]));
''';
    await assertDiagnostics(code, [
      lint(code.indexOf("'a word'"), "'a word'".length),
    ]);
  }

  Future<void> test_inputDecoration() async {
    const String code = r'''
import 'package:flutter/material.dart';

Widget w = TextField(decoration: InputDecoration(hintText: 'Email'));
''';
    await assertDiagnostics(code, [
      lint(
        code.indexOf("'Email'"),
        "'Email'".length,
        messageContainsAll: ["'InputDecoration'"],
      ),
    ]);
  }

  Future<void> test_bottomNavigationBarItem() async {
    const String code = r'''
import 'package:flutter/material.dart';

BottomNavigationBarItem i = BottomNavigationBarItem(
  icon: Widget(),
  label: 'Home',
);
''';
    await assertDiagnostics(code, [
      lint(
        code.indexOf("'Home'"),
        "'Home'".length,
        messageContainsAll: ["'BottomNavigationBarItem'"],
      ),
    ]);
  }

  Future<void> test_dropdownMenuEntry() async {
    const String code = r'''
import 'package:flutter/material.dart';

DropdownMenuEntry<String> e = DropdownMenuEntry(value: 'fr', label: 'French');
''';
    await assertDiagnostics(code, [
      lint(
        code.indexOf("'French'"),
        "'French'".length,
        messageContainsAll: ["'DropdownMenuEntry'"],
      ),
    ]);
  }

  Future<void> test_semanticsLabel() async {
    const String code = r'''
import 'package:flutter/material.dart';

Widget w = Text('Close', semanticsLabel: 'Close dialog');
''';
    await assertDiagnostics(code, [
      lint(code.indexOf("'Close'"), "'Close'".length),
      lint(code.indexOf("'Close dialog'"), "'Close dialog'".length),
    ]);
  }

  Future<void> test_imageSemanticLabel() async {
    const String code = r'''
import 'package:flutter/material.dart';

Widget w = Image.asset('assets/logo.png', semanticLabel: 'Company logo');
''';
    await assertDiagnostics(code, [
      lint(
        code.indexOf("'Company logo'"),
        "'Company logo'".length,
        messageContainsAll: ["'Image'"],
      ),
    ]);
  }

  Future<void> test_customWidget() async {
    const String code = r'''
import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  const MyButton({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Text(label);
}

Widget w = MyButton(label: 'Save');
''';
    await assertDiagnostics(code, [
      lint(
        code.indexOf("'Save'"),
        "'Save'".length,
        messageContainsAll: ["'MyButton'"],
      ),
    ]);
  }

  Future<void> test_nestedWidget_innerOnly() async {
    const String code = r'''
import 'package:flutter/material.dart';

Widget w = Padding(padding: EdgeInsets.all(1.0), child: Text('OK'));
''';
    await assertDiagnostics(code, [
      lint(code.indexOf("'OK'"), "'OK'".length, messageContainsAll: ["'Text'"]),
    ]);
  }

  Future<void> test_dotShorthand() async {
    const String code = r'''
import 'package:flutter/material.dart';

Text child = .new('Hello');
''';
    await assertDiagnostics(code, [
      lint(
        code.indexOf("'Hello'"),
        "'Hello'".length,
        messageContainsAll: ["'Text'"],
      ),
    ]);
  }

  Future<void> test_trailingDot() async {
    const String code = r'''
import 'package:flutter/material.dart';

Widget w = Text('Hello.');
''';
    await assertDiagnostics(code, [
      lint(code.indexOf("'Hello.'"), "'Hello.'".length),
    ]);
  }

  Future<void> test_formLabel_colon() async {
    const String code = r'''
import 'package:flutter/material.dart';

Widget w = Text('Email:');
''';
    await assertDiagnostics(code, [
      lint(code.indexOf("'Email:'"), "'Email:'".length),
    ]);
  }

  Future<void> test_nonAsciiLetters() async {
    const String code = r'''
import 'package:flutter/material.dart';

Widget a = Text('日本語');
Widget b = Text('été');
''';
    await assertDiagnostics(code, [
      lint(code.indexOf("'日本語'"), "'日本語'".length),
      lint(code.indexOf("'été'"), "'été'".length),
    ]);
  }

  Future<void> test_semanticsWidget_label() async {
    const String code = r'''
import 'package:flutter/material.dart';

Widget w = Semantics(label: 'Close', child: Widget());
''';
    await assertDiagnostics(code, [
      lint(
        code.indexOf("'Close'"),
        "'Close'".length,
        messageContainsAll: ["'Semantics'"],
      ),
    ]);
  }

  Future<void> test_otherMethodOnWidget() async {
    const String code = r'''
import 'package:flutter/material.dart';

String s = Text('Hello').toString();
''';
    await assertDiagnostics(code, [
      lint(code.indexOf("'Hello'"), "'Hello'".length),
    ]);
  }

  Future<void> test_constText() async {
    const String code = r'''
import 'package:flutter/material.dart';

Widget w = const Text('Hello');
''';
    await assertDiagnostics(code, [
      lint(code.indexOf("'Hello'"), "'Hello'".length),
    ]);
  }

  Future<void> test_customWidget_nameParameter() async {
    const String code = r'''
import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) => Text(name);
}

Widget w = ProfileHeader(name: 'Guest');
''';
    await assertDiagnostics(code, [
      lint(code.indexOf("'Guest'"), "'Guest'".length),
    ]);
  }

  Future<void> test_whitespaceOverridesTechnicalToken() async {
    const String code = r'''
import 'package:flutter/material.dart';

Widget a = Text('user_name is required');
Widget b = Text('See example.com for details');
Widget c = Text('Hello world_');
''';
    await assertDiagnostics(code, [
      lint(code.indexOf("'user_name"), "'user_name is required'".length),
      lint(code.indexOf("'See"), "'See example.com for details'".length),
      lint(code.indexOf("'Hello"), "'Hello world_'".length),
    ]);
  }

  Future<void> test_trailingSlash() async {
    const String code = r'''
import 'package:flutter/material.dart';

Widget w = Text('Yes/');
''';
    await assertDiagnostics(code, [
      lint(code.indexOf("'Yes/'"), "'Yes/'".length),
    ]);
  }

  // Not reported: no letter

  Future<void> test_noLetter() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

String a = 'a';
String b = 'b';
Widget w1 = Text('42');
Widget w2 = Text('');
Widget w3 = Text(' - ');
Widget w4 = Text('${a}_${b}');
''');
  }

  Future<void> test_interpolatedExpressionsNotCounted() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

class User {
  const User(this.name);

  final String name;
}

String name = 'x';
User user = const User('y');
Widget a = Text('$name');
Widget b = Text('${user.name}');
Widget c = Text('user' '_id');
''');
  }

  // Not reported: technical tokens

  Future<void> test_underscore() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

Widget w = Text('user_id');
''');
  }

  Future<void> test_slash() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

Widget w = Text('a/b');
''');
  }

  Future<void> test_dottedToken() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

Widget a = Text('logo.png');
Widget b = Text('v1.2.3');
''');
  }

  Future<void> test_colonAndHash() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

Widget a = Text('#tag');
Widget b = Text('key:value');
Widget c = Text('https://example.com');
''');
  }

  Future<void> test_abbreviation_acceptedFalseNegative() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

Widget w = Text('e.g.');
''');
  }

  Future<void> test_assetAndUrl() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

Widget a = Image.asset('assets/logo.png');
Widget b = Image.network('https://example.com/a.png');
''');
  }

  // Not reported: parameter not declared `String`

  Future<void> test_objectAndGenericParameters() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

Widget a = Hero(tag: 'avatar', child: Widget());
Widget b = DropdownMenuItem<String>(value: 'us', child: Widget());
''');
  }

  // Not reported: technical parameters

  Future<void> test_technicalParameters() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

Widget a = TextField(restorationId: 'email');
Widget b = Semantics(identifier: 'login', child: Widget());
Widget c = Image.asset('logo', package: 'ui');
Widget d = Image.network('avatar');
''');
  }

  Future<void> test_semanticsIdentifier_skippedWhileTextReported() async {
    const String code = r'''
import 'package:flutter/material.dart';

Widget w = Text('Hi', semanticsIdentifier: 'greeting');
''';
    await assertDiagnostics(code, [lint(code.indexOf("'Hi'"), "'Hi'".length)]);
  }

  // Not reported: translated in place

  Future<void> test_easyLocalization() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

extension TextTranslateExtension on Text {
  Text tr() => this;
  Text plural(num value) => this;
}

Widget a = Text('hello').tr();
Widget b = Text('hello').plural(2);
''');
  }

  // Not reported: not a literal argument

  Future<void> test_nonLiteralArguments() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

const String kTitle = 'Title';

class L10n {
  String get hello => 'Hello';
}

Widget build(String title, String name, L10n l10n) => Padding(
  padding: EdgeInsets.all(1.0),
  child: Text(title),
);

Widget a = Text(L10n().hello);
Widget b = Text(kTitle);
Widget c = Text('hello'.toUpperCase());
Widget d = Text('Hello ' + kTitle);
''');
  }

  Future<void> test_defaultValue() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  const MyButton({this.label = 'Save', super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Text(label);
}
''');
  }

  // Not reported: neither a widget nor a holder

  Future<void> test_nonWidgetSinks() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

class MyService {
  MyService({required this.label});

  final String label;
}

void log(String message) {}

void f() {
  log('started');
  MyService(label: 'Cache ready');
  Key('Some key');
  throw Exception('bad');
}
''');
  }

  Future<void> test_lookalikeClassesOutsideFlutter() async {
    await assertNoDiagnostics(r'''
class Widget {
  const Widget(this.title);

  final String title;
}

class InputDecoration {
  const InputDecoration({this.hintText});

  final String? hintText;
}

Widget w = Widget('Hello');
InputDecoration d = InputDecoration(hintText: 'Email');
''');
  }

  // Not reported: generated and test files

  Future<void> test_generatedFile_part() async {
    const String code = r'''
import 'package:flutter/material.dart';

part 'test.g.dart';

Widget a = Text('Hello');
''';
    String partPath = '$testPackageLibPath/test.g.dart';
    newFile(testFilePath, code);
    newFile(partPath, r'''
part of 'test.dart';

Widget b = Text('Generated');
''');
    await assertDiagnosticsInUnits([
      (testFilePath, [lint(code.indexOf("'Hello'"), "'Hello'".length)]),
      (partPath, []),
    ]);
  }

  Future<void> test_testDirectory() async {
    await assertDiagnosticsInNewFile(
      '$testPackageRootPath/test/helpers/pump_app.dart',
      r'''
import 'package:flutter/material.dart';

Widget w = Text('Hello');
''',
      [],
    );
  }

  Future<void> test_integrationTestDirectory() async {
    await assertDiagnosticsInNewFile(
      '$testPackageRootPath/integration_test/robots/login_robot.dart',
      r'''
import 'package:flutter/material.dart';

Widget w = Text('Hello');
''',
      [],
    );
  }

  Future<void> test_testSuffix() async {
    await assertDiagnosticsInNewFile(
      '$testPackageLibPath/golden_test.dart',
      r'''
import 'package:flutter/material.dart';

Widget w = Text('Hello');
''',
      [],
    );
  }
}
