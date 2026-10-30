/// A decoded character of a string literal: its code point, and the source
/// range of the character or of the escape sequence producing it.
typedef DecodedChar = ({int codePoint, int offset, int length});

const int _backslash = 0x5C;
const int _leftBrace = 0x7B;

/// The single-letter escapes and their control character.
const Map<String, int> _controlEscapes = <String, int>{
  'n': 0x0A,
  'r': 0x0D,
  't': 0x09,
  'b': 0x08,
  'f': 0x0C,
  'v': 0x0B,
};

final RegExp _hexDigits = RegExp(r'^[0-9a-fA-F]+$');

/// Decodes the content of a string literal, the [source] between [start] and
/// [end], into code points with their source range.
///
/// In a non-[raw] string, an escape sequence (`\n`, `’`, `\u{1F600}`,
/// `\x41`, `\'`) is one character spanning the whole sequence. A surrogate
/// pair, written as is or as two `\uXXXX` escapes, is one character.
///
/// Never throws: a malformed escape yields the backslash itself, and the scan
/// goes on. A plugin exception would kill every diagnostic of the plugin.
List<DecodedChar> decodeStringLiteral(
  String source,
  int start,
  int end, {
  required bool raw,
}) {
  List<DecodedChar> chars = <DecodedChar>[];
  int offset = start;
  while (offset < end) {
    DecodedChar char = raw
        ? _codePointAt(source, offset, end)
        : _decodeEscape(source, offset, end) ??
              _codePointAt(source, offset, end);
    offset += char.length;

    // Two escapes forming a surrogate pair (`𝐀`) are one character,
    // like the same pair written as is.
    DecodedChar? previous = chars.lastOrNull;
    if (previous != null &&
        _isHighSurrogate(previous.codePoint) &&
        _isLowSurrogate(char.codePoint)) {
      chars.last = (
        codePoint: _combineSurrogates(previous.codePoint, char.codePoint),
        offset: previous.offset,
        length: previous.length + char.length,
      );
    } else {
      chars.add(char);
    }
  }
  return chars;
}

/// The code point at [offset], combining a surrogate pair into one character.
DecodedChar _codePointAt(String source, int offset, int end) {
  int unit = source.codeUnitAt(offset);
  if (_isHighSurrogate(unit) && offset + 1 < end) {
    int next = source.codeUnitAt(offset + 1);
    if (_isLowSurrogate(next)) {
      return (
        codePoint: _combineSurrogates(unit, next),
        offset: offset,
        length: 2,
      );
    }
  }
  return (codePoint: unit, offset: offset, length: 1);
}

bool _isHighSurrogate(int unit) => unit >= 0xD800 && unit <= 0xDBFF;

bool _isLowSurrogate(int unit) => unit >= 0xDC00 && unit <= 0xDFFF;

int _combineSurrogates(int high, int low) =>
    0x10000 + ((high - 0xD800) << 10) + (low - 0xDC00);

/// The escape sequence starting at [offset], or `null` when there is none or
/// when it is malformed.
DecodedChar? _decodeEscape(String source, int offset, int end) {
  if (source.codeUnitAt(offset) != _backslash || offset + 1 >= end) {
    return null;
  }

  String letter = source[offset + 1];
  int? control = _controlEscapes[letter];
  if (control != null) {
    return (codePoint: control, offset: offset, length: 2);
  }

  switch (letter) {
    case 'u':
      if (offset + 2 < end && source.codeUnitAt(offset + 2) == _leftBrace) {
        int close = source.indexOf('}', offset + 3);
        if (close == -1 || close >= end) {
          return null;
        }
        int? codePoint = _hex(source, offset + 3, close, min: 1, max: 6);
        if (codePoint == null || codePoint > 0x10FFFF) {
          return null;
        }
        return (
          codePoint: codePoint,
          offset: offset,
          length: close + 1 - offset,
        );
      }
      return _fixedHex(source, offset, end, digits: 4);
    case 'x':
      return _fixedHex(source, offset, end, digits: 2);
    default:
      DecodedChar escaped = _codePointAt(source, offset + 1, end);
      return (
        codePoint: escaped.codePoint,
        offset: offset,
        length: 1 + escaped.length,
      );
  }
}

/// `\uXXXX` or `\xXX`: exactly [digits] hex digits after the two-char prefix.
DecodedChar? _fixedHex(
  String source,
  int offset,
  int end, {
  required int digits,
}) {
  int start = offset + 2;
  int stop = start + digits;
  if (stop > end) {
    return null;
  }
  int? codePoint = _hex(source, start, stop, min: digits, max: digits);
  if (codePoint == null) {
    return null;
  }
  return (codePoint: codePoint, offset: offset, length: stop - offset);
}

int? _hex(
  String source,
  int start,
  int end, {
  required int min,
  required int max,
}) {
  int length = end - start;
  if (length < min || length > max) {
    return null;
  }
  String digits = source.substring(start, end);
  // int.tryParse accepts a sign and surrounding whitespace: hex digits only.
  if (!_hexDigits.hasMatch(digits)) {
    return null;
  }
  return int.tryParse(digits, radix: 16);
}
