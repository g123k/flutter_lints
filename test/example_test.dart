@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:test/test.dart';

/// The rules of the plugin: `example/` has a triggering case for each.
const List<String> _rules = <String>[
  'avoid_alignment',
  'avoid_edge_insets_only',
  'avoid_hardcoded_strings',
  'avoid_media_query_of',
  'avoid_positioned',
  'avoid_repeated_of_context',
  'dispose_after_build',
  'field_ordering',
  'french_hyphen_only',
  'french_no_break_space',
  'french_straight_apostrophe',
  'prefer_double_literals',
  'super_key_last',
];

/// Analyzes `example/` with the real Flutter SDK: the only check that the
/// rules work against the real `package:flutter`, not the test stub.
///
/// Skipped when the Flutter SDK is not on the PATH.
void main() {
  test('the example reports every rule', () async {
    if (!await _hasFlutter()) {
      markTestSkipped('The Flutter SDK is not on the PATH.');
      return;
    }

    String example = '${Directory.current.path}/example';
    ProcessResult get = await Process.run('dart', <String>[
      'pub',
      'get',
    ], workingDirectory: example);
    expect(get.exitCode, 0, reason: '${get.stdout}${get.stderr}');

    ProcessResult analyze = await Process.run('dart', <String>[
      'analyze',
      '--format=machine',
    ], workingDirectory: example);
    // SEVERITY|TYPE|CODE|FILE|LINE|COLUMN|LENGTH|MESSAGE
    Set<String> reported = <String>{
      for (String line in (analyze.stdout as String).split('\n'))
        if (line.split('|').length >= 3) line.split('|')[2].toLowerCase(),
    };

    for (String rule in _rules) {
      expect(reported, contains(rule), reason: '${analyze.stdout}');
    }
  });
}

Future<bool> _hasFlutter() async {
  try {
    ProcessResult result = await Process.run('flutter', <String>[
      '--version',
    ], runInShell: true);
    return result.exitCode == 0;
  } on ProcessException {
    return false;
  }
}
