# Fence next enhancement checklist · session 3

This backlog follows the completed incremental-performance, parser-adapter,
policy-governance, consumer-contract, signed-release, and cross-platform tranche.
The items below are deeper investments, not v1 launch blockers.

## Performance and runtime

- [ ] **P1. Native concurrency adoption.** When Kujo exposes supported tasks or
  futures, run deterministic shards concurrently and require a measured win at
  10,000 files before enabling it by default.
- [ ] **P2. Glob filter acceleration.** Compile include/exclude patterns once or
  add extension/prefix indexes; benchmark against the profiled 10,000-file slope.
- [ ] **P3. Cache lifecycle hardening.** Add stale-entry compaction, bounded cache
  size, crash-safe replacement, and concurrent-writer tests without weakening
  cold-source authority.

## Detection and resolution

- [ ] **D1. Reference parser adapters.** Publish reviewed adapters for the most
  common AST ecosystems with pinned binaries, fixture parity, and trust guidance.
- [ ] **D2. Manifest-aware resolution.** Add opt-in package/workspace resolution
  for language ecosystems where source-only probing is ambiguous.
- [ ] **D3. Generated-code policy.** Support explicit generated-file classification
  and include/exclude/report behavior without silently dropping findings.

## Governance and security

- [ ] **G1. Effective-config provenance.** Add an explain/export command showing
  each composed value's source file and override chain.
- [ ] **G2. Adapter trust policy.** Explore executable allowlists and digest pins
  for parser adapters while keeping provider integrations outside Fence core.
- [ ] **G3. Ownership export.** Add provider-neutral owner summaries suitable for
  CODEOWNERS, catalogs, and notification bridges without embedding those services.

## Ecosystem and distribution

- [ ] **E1. PackWrite module resolution.** Coordinate an upstream fix so PackWrite
  can run inside Kujo repositories that already contain `src/`; then rerun the
  Fence fixture/context compatibility gate.
- [ ] **E2. Native consumer fixtures.** Land opt-in Fence JSON/SARIF contract tests
  in interested Scout, Eval, PackWrite, and ShipCheck repositories.
- [ ] **E3. Installation channels.** Add verified Kennel, source archive, and
  platform-launcher installation paths backed by the signed release attestations.
