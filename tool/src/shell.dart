import 'dart:io';

/// Thin wrapper around [Process] providing three execution modes:
/// capture output, stream to terminal, or probe exit code.
class Shell {
  /// Run a command and capture its output. Throws on non-zero exit.
  static Future<String> run(
    String executable,
    List<String> args, {
    String? workingDirectory,
    bool throwOnError = true,
  }) async {
    final result = await Process.run(
      executable,
      args,
      workingDirectory: workingDirectory,
    );
    if (throwOnError && result.exitCode != 0) {
      throw ProcessException(
        executable,
        args,
        '${result.stderr}'.trim(),
        result.exitCode,
      );
    }
    return '${result.stdout}'.trim();
  }

  /// Run a command with inherited stdio (streams to terminal).
  static Future<int> runInherited(
    String executable,
    List<String> args, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    final process = await Process.start(
      executable,
      args,
      workingDirectory: workingDirectory,
      environment: environment,
      mode: ProcessStartMode.inheritStdio,
    );
    return process.exitCode;
  }

  /// Run a command and return only its exit code (no output capture).
  static Future<int> runExitCode(
    String executable,
    List<String> args, {
    String? workingDirectory,
  }) async {
    final result = await Process.run(
      executable,
      args,
      workingDirectory: workingDirectory,
    );
    return result.exitCode;
  }
}
