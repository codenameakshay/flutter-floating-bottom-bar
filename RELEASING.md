# Releasing

1. In the package's pub.dev Admin tab, enable GitHub publishing for `codenameakshay/flutter-floating-bottom-bar` with tag pattern `v{{version}}` and require environment `pub.dev`.
2. Create the GitHub environment `pub.dev` and configure required reviewers if release approval is wanted.
3. Branch off `main` and set `version:` in `pubspec.yaml` to the new version, for example `3.1.0` or `3.1.0-beta.1`.
4. Rename `## Unreleased` in `CHANGELOG.md` to `## 3.1.0` for that version, then add an empty `## Unreleased` above it.
5. Run `make check` and `make publish-dry-run`, then merge the PR to `main`.
6. Tag the merge commit and push the tag, using the exact pubspec version:
   ```sh
   git checkout main && git pull
   git tag v3.1.0 && git push origin v3.1.0
   ```
7. If reviewers are configured, approve the `pub.dev` deployment before the job runs. The workflow checks the tag, pubspec and changelog, then publishes with OIDC.
