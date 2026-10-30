import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:daad_lints/src/rules/field_ordering.dart';
import 'package:daad_lints/src/utils/member_source_range.dart';

/// Reorders the fields of a class into their groups, keeping their relative
/// order inside a group.
///
/// Only applies when the fields are contiguous: moving a field across a method
/// or a constructor would reorganize the class.
class SortFields extends ResolvedCorrectionProducer {
  SortFields({required super.context});

  static const FixKind _fixKind = FixKind(
    'daad_lints.fix.field_ordering',
    DartFixKindPriority.standard,
    'Sort the fields',
  );

  static const FixKind _multiFixKind = FixKind(
    'daad_lints.fix.field_ordering.multi',
    DartFixKindPriority.inFile,
    'Sort the fields everywhere in file',
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
    AstNode? body = node.thisOrAncestorOfType<FieldDeclaration>()?.parent;
    List<ClassMember>? members = switch (body) {
      ClassBody() => body.members,
      EnumBody() => body.members,
      _ => null,
    };
    if (members == null || FieldOrdering.firstMisplacedField(members) == null) {
      return;
    }

    List<FieldDeclaration> fields = members
        .whereType<FieldDeclaration>()
        .toList();
    int firstIndex = members.indexOf(fields.first);
    if (members.indexOf(fields.last) - firstIndex != fields.length - 1) {
      return;
    }

    String content = unitResult.content;
    List<SourceRange> ranges = <SourceRange>[
      for (FieldDeclaration field in fields) memberSourceRange(content, field),
    ];
    for (int i = 1; i < ranges.length; i++) {
      // A block comment between two fields belongs to neither of them
      if (content
          .substring(ranges[i - 1].end, ranges[i].offset)
          .trim()
          .isNotEmpty) {
        return;
      }
    }

    List<int> order = <int>[
      for (int group in <int>[1, 2, 3, 4])
        for (int i = 0; i < fields.length; i++)
          if (FieldOrdering.groupOf(fields[i]) == group) i,
    ];

    await builder.addDartFileEdit(file, (DartFileEditBuilder builder) {
      builder.addSimpleReplacement(
        range.startOffsetEndOffset(ranges.first.offset, ranges.last.end),
        _joinFields(content, fields, ranges, order),
      );
    });
  }

  /// The source of [fields] (their [ranges] in [content]) in [order]: a blank
  /// line between two groups, the original separator between two fields that
  /// were already adjacent, a line break otherwise.
  static String _joinFields(
    String content,
    List<FieldDeclaration> fields,
    List<SourceRange> ranges,
    List<int> order,
  ) {
    String indentation = indentationAt(content, ranges.first.offset);
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < order.length; i++) {
      int index = order[i];
      if (i > 0) {
        int previous = order[i - 1];
        if (FieldOrdering.groupOf(fields[previous]) !=
            FieldOrdering.groupOf(fields[index])) {
          buffer.write('\n\n$indentation');
        } else if (previous == index - 1) {
          buffer.write(
            content.substring(ranges[previous].end, ranges[index].offset),
          );
        } else {
          buffer.write('\n$indentation');
        }
      }
      SourceRange field = ranges[index];
      buffer.write(content.substring(field.offset, field.end));
    }
    return buffer.toString();
  }
}
