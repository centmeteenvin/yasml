#!/usr/bin/env dart
/// Local publishing CLI for the yasml package.
///
/// Replaces the multi-workflow GitHub Actions pipeline with a single
/// resumable command: `dart run tool/publish.dart`
///
library;

import 'dart:convert';
import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

import 'src/console.dart';
import 'src/shell.dart';

// ── Main ─────────────────────────────────────────────────────────────

Future<void> main() async {
  try {
    await publish();
  } on ProcessException catch (e) {
    Console.error('Command failed: ${e.executable} ${e.arguments.join(' ')}');
    if (e.message.isNotEmpty) Console.error(e.message);
    exit(e.errorCode);
  }
}

// ── Stage runner ─────────────────────────────────────────────────────

/// Runs a pipeline stage. If [gate] returns true the stage is skipped.
/// Returns the runner's return value, or null when skipped.
Future<T?> stage<T>(
  int n,
  String title, {
  required Future<bool> Function() gate,
  required Future<T> Function() runner,
}) async {
  Console.step(n, title);
  if (await gate()) return null;
  return runner();
}

// ── Publish pipeline ─────────────────────────────────────────────────

Future<void> publish() async {
  Console.banner();

  final current = StateDetector.readPubspecVersion();

  await stage(0, 'Preflight',
    gate: StateDetector.isPreflightReady,
    runner: reportPreflightFailures,
  );

  final newVersion = await stage<Version>(1, 'Version selection',
    gate: () => StateDetector.isVersionBumped(current),
    runner: () async {
      final bumpType = Console.promptBumpType(current);
      final v = current.bump(bumpType);
      Console.success('Will release $v');
      return v;
    },
  ) ?? current;

  await stage(2, 'Changelog + commit',
    gate: () => StateDetector.isReleaseCommitted(newVersion),
    runner: () => commitRelease(newVersion),
  );

  await stage(3, 'Dry-run validation',
    gate: () => StateDetector.isDryRunPassed(newVersion),
    runner: () => dryRunValidation(newVersion),
  );

  await stage(4, 'Push',
    gate: () => StateDetector.isTagPushed(newVersion.tag),
    runner: () => pushRelease(newVersion),
  );

  await stage(5, 'Publish + GH release',
    gate: () => StateDetector.isFullyPublished(newVersion),
    runner: () => publishAndRelease(newVersion),
  );

  stdout.writeln('');
  Console.success('Release $newVersion complete!');
}

// ── Step implementations ─────────────────────────────────────────────

Future<void> reportPreflightFailures() async {
  final missing = <String>[];
  final instructions = <String, String>{
    'git-cliff': 'Install from: https://git-cliff.org',
    'gh': 'Install from: https://cli.github.com',
    'dart': 'Install from: https://dart.dev/get-dart',
    'pana': 'Install with: dart pub global activate pana',
  };

  for (final tool in ['git-cliff', 'gh', 'dart']) {
    if (await Shell.runExitCode('which', [tool]) != 0) {
      missing.add(tool);
    }
  }
  final globals = await Shell.run(
    'dart', ['pub', 'global', 'list'],
    throwOnError: false,
  );
  if (!globals.contains('pana')) missing.add('pana');

  if (missing.isNotEmpty) {
    Console.error('Missing tools: ${missing.join(', ')}');
    for (final tool in missing) {
      Console.info(instructions[tool]!);
    }
    exit(1);
  }

  final branch = await Shell.run('git', ['branch', '--show-current']);
  if (branch != 'main') {
    Console.error('Must be on main branch (currently on $branch)');
    exit(1);
  }

  final status = await Shell.run('git', ['status', '--porcelain']);
  final dirty = status
      .split('\n')
      .where((line) => line.trim().isNotEmpty)
      .where((line) => !line.contains('.dart_tool'));
  if (dirty.isNotEmpty) {
    Console.error('Working tree is dirty (excluding .dart_tool)');
    Console.info('Commit or stash changes before releasing.');
    exit(1);
  }

  await Shell.run('git', ['fetch', 'origin', 'main', '--quiet']);
  final local = await Shell.run('git', ['rev-parse', 'HEAD']);
  final remote = await Shell.run('git', ['rev-parse', 'origin/main']);
  if (local != remote) {
    Console.error('Local main is not up-to-date with origin/main');
    Console.info('Pull latest changes before releasing.');
    exit(1);
  }
}

