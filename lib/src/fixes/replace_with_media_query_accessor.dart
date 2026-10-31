import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:daad_lints/src/utils/flutter_elements.dart';

/// Replaces a `MediaQuery.of(context)` / `MediaQuery.maybeOf(context)` call
/// followed by a property read with the dedicated accessor:
/// - `MediaQuery.of(context).size` -> `MediaQuery.sizeOf(context)`
/// - `MediaQuery.of(context).size.width` -> `MediaQuery.widthOf(context)`
/// - `MediaQuery.maybeOf(context)?.padding.top` ->
///   `MediaQuery.maybePaddingOf(context)?.top`
///
/// The accessor is looked up on `MediaQuery` (`<property>Of`, then
/// `<property>`; `maybe<Property>Of`, then `maybe<Property>`), so the fix
/// follows the installed Flutter version. No fix when there is none.
class ReplaceWithMediaQueryAccessor extends ResolvedCorrectionProducer {
  ReplaceWithMediaQueryAccessor({required super.context});

  static const FixKind _fixKind = FixKind(
    'daad_lints.fix.avoid_media_query_of',
    DartFixKindPriority.standard,
    "Replace with 'MediaQuery.{0}'",
  );

  static const FixKind _multiFixKind = FixKind(
    'daad_lints.fix.avoid_media_query_of.multi',
    DartFixKindPriority.inFile,
    "Replace with the dedicated 'MediaQuery' accessors everywhere in file",
  );

  /// The accessor written by [compute], named in the fix label.
  String? _accessor;

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.acrossSingleFile;

  @override
  FixKind get fixKind => _fixKind;

  @override
  FixKind get multiFixKind => _multiFixKind;

  @override
  List<String>? get fixArguments => switch (_accessor) {
    String accessor => <String>[accessor],
    null => null,
  };

  @override
  Future<void> compute(ChangeBuilder builder) async {
    AstNode call = node;
    if (call is! MethodInvocation || !isMediaQueryCall(call)) {
      return;
    }

    AstNode? read = call.parent;
    if (read is! PropertyAccess ||
        read.target != call ||
        !isFlutterClass(
          read.propertyName.element?.enclosingElement,
          'MediaQueryData',
        )) {
      return;
    }

    InterfaceElement mediaQuery =
        call.methodName.element!.enclosingElement! as InterfaceElement;
    bool isMaybe = call.methodName.name == 'maybeOf';

    // `.size.width` has its own accessor, which only depends on the width.
    Expression replaced = read;
    String? accessor;
    AstNode? sizeRead = read.parent;
    if (read.propertyName.name == 'size' &&
        sizeRead is PropertyAccess &&
        sizeRead.target == read &&
        (sizeRead.propertyName.name == 'width' ||
            sizeRead.propertyName.name == 'height')) {
      accessor = _accessorFor(
        mediaQuery,
        sizeRead.propertyName.name,
        isMaybe: isMaybe,
      );
      if (accessor != null) {
        replaced = sizeRead;
      }
    }
    accessor ??= _accessorFor(
      mediaQuery,
      read.propertyName.name,
      isMaybe: isMaybe,
    );
    if (accessor == null) {
      return;
    }

    // In `maybeOf(c)?.padding.top`, `.top` is short-circuited by the `?.`:
    // after the rewrite, it needs its own `?.`.
    Token? continuation;
    if (isMaybe) {
      switch (replaced.parent) {
        case PropertyAccess(:Expression? target, :Token operator)
            when target == replaced && operator.type == TokenType.PERIOD:
          continuation = operator;
        case MethodInvocation(:Expression? target, :Token? operator)
            when target == replaced && operator?.type == TokenType.PERIOD:
          continuation = operator;
        case IndexExpression(:Expression? target) when target == replaced:
          return;
        case CascadeExpression(:Expression target) when target == replaced:
          return;
        case PostfixExpression(:Expression operand) when operand == replaced:
          return;
        case FunctionExpressionInvocation(:Expression function)
            when function == replaced:
          return;
      }
    }

    String arguments = unitResult.content.substring(
      call.argumentList.offset,
      call.argumentList.end,
    );
    _accessor = accessor;
    await builder.addDartFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(
        range.startEnd(call.methodName, replaced),
        '$accessor$arguments',
      );
      if (continuation != null) {
        builder.addSimpleReplacement(range.token(continuation), '?.');
      }
    });
  }

  /// The static `MediaQuery` method reading [property]: `<property>Of` or
  /// `<property>` (`maybe<Property>Of` or `maybe<Property>` if [isMaybe]),
  /// not deprecated, with the context as its only parameter.
  static String? _accessorFor(
    InterfaceElement mediaQuery,
    String property, {
    required bool isMaybe,
  }) {
    String capitalized = property[0].toUpperCase() + property.substring(1);
    List<String> candidates = isMaybe
        ? <String>['maybe${capitalized}Of', 'maybe$capitalized']
        : <String>['${property}Of', property];
    return candidates.where((String name) {
      MethodElement? method = mediaQuery.getMethod(name);
      return method != null &&
          method.isStatic &&
          !method.metadata.hasDeprecated &&
          method.formalParameters.length == 1;
    }).firstOrNull;
  }
}
