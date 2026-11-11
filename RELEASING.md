# Releasing

1. Branch off `main` and set `version:` in `pubspec.yaml` to the new version, for example `3.1.0`.
2. In `CHANGELOG.md`, rename `## Unreleased` to `## 3.1.0` and add a new empty `## Unreleased` above it.
3. Run `make check` and `make publish-dry-run`, then merge the PR to `main`.
4. Tag the merge commit and push the tag:

   ```sh
   git checkout main && git pull
   git tag v3.1.0 && git push origin v3.1.0
   ```

5. The `Publish to pub.dev` workflow checks that the tag, pubspec and changelog agree, then waits for approval in the `pub.dev` environment and publishes.
