// ignore_for_file: always_specify_types

import 'package:daad_lints/src/utils/string_decoder.dart';
import 'package:test/test.dart';

/// Decodes the whole of [source], as the content of a string literal.
List<DecodedChar> decode(String source, {bool raw = false}) =>
    decodeStringLiteral(source, 0, source.length, raw: raw);

void main() {
  test('a plain character is one code unit at its offset', () {
    expect(decode('ab'), [
      (codePoint: 0x61, offset: 0, length: 1),
      (codePoint: 0x62, offset: 1, length: 1),
    ]);
  });

  test('only the range between start and end is decoded', () {
    expect(decodeStringLiteral("'ab'", 1, 3, raw: false), [
      (codePoint: 0x61, offset: 1, length: 1),
      (codePoint: 0x62, offset: 2, length: 1),
    ]);
  });

  test('a control escape is one character spanning the escape', () {
    expect(decode(r'a\nb'), [
      (codePoint: 0x61, offset: 0, length: 1),
      (codePoint: 0x0A, offset: 1, length: 2),
      (codePoint: 0x62, offset: 3, length: 1),
    ]);
    expect(decode(r'\r\t\b\f\v').map((DecodedChar c) => c.codePoint), [
      0x0D,
      0x09,
      0x08,
      0x0C,
      0x0B,
    ]);
  });

  test('an escaped quote or backslash is the character itself', () {
    expect(decode(r"\'\\"), [
      (codePoint: 0x27, offset: 0, length: 2),
      (codePoint: 0x5C, offset: 2, length: 2),
    ]);
  });

  test(r'\uXXXX and \xXX are decoded with their whole range', () {
    // Assembled at runtime: some tools decode the escapes in a source file.
    String source = 'l${r'\'}u2019${r'\'}x41';
    expect(decode(source), [
      (codePoint: 0x6C, offset: 0, length: 1),
      (codePoint: 0x2019, offset: 1, length: 6),
      (codePoint: 0x41, offset: 7, length: 4),
    ]);
  });

  test(r'\u{...} accepts one to six hex digits', () {
    expect(decode(r'\u{41}\u{1F600}'), [
      (codePoint: 0x41, offset: 0, length: 6),
      (codePoint: 0x1F600, offset: 6, length: 9),
    ]);
  });

  test('a malformed escape yields the backslash and goes on', () {
    expect(decode(r'\u12'), [
      (codePoint: 0x5C, offset: 0, length: 1),
      (codePoint: 0x75, offset: 1, length: 1),
      (codePoint: 0x31, offset: 2, length: 1),
      (codePoint: 0x32, offset: 3, length: 1),
    ]);
    const DecodedChar backslash = (codePoint: 0x5C, offset: 0, length: 1);
    expect(decode(r'\u{}').first, backslash);
    expect(decode(r'\u{110000}').first, backslash);
    expect(decode(r'\u{41').first, backslash);
    expect(decode(r'\xZZ').first, backslash);
    expect(decode(r'\u+041').first, backslash);
  });

  test('a trailing backslash is the backslash itself', () {
    expect(decode(r'a\'), [
      (codePoint: 0x61, offset: 0, length: 1),
      (codePoint: 0x5C, offset: 1, length: 1),
    ]);
  });

  test('a surrogate pair written as is is one character', () {
    expect(decode('😀!'), [
      (codePoint: 0x1F600, offset: 0, length: 2),
      (codePoint: 0x21, offset: 2, length: 1),
    ]);
  });

  test('a surrogate pair written as two escapes is one character', () {
    String source = '${r'\'}uD83D${r'\'}uDE00';
    expect(decode(source), [(codePoint: 0x1F600, offset: 0, length: 12)]);
  });

  test('a lone surrogate stays a code unit', () {
    String source = String.fromCharCodes([0xD83D, 0x61]);
    expect(decode(source), [
      (codePoint: 0xD83D, offset: 0, length: 1),
      (codePoint: 0x61, offset: 1, length: 1),
    ]);
  });

  test('a raw string keeps its backslashes', () {
    expect(decode(r'\n', raw: true), [
      (codePoint: 0x5C, offset: 0, length: 1),
      (codePoint: 0x6E, offset: 1, length: 1),
    ]);
  });

  test('an empty range decodes to nothing', () {
    expect(decode(''), isEmpty);
  });
}
