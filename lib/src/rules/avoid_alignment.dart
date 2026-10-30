import 'package:analyzer/error/error.dart';
import 'package:daad_lints/src/rules/directional_rule.dart';

/// Forbids `Alignment` in favor of `AlignmentDirectional`, so that alignments
/// follow the text direction (LTR / RTL).
class AvoidAlignment extends DirectionalRule {
  AvoidAlignment()
    : super(
        name: 'avoid_alignment',
        description:
            "'Alignment' ignores the text direction. "
            "Use 'AlignmentDirectional' to support RTL languages.",
        mapping: const DirectionalMapping(
          className: 'Alignment',
          directionalClassName: 'AlignmentDirectional',
          members: <String, String>{
            'new': 'new',
            'topLeft': 'topStart',
            'topCenter': 'topCenter',
            'topRight': 'topEnd',
            'centerLeft': 'centerStart',
            'center': 'center',
            'centerRight': 'centerEnd',
            'bottomLeft': 'bottomStart',
            'bottomCenter': 'bottomCenter',
            'bottomRight': 'bottomEnd',
          },
          // Only the members depending on the text direction
          geometryClassName: 'AlignmentGeometry',
          geometryMembers: <String, String>{
            'xy': 'directional',
            'topLeft': 'topStart',
            'topRight': 'topEnd',
            'centerLeft': 'centerStart',
            'centerRight': 'centerEnd',
            'bottomLeft': 'bottomStart',
            'bottomRight': 'bottomEnd',
          },
        ),
      );

  static const LintCode code = LintCode(
    'avoid_alignment',
    "Avoid 'Alignment', use 'AlignmentDirectional' instead.",
    correctionMessage:
        "Try replacing with 'AlignmentDirectional' "
        "('left' becomes 'start' and 'right' becomes 'end').",
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  LintCode get diagnosticCode => code;
}
