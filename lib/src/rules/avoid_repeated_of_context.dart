import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:daad_lints/src/utils/generated_files.dart';

/// Forbids calling the same static `of` / `maybeOf` method several times with
/// the `context` of a `build` method (eg: `Theme.of(context)` twice): each
/// call walks the widget tree again.
///
/// Calls inside closures and `assert`s are not counted: they do not run on
/// each build.
class AvoidRepeatedOfContext extends AnalysisRule {
  AvoidRepeatedOfContext()
    : super(
        name: 'avoid_repeated_of_context',
        description:
            "Each '.of(context)' call walks the widget tree. In 'build', read "
            'the object once into a local variable.',
      );

  static const LintCode code = LintCode(
    'avoid_repeated_of_context',
    "'{0}' is called several times in 'build'.",
    correctionMessage: 'Try reading it once into a local variable.',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addMethodDeclaration(this, _Visitor(this, context));
  }

  /// The groups of identical `of` / `maybeOf` calls of the `build` method
  /// [node] made 2+ times, each in source order.
  static List<List<MethodInvocation>> repeatedCalls(MethodDeclaration node) {
    FormalParameterElement? context = _contextParameter(node);
    if (context == null) {
      return const <List<MethodInvocation>>[];
    }

    _CallCollector collector = _CallCollector(context);
    node.body.accept(collector);
    return <List<MethodInvocation>>[
      for (List<MethodInvocation> calls in collector.groups.values)
        if (calls.length > 1) calls,
    ];
  }

  /// The `BuildContext` parameter of [node], if [node] is a `build` method
  /// with a body.
  static FormalParameterElement? _contextParameter(MethodDeclaration node) {
    if (node.name.lexeme != 'build' ||
        node.isStatic ||
        node.body is EmptyFunctionBody ||
        node.isGetter ||
        node.isSetter) {
      return null;
    }

    List<FormalParameter>? parameters = node.parameters?.parameters;
    if (parameters == null || parameters.isEmpty) {
      return null;
    }

    FormalParameter parameter = parameters.first;
    FormalParameterElement? element = parameter.declaredFragment?.element;
    DartType? type = element?.type;
    if (parameter.name?.lexeme == '_' ||
        type is! InterfaceType ||
        type.element.name != 'BuildContext' ||
        !type.element.library.uri.toString().startsWith('package:flutter/')) {
      return null;
    }
    return element;
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AvoidRepeatedOfContext rule;
  final RuleContext context;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    List<List<MethodInvocation>> groups = AvoidRepeatedOfContext.repeatedCalls(
      node,
    );
    if (groups.isEmpty || isGeneratedUnit(context.currentUnit!)) {
      return;
    }

    String path = context.currentUnit!.file.path;
    for (List<MethodInvocation> calls in groups) {
      MethodInvocation first = calls.first;
      String name = first.target == null
          ? first.methodName.name
          : '${first.target}.${first.methodName}';
      for (MethodInvocation reported in calls) {
        rule.reportAtNode(
          reported,
          arguments: <Object>[name],
          contextMessages: <DiagnosticMessage>[
            for (MethodInvocation call in calls)
              if (call != reported)
                _ContextMessage(
                  filePath: path,
                  offset: call.offset,
                  length: call.length,
                  message: "'$name' is also called here.",
                ),
          ],
        );
      }
    }
  }
}

/// Collects the `of` / `maybeOf` calls receiving [context], grouped by method,
/// inferred type arguments and other arguments.
class _CallCollector extends RecursiveAstVisitor<void> {
  _CallCollector(this.context);

  final FormalParameterElement context;
  final Map<(Element, String, String), List<MethodInvocation>> groups =
      <(Element, String, String), List<MethodInvocation>>{};

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitAssertStatement(AssertStatement node) {}

  @override
  void visitMethodInvocation(MethodInvocation node) {
    Element? method = node.methodName.element;
    String name = node.methodName.name;
    if ((name == 'of' || name == 'maybeOf') &&
        method is MethodElement &&
        method.isStatic) {
      List<Argument> arguments = node.argumentList.arguments;
      Argument? contextArgument = arguments
          .where(
            (Argument argument) =>
                argument is SimpleIdentifier && argument.element == context,
          )
          .firstOrNull;
      if (contextArgument != null) {
        (Element, String, String) key = (
          method,
          // The inferred type arguments, so that `A a = Provider.of(context)`
          // and `B b = Provider.of(context)` are different groups
          <String>[
            for (DartType type in node.typeArgumentTypes ?? <DartType>[])
              type.getDisplayString(),
          ].join(', '),
          <String>[
            for (Argument argument in arguments)
              if (argument != contextArgument) argument.toSource(),
          ].join(', '),
        );
        groups.putIfAbsent(key, () => <MethodInvocation>[]).add(node);
      }
    }
    super.visitMethodInvocation(node);
  }
}

class _ContextMessage implements DiagnosticMessage {
  _ContextMessage({
    required this.filePath,
    required this.offset,
    required this.length,
    required this.message,
  });

  @override
  final String filePath;

  @override
  final int offset;

  @override
  final int length;

  final String message;

  @override
  String? get url => null;

  @override
  String messageText({required bool includeUrl}) => message;
}
