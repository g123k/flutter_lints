import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:daad_lints/src/utils/generated_files.dart';

/// Requires the fields of a class to be declared in this order: `static const`
/// and `static final` fields, then other `static` fields, then `final` instance
/// fields (`late final` included), then other instance fields.
class FieldOrdering extends AnalysisRule {
  FieldOrdering()
    : super(
        name: 'field_ordering',
        description:
            "Fields must be declared in this order: 'static const' and "
            "'static final' fields, other 'static' fields, 'final' instance "
            "fields, then other instance fields.",
      );

  static const LintCode code = LintCode(
    'field_ordering',
    'Field declared after a field of a later group.',
    correctionMessage:
        "Try ordering the fields: 'static const' and 'static final' fields, "
        "other 'static' fields, 'final' instance fields, then other instance "
        "fields.",
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    _Visitor visitor = _Visitor(this, context);
    registry
      ..addClassDeclaration(this, visitor)
      ..addMixinDeclaration(this, visitor)
      ..addEnumDeclaration(this, visitor);
  }

  /// The group of [field]: 1 for `static const` and `static final` fields,
  /// 2 for other `static` fields, 3 for `final` instance fields, 4 for the
  /// others.
  static int groupOf(FieldDeclaration field) {
    VariableDeclarationList variables = field.fields;
    if (field.isStatic) {
      return variables.isConst || variables.isFinal ? 1 : 2;
    }
    return variables.isFinal ? 3 : 4;
  }

  /// The first field of [members] declared after a field of a later group.
  static FieldDeclaration? firstMisplacedField(List<ClassMember> members) {
    int maxGroup = 0;
    for (FieldDeclaration field in members.whereType<FieldDeclaration>()) {
      int group = groupOf(field);
      if (group < maxGroup) {
        return field;
      }
      if (group > maxGroup) {
        maxGroup = group;
      }
    }
    return null;
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final FieldOrdering rule;
  final RuleContext context;

  @override
  void visitClassDeclaration(ClassDeclaration node) =>
      _check(node.body.members);

  @override
  void visitMixinDeclaration(MixinDeclaration node) =>
      _check(node.body.members);

  @override
  void visitEnumDeclaration(EnumDeclaration node) => _check(node.body.members);

  void _check(List<ClassMember> members) {
    FieldDeclaration? field = FieldOrdering.firstMisplacedField(members);
    if (field == null || isGeneratedUnit(context.currentUnit!)) {
      return;
    }

    rule.reportAtToken(field.fields.variables.first.name);
  }
}
