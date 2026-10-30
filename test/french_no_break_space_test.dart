// test_reflective_loader requires `test_` prefixed method names.
// ignore_for_file: non_constant_identifier_names, always_specify_types

import 'package:daad_lints/src/rules/french_no_break_space.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'utils/french_rule_tester.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FrenchNoBreakSpaceTest);
  });
}

/// The invisible characters are written as is: U+00A0 and U+202F are typed as
/// characters, not escapes.
@reflectiveTest
class FrenchNoBreakSpaceTest extends FrenchRuleTest {
  @override
  void setUp() {
    rule = FrenchNoBreakSpace();
    super.setUp();
  }

  Future<void> test_regularSpace() async {
    const String code = r'''
String a = 'Bonjour !';
String b = 'Pourquoi ?';
String c = 'Oui ; non';
String d = 'Prix : 5';
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(
        code.indexOf(' !'),
        2,
        messageContainsAll: [
          "'!' must be preceded by a narrow no-break space (U+202F), "
              'found a regular space (U+0020).',
        ],
        correctionContains: '.arb',
      ),
      lint(code.indexOf(' ?'), 2),
      lint(code.indexOf(' ;'), 2),
      lint(
        code.indexOf(' :'),
        2,
        messageContainsAll: [
          "':' must be preceded by a no-break space (U+00A0)",
        ],
      ),
    ]);
  }

  Future<void> test_wrongNoBreakSpace() async {
    const String code = r'''
String a = 'Bonjour !';
String b = 'Prix : 5';
String c = 'Pourquoi ?';
String d = 'Oui ; non';
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(
        code.indexOf(' !'),
        2,
        messageContainsAll: ['found a no-break space (U+00A0)'],
      ),
      lint(code.indexOf(' ?'), 2),
      lint(code.indexOf(' ;'), 2),
      lint(
        code.indexOf(' :'),
        2,
        messageContainsAll: ['found a narrow no-break space (U+202F)'],
      ),
    ]);
  }

  Future<void> test_noSpace() async {
    const String code = r'''
String a = 'Bonjour!';
String b = 'Pourquoi?';
String c = 'Oui; non';
String d = 'Prix: 5';
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(code.indexOf('!'), 1, messageContainsAll: ['found no space']),
      lint(code.indexOf('?'), 1),
      lint(code.indexOf('; non'), 1),
      lint(code.indexOf(':'), 1),
    ]);
  }

  Future<void> test_escapes() async {
    const String code = r'''
String a = 'Prix\u202f: 5';
String b = 'Bonjour\xA0!';
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(
        code.indexOf(r'\u202f'),
        7,
        messageContainsAll: ['found a narrow no-break space (U+202F)'],
      ),
      lint(
        code.indexOf(r'\xA0'),
        5,
        messageContainsAll: ['found a no-break space (U+00A0)'],
      ),
    ]);
  }

  Future<void> test_severalSpaces() async {
    const String code = r'''
String a = 'Bonjour  !';
String b = '5  €';
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(
        code.indexOf('  !'),
        3,
        messageContainsAll: ['found several spaces'],
      ),
      lint(code.indexOf('  €'), 3),
    ]);
  }

  Future<void> test_controlEscape() async {
    const String code = r'''
String a = 'Liste\t!';
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(code.indexOf(r'\t!'), 3, messageContainsAll: ['found U+0009']),
    ]);
  }

  Future<void> test_astralCharacters() async {
    const String code = r'''
String a = 'Bravo 🎉 !';
String b = 'a:𝐀';
String c = '\u{1F389} !';
String d = 'a:\uD835\uDC00';
String e = '\uD835\uDFCE€';
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(code.indexOf(' !'), 2),
      lint(code.lastIndexOf(' !'), 2),
      lint(code.indexOf('€'), 1),
    ]);
  }

  Future<void> test_euro() async {
    const String code = r'''
String a = '5 €';
String b = '5 €';
String c = '5€';
String d(String amount) => '$amount €';
String e(String price) => '${price}€';
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(
        code.indexOf(' €'),
        2,
        messageContainsAll: [
          "'€' must be preceded by a no-break space (U+00A0)",
        ],
      ),
      lint(code.indexOf(' €'), 2),
      lint(code.indexOf('5€') + 1, 1),
      lint(code.indexOf('amount €') + 'amount'.length, 2),
      lint(code.indexOf('}€') + 1, 1),
    ]);
  }

  Future<void> test_interpolation() async {
    const String code = r'''
String a(int count) => '${count} ?';
String b(String name) => '${name}?';
String c(String amount) => 'Total : $amount';
String d(String name) => 'Bravo !$name';
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(code.indexOf(' ?'), 2),
      lint(code.indexOf('}?') + 1, 1),
      lint(code.indexOf(' :'), 2),
      lint(code.indexOf(' !'), 2),
    ]);
  }

  Future<void> test_signAfterEuro() async {
    const String code = r'''
String a = '5 €?';
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(code.indexOf(' €'), 2),
      lint(code.indexOf('?'), 1),
    ]);
  }

  Future<void> test_smiley() async {
    const String code = r'''
String a = 'Super :)';
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(code.indexOf(' :'), 2),
    ]);
  }

  Future<void> test_ellipsis() async {
    const String code = r'''
String a = 'Vraiment…?';
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(code.indexOf('?'), 1),
    ]);
  }

  Future<void> test_newline() async {
    const String code = r'''
String a = 'Liste :\n- a';
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(code.indexOf(' :'), 2),
    ]);
  }

  Future<void> test_multiLine_signAtLineStart() async {
    const String code = r"""
String a = '''
Bonjour
!
''';
""";
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(code.indexOf('\n!'), 2, messageContainsAll: ['found U+000A']),
    ]);
  }

  Future<void> test_doubleQuoted() async {
    const String code = r'''
String a = "Bonjour !";
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(code.indexOf(' !'), 2),
    ]);
  }

  Future<void> test_rawString() async {
    const String code = r'''
String a = r'Prix : 5 €';
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(code.indexOf(' :'), 2),
      lint(code.indexOf(' €'), 2),
    ]);
  }

  Future<void> test_nestedLiteral() async {
    const String code = r'''
String f(int count, {required String one}) => one;
String a(int count) => '${f(count, one: 'Un article !')}';
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(code.indexOf(' !'), 2),
    ]);
  }

  Future<void> test_frFrFile() async {
    const String code = r'''
String a = 'Bonjour !';
''';
    await assertDiagnosticsInNewFile(
      '$testPackageLibPath/l10n/app_localizations_fr_FR.dart',
      code,
      [lint(code.indexOf(' !'), 2)],
    );
  }

  Future<void> test_regionalClass() async {
    const String code = r'''
class AppLocalizationsFr {
  AppLocalizationsFr([String locale = 'fr']);

  String get hello => 'Bonjour !';
}

class AppLocalizationsFrFr extends AppLocalizationsFr {
  AppLocalizationsFrFr() : super('fr_FR');

  String get hello => 'Salut !';
}

class AppLocalizationsFrCa extends AppLocalizationsFr {
  AppLocalizationsFrCa() : super('fr_CA');

  String get hello => 'Bonjour!';

  String get bye => 'Au revoir !';
}

class AppLocalizationsFrCh extends AppLocalizationsFr {
  AppLocalizationsFrCh() : super('fr-CH');

  String get hello => 'Adieu !';
}
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(code.indexOf(' !'), 2),
      lint(code.indexOf('Salut !') + 'Salut'.length, 2),
    ]);
  }

  Future<void> test_correctSpaces() async {
    await assertDiagnosticsInNewFile(frenchFilePath, r'''
String a = 'Bonjour !';
String b = 'Pourquoi ?';
String c = 'Oui ; non';
String d = 'Prix : 5 €';
''', []);
  }

  Future<void> test_euro_notAmount() async {
    await assertDiagnosticsInNewFile(frenchFilePath, r'''
String a = '€';
String b = '€5';
String c = 'Prix en €';
String d = '(en €)';
String e = '5 k€';
String f = ' €';
''', []);
  }

  Future<void> test_notSentencePunctuation() async {
    await assertDiagnosticsInNewFile(frenchFilePath, r'''
import 'package:flutter/painting.dart'; // ignore: unused_import

String a = 'HH:mm';
String b = '10:30';
String c = 'https://x';
String d = '?param=value';
String e = '!=';
String f(int h, int m) => '$h:$m';
String g(String amount) => 'Total :$amount';
''', []);
  }

  Future<void> test_repeatedSigns() async {
    const String code = r'''
String a = 'Quoi?!';
String b = 'Non!!!';
''';
    await assertDiagnosticsInNewFile(frenchFilePath, code, [
      lint(code.indexOf('?'), 1),
      lint(code.indexOf('!!!'), 1),
    ]);
  }

  Future<void> test_signAtStart() async {
    await assertDiagnosticsInNewFile(frenchFilePath, r'''
String a = '?';
String b = ': ';
String c = 'Bonjour ' '!';
''', []);
  }

  Future<void> test_regionalFile() async {
    for (String name in ['messages_fr_CA.dart', 'messages_fr_CH.dart']) {
      await assertDiagnosticsInNewFile('$testPackageLibPath/l10n/$name', r'''
String a = 'Bonjour !';
''', []);
    }
  }

  Future<void> test_franceFile_lowercase() async {
    const String code = r'''
String a = 'Bonjour !';
''';
    await assertDiagnosticsInNewFile(
      '$testPackageLibPath/l10n/messages_fr_fr.dart',
      code,
      [lint(code.indexOf(' !'), 2)],
    );
  }

  Future<void> test_ignoreForFile_name() async {
    await assertDiagnosticsInNewFile(frenchFilePath, r'''
// ignore_for_file: french_no_break_space

String a = 'Bonjour !';
''', []);
  }
}
