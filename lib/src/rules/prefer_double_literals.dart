import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:daad_lints/src/utils/generated_files.dart';

/// Requires a decimal part on the integer literals used as a `double`
/// (`10.0`, not `10`).
///
/// Hexadecimal literals are not reported: `0x10.0` is not valid.
class PreferDoubleLiterals extends AnalysisRule {
  PreferDoubleLiterals()
    : super(
        name: 'prefer_double_literals',
        description:
            'An integer literal used as a double hides its type. '
            'Write the decimal part (10.0, not 10).',
      );

  static const LintCode code = LintCode(
    'prefer_double_literals',
    'Integer literal used as a double.',
    correctionMessage: "Try adding '.0'.",
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addIntegerLiteral(this, _Visitor(this, context));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final PreferDoubleLiterals rule;
  final RuleContext context;

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    DartType? type = node.staticType;
    String lexeme = node.literal.lexeme;
    if (type == null ||
        !type.isDartCoreDouble ||
        lexeme.startsWith('0x') ||
        lexeme.startsWith('0X') ||
        isGeneratedUnit(context.currentUnit!)) {
      return;
    }

    rule.reportAtNode(node);
  }
}
