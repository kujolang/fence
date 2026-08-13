# Release checklist

Run from a clean branch with `kujo` on `PATH`.

- [ ] Update the release in `src/meta.kujo` and add a dated changelog section.
- [ ] Confirm README command, template, test-count, and project-layout claims.
- [ ] Run the Kujo-native cross-platform release gate:

  ```bash
  kujo run scripts/verify_release.kujo
  ```

- [ ] Run unit, CLI, validation, and self-dogfood gates:

  ```bash
  kujo run tests/fence_tests.kujo
  bash tests/cli_smoke.sh
  kujo run fence.kujo -- validate
  kujo run fence.kujo -- check --format json
  ```

- [ ] Run the scratch-repository flow in [the demo](demo.md).
- [ ] Generate and verify deterministic release integrity artifacts:

  ```bash
  kujo run scripts/release_artifacts.kujo -- --output dist/release
  ```

- [ ] Push a signed `v*` tag through the protected release workflow. GitHub
      creates keyless Sigstore-backed provenance attestations for `SHA256SUMS`,
      the SBOM, and provenance; Fence never reads or manages private keys.
- [ ] Verify `git status --short` is empty after committing release artifacts.
- [ ] Tag the verified commit and push the branch and tag through the normal
      protected-branch workflow.

Do not commit generated reports, SARIF, local caches, or scratch repositories.
