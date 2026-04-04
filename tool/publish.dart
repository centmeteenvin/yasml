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

// ── Publish pipeline ─────────────────────────────────────────────────

Future<void> publish() async {
  Console.banner();

  // ── Preflight: tools + repo state + state file ───────────────────
  Console.step(0, 'Preflight');
  await ensureTools();
  await ensureRepoState();

  var state = PublishState.load();

  if (state != null && state.isComplete) {
    Console.success('Previous release ${state.version} completed all steps');
    if (!Console.confirm('Start a new release cycle?')) {
      exit(0);
    }
    PublishState.clear();
    state = null;
  }

  final resumeAfter = state?.lastCompletedStep ?? 0;
  if (resumeAfter > 0) {
    Console.info('Resuming release ${state!.version} after step $resumeAfter');
  }
  Console.success('Preflight passed');

  // ── Step 1: Version selection ────────────────────────────────────
  Console.step(1, 'Version selection');
  late Version version;
  if (resumeAfter >= 1) {
    version = state!.version;
    Console.skip('Version $version already selected');
  } else {
    final latestTag = await latestGitTag();
    if (latestTag == null) {
      Console.error('No git tags found — cannot determine current version');
      exit(1);
    }
    final bumpType = Console.promptBumpType(latestTag);
    version = latestTag.bump(bumpType);
    Console.success('Will release $version');
    PublishState(version: version, lastCompletedStep: 1).save();
  }

  // ── Steps 2–5 ───────────────────────────────────────────────────
  final steps = [
    (2, 'Changelog + commit', () => commitRelease(version)),
    (3, 'Dry-run validation', () => dryRunValidation(version)),
    (4, 'Push', () => pushRelease(version)),
    (5, 'Publish + GH release', () => publishAndRelease(version)),
  ];

  for (final (n, title, runner) in steps) {
    Console.step(n, title);
    if (resumeAfter >= n) {
      Console.skip('$title — already done');
      continue;
    }
    await runner();
    PublishState(version: version, lastCompletedStep: n).save();
  }

  stdout.writeln('');
  Console.success('Release $version complete!');
}

// ── Preflight checks ─────────────────────────────────────────────────

Future<void> ensureTools() async {
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
}

Future<void> ensureRepoState() async {
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

// ── Step implementations ─────────────────────────────────────────────

Future<void> commitRelease(Version version) async {
  final pubspecFile = File(PublishState.pubspecPath);
  final pubspecContent = pubspecFile.readAsStringSync();
  pubspecFile.writeAsStringSync(
    pubspecContent.replaceFirst(
      RegExp(r'^version:\s*.+$', multiLine: true),
      'version: $version',
    ),
  );
  Console.success('Bumped ${PublishState.pubspecPath} to $version');

  final cliffExitCode = await Shell.runInherited('git-cliff', [
    '--config', 'cliff.toml',
    '--tag', version.tag,
    '--output', 'yasml/CHANGELOG.md',
  ]);
  if (cliffExitCode != 0) {
    Console.error('git-cliff failed (exit code $cliffExitCode)');
    exit(1);
  }

  // Verify the new version appears in the changelog.
  // If git-cliff omitted it, there are no qualifying commits — nothing to release.
  final changelog = File('yasml/CHANGELOG.md').readAsStringSync();
  if (!changelog.contains('## [$version]')) {
    Console.error('No qualifying commits since last release');
    Console.info('CHANGELOG.md has no entry for $version — nothing to release.');
    exit(1);
  }
  Console.success('Generated CHANGELOG.md');

  await Shell.run(
    'git',
    ['add', PublishState.pubspecPath, 'yasml/CHANGELOG.md'],
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
  if (!await isPublishedOnPubDev(version)) {
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

  if (!await ghReleaseExists(version.tag)) {
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

// ── Helpers ──────────────────────────────────────────────────────────

Future<Version?> latestGitTag() async {
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

Future<bool> isPublishedOnPubDev(Version version) async {
  try {
    final json = await Shell.run(
      'curl',
      ['-s', 'https://pub.dev/api/packages/yasml'],
    );
    final data = jsonDecode(json) as Map<String, dynamic>;
    final versions = (data['versions'] as List)
        .map((v) => (v as Map<String, dynamic>)['version'] as String)
        .toList();
    return versions.contains('$version');
  } catch (_) {
    return false;
  }
}

Future<bool> ghReleaseExists(String tag) async {
  final code = await Shell.runExitCode('gh', ['release', 'view', tag]);
  return code == 0;
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

// ── PublishState ─────────────────────────────────────────────────────

class PublishState {
  static const filePath = '.dart_tool/publish_state.json';
  static const pubspecPath = 'yasml/pubspec.yaml';
  static const totalSteps = 5;

  final Version version;
  final int lastCompletedStep;

  PublishState({required this.version, required this.lastCompletedStep});

  bool get isComplete => lastCompletedStep >= totalSteps;

  static PublishState? load() {
    final file = File(filePath);
    if (!file.existsSync()) return null;
    try {
      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      return PublishState(
        version: Version.parse(data['version'] as String),
        lastCompletedStep: data['lastCompletedStep'] as int,
      );
    } catch (_) {
      return null;
    }
  }

  void save() {
    File(filePath).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'version': '$version',
        'lastCompletedStep': lastCompletedStep,
      }),
    );
  }

  static void clear() {
    final file = File(filePath);
    if (file.existsSync()) file.deleteSync();
  }
}
