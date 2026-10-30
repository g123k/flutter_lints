import 'package:daad_lints/src/rules/french_text_rule.dart';
import 'package:daad_lints/src/utils/string_decoder.dart';

/// Forbids the typographic apostrophe `’` (U+2019) in the French localization
/// strings, in favor of the straight apostrophe `'`.
class FrenchStraightApostrophe extends FrenchTextRule {
  FrenchStraightApostrophe()
    : super(
        name: 'french_straight_apostrophe',
        description:
            'French localization strings use the straight apostrophe (\'), '
            'not the typographic one (’, U+2019).',
      );

  static const FrenchTextCode code = FrenchTextCode(
    'french_straight_apostrophe',
    "Typographic apostrophe (U+2019): use the straight apostrophe (').",
  );

  static const int _typographicApostrophe = 0x2019;

  @override
  FrenchTextCode get diagnosticCode => code;

  @override
  void check(FrenchText text) {
    for (DecodedChar char in text.chars) {
      if (char.codePoint == _typographicApostrophe) {
        reportAtOffset(char.offset, char.length);
      }
    }
  }
}
