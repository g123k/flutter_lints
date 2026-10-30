import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:daad_lints/src/rules/directional_rule.dart';

/// Replaces a forbidden member by its directional equivalent, as described by
/// the [DirectionalRule.mapping] of [rule]:
/// - `EdgeInsets.only(left: 1.0)` -> `EdgeInsetsDirectional.only(start: 1.0)`
/// - `alignment: .topLeft` -> `alignment: .topStart`
class ReplaceWithDirectional extends ResolvedCorrectionProducer {
  ReplaceWithDirectional(this.rule, {required super.context})
    : fixKind = FixKind(
        'daad_lints.fix.${rule.name}',
        DartFixKindPriority.standard,
        "Replace with '${rule.mapping.directionalClassName}'",
      ),
      multiFixKind = FixKind(
        'daad_lints.fix.${rule.name}.multi',
        DartFixKindPriority.inFile,
        "Replace with '${rule.mapping.directionalClassName}' everywhere in "
            'file',
      );

  final DirectionalRule rule;

  @override
  final FixKind fixKind;

  @override
  final FixKind multiFixKind;

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.acrossSingleFile;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    DirectionalMapping mapping = rule.mapping;
    DirectionalMatch? match = _match(mapping, node);
    if (match == null) {
      return;
    }

    ClassElement? directionalClass = match.element.library?.getClass(
      mapping.directionalClassName,
    );
    if (!match.isGeometry && directionalClass == null) {
      return;
    }

    await builder.addDartFileEdit(file, (DartFileEditBuilder builder) {
      if (match.isGeometry) {
        builder.addSimpleReplacement(
          range.node(match.memberName!),
          match.newMemberName,
        );
      } else {
        // writeReference adds the import (or its prefix) if necessary
        builder.addReplacement(match.head, (DartEditBuilder builder) {
          builder.writeReference(directionalClass!);
          if (match.newMemberName != 'new') {
            builder.write('.${match.newMemberName}');
          }
        });
      }

      ArgumentList? arguments = match.arguments;
      if (arguments == null) {
        return;
      }

      for (Argument argument in arguments.arguments) {
        if (argument is! NamedArgument) {
          continue;
        }

        String? newName = mapping.renamedArguments[argument.name.lexeme];
        if (newName != null) {
          builder.addSimpleReplacement(range.token(argument.name), newName);
        }
      }
    });
  }

  /// The usage [mapping] matches at [node] or at its closest matching
  /// ancestor: the diagnostic is on the head of the usage (`EdgeInsets.only`),
  /// inside the matched node.
  static DirectionalMatch? _match(DirectionalMapping mapping, AstNode node) {
    for (AstNode? current = node; current != null; current = current.parent) {
      DirectionalMatch? match = mapping.match(current);
      if (match != null) {
        return match;
      }
    }
    return null;
  }
}
