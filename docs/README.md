# Fence Documentation

Start at the [project README](../README.md) for the overview, then dive into:

- **[Getting started](getting-started.md)** — install, first run, agent workflow.
- **[Two-minute demo](demo.md)** — runnable violation-to-clean workflow.
- **[Enterprise adoption](adoption.md)** — staged rollout and policy ownership.
- **[Configuration](configuration.md)** — `fence.toml` reference.
- **[Commands](commands.md)** — every command and flag with examples.
- **[CI integration](ci.md)** — gating builds, changed-only, baselines, SARIF.
- **[JSON schema](JSON_SCHEMA.md)** — stable machine-readable output contract.
- **[Architecture](architecture.md)** — module map and pipeline internals.
- **[Performance](performance.md)** — measured numbers and scaling guidance.
- **[Consumer contract matrix](consumer-contract-matrix.md)** — Scout, Eval, PackWrite, and ShipCheck results.
- **[Linux and Windows verification](platform-verification.md)** — native release-gate coverage.
- **[FAQ](faq.md)** — common questions.
- **[Troubleshooting](troubleshooting.md)** — fixes for common issues.
- **[Release checklist](release.md)** — deterministic release gates.
- **[Packaging](packaging.md)** — vendoring, centralized installs, checksums, SBOM, and provenance.
- **[Enhancements backlog](ENHANCEMENTS.md)** — completed v1 hardening checklist.
- **[Completed session 2](NEXT_ENHANCEMENTS_2026-08-12_SESSION_2.md)** — latest completed hardening tranche.
- **[Next enhancements](NEXT_ENHANCEMENTS_2026-08-12_SESSION_3.md)** — next-session review backlog.

Canonical examples are in `README.md` and the command-focused docs above.
`agent/**` and `tests/fixtures/**` are implementation history or validation
data, not examples to copy into user projects.
