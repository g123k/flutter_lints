import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:daad_lints/src/utils/generated_files.dart';

/// Requires `dispose` to be declared after `build` in a Flutter `State`, so
/// that the clean-up of a class is always found in the same place.
class DisposeAfterBuild extends AnalysisRule {
  DisposeAfterBuild()
    : super(
        name: 'dispose_after_build',
        description:
            "In a 'State', 'dispose' must be declared after 'build', so that "
            'the clean-up is always found at the end of the class.',
      );

  static const LintCode code = LintCode(
    'dispose_after_build',
    "'dispose' should be declared after 'build'.",
    correctionMessage: "Try moving 'dispose' to the end of the class.",
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _Visitor(this, context));
  }

  /// The `dispose` method of [node] if it is declared before `build`, and
  /// [node] is a Flutter `State`.
  static MethodDeclaration? misplacedDispose(ClassDeclaration node) {
    MethodDeclaration? build;
    MethodDeclaration? dispose;
    for (ClassMember member in node.body.members) {
      if (member is! MethodDeclaration ||
          member.isStatic ||
          member.isGetter ||
          member.isSetter) {
        continue;
      }

      int parameterCount = member.parameters?.parameters.length ?? -1;
      if (member.name.lexeme == 'build' && parameterCount == 1) {
        build = member;
      } else if (member.name.lexeme == 'dispose' && parameterCount == 0) {
        dispose = member;
      }
    }

    if (build == null || dispose == null || dispose.offset > build.offset) {
      return null;
    }

    ClassElement? element = node.declaredFragment?.element;
    if (element == null || !element.allSupertypes.any(_isFlutterState)) {
      return null;
    }
    return dispose;
  }

  static bool _isFlutterState(InterfaceType type) =>
      type.element.name == 'State' &&
      type.element.library.uri.toString() ==
          'package:flutter/src/widgets/framework.dart';
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final DisposeAfterBuild rule;
  final RuleContext context;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    MethodDeclaration? dispose = DisposeAfterBuild.misplacedDispose(node);
    if (dispose == null || isGeneratedUnit(context.currentUnit!)) {
      return;
    }

    rule.reportAtToken(dispose.name);
  }
}
