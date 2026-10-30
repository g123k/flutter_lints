import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:daad_lints/src/utils/member_source_range.dart';
import 'package:test/test.dart';

/// The source of the first member of the first class of [code], with what
/// moves along with it.
String memberSource(String code) {
  ClassDeclaration declaration =
      parseString(content: code).unit.declarations.first as ClassDeclaration;
  ClassMember member = declaration.body.members.first;
  SourceRange range = memberSourceRange(code, member);
  return code.substring(range.offset, range.end);
}

void main() {
  group('memberSourceRange', () {
    test('a bare member is its own range', () {
      const String code = '''
class A {
  final int a = 1;
}
''';
      expect(memberSource(code), 'final int a = 1;');
    });

    test('the doc comment and the annotations move with the member', () {
      const String code = '''
class A {
  /// Doc.
  @Deprecated('x')
  final int a = 1;
}
''';
      expect(memberSource(code), '''
/// Doc.
  @Deprecated('x')
  final int a = 1;''');
    });

    test('the comment lines directly above move with the member', () {
      const String code = '''
class A {
  // ignore: unused_field
  // ignore: another
  final int a = 1;
}
''';
      expect(memberSource(code), '''
// ignore: unused_field
  // ignore: another
  final int a = 1;''');
    });

    test('a comment separated by a blank line stays behind', () {
      const String code = '''
class A {
  // A section header

  final int a = 1;
}
''';
      expect(memberSource(code), 'final int a = 1;');
    });

    test('a comment above the class is not reached', () {
      const String code = '''// header
class A {
  final int a = 1;
}
''';
      expect(memberSource(code), 'final int a = 1;');
    });

    test('a trailing comment on the last line moves with the member', () {
      const String code = '''
class A {
  final int a = 1; // trailing
  final int b = 2;
}
''';
      expect(memberSource(code), 'final int a = 1; // trailing');
    });

    test('a member on the last line of the file has no trailing comment', () {
      const String code = 'class A { final int a = 1; }';
      expect(memberSource(code), 'final int a = 1;');
    });
  });

  test('lineStartOf is the offset after the previous line break', () {
    const String code = 'ab\ncd\n';
    expect(lineStartOf(code, 0), 0);
    expect(lineStartOf(code, 2), 0);
    expect(lineStartOf(code, 3), 3);
    expect(lineStartOf(code, 5), 3);
    expect(lineStartOf(code, 6), 6);
  });

  test('indentationAt is the whitespace before the offset on its line', () {
    const String code = 'a\n    b\n\tc';
    expect(indentationAt(code, 0), '');
    expect(indentationAt(code, code.indexOf('b')), '    ');
    expect(indentationAt(code, code.indexOf('c')), '\t');
  });
}
