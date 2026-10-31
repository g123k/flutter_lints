import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

/// Whether [element] is the class [name] of the Flutter SDK
/// (eg: `MediaQuery`, `MediaQueryData`).
bool isFlutterClass(Element? element, String name) =>
    element is InterfaceElement &&
    element.name == name &&
    element.library.uri.toString().startsWith('package:flutter/');

/// Whether [node] calls the static `of` / `maybeOf` of Flutter's `MediaQuery`,
/// directly, through an import prefix or a typedef.
bool isMediaQueryCall(MethodInvocation node) {
  String name = node.methodName.name;
  if (name != 'of' && name != 'maybeOf') {
    return false;
  }

  Element? method = node.methodName.element;
  return method is MethodElement &&
      method.isStatic &&
      isFlutterClass(method.enclosingElement, 'MediaQuery');
}
