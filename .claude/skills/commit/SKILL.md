---
name: commit
description: Create a git commit following the Conventional Commits specification. Use when the user asks to commit changes.
---

# Conventional Commit

Create a git commit following the [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) specification.

## Commit Message Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Type (required)

Must be one of:

- **feat**: A new feature (correlates with MINOR in semver)
- **fix**: A bug fix (correlates with PATCH in semver)
- **docs**: Documentation only changes
- **style**: Changes that do not affect the meaning of the code (white-space, formatting, etc.)
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **perf**: A code change that improves performance
- **test**: Adding missing tests or correcting existing tests
- **build**: Changes that affect the build system or external dependencies
- **ci**: Changes to CI configuration files and scripts
- **chore**: Other changes that don't modify src or test files

### Scope (optional)

A noun in parentheses describing the section of the codebase affected: e.g. `feat(parser):`, `fix(auth):`.

### Breaking Changes

Indicate breaking changes in one of two ways:
1. Append `!` after the type/scope: `feat!: remove deprecated endpoint`
2. Add a `BREAKING CHANGE:` footer in the commit body

Breaking changes correlate with MAJOR in semver.

## Steps

1. Run `git status` (never use `-uall`) and `git diff --cached` in parallel to understand what is staged.
2. If nothing is staged, run `git diff` to see unstaged changes and stage the relevant files by name (avoid `git add .` or `git add -A`).
3. Run `git log --oneline -5` to see the recent commit style for this repo.
4. Analyze the changes and determine the appropriate type, optional scope, and description.
5. Write a concise description (imperative mood, lowercase, no period at the end).
6. Add a body only if the "what" and "why" aren't obvious from the description alone.
7. Commit using a HEREDOC for proper formatting:

```bash
git commit -m "$(cat <<'EOF'
<type>(<scope>): <description>

[optional body]

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

8. Run `git status` after the commit to verify success.

## Rules

- NEVER amend commits unless the user explicitly asks
- NEVER skip hooks (no `--no-verify`)
- NEVER use `git add .` or `git add -A` — stage specific files by name
- If a pre-commit hook fails, fix the issue and create a NEW commit
- Do not commit files that likely contain secrets (.env, credentials, etc.)
- Always end with the `Co-Authored-By` footer

## Arguments

$ARGUMENTS
