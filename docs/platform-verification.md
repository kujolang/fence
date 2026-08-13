# Linux and Windows verification

`.github/workflows/platform-verification.yml` runs the same Kujo-native release
gate on `ubuntu-latest` and `windows-latest` using pinned Kujo v1.0.1 source and
pinned action revisions. `scripts/verify_release.kujo` checks every Kujo module,
the unit/contract suite, CLI exit codes, self-dogfood, all passing and failing
examples, and deterministic release-artifact generation.

Platform-specific behavior is intentionally narrow:

- Paths are normalized to `/` internally; Windows drive-qualified, absolute,
  parent-traversal, and backslash escape attempts are rejected for outputs and
  composed config.
- The Windows job uses Git Bash only for the POSIX launcher/exit-code smoke test;
  Fence analysis and release orchestration remain Kujo.
- Config composition resolves existing files and rejects symlink escapes. Output
  writes resolve the nearest existing ancestor for the same reason.
- Executable permission bits apply to the optional POSIX `fence.sh` launcher;
  direct `kujo run fence.kujo -- ...` is the portable contract.

Local macOS verification covers the same release gate. Linux and Windows are
authoritative through the matrix because platform-specific filesystem behavior
must be exercised on native hosted runners.
