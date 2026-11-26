# Fence repository hardening

Reviewed public main `d3173049b5365af975624fddd48e943d39738c75`
and the published `v1.1.0` package. The pass covered CLI selection,
config composition, source and cache boundaries, rule and report behavior,
scalability, package entry points, and CI/release verification.

- The changed-files gate applies the same include, exclude and source-root
  selection as a full scan for normal repository-relative files. Normalized
  overlapping roots visit files once, and `.` keeps candidate paths relative
  for exact patterns. Git path merging uses a fingerprint-free membership
  map while retaining NUL-delimited input and deterministic sort order.
- Config composition checks each reference before joining it to its owner,
  recognizes equivalent relative paths in cycle checks, and bounds total
  reads and bytes per file. Config, baseline and cache reads use native
  beneath-root access. Incomplete scans retain the previous cache.
- The release gate recomputes source digests and checks the ordered checksum
  and SBOM entries plus the provenance subject digest. Artifact writes use
  native confined atomic replacement. CI validates the full architecture on
  push and passes the pull request base via an environment value. Checkout
  credentials are ephemeral across the verification and release jobs.

Released Kujo 1.4.0 and 1.10.0 passed the release verifier on Intel macOS.
The suite had 317 unit and report assertions, 98 CLI checks, and six passing
and failing consumer examples. Seven of the new CLI checks failed against
the baseline. A controlled fixture with altered checksums and matching but
incorrect SBOM digests failed verification. The public `v1.1.0` Kennel package
installed, reinstalled from the lock, validated, and initialized and checked
a fresh consumer project.

Five alternating pairs on the same Intel macOS host and released Kujo 1.10.0
produced identical result counts and analysis metrics on a 900-file synthetic
benchmark. Median filter time moved from 649.823 to 358.032 ms and median total
scan time from 3436.604 to 1933.623 ms. In a separate 2,800-path Git fixture,
medians moved from 2217.649 to 353.361 ms with the same sorted-path digest.
These timings describe the local fixtures.

Configured parser adapters remain trusted executables. Source traversal and
import resolution retain the repository layout trust model described in
[SECURITY.md](../../SECURITY.md).
