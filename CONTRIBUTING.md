# Contributing to yasml

Thank you for your interest in contributing to **yasml**! Every contribution helps —
whether it's a bug report, a feature idea, a documentation improvement, or a code change.

## Ways to contribute

| Type             | Where                                                                                  |
| ---------------- | -------------------------------------------------------------------------------------- |
| Bug reports      | [Open an issue](https://github.com/centmeteenvin/yasml/issues/new?template=bug_report.yml)       |
| Feature requests | [Open an issue](https://github.com/centmeteenvin/yasml/issues/new?template=feature_request.yml)  |
| Code changes     | Submit a pull request (see below)                                                      |
| Documentation    | PRs that improve docs are always welcome                                               |

## Development setup

### Prerequisites

- **Dart SDK** `^3.7.0` (bundled with the Flutter versions above).

### Clone & install

```bash
git clone https://github.com/centmeteenvin/yasml.git
cd yasml
flutter pub get        # resolves all packages via the pub workspace
```

> **Pub workspaces** — the root `pubspec.yaml` declares a `workspace:` key
> that groups `yasml/` and `yasml_example/`. Running `flutter pub get` at the
> root resolves dependencies for every package in one step.

### Running tests

```bash
cd yasml
flutter test
```

### Static analysis

The project uses [`very_good_analysis`](https://pub.dev/packages/very_good_analysis) for linting.
Make sure your changes pass analysis before opening a PR:

```bash
cd yasml
flutter analyze --fatal-infos
```

## Commit conventions

This repository follows [**Conventional Commits**](https://www.conventionalcommits.org/).
The format is:

```
<type>(<scope>): <short description>
```

Common types: `feat`, `fix`, `refactor`, `docs`, `chore`, `ci`, `test`.

Scopes used in this repo are typically `yasml` or `yasml_example`.

**Examples from this repo:**

```
feat(yasml): functional compositions
docs(yasml): rewrite README with functional-first approach
refactor(yasml_example): migrate examples to functional API
ci: add testing workflow and fix version constraints
```

## Pull request process

1. **Fork** the repository and create a branch from `main`.
   Use a descriptive branch name, e.g. `feat/stream-query-timeout` or
   `fix/composition-dispose-leak`.
2. **Make your changes.** Keep PRs focused — one logical change per PR.
3. **Add or update tests** for any new or changed behavior.
4. **Ensure CI passes locally:**
   ```bash
   cd yasml
   flutter analyze --fatal-infos
   flutter test
   ```
5. **Push** your branch and open a pull request against `main`.
6. Fill out the PR template and describe *what* changed and *why*.

A maintainer will review your PR. CI runs analysis and tests against
Flutter 3.35.7, 3.38.10, and 3.41.2 — all three must pass.

## Code style

- Follow the rules enforced by `very_good_analysis`. The linter
  catches most style issues automatically.
- Prefer clear, self-documenting code over comments.
- Public API members should have dartdoc comments.

## Questions?

If something is unclear, feel free to
[open an issue](https://github.com/centmeteenvin/yasml/issues) with
the label **question** — or start a discussion in an existing issue thread.
