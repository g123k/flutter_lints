import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';

/// The range of [member] in [content], with what moves along with it: its doc
/// comment and annotations, the `//` comment lines directly above it (no
/// blank line in between), such as `// ignore:` comments, and a `//` comment
/// at the end of its last line.
SourceRange memberSourceRange(String content, ClassMember member) {
  int start = member.offset;
  while (true) {
    int lineStart = lineStartOf(content, start);
    if (lineStart == 0) {
      break;
    }

    int previousLineStart = lineStartOf(content, lineStart - 1);
    String previousLine = content.substring(previousLineStart, lineStart - 1);
    if (!previousLine.trimLeft().startsWith('//')) {
      break;
    }
    start =
        previousLineStart +
        previousLine.length -
        previousLine.trimLeft().length;
  }

  int end = member.end;
  int lineEnd = content.indexOf('\n', end);
  String rest = content.substring(
    end,
    lineEnd == -1 ? content.length : lineEnd,
  );
  if (rest.trimLeft().startsWith('//')) {
    end += rest.trimRight().length;
  }
  return SourceRange(start, end - start);
}

/// The offset of the start of the line containing [offset].
int lineStartOf(String content, int offset) =>
    offset == 0 ? 0 : content.lastIndexOf('\n', offset - 1) + 1;

/// The indentation of the line containing [offset].
String indentationAt(String content, int offset) {
  int lineStart = lineStartOf(content, offset);
  String line = content.substring(lineStart, offset);
  return line.substring(0, line.length - line.trimLeft().length);
}
