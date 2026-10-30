import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:daad_lints/src/utils/generated_files.dart';

/// Requires the optional named `super.key` parameter to be the last parameter
/// of a constructor.
///
/// `required super.key` is not reported: moving it last would break
/// `always_put_required_named_parameters_first`.
class SuperKeyLast extends AnalysisRule {
  SuperKeyLast()
    : super(
        name: 'super_key_last',
        description:
            "'super.key' must be the last parameter of a constructor, so "
            'that every widget constructor reads the same way.',
      );

  static const LintCode code = LintCode(
    'super_key_last',
    "'super.key' should be the last parameter.",
    correctionMessage: "Try moving 'super.key' to the end of the parameters.",
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addConstructorDeclaration(this, _Visitor(this, context));
  }

  /// The optional named `super.key` parameter of [constructor], if it is not
  /// its last parameter.
  static SuperFormalParameter? misplacedSuperKey(
    ConstructorDeclaration constructor,
  ) {
    List<FormalParameter> parameters = constructor.parameters.parameters;
    for (FormalParameter parameter in parameters) {
      if (parameter is SuperFormalParameter &&
          parameter.name.lexeme == 'key' &&
          parameter.isOptionalNamed) {
        return parameter == parameters.last ? null : parameter;
      }
    }
    return null;
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final SuperKeyLast rule;
  final RuleContext context;

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    SuperFormalParameter? superKey = SuperKeyLast.misplacedSuperKey(node);
    if (superKey == null || isGeneratedUnit(context.currentUnit!)) {
      return;
    }

    rule.reportAtOffset(
      superKey.superKeyword.offset,
      superKey.name.end - superKey.superKeyword.offset,
    );
  }
}
