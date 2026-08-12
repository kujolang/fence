# Packaging and reproducible installation

Fence has no build step or runtime dependency beyond Kujo. Distribute the root
`fence.kujo`, `fence.sh`, and the complete `src/` directory together.

## Vendor in one repository

Copy a tagged Fence source tree under a tools directory and invoke its entrypoint
from the target repository root:

```bash
kujo run tools/fence/fence.kujo -- check
```

Record the Fence commit or tag and the Kujo runtime version in the consuming
repository. Do not copy only `fence.kujo`; it intentionally delegates to `src/`.

## Central installation

Keep one immutable versioned directory and expose `fence.sh` on `PATH`. The
wrapper resolves its own directory, so analysis still runs against the caller's
working directory. Upgrade by installing a new versioned directory, validating
it, then changing the stable symlink atomically.

## Reproducibility and integrity

Pin both the Fence commit/tag and Kujo runtime. Generate deterministic integrity
artifacts before publishing:

```bash
kujo run scripts/release_artifacts.kujo -- --output dist/release
```

This writes `SHA256SUMS`, an SPDX 2.3 JSON SBOM, and an in-toto/SLSA-shaped
provenance statement. Sign these artifacts with the organization's approved
external signing service; Fence never reads or manages signing keys.

Consumers should verify checksums before installation and retain provenance with
the release. The generated artifacts contain no timestamps or host-specific
paths, so identical source produces identical output.
