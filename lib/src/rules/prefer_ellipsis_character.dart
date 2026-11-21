import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:daad_lints/src/utils/generated_files.dart';
import 'package:daad_lints/src/utils/string_decoder.dart';

/// Reports a run of exactly three dots (`...`) in a string literal, in favor
/// of the ellipsis character `…` (U+2026).
///
/// The dots may be escapes (`'\x2e..'`): the diagnostic covers the source of
/// the three characters.
///
/// Not reported: shorter or longer runs (`'..'`, `'....'`), dots split by an
/// interpolation or across adjacent strings (`'.$a..'`, `'a.' '..'`), the
/// pattern of a `dart:core` `RegExp` constructor (where `...` means three
/// characters), directive URIs (`import 'a...b.dart';`) and generated files.
/// Test files are reported: a test checking a displayed text must follow it.
///
/// Known false positives, left to `// ignore:`:
/// - comparisons and searches on three dots (`replaceAll('...', '…')`,
///   `endsWith('...')`, `== '...'`, `case '...':`);
/// - `RegExp.escape('...')`, and a pattern stored in a variable or built with
///   `+`, `?:` or parentheses before reaching `RegExp`;
/// - code depending on the length (`'...'.length`,
///   `substring(0, n - 3) + '...'`);
/// - Dart or git syntax inside a string (`'[...items]'`, `'...?extra'`,
///   `'main...HEAD'`). A heuristic on the next character would also skip
///   `'Wait...what?'`.
class PreferEllipsisCharacter extends AnalysisRule {
  PreferEllipsisCharacter()
    : super(
        name: 'prefer_ellipsis_character',
        description:
            'Use the ellipsis character (\u2026, U+2026), '
            'not three dots (...).',
      );

  static const LintCode code = LintCode(
    'prefer_ellipsis_character',
    "Three dots ('...') instead of the ellipsis character ('\u2026').",
    correctionMessage:
        "Try replacing with '\u2026' (U+2026), in the .arb file too "
        'when the text is localized.',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  LintCode get diagnosticCode => code;

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
}

const int _dot = 0x2E;

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final PreferEllipsisCharacter rule;
  final RuleContext context;

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) => _check(
    node,
    node.value,
    node.contentsOffset,
    node.contentsEnd,
    raw: node.isRaw,
  );

  @override
  void visitInterpolationString(InterpolationString node) => _check(
    node.parent! as StringInterpolation,
    node.value,
    node.contentsOffset,
    node.contentsEnd,
    raw: false,
  );

  /// Reports the runs of three dots of [value], the decoded source between
  /// [start] and [end] of [string].
  void _check(
    Expression string,
    String value,
    int start,
    int end, {
    required bool raw,
  }) {
    // `value` is already decoded: checking it first avoids decoding the many
    // literals without three dots.
    if (!value.contains('...')) {
      return;
    }

    RuleContextUnit unit = context.currentUnit!;
    List<SourceRange> runs = _threeDotRuns(
      decodeStringLiteral(unit.content, start, end, raw: raw),
    );
    if (runs.isEmpty || isGeneratedUnit(unit)) {
      return;
    }

    Expression outermost = _outermostString(string);
    if (_isDirectiveUri(outermost) || _isRegExpPattern(outermost)) {
      return;
    }

    for (SourceRange run in runs) {
      rule.reportAtOffset(run.offset, run.length);
    }
  }

  /// The source ranges of the runs of exactly three dots of [chars].
  static List<SourceRange> _threeDotRuns(List<DecodedChar> chars) {
    List<SourceRange> runs = <SourceRange>[];
    int index = 0;
    while (index < chars.length) {
      if (chars[index].codePoint != _dot) {
        index++;
        continue;
      }
      int first = index;
      while (index < chars.length && chars[index].codePoint == _dot) {
        index++;
      }
      if (index - first == 3) {
        DecodedChar last = chars[index - 1];
        int offset = chars[first].offset;
        runs.add(SourceRange(offset, last.offset + last.length - offset));
      }
    }
    return runs;
  }

  /// [string] itself, or the `AdjacentStrings` it belongs to.
  static Expression _outermostString(Expression string) {
    AstNode? parent = string.parent;
    return parent is AdjacentStrings ? parent : string;
  }

  static bool _isDirectiveUri(Expression expression) {
    AstNode? parent = expression.parent;
    return parent is UriBasedDirective ||
        parent is PartOfDirective ||
        parent is Configuration;
  }

  static bool _isRegExpPattern(Expression expression) {
    Element? enclosing =
        expression.correspondingParameter?.baseElement.enclosingElement;
    return enclosing is ConstructorElement &&
        enclosing.enclosingElement.name == 'RegExp' &&
        enclosing.library.isDartCore;
  }
}
