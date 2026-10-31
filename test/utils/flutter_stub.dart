/// The files of a minimal `flutter` package, keyed by their path in the
/// package, with only the APIs the rules depend on.
const Map<String, String> flutterStubFiles = <String, String>{
  'lib/painting.dart': r'''
export 'src/painting/alignment.dart';
export 'src/painting/basic_types.dart';
export 'src/painting/edge_insets.dart';
export 'src/painting/inline_span.dart';
export 'src/painting/text_span.dart';
''',
  'lib/widgets.dart': r'''
export 'painting.dart';
export 'src/widgets/basic.dart';
export 'src/widgets/framework.dart';
export 'src/widgets/heroes.dart';
export 'src/widgets/image.dart';
export 'src/widgets/media_query.dart';
export 'src/widgets/navigator.dart';
export 'src/widgets/text.dart';
''',
  'lib/material.dart': r'''
export 'widgets.dart';
export 'src/material/bottom_navigation_bar.dart';
export 'src/material/dropdown.dart';
export 'src/material/dropdown_menu.dart';
export 'src/material/input_decorator.dart';
export 'src/material/text_field.dart';
export 'src/material/theme.dart';
export 'src/material/tooltip.dart';
''',
  'lib/src/painting/alignment.dart': _alignment,
  'lib/src/painting/basic_types.dart': _basicTypes,
  'lib/src/painting/edge_insets.dart': _edgeInsets,
  'lib/src/painting/inline_span.dart': _inlineSpan,
  'lib/src/painting/text_span.dart': _textSpan,
  'lib/src/widgets/basic.dart': _basic,
  'lib/src/widgets/framework.dart': _framework,
  'lib/src/widgets/heroes.dart': _heroes,
  'lib/src/widgets/image.dart': _image,
  'lib/src/widgets/media_query.dart': _mediaQuery,
  'lib/src/widgets/navigator.dart': _navigator,
  'lib/src/widgets/text.dart': _text,
  'lib/src/material/bottom_navigation_bar.dart': _bottomNavigationBar,
  'lib/src/material/dropdown.dart': _dropdown,
  'lib/src/material/dropdown_menu.dart': _dropdownMenu,
  'lib/src/material/input_decorator.dart': _inputDecorator,
  'lib/src/material/text_field.dart': _textField,
  'lib/src/material/theme.dart': _theme,
  'lib/src/material/tooltip.dart': _tooltip,
};

const String _alignment = r'''
abstract class AlignmentGeometry {
  const AlignmentGeometry();
  const factory AlignmentGeometry.xy(double x, double y) = Alignment;
  const factory AlignmentGeometry.directional(double start, double y) =
      AlignmentDirectional;

  static const AlignmentGeometry topLeft = Alignment.topLeft;
  static const AlignmentGeometry topStart = AlignmentDirectional.topStart;
  static const AlignmentGeometry center = Alignment.center;
}

class Alignment extends AlignmentGeometry {
  const Alignment(this.x, this.y);

  static const Alignment topLeft = Alignment(-1.0, -1.0);
  static const Alignment center = Alignment(0.0, 0.0);

  final double x;
  final double y;

  static Alignment? lerp(Alignment? a, Alignment? b, double t) => a;
}

class AlignmentDirectional extends AlignmentGeometry {
  const AlignmentDirectional(this.start, this.y);

  static const AlignmentDirectional topStart = AlignmentDirectional(-1.0, -1.0);
  static const AlignmentDirectional center = AlignmentDirectional(0.0, 0.0);

  final double start;
  final double y;
}
''';

const String _edgeInsets = r'''
abstract class EdgeInsetsGeometry {
  const EdgeInsetsGeometry();
  const factory EdgeInsetsGeometry.only({
    double left,
    double top,
    double right,
    double bottom,
  }) = EdgeInsets.only;
  const factory EdgeInsetsGeometry.directional({
    double start,
    double top,
    double end,
    double bottom,
  }) = EdgeInsetsDirectional.only;
}

class EdgeInsets extends EdgeInsetsGeometry {
  const EdgeInsets.all(double value)
    : left = value,
      top = value,
      right = value,
      bottom = value;
  const EdgeInsets.only({
    this.left = 0.0,
    this.top = 0.0,
    this.right = 0.0,
    this.bottom = 0.0,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;
}

class EdgeInsetsDirectional extends EdgeInsetsGeometry {
  const EdgeInsetsDirectional.only({
    this.start = 0.0,
    this.top = 0.0,
    this.end = 0.0,
    this.bottom = 0.0,
  });

  final double start;
  final double top;
  final double end;
  final double bottom;
}
''';

