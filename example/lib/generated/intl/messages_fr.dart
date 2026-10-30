// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a fr locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// A hand-written mimic of the `intl_translation` output: the header above is
// the one it writes, and the French rules must still report the file.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes
// ignore_for_file:always_specify_types

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final MessageLookup messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'fr';

  static String m0(user) => "Bienvenue ${user} !";

  static String m1(username) => "Utilisateur : ${username}";

  static String m2(amount) => "Prix : ${amount} €";

  final Map<String, Function> messages = _notInlinedMessages(
    _notInlinedMessages,
  );

  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "openingHours": MessageLookupByLibrary.simpleMessage("Lun — Ven"),
    "price": m2,
    "summer": MessageLookupByLibrary.simpleMessage("l’été"),
    "user": m1,
    "welcome": m0,
  };
}
