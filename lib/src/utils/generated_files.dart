import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/token.dart';

const List<String> _generatedSuffixes = <String>[
  '.g.dart',
  '.freezed.dart',
  '.gr.dart',
  '.mocks.dart',
];

/// Whether [unit] is a generated file: a known generated suffix, or a
/// `GENERATED CODE` header comment.
bool isGeneratedUnit(RuleContextUnit unit) {
  String path = unit.file.path;
  if (_generatedSuffixes.any(path.endsWith)) {
    return true;
  }

  Token? comment = unit.unit.beginToken.precedingComments;
  while (comment != null) {
    if (comment.lexeme.toUpperCase().contains('GENERATED CODE')) {
      return true;
    }
    comment = comment.next;
  }
  return false;
}