const String _basic = r'''
import '../painting/alignment.dart';
import '../painting/edge_insets.dart';
import 'framework.dart';

enum TextDirection { rtl, ltr }

class Align extends Widget {
  const Align({this.alignment = AlignmentDirectional.center, this.child});

  final AlignmentGeometry alignment;
  final Widget? child;
}

class Padding extends Widget {
  const Padding({required this.padding, this.child});

  final EdgeInsetsGeometry padding;
  final Widget? child;
}

class Positioned extends Widget {
  const Positioned({
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.width,
    this.height,
    required this.child,
  });

  const Positioned.fill({
    this.left = 0.0,
    this.top = 0.0,
    this.right = 0.0,
    this.bottom = 0.0,
    required this.child,
  }) : width = null,
       height = null;

  factory Positioned.directional({
    required TextDirection textDirection,
    double? start,
    double? top,
    double? end,
    double? bottom,
    double? width,
    double? height,
    required Widget child,
  }) => Positioned(child: child);

  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? width;
  final double? height;
  final Widget child;
}

class Semantics extends Widget {
  const Semantics({this.identifier, this.label, this.child, super.key});

  final String? identifier;
  final String? label;
  final Widget? child;
}

class PositionedDirectional extends Widget {
  const PositionedDirectional({
    this.start,
    this.top,
    this.end,
    this.bottom,
    this.width,
    this.height,
    required this.child,
  });

  final double? start;
  final double? top;
  final double? end;
  final double? bottom;
  final double? width;
  final double? height;
  final Widget child;
}
''';

const String _framework = r'''
class Key {
  const Key(this.value);

  final String value;
}

abstract class BuildContext {}

class Widget {
  const Widget({this.key});

  final Key? key;
}

abstract class StatelessWidget extends Widget {
  const StatelessWidget({super.key});

  Widget build(BuildContext context);
}

abstract class StatefulWidget extends Widget {
  const StatefulWidget({super.key});

  State<StatefulWidget> createState();
}

abstract class State<T extends StatefulWidget> {
  T get widget => throw Exception();

  BuildContext get context => throw Exception();

  void initState() {}

  Widget build(BuildContext context);

  void dispose() {}
}
''';

const String _basicTypes = r'''
class Size {
  const Size(this.width, this.height);

  final double width;
  final double height;

  double get shortestSide => width;
}
''';

const String _mediaQuery = r'''
import '../painting/basic_types.dart';
import '../painting/edge_insets.dart';
import 'framework.dart';

class MediaQueryData {
  const MediaQueryData({
    this.size = const Size(0.0, 0.0),
    this.devicePixelRatio = 1.0,
    this.padding = const EdgeInsets.all(0.0),
    this.letterSpacingOverride,
    this.supportsShowingSystemContextMenu = false,
    this.displayFeatures = const <Object>[],
  });

  final Size size;
  final double devicePixelRatio;
  final EdgeInsets padding;
  final double? letterSpacingOverride;
  final bool supportsShowingSystemContextMenu;
  final List<Object> displayFeatures;

  @Deprecated('Use textScaler instead.')
  double get textScaleFactor => 1.0;

  MediaQueryData copyWith({Size? size}) => this;

  MediaQueryData removePadding({bool removeTop = false}) => this;

  MediaQueryData removeViewInsets({bool removeTop = false}) => this;

  MediaQueryData removeViewPadding({bool removeTop = false}) => this;

  MediaQueryData removeDisplayFeatures(Object subScreen) => this;
}

abstract final class MediaQuery {
  static MediaQueryData of(BuildContext context) => const MediaQueryData();

  static MediaQueryData? maybeOf(BuildContext context) => null;

  static Size sizeOf(BuildContext context) => of(context).size;

  static Size? maybeSizeOf(BuildContext context) => maybeOf(context)?.size;

  static double widthOf(BuildContext context) => of(context).size.width;

  static double? maybeWidthOf(BuildContext context) =>
      maybeOf(context)?.size.width;

  static double heightOf(BuildContext context) => of(context).size.height;

  static double? maybeHeightOf(BuildContext context) =>
      maybeOf(context)?.size.height;

  static EdgeInsets paddingOf(BuildContext context) => of(context).padding;

  static EdgeInsets? maybePaddingOf(BuildContext context) =>
      maybeOf(context)?.padding;

  @Deprecated('Use textScalerOf instead.')
  static double textScaleFactorOf(BuildContext context) => 1.0;

  static double? maybeLetterSpacingOverrideOf(BuildContext context) =>
      maybeOf(context)?.letterSpacingOverride;

  static bool supportsShowingSystemContextMenu(BuildContext context) =>
      of(context).supportsShowingSystemContextMenu;

  static bool? maybeSupportsShowingSystemContextMenu(BuildContext context) =>
      maybeOf(context)?.supportsShowingSystemContextMenu;

  static List<Object> displayFeaturesOf(BuildContext context) =>
      of(context).displayFeatures;

  static List<Object>? maybeDisplayFeaturesOf(BuildContext context) =>
      maybeOf(context)?.displayFeatures;
}
''';

