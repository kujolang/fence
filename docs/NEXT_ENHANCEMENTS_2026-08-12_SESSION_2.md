# Fence next enhancement checklist · session 2

This backlog follows completion of the August 12 scale, policy, workspace,
language-coverage, supply-chain, and ecosystem tranche. Fence is production
ready for its documented line-based enforcement model; these are deeper future
investments rather than launch blockers.

## Performance and scale

- [x] **P1. Parallel analysis research.** Determine whether current Kujo process
  primitives can shard file analysis with deterministic merge ordering and a
  measurable win at 10,000+ files.
- [x] **P2. Incremental local cache.** Design a content-digest cache with explicit
  schema/version invalidation; prove a cold run remains the source of truth.
- [x] **P3. Walk profiling.** Separate directory traversal from include/exclude
  matching in benchmark metrics and investigate the 10,000-file walk slope.

## Detection fidelity

- [x] **D1. Optional parser adapters.** Define an offline adapter contract for
  AST-quality extraction while retaining built-in Kujo line scanners as the
  zero-dependency default.
- [x] **D2. Language conformance corpus.** Add versioned fixtures from real syntax
  for every supported language, including comments, aliases, conditional imports,
  generated-code markers, and malformed input.
- [x] **D3. Confidence metadata.** Explore `exact`/`best_effort` extraction
  confidence in machine reports without breaking schema v1 consumers.

## Policy governance

- [x] **G1. Exception audit command.** Add `ignores list/check` with expiring-soon
  and expired output suitable for CI ownership reviews.
- [x] **G2. Policy ownership metadata.** Support optional owner identifiers per
  zone and surface them in violations without embedding provider integrations.
- [x] **G3. Config composition.** Research deterministic local-only includes for
  large monorepos with cycle detection and path confinement.

## Ecosystem and release

- [x] **E1. Consumer contract matrix.** Run the versioned JSON/SARIF fixtures in
  Scout, Eval, PackWrite, and ShipCheck repositories and record compatibility.
- [x] **E2. Signed release workflow.** Connect integrity artifacts to the official
  Kujo publishing/signing flow when its protected workflow is finalized.
- [x] **E3. Cross-platform verification.** Run the full release checklist and
  examples on Linux and Windows, documenting path and permission differences.
