import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Describes how a non-directional Flutter class (eg: `Alignment`) is replaced
/// by its directional equivalent (eg: `AlignmentDirectional`).
class DirectionalMapping {
  const DirectionalMapping({
    required this.className,
    required this.directionalClassName,
    required this.members,
    this.geometryClassName,
    this.geometryMembers = const <String, String>{},
    this.renamedArguments = const <String, String>{},
  });

  /// The forbidden class (eg: `Alignment`).
  final String className;

  /// The class to use instead (eg: `AlignmentDirectional`).
  final String directionalClassName;

  /// Forbidden members of [className] (constructors or static fields), with
  /// their name in [directionalClassName]. `new` is the unnamed constructor.
  final Map<String, String> members;

  /// The shared parent class exposing some members of [className], mostly used
  /// by dot shorthands (eg: `AlignmentGeometry`, for `alignment: .topLeft`).
  final String? geometryClassName;

  /// Forbidden members of [geometryClassName], with their directional name in
  /// that same class (eg: `topLeft` -> `topStart`).
  final Map<String, String> geometryMembers;

  /// Named arguments to rename (eg: `left` -> `start`).
  final Map<String, String> renamedArguments;

  /// Returns a [DirectionalMatch] if [node] uses a forbidden member.
  DirectionalMatch? match(AstNode node) {
    return switch (node) {
      // eg: EdgeInsets.only(left: 8.0)
      InstanceCreationExpression() => _match(
        node,
        node.constructorName.element,
        range.node(node.constructorName),
        node.constructorName.name,
        node.argumentList,
      ),
      // eg: padding: .only(left: 8.0)
      DotShorthandConstructorInvocation() => _match(
        node,
        node.element,
        range.startEnd(node.period, node.constructorName),
        node.constructorName,
        node.argumentList,
      ),
      // eg: Alignment.topLeft
      PrefixedIdentifier() => _match(
        node,
        node.identifier.element,
        range.node(node),
        node.identifier,
        null,
      ),
      // eg: prefix.Alignment.topLeft
      PropertyAccess() => _match(
        node,
        node.propertyName.element,
        range.node(node),
        node.propertyName,
        null,
      ),
      // eg: alignment: .topLeft
      DotShorthandPropertyAccess() => _match(
        node,
        node.propertyName.element,
        range.node(node),
        node.propertyName,
        null,
      ),
      _ => null,
    };
  }

  DirectionalMatch? _match(
    AstNode node,
    Element? element,
    SourceRange head,
    SimpleIdentifier? memberName,
    ArgumentList? arguments,
  ) {
    Element? enclosingElement = element?.enclosingElement;
    if (element == null ||
        enclosingElement is! InterfaceElement ||
        !enclosingElement.library.uri.toString().startsWith(
          'package:flutter/',
        )) {
      return null;
    }

    String? name = element.name;
    String? newName;
    bool isGeometry = false;
    if (enclosingElement.name == className) {
      newName = members[name];
    } else if (enclosingElement.name == geometryClassName) {
      newName = geometryMembers[name];
      isGeometry = true;
    }

    if (newName == null) {
      return null;
    }

    return DirectionalMatch(
      node: node,
      element: element,
      head: head,
      memberName: memberName,
      newMemberName: newName,
      arguments: arguments,
      isGeometry: isGeometry,
    );
  }
}

/// A usage of a forbidden member, found by [DirectionalMapping.match].
class DirectionalMatch {
  const DirectionalMatch({
    required this.node,
    required this.element,
    required this.head,
    required this.memberName,
    required this.newMemberName,
    required this.arguments,
    required this.isGeometry,
  });

  final AstNode node;

  /// The forbidden member (constructor or static field).
  final Element element;

  /// The range to report and to replace (eg: `EdgeInsets.only`, without the
  /// arguments).
  final SourceRange head;

  /// The member name, `null` for an unnamed constructor (eg: `Alignment(x, y)`).
  final SimpleIdentifier? memberName;

  /// The member to use instead.
  final String newMemberName;

  final ArgumentList? arguments;

  /// Whether the member belongs to [DirectionalMapping.geometryClassName], in
  /// which case only the member is renamed (eg: `.topLeft` -> `.topStart`).
  final bool isGeometry;
}

/// A rule forbidding a non-directional Flutter class, in favor of its
/// directional equivalent, as described by [mapping].
abstract class DirectionalRule extends AnalysisRule {
  DirectionalRule({
    required super.name,
    required super.description,
    required this.mapping,
  });

  final DirectionalMapping mapping;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    _Visitor visitor = _Visitor(this);
    registry
      ..addInstanceCreationExpression(this, visitor)
      ..addDotShorthandConstructorInvocation(this, visitor)
      ..addPrefixedIdentifier(this, visitor)
      ..addPropertyAccess(this, visitor)
      ..addDotShorthandPropertyAccess(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final DirectionalRule rule;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) =>
      _check(node);

  @override
  void visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) => _check(node);

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) => _check(node);

  @override
  void visitPropertyAccess(PropertyAccess node) => _check(node);

  @override
  void visitDotShorthandPropertyAccess(DotShorthandPropertyAccess node) =>
      _check(node);

  void _check(AstNode node) {
    // Ignore doc comments, eg: /// See [Alignment.topLeft]
    if (node.thisOrAncestorOfType<CommentReference>() != null) {
      return;
    }

    DirectionalMatch? match = rule.mapping.match(node);
    if (match != null) {
      rule.reportAtOffset(match.head.offset, match.head.length);
    }
  }
}
