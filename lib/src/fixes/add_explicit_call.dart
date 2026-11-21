import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Inserts `.call` after the callee of a function value call
/// (`callback(x)` -> `callback.call(x)`, `f<int>(x)` -> `f.call<int>(x)`).
class AddExplicitCall extends ResolvedCorrectionProducer {
  AddExplicitCall({required super.context});

  static const FixKind _fixKind = FixKind(
    'daad_lints.fix.prefer_explicit_call',
    DartFixKindPriority.standard,
    "Add '.call'",
  );

  static const FixKind _multiFixKind = FixKind(
    'daad_lints.fix.prefer_explicit_call.multi',
    DartFixKindPriority.inFile,
    "Add '.call' everywhere in file",
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
    // The diagnostic covers exactly the callee, already a postfix-level
    // expression (`(a ?? b)`, `f()`, `n!`): `.call` needs no parentheses.
    int? offset = diagnosticOffset;
    int? length = diagnosticLength;
    if (offset == null || length == null) {
      return;
    }

    await builder.addDartFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleInsertion(offset + length, '.call');
    });
  }
}
