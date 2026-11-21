import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Replaces three dots with the ellipsis character (`'a...'` -> `'a…'`).
class ReplaceWithEllipsis extends ResolvedCorrectionProducer {
  ReplaceWithEllipsis({required super.context});

  static const FixKind _fixKind = FixKind(
    'daad_lints.fix.prefer_ellipsis_character',
    DartFixKindPriority.standard,
    "Replace '...' with '\u2026'",
  );

  static const FixKind _multiFixKind = FixKind(
    'daad_lints.fix.prefer_ellipsis_character.multi',
    DartFixKindPriority.inFile,
    "Replace '...' with '\u2026' everywhere in file",
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
    // Not `node`: the covering node is the whole literal, while the
    // diagnostic range is the three dots only.
    int? offset = diagnosticOffset;
    int? length = diagnosticLength;
    if (offset == null || length == null) {
      return;
    }

    await builder.addDartFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(SourceRange(offset, length), '\u2026');
    });
  }
}
