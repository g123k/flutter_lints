import 'rule_tester.dart';

/// Base class of the French typography rule tests.
abstract class FrenchRuleTest extends RuleTest {
  /// A French localization file, as `flutter gen-l10n` names it.
  String get frenchFilePath =>
      '$testPackageLibPath/l10n/app_localizations_fr.dart';
}
