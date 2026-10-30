import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:daad_lints/src/rules/super_key_last.dart';

/// Moves `super.key` to the end of the constructor parameters, keeping its
/// metadata, comments and default value.
class MoveSuperKeyLast extends ResolvedCorrectionProducer {
  MoveSuperKeyLast({required super.context});

  static const FixKind _fixKind = FixKind(
    'daad_lints.fix.super_key_last',
    DartFixKindPriority.standard,
    "Move 'super.key' to the end",
  );

  static const FixKind _multiFixKind = FixKind(
    'daad_lints.fix.super_key_last.multi',
    DartFixKindPriority.inFile,
    "Move 'super.key' to the end everywhere in file",
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
    ConstructorDeclaration? constructor = node
        .thisOrAncestorOfType<ConstructorDeclaration>();
    if (constructor == null) {
      return;
    }

    SuperFormalParameter? superKey = SuperKeyLast.misplacedSuperKey(
      constructor,
    );
    if (superKey == null) {
      return;
    }

    List<FormalParameter> parameters = constructor.parameters.parameters;
    FormalParameter next = parameters[parameters.indexOf(superKey) + 1];
    String content = unitResult.content;
    FormalParameterList list = constructor.parameters;
    int listEnd = (list.rightDelimiter ?? list.rightParenthesis).offset;
    // A comment after super.key or after the last parameter would no longer
    // follow the same parameter once super.key is moved.
    if (_hasComment(content.substring(superKey.end, next.offset)) ||
        _hasComment(content.substring(parameters.last.end, listEnd))) {
      return;
    }

    int start = _startWithComments(superKey);
    int nextStart = _startWithComments(next);

    // The separator between super.key and the next parameter tells whether
    // the list has one parameter per line.
    String gap = content.substring(superKey.end, nextStart);
    int lastNewLine = gap.lastIndexOf('\n');
    String separator = lastNewLine == -1
        ? ', '
        : ',\n${gap.substring(lastNewLine + 1)}';

    await builder.addDartFileEdit(file, (DartFileEditBuilder builder) {
      builder.addDeletion(range.startOffsetEndOffset(start, nextStart));
      builder.addSimpleInsertion(
        parameters.last.end,
        '$separator${content.substring(start, superKey.end)}',
      );
    });
  }

  static bool _hasComment(String text) =>
      text.contains('//') || text.contains('/*');

  static int _startWithComments(FormalParameter parameter) =>
      parameter.beginToken.precedingComments?.offset ?? parameter.offset;
}
