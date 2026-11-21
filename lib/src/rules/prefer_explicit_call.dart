import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:daad_lints/src/utils/generated_files.dart';

/// Reports a call to a function value written without `.call`
/// (`callback(x)`), in favor of `callback.call(x)`.
///
/// A function value is any callee that is not a declared function or method:
/// a variable, parameter, field, getter, record field, index, call result,
/// parenthesized expression, closure or callable object, whatever its static
/// type (function type, typedef, `Function`, `dynamic`, a class or extension
/// `call`). The analyzer parses these calls as `FunctionExpressionInvocation`
/// (`CallInvocation` in the experimental v2 AST), while calls to declared
/// functions and methods stay `MethodInvocation`.
///
/// The diagnostic covers the callee: for an immediately invoked closure
/// (`() { ... }()`), the whole closure, so an `// ignore:` goes above its
/// first line.
///
/// Not reported: `cb.call(x)`, `cb?.call(x)`, calls to declared functions,
/// methods and constructors, calls on a non-callable, `void` or nullable value
/// (`onDone()` with `VoidCallback? onDone`: already compile errors, which
/// `.call` alone would not fix) and generated files. Test files are reported.
class PreferExplicitCall extends AnalysisRule {
  PreferExplicitCall()
    : super(
        name: 'prefer_explicit_call',
        description:
            "Call a function value with '.call(...)', not '(...)' alone.",
      );

  static const LintCode code = LintCode(
    'prefer_explicit_call',
    "A function value called without '.call'.",
    correctionMessage: "Try adding '.call' after the callee.",
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addFunctionExpressionInvocation(this, _Visitor(this, context));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final PreferExplicitCall rule;
  final RuleContext context;

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    DartType? calleeType = node.function.staticType;
    if (node.staticInvokeType is InvalidType ||
        calleeType is VoidType ||
        calleeType?.nullabilitySuffix == NullabilitySuffix.question ||
        isGeneratedUnit(context.currentUnit!)) {
      return;
    }
    rule.reportAtNode(node.function);
  }
}
