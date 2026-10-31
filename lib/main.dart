import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:daad_lints/src/fixes/add_decimal_part.dart';
import 'package:daad_lints/src/fixes/extract_of_context.dart';
import 'package:daad_lints/src/fixes/move_dispose_to_end.dart';
import 'package:daad_lints/src/fixes/move_super_key_last.dart';
import 'package:daad_lints/src/fixes/replace_with_directional.dart';
import 'package:daad_lints/src/fixes/replace_with_media_query_accessor.dart';
import 'package:daad_lints/src/fixes/sort_fields.dart';
import 'package:daad_lints/src/rules/avoid_alignment.dart';
import 'package:daad_lints/src/rules/avoid_edge_insets_only.dart';
import 'package:daad_lints/src/rules/avoid_hardcoded_strings.dart';
import 'package:daad_lints/src/rules/avoid_media_query_of.dart';
import 'package:daad_lints/src/rules/avoid_positioned.dart';
import 'package:daad_lints/src/rules/avoid_repeated_of_context.dart';
import 'package:daad_lints/src/rules/directional_rule.dart';
import 'package:daad_lints/src/rules/dispose_after_build.dart';
import 'package:daad_lints/src/rules/field_ordering.dart';
import 'package:daad_lints/src/rules/french_hyphen_only.dart';
import 'package:daad_lints/src/rules/french_no_break_space.dart';
import 'package:daad_lints/src/rules/french_straight_apostrophe.dart';
import 'package:daad_lints/src/rules/prefer_double_literals.dart';
import 'package:daad_lints/src/rules/super_key_last.dart';

/// The entry point the analysis server loads.
final DaadLintsPlugin plugin = DaadLintsPlugin();

/// The `daad_lints` analyzer plugin: registers every rule (enabled by default,
/// reported as a warning) and its quick fix. Adopters enable it in the
/// top-level `plugins` section of `analysis_options.yaml`; see the README.
class DaadLintsPlugin extends Plugin {
  @override
  void register(PluginRegistry registry) {
    for (DirectionalRule rule in <DirectionalRule>[
      AvoidEdgeInsetsOnly(),
      AvoidAlignment(),
      AvoidPositioned(),
    ]) {
      registry.registerWarningRule(rule);
      registry.registerFixForRule(
        rule.diagnosticCode,
        ({required CorrectionProducerContext context}) =>
            ReplaceWithDirectional(rule, context: context),
      );
    }

    registry
      ..registerWarningRule(SuperKeyLast())
      ..registerFixForRule(SuperKeyLast.code, MoveSuperKeyLast.new)
      ..registerWarningRule(PreferDoubleLiterals())
      ..registerFixForRule(PreferDoubleLiterals.code, AddDecimalPart.new)
      ..registerWarningRule(DisposeAfterBuild())
      ..registerFixForRule(DisposeAfterBuild.code, MoveDisposeToEnd.new)
      ..registerWarningRule(FieldOrdering())
      ..registerFixForRule(FieldOrdering.code, SortFields.new)
      ..registerWarningRule(AvoidRepeatedOfContext())
      ..registerFixForRule(AvoidRepeatedOfContext.code, ExtractOfContext.new)
      ..registerWarningRule(AvoidMediaQueryOf())
      ..registerFixForRule(
        AvoidMediaQueryOf.code,
        ReplaceWithMediaQueryAccessor.new,
      )
      // No fix: extracting the string depends on the project's l10n setup.
      ..registerWarningRule(AvoidHardcodedStrings())
      // The French typography rules have no fix: the .arb source is the place
      // to fix, the generated file is overwritten.
      ..registerWarningRule(FrenchStraightApostrophe())
      ..registerWarningRule(FrenchHyphenOnly())
      ..registerWarningRule(FrenchNoBreakSpace());
  }

  @override
  String get name => 'daad_lints';
}
