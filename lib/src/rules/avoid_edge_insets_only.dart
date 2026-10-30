import 'package:analyzer/error/error.dart';
import 'package:daad_lints/src/rules/directional_rule.dart';

/// Forbids `EdgeInsets.only(...)` in favor of `EdgeInsetsDirectional.only(...)`,
/// so that paddings follow the text direction (LTR / RTL).
class AvoidEdgeInsetsOnly extends DirectionalRule {
  AvoidEdgeInsetsOnly()
    : super(
        name: 'avoid_edge_insets_only',
        description:
            "'EdgeInsets.only' ignores the text direction. "
            "Use 'EdgeInsetsDirectional.only' to support RTL languages.",
        mapping: const DirectionalMapping(
          className: 'EdgeInsets',
          directionalClassName: 'EdgeInsetsDirectional',
          members: <String, String>{'only': 'only'},
          geometryClassName: 'EdgeInsetsGeometry',
          geometryMembers: <String, String>{'only': 'directional'},
          renamedArguments: <String, String>{'left': 'start', 'right': 'end'},
        ),
      );

  static const LintCode code = LintCode(
    'avoid_edge_insets_only',
    "Avoid 'EdgeInsets.only', use 'EdgeInsetsDirectional.only' instead.",
    correctionMessage:
        "Try replacing with 'EdgeInsetsDirectional.only' "
        "('left' becomes 'start' and 'right' becomes 'end').",
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  LintCode get diagnosticCode => code;
}
