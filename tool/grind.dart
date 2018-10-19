import 'dart:io';

import 'package:grinder/grinder.dart';

void main(List<String> args) => grind(args);

final Set<Directory> sourceDirs = [
  'lib',
  'test',
  'tool',
].map((path) => Directory(path)).toSet();

@Task('Travis checks')
void travis() {
  if (DartFmt.dryRun(sourceDirs)) {
    throw Exception('Source code not formatted');
  }

  Analyzer.analyze(sourceDirs);

  TestRunner().test();
}