Future<void> commitRelease(Version version) async {
  final pubspecFile = File('yasml/pubspec.yaml');
  final pubspecContent = pubspecFile.readAsStringSync();
  pubspecFile.writeAsStringSync(
    pubspecContent.replaceFirst(
      RegExp(r'^version:\s*.+$', multiLine: true),
      'version: $version',
    ),
  );
  Console.success('Bumped yasml/pubspec.yaml to $version');

  final cliffExitCode = await Shell.runInherited('git-cliff', [
    '--config', 'cliff.toml',
    '--tag', version.tag,
    '--output', 'yasml/CHANGELOG.md',
  ]);
  if (cliffExitCode != 0) {
    Console.error('git-cliff failed (exit code $cliffExitCode)');
    exit(1);
  }
  Console.success('Generated CHANGELOG.md');

  await Shell.run(
    'git',
    ['add', 'yasml/pubspec.yaml', 'yasml/CHANGELOG.md'],
  );
  await Shell.run('git', [
    'commit', '-m', 'chore(yasml): release $version',
  ]);
  Console.success('Created release commit');
}

Future<void> dryRunValidation(Version version) async {
  Console.info('Running pana analysis...');
  final panaExit = await Shell.runInherited(
    'dart',
    ['pub', 'global', 'run', 'pana', '--exit-code-threshold', '0', '.'],
    workingDirectory: 'yasml',
    environment: {'PANA_ANALYSIS_INCLUDES': '1'},
  );
  if (panaExit != 0) {
    Console.error('pana analysis failed (exit code $panaExit)');
    exit(1);
  }
  Console.success('pana analysis passed');

  Console.info('Running dart pub publish --dry-run...');
  final dryRunExit = await Shell.runInherited(
    'dart',
    ['pub', 'publish', '--dry-run'],
    workingDirectory: 'yasml',
  );
  if (dryRunExit != 0) {
    Console.error('dart pub publish --dry-run failed (exit code $dryRunExit)');
    exit(1);
  }
  Console.success('Publish dry-run passed');

  // Write state file so re-runs can skip this step for the same version.
  StateDetector.writeDryRunState(version);
}

Future<void> pushRelease(Version version) async {
  Console.info(
    'Ready to create tag ${version.tag} and push to origin/main.',
  );
  if (!Console.confirm('Push commit and tag to origin?')) {
    Console.warn('Aborted. Re-run to resume from this step.');
    exit(0);
  }

  await Shell.run('git', ['tag', version.tag]);
  Console.success('Created tag ${version.tag}');

  final pushExit = await Shell.runInherited(
    'git',
    ['push', 'origin', 'main', '--tags'],
  );
  if (pushExit != 0) {
    Console.error('git push failed');
    exit(1);
  }
  Console.success('Pushed to origin/main with tag ${version.tag}');
}

Future<void> publishAndRelease(Version version) async {
  if (!await StateDetector.isPublishedOnPubDev(version)) {
    Console.info('Ready to publish $version to pub.dev.');
    if (!Console.confirm('Publish to pub.dev?')) {
      Console.warn('Aborted. Re-run to resume from this step.');
      exit(0);
    }

    final publishExit = await Shell.runInherited(
      'dart',
      ['pub', 'publish', '--force'],
      workingDirectory: 'yasml',
    );
    if (publishExit != 0) {
      Console.error('dart pub publish failed (exit code $publishExit)');
      exit(1);
    }
    Console.success('Published $version to pub.dev');
  }

  if (!await StateDetector.ghReleaseExists(version.tag)) {
    final releaseNotes = await generateReleaseNotes(version);

    final ghExit = await Shell.runInherited('gh', [
      'release', 'create', version.tag,
      '--title', version.tag,
      '--notes', releaseNotes,
    ]);
    if (ghExit != 0) {
      Console.error('gh release create failed (exit code $ghExit)');
      exit(1);
    }
    Console.success('Created GitHub release for ${version.tag}');
  }
}

Future<String> generateReleaseNotes(Version version) async {
  String notes;
  try {
    notes = await Shell.run('git-cliff', [
      '--config', 'cliff.toml',
      '--unreleased',
      '--tag', version.tag,
      '--strip', 'header',
    ]);
  } catch (_) {
    notes = await Shell.run('git-cliff', [
      '--config', 'cliff.toml', '--latest', '--strip', 'header',
    ]);
  }

  if (notes.trim().isEmpty) {
    notes = await Shell.run('git-cliff', [
      '--config', 'cliff.toml', '--latest', '--strip', 'header',
    ]);
  }

  return notes;
}

