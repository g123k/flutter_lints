import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:daad_lints/src/utils/generated_files.dart';

/// Reports a string literal passed to the constructor of a Flutter widget, an
/// `InlineSpan`, or an `InputDecoration` / `BottomNavigationBarItem` /
/// `DropdownMenuEntry`: user-facing text belongs in the localization files.
///
/// Only the arguments of a parameter declared `String` / `String?` are
/// considered (a generic `T value` or an `Object tag` is not), minus the
/// technical ones (`restorationId`, `semanticsIdentifier`, and the asset
/// names of Flutter's own classes).
/// A literal without any letter, or a single technical token (`user_id`,
/// `logo.png`, `a/b`, `#tag`, `https://x`), is not reported.
///
/// Variables, constants, concatenations, method results and constructor
/// default values are never followed. Test files are skipped.
class AvoidHardcodedStrings extends AnalysisRule {
  AvoidHardcodedStrings()
    : super(
        name: 'avoid_hardcoded_strings',
        description:
            'User-facing strings belong in the localization files, not in '
            'widget constructors.',
      );

  static const LintCode code = LintCode(
    'avoid_hardcoded_strings',
    "Hardcoded string passed to '{0}'.",
    correctionMessage: 'Try using a localized string instead.',
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
      ..addInstanceCreationExpression(this, visitor)
      ..addDotShorthandConstructorInvocation(this, visitor);
  }
}

/// The Flutter classes whose subclasses display their string arguments.
const Set<String> _displayingClasses = <String>{'Widget', 'InlineSpan'};

/// Flutter classes that are not widgets but hold user-visible strings.
const Set<String> _reportedHolders = <String>{
  'InputDecoration',
  'BottomNavigationBarItem',
  'DropdownMenuEntry',
};

/// `String` parameters whose value is an identifier, never shown to the user,
/// on any class: app widgets forward them to the Flutter widget they wrap.
const Set<String> _technicalParameters = <String>{
  'restorationId',
  'identifier',
  'semanticsIdentifier',
};

/// Asset and package names (`Image.asset`, `Image.network`), skipped on
/// Flutter's own classes only: an app widget's `name` is usually displayed.
const Set<String> _flutterTechnicalParameters = <String>{
  'name',
  'src',
  'package',
};

/// Extension methods that translate the widget's string in place
/// (easy_localization's `Text('key').tr()`).
const Set<String> _translatingMethods = <String>{'tr', 'plural'};

final RegExp _letter = RegExp(r'\p{L}', unicode: true);

final RegExp _whitespace = RegExp(r'\s');

/// An identifier, a path, a URL, a hashtag or a file name: `_`, a `/` `:` `#`
/// followed by a non-space, or a `.` between two letters or digits.
final RegExp _technicalToken = RegExp(
  r'_|[/:#]\S|[\p{L}\p{N}]\.[\p{L}\p{N}]',
  unicode: true,
);

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AvoidHardcodedStrings rule;
  final RuleContext context;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) =>
      _check(node, node.staticType, node.argumentList);

  @override
  void visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) => _check(node, node.staticType, node.argumentList);

  void _check(Expression node, DartType? type, ArgumentList arguments) {
    if (type is! InterfaceType || !_isReported(type.element)) {
      return;
    }

    RuleContextUnit unit = context.currentUnit!;
    if (isGeneratedUnit(unit) ||
        context.isInTestDirectory ||
        unit.file.shortName.endsWith('_test.dart')) {
      return;
    }

    AstNode? parent = node.parent;
    if (parent is MethodInvocation &&
        parent.target == node &&
        _translatingMethods.contains(parent.methodName.name)) {
      return;
    }

    for (Argument argument in arguments.arguments) {
      Expression expression = argument.argumentExpression;
      if (expression is! StringLiteral) {
        continue;
      }

      FormalParameterElement? parameter =
          argument.correspondingParameter?.baseElement;
      if (parameter == null ||
          !parameter.type.isDartCoreString ||
          _technicalParameters.contains(parameter.name) ||
          (_flutterTechnicalParameters.contains(parameter.name) &&
              _isFromFlutter(parameter))) {
        continue;
      }

      String text = _text(expression);
      if (!_letter.hasMatch(text) ||
          (!_whitespace.hasMatch(text) && _technicalToken.hasMatch(text))) {
        continue;
      }

      rule.reportAtNode(
        expression,
        arguments: <Object>[type.element.displayName],
      );
    }
  }

  /// Whether [element] is one of the holders, or is (or extends) a displaying
  /// class, from `package:flutter/`.
  static bool _isReported(InterfaceElement element) =>
      _isFlutterClass(element, _reportedHolders) ||
      _isFlutterClass(element, _displayingClasses) ||
      element.allSupertypes.any(
        (InterfaceType supertype) =>
            _isFlutterClass(supertype.element, _displayingClasses),
      );

  static bool _isFlutterClass(InterfaceElement element, Set<String> names) =>
      names.contains(element.name) && _isFromFlutter(element);

  static bool _isFromFlutter(Element element) =>
      element.library?.uri.toString().startsWith('package:flutter/') ?? false;

  /// The literal text, with the interpolated expressions left out.
  static String _text(StringLiteral literal) => switch (literal) {
    SimpleStringLiteral() => literal.value,
    AdjacentStrings() => literal.strings.map(_text).join(),
    StringInterpolation() => <String>[
      for (InterpolationElement element in literal.elements)
        if (element is InterpolationString) element.value,
    ].join(),
  };
}
