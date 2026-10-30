import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:daad_lints/src/utils/string_decoder.dart';

/// The diagnostic code of the French typography rules.
///
/// Not a [LintCode]: `flutter gen-l10n` writes `// ignore_for_file: type=lint`
/// at the top of every per-locale file, which silences every lint. A static
/// warning goes through, and stays ignorable by name.
class FrenchTextCode extends DiagnosticCode {
  const FrenchTextCode(String name, String problemMessage)
    : super(
        name: name,
        problemMessage: problemMessage,
        uniqueName: 'FrenchTextCode.$name',
        correctionMessage:
            'Fix the string in the .arb source file and regenerate '
            '(a generated file is overwritten), or here when the file is '
            'hand-written.',
      );

  @override
  DiagnosticSeverity get severity => DiagnosticSeverity.WARNING;

  @override
  DiagnosticType get type => DiagnosticType.STATIC_WARNING;
}

/// The decoded content of a string literal, or of one string segment of an
/// interpolated string.
class FrenchText {
  FrenchText({
    required this.chars,
    required this.afterInterpolation,
    required this.beforeInterpolation,
    required bool Function() regional,
    // A named parameter cannot be private: no initializing formal possible.
  }) : _regional = regional; // ignore: prefer_initializing_formals

  final List<DecodedChar> chars;

  /// Whether the segment follows an `$expression` (`'$amount €'`).
  final bool afterInterpolation;

  /// Whether the segment is followed by an `$expression` (`'$h:$m'`).
  final bool beforeInterpolation;

  final bool Function() _regional;

  /// Whether the string belongs to a regional variant of French (`fr_CA`,
  /// `fr_CH`...), whose typography rules differ from France's.
  ///
  /// Computed on first read: it walks the enclosing class, and only one rule
  /// needs it.
  late final bool regional = _regional();
}

/// A rule checking the French typography of the string literals of the
/// generated per-locale localization files (`*_fr.dart`,
/// `*_fr_<REGION>.dart`).
///
/// Generated files are not skipped: they are the only place where the plugin
/// sees the French strings of the `.arb` files.
abstract class FrenchTextRule extends AnalysisRule {
  FrenchTextRule({required super.name, required super.description});

  /// `_fr.dart`, or `_fr_<REGION>.dart` with a two-letter or three-digit
  /// region. Longer segments are words (`date_fr_util.dart`), not regions.
  static final RegExp _frenchFile = RegExp(
    r'_fr(?:_([a-z]{2}|[0-9]{3}))?\.dart$',
    caseSensitive: false,
  );

  /// A `super('fr_CA')` argument, as gen-l10n writes for a regional subclass
  /// in the same file as the `fr` class.
  static final RegExp _regionalLocale = RegExp(
    r'^fr[_-](?!fr$)\w+$',
    caseSensitive: false,
  );

  /// Reports the typography diagnostics of [text], one string literal (or one
  /// segment of an interpolated string) of a French localization file.
  void check(FrenchText text);

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    _Visitor visitor = _Visitor(this, context);
    registry
      ..addSimpleStringLiteral(this, visitor)
      ..addInterpolationString(this, visitor);
  }

  static _FrenchFile _classify(String shortName) {
    RegExpMatch? match = _frenchFile.firstMatch(shortName);
    if (match == null) {
      return _FrenchFile.none;
    }
    String? region = match[1]?.toLowerCase();
    return region == null || region == 'fr'
        ? _FrenchFile.france
        : _FrenchFile.regional;
  }

  static bool _regionalClass(AstNode node) {
    ClassDeclaration? declaration = node.thisOrAncestorOfType();
    if (declaration == null) {
      return false;
    }
    for (ClassMember member in declaration.body.members) {
      if (member is! ConstructorDeclaration) {
        continue;
      }
      for (ConstructorInitializer initializer in member.initializers) {
        if (initializer is! SuperConstructorInvocation) {
          continue;
        }
        for (Argument argument in initializer.argumentList.arguments) {
          if (argument is SimpleStringLiteral &&
              _regionalLocale.hasMatch(argument.value)) {
            return true;
          }
        }
      }
    }
    return false;
  }
}

/// The verdict on a file name: not a French localization file, French as
/// written in France (`fr`, `fr_FR`), or a regional variant (`fr_CA`).
enum _FrenchFile { none, france, regional }

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final FrenchTextRule rule;
  final RuleContext context;

  /// The unit [_file] was computed for: the verdict is a property of the
  /// file, not of each of its string literals.
  RuleContextUnit? _unit;
  _FrenchFile _file = _FrenchFile.none;

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) => _check(
    node,
    node.contentsOffset,
    node.contentsEnd,
    raw: node.isRaw,
    afterInterpolation: false,
    beforeInterpolation: false,
  );

  @override
  void visitInterpolationString(InterpolationString node) {
    NodeList<InterpolationElement> elements =
        (node.parent! as StringInterpolation).elements;
    int index = elements.indexOf(node);
    _check(
      node,
      node.contentsOffset,
      node.contentsEnd,
      raw: false,
      afterInterpolation:
          index > 0 && elements[index - 1] is InterpolationExpression,
      beforeInterpolation:
          index < elements.length - 1 &&
          elements[index + 1] is InterpolationExpression,
    );
  }

  void _check(
    AstNode node,
    int start,
    int end, {
    required bool raw,
    required bool afterInterpolation,
    required bool beforeInterpolation,
  }) {
    RuleContextUnit unit = context.currentUnit!;
    if (unit != _unit) {
      _unit = unit;
      _file = FrenchTextRule._classify(unit.file.shortName);
    }
    _FrenchFile file = _file;
    if (file == _FrenchFile.none) {
      return;
    }

    rule.check(
      FrenchText(
        chars: decodeStringLiteral(unit.content, start, end, raw: raw),
        afterInterpolation: afterInterpolation,
        beforeInterpolation: beforeInterpolation,
        regional: () =>
            file == _FrenchFile.regional || FrenchTextRule._regionalClass(node),
      ),
    );
  }
}
