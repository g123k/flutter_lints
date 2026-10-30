import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:daad_lints/src/rules/dispose_after_build.dart';
import 'package:daad_lints/src/utils/member_source_range.dart';

/// Moves `dispose` to the end of its `State` class, with its doc comment,
/// annotations and the comments directly above it.
class MoveDisposeToEnd extends ResolvedCorrectionProducer {
  MoveDisposeToEnd({required super.context});

  static const FixKind _fixKind = FixKind(
    'daad_lints.fix.dispose_after_build',
    DartFixKindPriority.standard,
    "Move 'dispose' to the end of the class",
  );

  static const FixKind _multiFixKind = FixKind(
    'daad_lints.fix.dispose_after_build.multi',
    DartFixKindPriority.inFile,
    "Move 'dispose' to the end of the class everywhere in file",
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
    ClassDeclaration? classNode = node.thisOrAncestorOfType<ClassDeclaration>();
    if (classNode == null) {
      return;
    }

    MethodDeclaration? dispose = DisposeAfterBuild.misplacedDispose(classNode);
    if (dispose == null) {
      return;
    }

    String content = unitResult.content;
    SourceRange member = memberSourceRange(content, dispose);
    String indentation = indentationAt(content, member.offset);

    // Removes the whole lines of the member, and one of the blank lines
    // around it.
    int removalStart = lineStartOf(content, member.offset);
    int removalEnd = _nextLineStart(content, member.end);
    int afterBlankLine = _nextLineStart(content, removalEnd);
    if (content.substring(removalEnd, afterBlankLine).trim().isEmpty) {
      removalEnd = afterBlankLine;
    }

    await builder.addDartFileEdit(file, (DartFileEditBuilder builder) {
      builder.addDeletion(range.startOffsetEndOffset(removalStart, removalEnd));
      builder.addSimpleInsertion(
        memberSourceRange(content, classNode.body.members.last).end,
        '\n\n$indentation${content.substring(member.offset, member.end)}',
      );
    });
  }

  static int _nextLineStart(String content, int offset) {
    int newLine = content.indexOf('\n', offset);
    return newLine == -1 ? content.length : newLine + 1;
  }
}
