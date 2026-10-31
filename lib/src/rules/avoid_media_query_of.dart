import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:daad_lints/src/utils/flutter_elements.dart';
import 'package:daad_lints/src/utils/generated_files.dart';

/// Forbids `MediaQuery.of(context)` / `MediaQuery.maybeOf(context)`: they make
/// the widget depend on every `MediaQueryData` property, so it rebuilds when
/// any of them changes (eg: on each frame of the keyboard animation). The
/// dedicated accessors (`MediaQuery.sizeOf`, `MediaQuery.paddingOf`...) only
/// depend on the property they read.
///
/// The `MediaQueryData` methods with no dedicated accessor (`copyWith`,
/// `removePadding`...) called on the result are not reported.
class AvoidMediaQueryOf extends AnalysisRule {
  AvoidMediaQueryOf()
    : super(
        name: 'avoid_media_query_of',
        description:
            "'MediaQuery.of(context)' rebuilds the widget when any MediaQuery "
            "property changes. Use a dedicated accessor, such as "
            "'MediaQuery.sizeOf(context)'.",
      );

  static const LintCode code = LintCode(
    'avoid_media_query_of',
    "'MediaQuery.{0}' rebuilds the widget when any MediaQuery property "
        'changes.',
    correctionMessage: "Try a dedicated accessor, such as 'MediaQuery.sizeOf'.",
    severity: DiagnosticSeverity.WARNING,
  );

  /// The `MediaQueryData` methods with no dedicated accessor.
  static const Set<String> _exemptedMethods = <String>{
    'copyWith',
    'removePadding',
    'removeViewInsets',
    'removeViewPadding',
    'removeDisplayFeatures',
    'applyDisplayCornerRadii',
  };

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addMethodInvocation(this, _Visitor(this, context));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AvoidMediaQueryOf rule;
  final RuleContext context;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!isMediaQueryCall(node) ||
        _isExempted(node) ||
        isGeneratedUnit(context.currentUnit!)) {
      return;
    }

    rule.reportAtNode(node, arguments: <Object>[node.methodName.name]);
  }

  /// Whether [node] is the target of an exempted method, called or torn off.
  static bool _isExempted(MethodInvocation node) {
    String? name = switch (node.parent) {
      MethodInvocation(:Expression? target, :SimpleIdentifier methodName)
          when target == node =>
        methodName.name,
      PropertyAccess(:Expression? target, :SimpleIdentifier propertyName)
          when target == node =>
        propertyName.name,
      _ => null,
    };
    return AvoidMediaQueryOf._exemptedMethods.contains(name);
  }
}
