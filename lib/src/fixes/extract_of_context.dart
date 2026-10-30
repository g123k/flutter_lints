import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:daad_lints/src/rules/avoid_repeated_of_context.dart';
import 'package:daad_lints/src/utils/member_source_range.dart';

/// Reads a repeated `X.of(context)` once into a typed `final` local, declared
/// in the smallest block holding every call, and replaces the calls by it.
///
/// No fix for an expression-bodied `build`, when the type cannot be written,
/// or when the variable name is already used in `build`.
class ExtractOfContext extends ResolvedCorrectionProducer {
  ExtractOfContext({required super.context});

  static const FixKind _fixKind = FixKind(
    'daad_lints.fix.avoid_repeated_of_context',
    DartFixKindPriority.standard,
    'Read it once into a local variable',
  );

  static const FixKind _multiFixKind = FixKind(
    'daad_lints.fix.avoid_repeated_of_context.multi',
    DartFixKindPriority.inFile,
    'Read it once into a local variable everywhere in file',
  );

  static final RegExp _leadingUnderscores = RegExp('^_+');

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.acrossSingleFile;

  @override
  FixKind get fixKind => _fixKind;

  @override
  FixKind get multiFixKind => _multiFixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    MethodInvocation? invocation = node
        .thisOrAncestorOfType<MethodInvocation>();
    MethodDeclaration? build = invocation
        ?.thisOrAncestorOfType<MethodDeclaration>();
    if (invocation == null ||
        build == null ||
        build.body is! BlockFunctionBody) {
      return;
    }

    List<List<MethodInvocation>> groups = AvoidRepeatedOfContext.repeatedCalls(
      build,
    );
    int groupIndex = groups.indexWhere(
      (List<MethodInvocation> calls) => calls.contains(invocation),
    );
    if (groupIndex == -1) {
      return;
    }

    List<MethodInvocation> calls = groups[groupIndex];
    DartType? type = calls.first.staticType;
    String name = _variableName(calls.first);
    if (type == null ||
        type is DynamicType ||
        type is InvalidType ||
        _isUsed(build, name) ||
        // Two groups giving the same name (eg: `Navigator.of(context)` with
        // and without `rootNavigator`) would declare the variable twice.
        groups
            .take(groupIndex)
            .any(
              (List<MethodInvocation> other) =>
                  _variableName(other.first) == name,
            )) {
      return;
    }

    Block? block = _commonBlock(calls);
    if (block == null) {
      return;
    }
    Statement statement =
        calls.first.thisOrAncestorMatching(
              (AstNode node) => node.parent == block,
            )!
            as Statement;
    String content = unitResult.content;
    String indentation = indentationAt(content, statement.offset);
    String callSource = content.substring(calls.first.offset, calls.first.end);

    await builder.addDartFileEdit(file, (DartFileEditBuilder builder) {
      if (!builder.canWriteType(type, offset: statement.offset)) {
        return;
      }

      // The last call is replaced first: in a fix-all, the fix of another
      // call of the same group conflicts on it and is reverted before
      // inserting a second declaration. It is always after the insertion
      // offset, which may be the start of the first call.
      builder.addSimpleReplacement(range.node(calls.last), name);
      builder.addInsertion(statement.offset, (DartEditBuilder builder) {
        builder.write('final ');
        builder.writeType(type);
        builder.write(' $name = $callSource;\n$indentation');
      });
      for (MethodInvocation call in calls.take(calls.length - 1)) {
        builder.addSimpleReplacement(range.node(call), name);
      }
    });
  }

  /// The variable name for [call]: from its type argument if any, inferred
  /// or not (`Provider.of<CartModel>` -> `cartModel`), else from its class
  /// (`MediaQuery.of` -> `mediaQuery`).
  static String _variableName(MethodInvocation call) {
    DartType? typeArgument = call.typeArgumentTypes?.firstOrNull;
    Expression? target = call.target;
    String name = switch ((typeArgument, target)) {
      (InterfaceType type, _) => type.element.name ?? call.methodName.name,
      (_, PrefixedIdentifier target) => target.identifier.name,
      (_, SimpleIdentifier target) => target.name,
      _ => call.methodName.name,
    };

    name = name.replaceFirst(_leadingUnderscores, '');
    return name.isEmpty ? name : name[0].toLowerCase() + name.substring(1);
  }

  /// Whether [name] is declared or referenced in [build], not counting
  /// member accesses (`x.theme`) and argument labels (`theme: ...`).
  static bool _isUsed(MethodDeclaration build, String name) {
    _NameFinder finder = _NameFinder(name);
    build.accept(finder);
    return finder.found;
  }

  /// The innermost block containing all [calls], or `null` when none does
  /// (the calls of a block-bodied `build` always share its block).
  static Block? _commonBlock(List<MethodInvocation> calls) {
    for (AstNode? node = calls.first.parent; node != null; node = node.parent) {
      if (node is Block &&
          calls.every(
            (MethodInvocation call) =>
                call.thisOrAncestorMatching((AstNode n) => n == node) != null,
          )) {
        return node;
      }
    }
    return null;
  }
}

class _NameFinder extends GeneralizingAstVisitor<void> {
  _NameFinder(this.name);

  final String name;
  bool found = false;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    AstNode? parent = node.parent;
    bool isMemberAccess = switch (parent) {
      PropertyAccess() => parent.propertyName == node,
      PrefixedIdentifier() => parent.identifier == node,
      MethodInvocation() => parent.methodName == node && parent.target != null,
      _ => false,
    };
    if (!isMemberAccess && node.name == name) {
      found = true;
    }
  }

  @override
  void visitNode(AstNode node) {
    if (_declaredName(node) == name) {
      found = true;
    }
    super.visitNode(node);
  }

  static String? _declaredName(AstNode node) => switch (node) {
    VariableDeclaration() => node.name.lexeme,
    FormalParameter() => node.name?.lexeme,
    DeclaredIdentifier() => node.name.lexeme,
    DeclaredVariablePattern() => node.name.lexeme,
    FunctionDeclaration() => node.name.lexeme,
    _ => null,
  };
}
