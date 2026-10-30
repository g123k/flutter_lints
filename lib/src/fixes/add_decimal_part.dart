import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Appends `.0` to an integer literal used as a double (`-1` -> `-1.0`).
class AddDecimalPart extends ResolvedCorrectionProducer {
  AddDecimalPart({required super.context});

  static const FixKind _fixKind = FixKind(
    'daad_lints.fix.prefer_double_literals',
    DartFixKindPriority.standard,
    "Add '.0'",
  );

  static const FixKind _multiFixKind = FixKind(
    'daad_lints.fix.prefer_double_literals.multi',
    DartFixKindPriority.inFile,
    "Add '.0' everywhere in file",
  );

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.acrossSingleFile;

  @override
  FixKind get fixKind => _fixKind;

  @override
  FixKind get multiFixKind => _multiFixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    AstNode literal = node;
    if (literal is! IntegerLiteral) {
      return;
    }

    await builder.addDartFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleInsertion(literal.end, '.0');
    });
  }
}
