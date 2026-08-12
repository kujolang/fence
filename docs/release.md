# Release checklist

Run from a clean branch with `kujo` on `PATH`.

- [ ] Update the release in `src/meta.kujo` and add a dated changelog section.
- [ ] Confirm README command, template, test-count, and project-layout claims.
- [ ] Check every Kujo source and test:

  ```bash
  for f in fence.kujo src/*.kujo tests/*.kujo; do kujo check "$f"; done
  ```

- [ ] Run unit, CLI, validation, and self-dogfood gates:

  ```bash
  kujo run tests/fence_tests.kujo
  bash tests/cli_smoke.sh
  kujo run fence.kujo -- validate
  kujo run fence.kujo -- check --format json
  ```

- [ ] Run the scratch-repository flow in [the demo](demo.md).
- [ ] Verify `git status --short` is empty after committing release artifacts.
- [ ] Tag the verified commit and push the branch and tag through the normal
      protected-branch workflow.

Do not commit generated reports, SARIF, local caches, or scratch repositories.
