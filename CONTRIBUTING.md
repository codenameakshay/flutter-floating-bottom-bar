Contributing to Flutter Floating Bottom Bar
===========================================

Thanks for contributing.

Please follow the
[code of conduct](https://github.com/codenameakshay/flutter-floating-bottom-bar/blob/master/CODE_OF_CONDUCT.md)
in all project interactions.

## Report bugs and issues

Before opening a new issue:

- Check whether an existing issue already covers the problem.
- Include clear reproduction steps.
- Include expected behavior, actual behavior, and environment details.
- Add screenshots or screen recordings for UI issues when possible.

## Local setup

This repo is pinned to Flutter `3.44.4` through FVM.

```bash
fvm install 3.44.4
fvm use 3.44.4
make setup
```

Useful commands:

- `make format` to rewrite Dart formatting.
- `make analyze` to run static analysis for the package and example app.
- `make test` to run tests for the package and example app.
- `make check` to run format check, analyze, and tests together.
- `make publish-dry-run` to validate the package for pub.dev without
  publishing.

## Pull requests

- Keep changes small and reviewable.
- Update docs and examples when public behavior changes.
- Add or update tests when behavior changes.
- Run `make check` before opening the PR.
- Run `make publish-dry-run` for release-oriented changes.
- Explain user-visible behavior changes clearly in the PR description.

If you want to propose a larger change, open an issue first so the approach can
be discussed in the open.

## Style and scope

- Prefer the simplest implementation that fully solves the current problem.
- Reuse existing patterns and utilities before adding new ones.
- Remove obsolete paths instead of adding compatibility layers.
- Keep public API docs accurate when contracts change.

## Commit messages

Use clear, imperative commit messages that explain why the change was needed.
Reference relevant issues or PRs when helpful.
