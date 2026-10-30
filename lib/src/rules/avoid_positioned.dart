import 'package:analyzer/error/error.dart';
import 'package:daad_lints/src/rules/directional_rule.dart';

/// Forbids `Positioned` in favor of `PositionedDirectional`, so that widgets
/// in a `Stack` follow the text direction (LTR / RTL).
///
/// `Positioned.fill` and `Positioned.directional` are allowed, and
/// `Positioned.fromRect` / `Positioned.fromRelativeRect` are ignored (no
/// directional equivalent).
class AvoidPositioned extends DirectionalRule {
  AvoidPositioned()
    : super(
        name: 'avoid_positioned',
        description:
            "'Positioned' ignores the text direction. "
            "Use 'PositionedDirectional' to support RTL languages.",
        mapping: const DirectionalMapping(
          className: 'Positioned',
          directionalClassName: 'PositionedDirectional',
          members: <String, String>{'new': 'new'},
          renamedArguments: <String, String>{'left': 'start', 'right': 'end'},
        ),
      );

  static const LintCode code = LintCode(
    'avoid_positioned',
    "Avoid 'Positioned', use 'PositionedDirectional' instead.",
    correctionMessage:
        "Try replacing with 'PositionedDirectional' "
        "('left' becomes 'start' and 'right' becomes 'end').",
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  LintCode get diagnosticCode => code;
}
