import 'package:daad_lints/src/rules/french_text_rule.dart';
import 'package:daad_lints/src/utils/string_decoder.dart';

/// Forbids the em dash `—` (U+2014) and the en dash `–` (U+2013) in the
/// French localization strings, in favor of the hyphen `-`.
class FrenchHyphenOnly extends FrenchTextRule {
  FrenchHyphenOnly()
    : super(
        name: 'french_hyphen_only',
        description:
            'French localization strings use the hyphen (-), '
            'not the em dash (—, U+2014) or the en dash (–, U+2013).',
      );

  static const FrenchTextCode code = FrenchTextCode(
    'french_hyphen_only',
    '{0}: use the hyphen (-).',
  );

  static const Map<int, String> _dashes = <int, String>{
    0x2014: 'Em dash (U+2014)',
    0x2013: 'En dash (U+2013)',
  };

  @override
  FrenchTextCode get diagnosticCode => code;

  @override
  void check(FrenchText text) {
    for (DecodedChar char in text.chars) {
      String? dash = _dashes[char.codePoint];
      if (dash != null) {
        reportAtOffset(char.offset, char.length, arguments: <Object>[dash]);
      }
    }
  }
}