// ── Version helpers ──────────────────────────────────────────────────

extension VersionHelpers on Version {
  String get tag => 'v$this';

  static Version parse(String s) {
    final clean = s.startsWith('v') ? s.substring(1) : s;
    return Version.parse(clean);
  }

  Version bump(BumpType type) => switch (type) {
    BumpType.major => nextMajor,
    BumpType.minor => nextMinor,
    BumpType.patch => nextPatch,
  };
}

// ── StateDetector ────────────────────────────────────────────────────

class StateDetector {
  static const pubspecPath = 'yasml/pubspec.yaml';
  static const dryRunStateFile = '.dart_tool/publish_dry_run';

  static Version readPubspecVersion() {
    final content = File(pubspecPath).readAsStringSync();
    final pubspec = Pubspec.parse(content);
    final version = pubspec.version;
    if (version == null) throw StateError('No version found in $pubspecPath');
    return version;
  }

  static Future<Version?> latestGitTag() async {
    try {
      final tag = await Shell.run(
        'git',
        ['describe', '--tags', '--abbrev=0'],
      );
      return VersionHelpers.parse(tag);
    } catch (_) {
      return null;
    }
  }

  static void writeDryRunState(Version version) {
    File(dryRunStateFile).writeAsStringSync('$version');
  }

  // ── Skip gates (return true + log when already done) ───────────────

  static Future<bool> isPreflightReady() async {
    for (final tool in ['git-cliff', 'gh', 'dart']) {
      if (await Shell.runExitCode('which', [tool]) != 0) return false;
    }
    final globals = await Shell.run(
      'dart', ['pub', 'global', 'list'],
      throwOnError: false,
    );
    if (!globals.contains('pana')) return false;

    final branch = await Shell.run('git', ['branch', '--show-current']);
    if (branch != 'main') return false;

    final status = await Shell.run('git', ['status', '--porcelain']);
    final dirty = status
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .where((line) => !line.contains('.dart_tool'));
    if (dirty.isNotEmpty) return false;

    await Shell.run('git', ['fetch', 'origin', 'main', '--quiet']);
    final local = await Shell.run('git', ['rev-parse', 'HEAD']);
    final remote = await Shell.run('git', ['rev-parse', 'origin/main']);
    if (local != remote) return false;

    Console.skip('All preflight checks passed');
    return true;
  }

  static Future<bool> isVersionBumped(Version current) async {
    final latestTag = await latestGitTag();
    if (latestTag != null && current > latestTag) {
      Console.skip(
        'Version already bumped: $current > $latestTag (latest tag)',
      );
      return true;
    }
    return false;
  }

  static Future<bool> isReleaseCommitted(Version version) async {
    final msg = await Shell.run('git', ['log', '-1', '--format=%s']);
    final committed = msg == 'chore(yasml): release $version';
    if (committed) Console.skip('Release commit already exists for $version');
    return committed;
  }

  static Future<bool> isDryRunPassed(Version version) async {
    final file = File(dryRunStateFile);
    if (!file.existsSync()) return false;
    final stored = file.readAsStringSync().trim();
    final passed = stored == '$version';
    if (passed) Console.skip('Dry-run already passed for $version');
    return passed;
  }

  static Future<bool> isTagPushed(String tag) async {
    final output = await Shell.run(
      'git',
      ['ls-remote', '--tags', 'origin', tag],
      throwOnError: false,
    );
    final pushed = output.isNotEmpty;
    if (pushed) Console.skip('Tag $tag already exists on remote');
    return pushed;
  }

  static Future<bool> isFullyPublished(Version version) async {
    final onPubDev = await isPublishedOnPubDev(version);
    final onGitHub = await ghReleaseExists(version.tag);
    return onPubDev && onGitHub;
  }

  static Future<bool> isPublishedOnPubDev(Version version) async {
    try {
      final json = await Shell.run(
        'curl',
        ['-s', 'https://pub.dev/api/packages/yasml'],
      );
      final data = jsonDecode(json) as Map<String, dynamic>;
      final versions = (data['versions'] as List)
          .map((v) => (v as Map<String, dynamic>)['version'] as String)
          .toList();
      final published = versions.contains('$version');
      if (published) Console.skip('Version $version already on pub.dev');
      return published;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> ghReleaseExists(String tag) async {
    final code = await Shell.runExitCode('gh', ['release', 'view', tag]);
    final exists = code == 0;
    if (exists) Console.skip('GitHub release for $tag already exists');
    return exists;
  }
}
