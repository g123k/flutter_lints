import 'package:daad_lints/src/rules/french_text_rule.dart';
import 'package:daad_lints/src/utils/string_decoder.dart';

/// Requires the French no-break spaces before the high punctuation signs of
/// the French localization strings: a narrow no-break space (U+202F) before
/// `?`, `!` and `;`, a no-break space (U+00A0) before `:` and before `€`
/// after an amount.
///
/// Regional variants of French (`fr_CA`, `fr_CH`...) are not checked: their
/// spacing rules differ from France's.
class FrenchNoBreakSpace extends FrenchTextRule {
  FrenchNoBreakSpace()
    : super(
        name: 'french_no_break_space',
        description:
            'French localization strings use a narrow no-break space (U+202F) '
            'before ?, ! and ;, and a no-break space (U+00A0) before : and €.',
      );

  static const FrenchTextCode code = FrenchTextCode(
    'french_no_break_space',
    "'{0}' must be preceded by {1}, found {2}.",
  );

  static const int _narrowNoBreakSpace = 0x202F;
  static const int _noBreakSpace = 0x00A0;
  static const int _questionMark = 0x3F;
  static const int _exclamationMark = 0x21;
  static const int _semicolon = 0x3B;
  static const int _colon = 0x3A;
  static const int _euro = 0x20AC;

  /// The space expected before each sign.
  static const Map<int, int> _expectedSpaces = <int, int>{
    _questionMark: _narrowNoBreakSpace,
    _exclamationMark: _narrowNoBreakSpace,
    _semicolon: _narrowNoBreakSpace,
    _colon: _noBreakSpace,
    _euro: _noBreakSpace,
  };

  static const Map<int, String> _spaceNames = <int, String>{
    0x20: 'a regular space (U+0020)',
    _noBreakSpace: 'a no-break space (U+00A0)',
    _narrowNoBreakSpace: 'a narrow no-break space (U+202F)',
  };

  static final RegExp _whitespace = RegExp(r'\s');
  static final RegExp _letterOrDigit = RegExp(r'[\p{L}\p{N}]', unicode: true);
  static final RegExp _digit = RegExp(r'\p{N}', unicode: true);

  @override
  FrenchTextCode get diagnosticCode => code;

  @override
  void check(FrenchText text) {
    if (text.regional) {
      return;
    }

    List<DecodedChar> chars = text.chars;
    for (int i = 0; i < chars.length; i++) {
      int sign = chars[i].codePoint;
      int? expected = _expectedSpaces[sign];
      if (expected == null) {
        continue;
      }
      bool applies = sign == _euro
          ? _isAmount(text, i)
          : _isSentencePunctuation(text, i);
      if (applies) {
        _checkSpace(text, i, expected);
      }
    }
  }

  /// Whether the `? ! ; :` at [index] ends a sentence part, as opposed to the
  /// separators of `HH:mm`, `https://`, `?param=value`, `!=`, `'$h:$m'`, or
  /// the second sign of `?!`.
  static bool _isSentencePunctuation(FrenchText text, int index) {
    List<DecodedChar> chars = text.chars;
    int sign = chars[index].codePoint;
    if (index + 1 < chars.length) {
      String next = String.fromCharCode(chars[index + 1].codePoint);
      if (next == '/' || next == '=' || _letterOrDigit.hasMatch(next)) {
        return false;
      }
    } else if (sign == _colon && text.beforeInterpolation) {
      return false;
    }
    if (index > 0) {
      int previous = chars[index - 1].codePoint;
      if (previous != _euro && _expectedSpaces.containsKey(previous)) {
        return false;
      }
    }
    return true;
  }

  /// Whether the `€` at [index] follows an amount: a digit, or an
  /// interpolation, spaces aside.
  static bool _isAmount(FrenchText text, int index) {
    List<DecodedChar> chars = text.chars;
    int previous = _spaceRunStart(chars, index) - 1;
    if (previous < 0) {
      return text.afterInterpolation;
    }
    return _digit.hasMatch(String.fromCharCode(chars[previous].codePoint));
  }

  /// The index of the first char of the whitespace run ending right before
  /// [index] ([index] itself when there is none).
  static int _spaceRunStart(List<DecodedChar> chars, int index) {
    int runStart = index;
    while (runStart > 0 && _isWhitespace(chars[runStart - 1])) {
      runStart--;
    }
    return runStart;
  }

  void _checkSpace(FrenchText text, int index, int expected) {
    List<DecodedChar> chars = text.chars;
    DecodedChar sign = chars[index];
    List<DecodedChar> run = chars.sublist(_spaceRunStart(chars, index), index);

    if (run.length == 1 && run.single.codePoint == expected) {
      return;
    }
    if (run.isEmpty && index == 0 && !text.afterInterpolation) {
      // The sign starts the literal: a separator joined at runtime ('?', ': ')
      return;
    }

    String found = switch (run) {
      [] => 'no space',
      [DecodedChar space] =>
        _spaceNames[space.codePoint] ??
            'U+${space.codePoint.toRadixString(16).toUpperCase().padLeft(4, '0')}',
      _ => 'several spaces',
    };
    int offset = run.isEmpty ? sign.offset : run.first.offset;
    reportAtOffset(
      offset,
      sign.offset + sign.length - offset,
      arguments: <Object>[
        String.fromCharCode(sign.codePoint),
        _spaceNames[expected]!,
        found,
      ],
    );
  }

  static bool _isWhitespace(DecodedChar char) =>
      _whitespace.hasMatch(String.fromCharCode(char.codePoint));
}
