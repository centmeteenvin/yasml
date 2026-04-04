import 'dart:io';

import 'package:pub_semver/pub_semver.dart';

/// Version bump type for semver.
enum BumpType { major, minor, patch }

/// Colored terminal output, step banners, and interactive user prompts.
class Console {
  static const reset = '\x1B[0m';
  static const bold = '\x1B[1m';
  static const green = '\x1B[32m';
  static const yellow = '\x1B[33m';
  static const red = '\x1B[31m';
  static const cyan = '\x1B[36m';
  static const dim = '\x1B[2m';

  static void step(int n, String title) {
    stdout.writeln('');
    stdout.writeln('$bold$cyan── Step $n: $title ──$reset');
  }

  static void success(String msg) => stdout.writeln('$green✓$reset $msg');
  static void skip(String msg) => stdout.writeln('$dim⏭ $msg$reset');
  static void info(String msg) => stdout.writeln('  $msg');
  static void warn(String msg) => stdout.writeln('$yellow⚠ $msg$reset');
  static void error(String msg) => stderr.writeln('$red✗ $msg$reset');

  static void banner() {
    stdout.writeln('');
    stdout.writeln('$bold${cyan}yasml publish$reset');
    stdout.writeln('${dim}Local release pipeline with resumability$reset');
  }

  /// Prompt the user to select a bump type, showing version previews.
  static BumpType promptBumpType(Version current) {
    stdout.writeln('');
    stdout.writeln('Current version: $bold$current$reset');
    stdout.writeln('');
    stdout.writeln(
      '  ${bold}1$reset) patch → $green${current.nextPatch}$reset',
    );
    stdout.writeln(
      '  ${bold}2$reset) minor → $green${current.nextMinor}$reset',
    );
    stdout.writeln(
      '  ${bold}3$reset) major → $green${current.nextMajor}$reset',
    );
    stdout.writeln('');

    while (true) {
      stdout.write('Select bump type [1/2/3]: ');
      final input = stdin.readLineSync()?.trim();
      switch (input) {
        case '1' || 'patch':
          return BumpType.patch;
        case '2' || 'minor':
          return BumpType.minor;
        case '3' || 'major':
          return BumpType.major;
        default:
          Console.warn('Invalid selection. Enter 1, 2, or 3.');
      }
    }
  }

  /// Ask the user for a yes/no confirmation. Returns true if confirmed.
  static bool confirm(String prompt) {
    stdout.write('$yellow$prompt [y/N]:$reset ');
    final input = stdin.readLineSync()?.trim().toLowerCase();
    return input == 'y' || input == 'yes';
  }
}