const String _navigator = r'''
import 'framework.dart';

class NavigatorState {
  bool canPop() => false;

  void pop() {}
}

abstract final class Navigator {
  static NavigatorState of(
    BuildContext context, {
    bool rootNavigator = false,
  }) => NavigatorState();

  static NavigatorState? maybeOf(
    BuildContext context, {
    bool rootNavigator = false,
  }) => null;
}
''';

const String _theme = r'''
import '../widgets/framework.dart';

class ThemeData {
  const ThemeData({this.useMaterial3 = true});

  final bool useMaterial3;
}

abstract final class Theme {
  static ThemeData of(BuildContext context) => const ThemeData();

  static ThemeData? maybeOf(BuildContext context) => null;
}
''';

const String _inlineSpan = r'''
abstract class InlineSpan {
  const InlineSpan();
}
''';

const String _textSpan = r'''
import 'inline_span.dart';

class TextSpan extends InlineSpan {
  const TextSpan({this.text, this.children});

  final String? text;
  final List<InlineSpan>? children;
}
''';

const String _heroes = r'''
import 'framework.dart';

class Hero extends Widget {
  const Hero({required this.tag, required this.child, super.key});

  final Object tag;
  final Widget child;
}
''';

const String _image = r'''
import 'framework.dart';

class Image extends Widget {
  Image.asset(String name, {this.package, this.semanticLabel, super.key});

  Image.network(String src, {this.semanticLabel, super.key}) : package = null;

  final String? package;
  final String? semanticLabel;
}
''';

const String _text = r'''
import '../painting/inline_span.dart';
import 'framework.dart';

class Text extends Widget {
  const Text(
    String this.data, {
    this.semanticsLabel,
    this.semanticsIdentifier,
    super.key,
  }) : textSpan = null;

  const Text.rich(InlineSpan this.textSpan, {super.key})
    : data = null,
      semanticsLabel = null,
      semanticsIdentifier = null;

  final String? data;
  final InlineSpan? textSpan;
  final String? semanticsLabel;
  final String? semanticsIdentifier;
}
''';

const String _bottomNavigationBar = r'''
import '../widgets/framework.dart';

class BottomNavigationBarItem {
  const BottomNavigationBarItem({required this.icon, this.label, this.tooltip});

  final Widget icon;
  final String? label;
  final String? tooltip;
}
''';

const String _dropdown = r'''
import '../widgets/framework.dart';

class DropdownMenuItem<T> extends Widget {
  const DropdownMenuItem({this.value, required this.child, super.key});

  final T? value;
  final Widget child;
}
''';

const String _dropdownMenu = r'''
class DropdownMenuEntry<T> {
  const DropdownMenuEntry({required this.value, required this.label});

  final T value;
  final String label;
}
''';

const String _inputDecorator = r'''
class InputDecoration {
  const InputDecoration({this.hintText, this.labelText});

  final String? hintText;
  final String? labelText;
}
''';

const String _textField = r'''
import '../widgets/framework.dart';
import 'input_decorator.dart';

class TextField extends Widget {
  const TextField({this.decoration, this.restorationId, super.key});

  final InputDecoration? decoration;
  final String? restorationId;
}
''';

const String _tooltip = r'''
import '../widgets/framework.dart';

class Tooltip extends Widget {
  const Tooltip({this.message, this.child, super.key});

  final String? message;
  final Widget? child;
}
''';
