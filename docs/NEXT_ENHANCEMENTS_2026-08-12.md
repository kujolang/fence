# Fence next enhancement checklist

This is the next-session backlog after the August 12, 2026 production-readiness
review. Fence is release-ready for deterministic local and CI enforcement; the
items below target scale, stricter enterprise policy, and deeper language
coverage without changing its local-first Kujo-native posture.

## Ground rules

- Keep the implementation in Kujo; shell remains limited to wrappers and CLI
  integration tests.
- Preserve stable output, existing exit codes, no network access, and safe paths.
- Add focused regression assertions and run the full release checklist.

## Performance

- [ ] **P1. Cache benchmark and instrumentation.** Measure hit rates and wall
  time at 1,600 and 10,000 files without changing normal report output; use the
  evidence to tune cache keys or reject further complexity.
- [ ] **P2. Walk fast path.** Measure include/exclude glob cost and add a safe
  extension/prefix prefilter before the general matcher when semantics match.
- [ ] **P3. Checked-in Kujo benchmark harness.** Replace manual synthetic-tree
  setup with a deterministic Kujo generator/runner that reports stage timings
  and does not require Python.

## Security and operations

- [ ] **S1. Configurable output roots.** Add an opt-in allow-list such as
  `output_roots = ["reports", ".fence"]`; preserve today's repo-relative default.
- [ ] **S2. Unreadable-file diagnostics.** Report skipped paths and counts in
  human, JSON, Markdown, and SARIF without leaking file contents.
- [ ] **S3. Resource limits.** Add optional maximum files/imports/report bytes
  with deterministic diagnostics for hostile or accidentally huge trees.
- [ ] **S4. Supply-chain release automation.** Publish checksums and provenance
  once the Kujo distribution channel has a canonical signing workflow.

## Functionality

- [ ] **F1. Workspace package zones.** Generate per-package zone stanzas from a
  deterministic local manifest command while keeping `init --template monorepo`
  as the zero-discovery preset.
- [ ] **F2. Structured ignore rules.** Support narrowly scoped, explained,
  expiring policy exceptions without turning the baseline into permanent debt.
- [ ] **F3. Import coverage.** Add JS/TS multiline imports, Rust nested groups,
  PHP grouped `use`, and Go module-prefix mapping; document each best-effort edge.
- [ ] **F4. Graph observed edges.** Add an opt-in graph mode that contrasts
  configured allowed edges with dependencies actually seen in the repository.
- [ ] **F5. Baseline maintenance.** Add `baseline prune` to remove stale
  fingerprints safely and report exactly what changed.

## Presentation and ecosystem

- [ ] **E1. Versioned schema fixtures.** Check canonical JSON and SARIF fixtures
  for consumer contract tests across Scout, Eval, PackWrite, and ShipCheck.
- [ ] **E2. Real-world examples.** Add small Kujo-native example repositories for
  a CLI, web app, and monorepo, each with a passing contract and one teachable
  failing branch.
- [ ] **E3. Packaging guide.** Document vendoring, centralized installation, and
  reproducible Kujo runtime pinning once the official package flow stabilizes.
