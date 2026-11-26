Contributing to Flutter Floating Bottom Bar
===========================================

Thanks for contributing.

Please follow the
[code of conduct](https://github.com/codenameakshay/flutter-floating-bottom-bar/blob/main/CODE_OF_CONDUCT.md)
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

## Goldens

Goldens are PNG images of the widgets. Each one is compared pixel for pixel,
with no tolerance. Goldens render and are checked on one pinned setup only:
Linux x86_64 with Flutter `3.44.4` (from `.fvmrc`), in the Docker image built
from `tool/goldens/Dockerfile`. The image is always `linux/amd64`. A Mac runs
it through emulation and gets the same pixels as CI and a Boat sandbox. The
image is rebuilt when `tool/goldens/Dockerfile` changes.

The pinned setup keeps the pixels the same on every run. The image pins its
Ubuntu base by digest and clones Flutter at one commit. Roboto and the Material
Icons come from the Flutter SDK, and the device pixel ratio is 1. The package
commits no lockfile, so the goldens keep their own in
`tool/goldens/pubspec.lock`. A new dependency release then cannot change the
pixels.

- `make goldens` checks the goldens in Docker.
- `make goldens-update` regenerates every PNG and `test/goldens/gallery.json`
  in Docker. It removes PNGs that no case produces, and it refreshes
  `tool/goldens/pubspec.lock`.
- `make check` runs everything except tests tagged `golden`. It also runs
  `make gallery-check`, and it prints how to run the goldens.

Running a golden test outside the pinned setup fails with a message that points
to `make goldens`. Failure diffs go to `test/goldens/failures/`, which is
gitignored.

Docker:

- Use Docker Desktop or colima.
- On Apple Silicon, start colima with `colima start --vm-type vz --vz-rosetta`.
- colima shares only your home folder, so keep the repo under `$HOME`.
- `GOLDENS_DOCKER=0 make goldens` runs without Docker. It stops unless the
  machine is Linux x86_64 with Flutter 3.44.4 on the `PATH`.

Adding a golden:

- Add a `GoldenCase` to the feature's file in `test/goldens/cases/`. Or add a
  new file there, plus an entry in `test/goldens/cases/table.dart`.
- Set `shots` to any of `Shot.light`, `Shot.dark`, `Shot.rtl` and
  `Shot.text2x`.
- Run `make goldens-update`.
- Commit the PNGs and `test/goldens/gallery.json`.

One table drives both the tests and the gallery. Because goldens are exact, an
image change is a real change. Review a golden diff as you would review code.

CI:

- The `goldens` job in `.github/workflows/ci.yml` runs `make goldens` on
  `ubuntu-latest`, in the same image, on every pull request.
- When it fails, the job uploads the diffs as the `golden-failures` artifact.
- The macOS matrix runs `make check`.

Gallery:

- `make gallery` builds a static page into `build/gallery` from
  `test/goldens/gallery.json` and the PNGs.
- The page groups the cases by feature. It shows the shots of each case side by
  side, with links to the README section and the playground demo.
- `make gallery-check` fails when a PNG has no case, or a case has no PNG.
- Pages publishes the gallery at
  https://codenameakshay.github.io/flutter-floating-bottom-bar/gallery/.

## Pull requests

- Keep changes small and reviewable.
- Update docs and examples when public behavior changes.
- Add or update tests when behavior changes.
- Run `make check` before opening the PR.
- Run `make goldens` for changes that draw something.
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
