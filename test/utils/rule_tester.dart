import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
// ignore: implementation_imports, commit/revert are only public on the impl
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/conflicting_edit_exception.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
// ignore: implementation_imports, ExpectedDiagnostic is not exported
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart'
    show ExpectedDiagnostic;
import 'package:test/test.dart';

import 'flutter_stub.dart';

/// Base class to test a rule and its fix, against a minimal Flutter package.
abstract class RuleTest extends AnalysisRuleTest {
  /// Creates the fix of [rule], to set in [setUp] before calling the
  /// `assert*Fix*` methods.
  late CorrectionProducer<ParsedUnitResult> Function({
    required CorrectionProducerContext context,
  })
  createFix;

  /// The files of the `flutter` package, keyed by their path in the package.
  /// Override to test against another Flutter version.
  Map<String, String> get flutterFiles => flutterStubFiles;

  @override
  void setUp() {
    PackageBuilder flutter = newPackage('flutter');
    flutterFiles.forEach(flutter.addFile);
    super.setUp();
  }

  /// Writes [code] at [path] and asserts its diagnostics.
  Future<void> assertDiagnosticsInNewFile(
    String path,
    String code,
    List<ExpectedDiagnostic> expected,
  ) async {
    newFile(path, code);
    await assertDiagnosticsInFile(path, expected);
  }

  /// Asserts that [code] reports a diagnostic, and that the fix of each of
  /// its diagnostics transforms [code] into [expected], with [fixArguments]
  /// (the arguments of the fix label) when given.
  Future<void> assertFix(
    String code,
    String expected, {
    List<String>? fixArguments,
  }) async {
    _Resolved resolved = await _resolve(code);
    expect(resolved.diagnostics, isNotEmpty);

    for (Diagnostic diagnostic in resolved.diagnostics) {
      ChangeBuilder builder = ChangeBuilder(session: resolved.unit.session);
      CorrectionProducer<ParsedUnitResult> producer = createFix(
        context: resolved.context(diagnostic),
      );
      expect(producer.fixKind, isNotNull, reason: 'The fix must have a kind');
      await producer.compute(builder);

      expect(_apply(code, builder), expected);
      if (fixArguments != null) {
        expect(producer.fixArguments, fixArguments);
      }
    }
  }

  /// Asserts that [code] reports a diagnostic, and that the fix of each of
  /// its diagnostics does not change anything.
  Future<void> assertNoFix(String code) async {
    _Resolved resolved = await _resolve(code);
    expect(resolved.diagnostics, isNotEmpty);

    for (Diagnostic diagnostic in resolved.diagnostics) {
      ChangeBuilder builder = ChangeBuilder(session: resolved.unit.session);
      await createFix(context: resolved.context(diagnostic)).compute(builder);

      expect(builder.sourceChange.edits, isEmpty);
    }
  }

  /// Asserts that "fix all in file" transforms [code] into [expected].
  ///
  /// Follows `FixInFileProcessor`: every fix is computed on the original
  /// source into a single builder, and a fix conflicting with a previous one
  /// is reverted.
  Future<void> assertFixAll(String code, String expected) async {
    _Resolved resolved = await _resolve(code);
    expect(
      resolved.diagnostics.length,
      greaterThanOrEqualTo(2),
      reason: '"Fix all in file" is only offered for 2+ diagnostics',
    );

    ChangeBuilderImpl builder =
        ChangeBuilder(session: resolved.unit.session) as ChangeBuilderImpl;
    for (Diagnostic diagnostic in resolved.diagnostics) {
      CorrectionProducer<ParsedUnitResult> producer = createFix(
        context: resolved.context(diagnostic, applyingBulkFixes: true),
      );
      expect(producer.canBeAppliedAcrossSingleFile, isTrue);
      expect(
        producer.multiFixKind,
        isNotNull,
        reason: 'Without a multiFixKind, the fix-all change is reverted',
      );

      try {
        await producer.compute(builder);
        builder.commit();
      } on ConflictingEditException {
        builder.revert();
      }
    }

    expect(_apply(code, builder), expected);
  }

  Future<_Resolved> _resolve(String code) async {
    newFile(testFilePath, code);
    ResolvedUnitResult unit = await resolveFile(testFilePath);
    ResolvedLibraryResult library = await unit.session.getResolvedLibrary(
      unit.path,
    ) as ResolvedLibraryResult;
    return _Resolved(
      unit: unit,
      library: library,
      diagnostics: unit.diagnostics
          .where(
            (Diagnostic diagnostic) =>
                diagnostic.diagnosticCode == rule.diagnosticCodes.single,
          )
          .toList(),
    );
  }

  String _apply(String code, ChangeBuilder builder) {
    List<SourceFileEdit> edits = builder.sourceChange.edits;
    expect(edits, hasLength(1), reason: 'A single file must be edited');
    return SourceEdit.applySequence(code, edits.single.edits);
  }
}

class _Resolved {
  const _Resolved({
    required this.unit,
    required this.library,
    required this.diagnostics,
  });

  final ResolvedUnitResult unit;
  final ResolvedLibraryResult library;

  /// The diagnostics of the rule under test.
  final List<Diagnostic> diagnostics;

  CorrectionProducerContext context(
    Diagnostic diagnostic, {
    bool applyingBulkFixes = false,
  }) => CorrectionProducerContext.createResolved(
    libraryResult: library,
    unitResult: unit,
    applyingBulkFixes: applyingBulkFixes,
    diagnostic: diagnostic,
    selectionOffset: diagnostic.offset,
    selectionLength: diagnostic.length,
  );
}
