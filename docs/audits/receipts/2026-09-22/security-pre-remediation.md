# Security Review: Fence pre-remediation working-tree source snapshot

## Scope

Fence repository security review; all production code, automation, harnesses, runnable examples and fixture inputs reviewed. Historical receipts and non-executable prose were supporting context, not full audit coverage.

- Scan mode: repository
- Target kind: directory_snapshot
- Target ID: fence-20260922-7b2203e9770ca42c
- Snapshot digest: codex-security-snapshot/v1:sha256:7b2203e9770ca42c50ea77713e5889b3a4049de6c8e7aa28ecaefe2ae3e923d3
- Inventory strategy: repository
- Included paths: .
- Excluded paths: none
- Runtime or test status: No application execution: offline source review only.
- Artifacts reviewed: .github/scripts/check-kujo-tool-artifacts.sh, .github/workflows/fence.yml, .github/workflows/kujo-tool-artifacts-guard.yml, .github/workflows/platform-verification.yml, .github/workflows/release.yml, SECURITY.md, benchmarks/baseline_benchmark.kujo, benchmarks/fence_benchmark.kujo, benchmarks/pruning_benchmark.kujo, benchmarks/report_benchmark.kujo, examples/README.md, examples/cli/failing/fence.toml, examples/cli/failing/src/commands/run.kujo, examples/cli/failing/src/core/service.kujo, examples/cli/passing/fence.toml, examples/cli/passing/src/commands/run.kujo, examples/cli/passing/src/core/service.kujo, examples/monorepo/failing/apps/web/main.kujo, examples/monorepo/failing/fence.toml, examples/monorepo/failing/packages/core/service.kujo, examples/monorepo/passing/apps/web/main.kujo, examples/monorepo/passing/fence.toml, examples/monorepo/passing/packages/core/service.kujo, examples/web-app/failing/fence.toml, examples/web-app/failing/src/domain/user.kujo, examples/web-app/failing/src/ui/page.kujo, examples/web-app/passing/fence.toml, examples/web-app/passing/src/domain/user.kujo, examples/web-app/passing/src/ui/page.kujo, fence.kujo, fence.sh, fence.spec.yml, fence.toml, kennel.toml, scripts/release_artifacts.kujo, scripts/verify_release.kujo, src/analyze.kujo, src/baseline.kujo, src/cache.kujo, src/cli.kujo, src/cliargs.kujo, src/cmd_baseline.kujo, src/cmd_check.kujo, src/cmd_doctor.kujo, src/cmd_explain.kujo, src/cmd_graph.kujo, src/cmd_ignores.kujo, src/cmd_init.kujo, src/cmd_validate.kujo, src/cmd_workspace.kujo, src/config.kujo, src/cycles.kujo, src/decisions.kujo, src/git.kujo, src/glob.kujo, src/graph.kujo, src/ignores.kujo, src/imports.kujo, src/imports_ext.kujo, src/meta.kujo, src/output.kujo, src/parser_adapters.kujo, src/paths.kujo, src/reports.kujo, src/resolve.kujo, src/rules.kujo, src/templates.kujo, src/util.kujo, src/validate.kujo, src/walk.kujo, src/zones.kujo, tests/cli_smoke.sh, tests/config_composition/base.toml, tests/config_composition/child.toml, tests/config_composition/cycle-a.toml, tests/config_composition/cycle-b.toml, tests/config_composition/escape.toml, tests/conformance/v1/expected.json, tests/conformance/v1/go.go, tests/conformance/v1/javascript.ts, tests/conformance/v1/kujo.kujo, tests/conformance/v1/php.php, tests/conformance/v1/python.py, tests/conformance/v1/rust.rs, tests/consumer_contract_eval.json, tests/contracts/check-v1.json, tests/contracts/sarif-v2.1.0.json, tests/fence_eval.json, tests/fence_tests.kujo, tests/fence_tests.out, tests/fixtures/parser_adapter.kujo, tests/fixtures/sample/src/database/__init__.py, tests/fixtures/sample/src/database/users.ts, tests/fixtures/sample/src/domain/user.py, tests/fixtures/sample/src/rust/parent/child.rs, tests/fixtures/sample/src/rust/parent/mod.rs, tests/fixtures/sample/src/rust/parent/nested/mod.rs, tests/fixtures/sample/src/rust/parent/sibling.rs, tests/fixtures/sample/src/shared/util.ts, tests/fixtures/sample/src/ui/Login.tsx
- Scan context: audit CLI arguments, paths, filenames, environment/config, repository content, subprocess argv, temp files, credentials/permissions, traversal/injection, symlink races, resource exhaustion; implement only evidenced fixes in Fence while preserving public contracts (parent implements).

Limitations and exclusions:
- Source was shared with a parent doing authorized fixes. Finding evidence and resource map are bound to preserved source-snapshot files; some non-security parent edits had already landed before snapshot capture.
- Native Kujo implementation, OS enforcement, hosted settings and Daybreak unavailable.
- Token usage measurement unavailable for this prompt-only scan.
- Excluded docs/\*\*, README.md, CHANGELOG.md, CONTRIBUTING.md, CODE_OF_CONDUCT.md, LICENSE, config/kujo-tool-artifacts.gitignore, .gitignore: Non-executable documentation/history/ignore data inventoried and selectively used for contracts; not counted as fully security-audited source.
- Excluded .git/\*\* and ignored build/cache/local-tool artifacts: Repository internals and transient generated state are not authored product source.
- Excluded Kujo native runtime and external GitHub settings: Outside authorized Fence repository; platform enforcement not independently audited.

### Scan Summary

| Field | Value |
| --- | --- |
| Scan outcome | completed |
| Reportable findings | 3 |
| Severity mix | medium: 1, low: 2 |
| Confidence mix | high: 3 |
| Coverage | complete |
| Validation mode | Independent baseline, independent architecture mapping, source-backed validation. |

Canonical artifacts: `scan-manifest.json`, `findings.json`, and `coverage.json`. This report is a deterministic projection of those files.

## Threat Model

Fence is a local Kujo architecture-enforcement CLI. fence.kujo passes process arguments to command dispatch; fence.sh is a quoted-argument convenience wrapper (fence.kujo:10-14; fence.sh:4; src/cli.kujo:55-79). Configuration selects sources, import parsers, zones, dependency rules, exceptions and limits. Analysis reads source text or invokes explicitly configured parser adapters, resolves imports, evaluates rules, and renders reports (src/config.kujo:140-175; src/analyze.kujo:58-113; src/imports.kujo:266-275). Normal operation uses the invoking working directory, including when an absolute Fence entry point is launched from another repository (scripts/verify_release.kujo:24-25,43-48). Separate trusted release tooling generates integrity artifacts and publishes tagged GitHub releases (.github/workflows/release.yml:3-10,29-45). This is an architecture review, not completed audit coverage.

### Assets

- Operator filesystem integrity outside the intended working directory and preservation of existing files during failed output publication. User-facing writers delegate to write_file_atomic_beneath(".", normalizedRelativePath, content, overwrite) (src/output.kujo:10-36).
- Integrity and completeness of check results, baseline suppression and cached import records. Skipped source files produce a failing check exit; baselines deliberately suppress matching fingerprints; cache records are structurally checked but not authenticated (src/cmd_check.kujo:74-86,136-140; src/baseline.kujo:108-134; src/cache.kujo:107-124; SECURITY.md:34-38).
- Confidentiality of files readable by the operator, including source text consumed through filesystem paths, and integrity of report/log consumers receiving repository-controlled paths and import strings (src/imports.kujo:266-275; src/cmd_explain.kujo:106-117,123-150; src/cmd_check.kujo:108-125).
- Process authority available to Git and trusted parser adapters, and availability of the local or CI process handling potentially large source trees (src/git.kujo:65-72; src/parser_adapters.kujo:28-40; src/walk.kujo:29-80).
- Release integrity artifacts and the GitHub release/attestation authority exposed only in the tag-triggered publisher workflow (.github/workflows/release.yml:3-10,35-45).

### Trust Boundaries

- User-provided context: operator-controlled configuration and adapters are trusted executable policy; scanned source is untrusted. Config is parsed as TOML/JSON data with shape validation, dependency-first composition, a depth limit, cycle checks, lexical restrictions and canonical containment checks (src/config.kujo:41-87,99-117,203-235).
- Untrusted repository filesystem to source reader: full traversal follows configured roots using directory/file predicates and canonical ancestor cycle detection; built-in extraction then reads the complete selected file. The inspected walker does not impose source-root canonical containment. Changed-only selection instead consumes Git NUL-delimited names and filters by existence/include/exclude; explain consumes an explicit positional path (src/walk.kujo:34-75; src/imports.kujo:266-275; src/cmd_check.kujo:178-208; src/cmd_explain.kujo:22-43).
- CLI ref input to Git subprocess: --base defaults to HEAD; validation rejects leading options, excessive length, range/reflog constructs and disallowed characters before structured argv execution. Changed-file output is NUL-delimited and truncation fails selection (src/cmd_check.kujo:179-186; src/git.kujo:33-75,95-107).
- Trusted adapter policy to subprocess authority: extension-keyed argv receives the selected file as its last argument. Fence applies a 30-second timeout, 4 MiB output cap, success/truncation checks, JSON schema and import-record validation. It does not establish an adapter sandbox, scrubbed environment or network prohibition in the inspected call (src/parser_adapters.kujo:8-42,45-67).
- CLI output request to filesystem mutation: lexical validation rejects absolute/home/traversal/colon/.git paths; normalized components are handed to a native confined atomic-write primitive. check and graph additionally enforce configured output_roots before writing. Native implementation is outside this repository (src/paths.kujo:17-46; src/output.kujo:10-62; src/cmd_check.kujo:108-113; src/cmd_graph.kujo:53-58).
- Optional persistent analysis state to policy decisions: .fence/cache-v1.json is read only after canonical containment, size, schema and extractor-version checks; import entries require matching source digest and valid shapes. Adapter results bypass cache. fence-baseline.json is schema-checked and deliberately grants suppression authority (src/cache.kujo:19-61,92-124; src/baseline.kujo:49-103,108-134).
- Trusted release operator to publication: tag pushes run verification and artifact generation, checksum verification, keyless attestations and gh release create. GitHub-issued token and OIDC authority belong to the CI job; runtime CLI analysis has no corresponding publication capability (.github/workflows/release.yml:3-10,29-45).

### Attacker Capabilities

- User-provided scope: an attacker may control scanned source contents, filenames and repository filesystem objects without controlling trusted Fence configuration, adapters, the operator account or publisher authority.
- Repository data can influence selected file paths, parsed import strings, resolution and rendered reports. Source text is parsed rather than evaluated by built-in extraction (src/walk.kujo:60-74; src/imports.kujo:266-294; src/analyze.kujo:74-113).
- An attacker who can also mutate local cache or baseline state could influence reused imports or suppression; that extra policy/state authority must be stated separately. SECURITY.md explicitly excludes authenticated-cache guarantees (SECURITY.md:34-38; src/baseline.kujo:108-134).
- A concurrent hostile filesystem writer is a separate deployment prerequisite for replacement races. Do not assume this capability merely from static untrusted source, or infer access to trusted configuration or executable installations.
- Potential new authority to investigate includes unintended reads/writes outside authorized locations, executable argument reinterpretation, corruption of enforcement/report consumers, or CI/local resource exhaustion. These are scenarios, not validated findings.

### Security Objectives

- Preserve structured argv boundaries and distinguish trusted adapter execution from untrusted source parsing (src/git.kujo:60-72; src/parser_adapters.kujo:18-29).
- Keep normal command output beneath the working directory and configured output roots where applicable, publish atomically, and fail closed if native confined publication is unavailable (src/output.kujo:29-45).
- Reject malformed configuration and adapter responses; do not report incomplete source analysis as a clean passing check or replace baselines from incomplete analysis (src/config.kujo:79-89; src/parser_adapters.kujo:30-55; src/cmd_check.kujo:136-140; src/cmd_baseline.kujo:41-45).
- Apply configured check file/import/report ceilings while recognizing allocation precedes some checks and zero means unlimited (src/config.kujo:150-153; src/cmd_check.kujo:50-69,89-102; src/analyze.kujo:71-76; src/validate.kujo:172-185).
- Keep release credentials in publisher infrastructure and bind publication to verified tagged source and generated artifacts (.github/workflows/release.yml:29-45).

### Assumptions

- Trusted configuration/adapters and untrusted scanned source are supplied user-context facts. No remote server, tenant model or native code-execution sandbox is established by this repository.
- SECURITY.md:16-22 describes canonical-ancestor checks and publication as separate operations, but current src/output.kujo:29-32 delegates traversal and publication to native directory handles with no path-based fallback. Retain this documentation discrepancy; actual native enforcement and temporary-file permissions cannot be verified from this repository.
- SECURITY.md:7 says Fence never makes network calls. Built-in analysis is local, but configured adapters execute with no explicit network sandbox in src/parser_adapters.kujo:29; the separate publisher workflow necessarily uses GitHub services (.github/workflows/release.yml:35-45). Treat the guarantee as applying to built-in analysis rather than enforced denial of all child-process networking.
- Source reads use path-based read_file, unlike confined output writes. Source-root policy only checks the root list is nonempty in src/validate.kujo:58-61; selected directory/file symlinks may resolve outside the working tree. User-intended source-read confinement and the host/runtime semantics of path predicates remain material questions (src/walk.kujo:39-75; src/imports.kujo:271).
- Config and cache read containment checks are separate from their subsequent path-based reads; native implementation, replacement-race behavior and OS permission guarantees are outside inspected source (src/config.kujo:47-48,68-83; src/cache.kujo:21-28,92-102).
- check enforces max_files and max_report_bytes, while baseline create/prune and observed graph call walk/analyze without those command-level checks; shared analyze still enforces max_imports (src/cmd_check.kujo:57-59,97-102; src/cmd_baseline.kujo:41-42; src/cmd_graph.kujo:43-46; src/analyze.kujo:76).
- Release generation uses ordinary write_file and a trusted CLI-selected directory; this developer/publisher utility has a different output contract from the normal Fence CLI (scripts/release_artifacts.kujo:5-13,44-46).
- No application execution, network access, history inspection or source modification was performed. Native Kujo internals and platform-specific behavior were not inspected.
- The preserved snapshot precedes parent security fixes. This report is discovery evidence, not a claim that its findings remain open after the parent completes remediation.
- Daybreak tooling was unavailable; independent local baseline and architecture reviews were completed instead. No application code was executed in this audit.

## Findings

| Finding | Severity | Confidence | Detailed write-up |
| --- | --- | --- | --- |
| [Alias dot segments bypass forbidden dependency policy](#finding-1) | medium | high | inline below |
| [Backslash filenames can disappear from full scans](#finding-2) | low | high | inline below |
| [Repository text controls terminal and Markdown report presentation](#finding-3) | low | high | inline below |

### Confidence Scale

| Label | Meaning |
| --- | --- |
| high | Direct evidence supports the finding with no material unresolved blocker. |
| medium | Evidence supports a plausible issue, but material runtime or reachability proof remains. |
| low | Evidence is incomplete and the item is retained only for explicit follow-up. |

<a id="finding-1"></a>

### [1] Alias dot segments bypass forbidden dependency policy

| Field | Value |
| --- | --- |
| Severity | medium |
| Confidence | high |
| Confidence rationale | Complete static source trace confirms the transformation and affected consumer; no application execution was performed. |
| Category | path-canonicalization |
| CWE | CWE-180 |
| Affected lines | src/resolve.kujo:175-179, src/resolve.kujo:95-99, src/resolve.kujo:283-300, src/glob.kujo:40-47, src/rules.kujo:28-35 |

#### Summary

An import spelling with dot segments can resolve to a forbidden filesystem target while Fence assigns it to an allowed lexical zone.

#### Root Cause

`apply_alias` preserves the suffix and `try_candidates` returns its spelling after filesystem lookup; zone matching then operates on that spelling. Relative ./ imports normalize first, but alias and direct-slash routes do not.

**Alias preserves untrusted suffix** — `src/resolve.kujo:175-179`

The trusted alias root is concatenated with the source-controlled suffix without normalizing dot segments.

```
    if raw == best_key {
        return best_target
    }
    let rest = substring(raw, len(best_key) + 1, len(raw))
    return best_target + "/" + rest
```

**Candidate lookup returns original spelling** — `src/resolve.kujo:95-99`

Filesystem lookup resolves dot segments, but the returned target retains them.

```
    while i < en {
        let cand_f = base + exts[i]
        if file_exists(cand_f) {
            return cand_f
        }
```

**Alias and direct-path consumers** — `src/resolve.kujo:283-300`

Both routes return unnormalized candidate strings as internal targets.

```
    // 5. Alias prefix.
    let aliased = apply_alias(raw, aliases)
    if aliased != "" {
        let r_alias = try_candidates(aliased)
        if r_alias != "" {
            return mk("internal", r_alias, raw)
        }
        return mk("unknown", "", raw)
    }

    // 6. Root-relative / dotted module path.
    let modpath = module_to_path(raw)
    let direct = try_candidates(modpath)
    if direct != "" {
        return mk("internal", direct, raw)
    }
    let under = try_under_roots(modpath, source_roots)
    if under != "" {
```

**Lexical zone classification** — `src/glob.kujo:40-47`

Prefix matching classifies a target by its spelling rather than its actual dot-normalized location.

```
    // `prefix/**` -> match anything at/under prefix.
    if ends_with(pat, "/**") {
        let prefix = substring(pat, 0, len(pat) - 3)
        if p == prefix {
            return true
        }
        return starts_with(p, prefix + "/")
    }
```

**Same-zone rule short circuit** — `src/rules.kujo:28-35`

A target that appears in the source zone is allowed before forbidden-zone checks.

```
    }

    // Explicit deny wins.
    if arr_has(zinfo["cannot_depend_on"], to_zone) {
        let rule = "zones." + from_zone + ".cannot_depend_on includes " + to_zone
        return verdict(false, sev, rule, from_zone + " cannot depend on " + to_zone)
    }

```

#### Validation

With @=src, a src/ui file imports '@/ui/../database/users'. Existing src/database/users.ts is found via src/ui/../database/users.ts. Prefix src/ui/\*\* matches that returned spelling and same-zone policy permits the dependency despite ui denying database.

Validation method: static source trace

**Alias preserves untrusted suffix** — `src/resolve.kujo:175-179`

The trusted alias root is concatenated with the source-controlled suffix without normalizing dot segments.

```
    if raw == best_key {
        return best_target
    }
    let rest = substring(raw, len(best_key) + 1, len(raw))
    return best_target + "/" + rest
```

**Candidate lookup returns original spelling** — `src/resolve.kujo:95-99`

Filesystem lookup resolves dot segments, but the returned target retains them.

```
    while i < en {
        let cand_f = base + exts[i]
        if file_exists(cand_f) {
            return cand_f
        }
```

**Alias and direct-path consumers** — `src/resolve.kujo:283-300`

Both routes return unnormalized candidate strings as internal targets.

```
    // 5. Alias prefix.
    let aliased = apply_alias(raw, aliases)
    if aliased != "" {
        let r_alias = try_candidates(aliased)
        if r_alias != "" {
            return mk("internal", r_alias, raw)
        }
        return mk("unknown", "", raw)
    }

    // 6. Root-relative / dotted module path.
    let modpath = module_to_path(raw)
    let direct = try_candidates(modpath)
    if direct != "" {
        return mk("internal", direct, raw)
    }
    let under = try_under_roots(modpath, source_roots)
    if under != "" {
```

**Lexical zone classification** — `src/glob.kujo:40-47`

Prefix matching classifies a target by its spelling rather than its actual dot-normalized location.

```
    // `prefix/**` -> match anything at/under prefix.
    if ends_with(pat, "/**") {
        let prefix = substring(pat, 0, len(pat) - 3)
        if p == prefix {
            return true
        }
        return starts_with(p, prefix + "/")
    }
```

**Same-zone rule short circuit** — `src/rules.kujo:28-35`

A target that appears in the source zone is allowed before forbidden-zone checks.

```
    }

    // Explicit deny wins.
    if arr_has(zinfo["cannot_depend_on"], to_zone) {
        let rule = "zones." + from_zone + ".cannot_depend_on includes " + to_zone
        return verdict(false, sev, rule, from_zone + " cannot depend on " + to_zone)
    }

```

Limitations:
- Pre-remediation source preserved in source-snapshot; parent is independently implementing and testing fixes. No runtime reproduction in this audit.

#### Dataflow

With @=src, a src/ui file imports '@/ui/../database/users'. Existing src/database/users.ts is found via src/ui/../database/users.ts. Prefix src/ui/\*\* matches that returned spelling and same-zone policy permits the dependency despite ui denying database.

**Alias preserves untrusted suffix** — `src/resolve.kujo:175-179`

The trusted alias root is concatenated with the source-controlled suffix without normalizing dot segments.

```
    if raw == best_key {
        return best_target
    }
    let rest = substring(raw, len(best_key) + 1, len(raw))
    return best_target + "/" + rest
```

**Candidate lookup returns original spelling** — `src/resolve.kujo:95-99`

Filesystem lookup resolves dot segments, but the returned target retains them.

```
    while i < en {
        let cand_f = base + exts[i]
        if file_exists(cand_f) {
            return cand_f
        }
```

**Alias and direct-path consumers** — `src/resolve.kujo:283-300`

Both routes return unnormalized candidate strings as internal targets.

```
    // 5. Alias prefix.
    let aliased = apply_alias(raw, aliases)
    if aliased != "" {
        let r_alias = try_candidates(aliased)
        if r_alias != "" {
            return mk("internal", r_alias, raw)
        }
        return mk("unknown", "", raw)
    }

    // 6. Root-relative / dotted module path.
    let modpath = module_to_path(raw)
    let direct = try_candidates(modpath)
    if direct != "" {
        return mk("internal", direct, raw)
    }
    let under = try_under_roots(modpath, source_roots)
    if under != "" {
```

**Lexical zone classification** — `src/glob.kujo:40-47`

Prefix matching classifies a target by its spelling rather than its actual dot-normalized location.

```
    // `prefix/**` -> match anything at/under prefix.
    if ends_with(pat, "/**") {
        let prefix = substring(pat, 0, len(pat) - 3)
        if p == prefix {
            return true
        }
        return starts_with(p, prefix + "/")
    }
```

**Same-zone rule short circuit** — `src/rules.kujo:28-35`

A target that appears in the source zone is allowed before forbidden-zone checks.

```
    }

    // Explicit deny wins.
    if arr_has(zinfo["cannot_depend_on"], to_zone) {
        let rule = "zones." + from_zone + ".cannot_depend_on includes " + to_zone
        return verdict(false, sev, rule, from_zone + " cannot depend on " + to_zone)
    }

```

#### Reachability

A contributor changes only an import to an equivalent dot-segment spelling, with the traversed directory and forbidden target present; the configured alias and deny rules are unchanged.

- **Attacker:** Contributor controlling scanned source contents or filenames, without trusted configuration authority

Limitations:
- Fence is a best-effort local architecture tool; this finding does not establish application runtime authorization bypass.

#### Severity

**Medium** — Architecture gate integrity is affected for source contributors without policy authority.

Additional runtime or deployment evidence could raise or lower this severity.

#### Remediation

Normalize candidate identities consistently before policy classification, preserving explicitly supported root semantics and rejecting traversal above the allowed base.

Tests:
- Alias and direct-slash spellings containing dot segments must receive the same deny decision as their normalized target.
- Retain ordinary relative, Python/Rust, and configured alias compatibility tests.

<a id="finding-2"></a>

### [2] Backslash filenames can disappear from full scans

| Field | Value |
| --- | --- |
| Severity | low |
| Confidence | high |
| Confidence rationale | Complete static source trace confirms the transformation and affected consumer; no application execution was performed. |
| Category | path-confusion |
| CWE | CWE-706 |
| Affected lines | src/walk.kujo:60-74 |

#### Summary

Full traversal rewrites a legal POSIX filename before checking its existence, permitting a source file to be omitted without an incomplete-scan error.

#### Root Cause

`collect_files` replaces every backslash in a joined directory entry before `path_is_file`. POSIX permits backslashes in a filename; the missing rewritten path is neither selected nor recorded as unreadable.

**Directory entries are rewritten before lookup** — `src/walk.kujo:60-74`

A literal backslash in an on-disk POSIX basename becomes a slash; predicates test a different path and silently omit it if absent.

```
        let entries = list_dir(dir)
        let en = len(entries)
        mut ei = 0
        while ei < en {
            let name = entries[ei]
            mut full = dir + "/" + name
            full = replace(full, "\\", "/")
            if name == ".git" {
                // skip
            } else {
                if path_is_dir(full) {
                    stack = push(stack, { "path": full, "ancestors": ancestors })
                } else if path_is_file(full) {
                    found = push(found, full)
                }
```

#### Validation

list_dir yields a source basename containing a literal backslash; replace changes it to a nonexistent nested path; both predicates fail; found excludes the original file and later analysis sees no skipped file.

Validation method: static source trace

**Directory entries are rewritten before lookup** — `src/walk.kujo:60-74`

A literal backslash in an on-disk POSIX basename becomes a slash; predicates test a different path and silently omit it if absent.

```
        let entries = list_dir(dir)
        let en = len(entries)
        mut ei = 0
        while ei < en {
            let name = entries[ei]
            mut full = dir + "/" + name
            full = replace(full, "\\", "/")
            if name == ".git" {
                // skip
            } else {
                if path_is_dir(full) {
                    stack = push(stack, { "path": full, "ancestors": ancestors })
                } else if path_is_file(full) {
                    found = push(found, full)
                }
```

Limitations:
- Pre-remediation source preserved in source-snapshot; parent is independently implementing and testing fixes. No runtime reproduction in this audit.

#### Dataflow

list_dir yields a source basename containing a literal backslash; replace changes it to a nonexistent nested path; both predicates fail; found excludes the original file and later analysis sees no skipped file.

**Directory entries are rewritten before lookup** — `src/walk.kujo:60-74`

A literal backslash in an on-disk POSIX basename becomes a slash; predicates test a different path and silently omit it if absent.

```
        let entries = list_dir(dir)
        let en = len(entries)
        mut ei = 0
        while ei < en {
            let name = entries[ei]
            mut full = dir + "/" + name
            full = replace(full, "\\", "/")
            if name == ".git" {
                // skip
            } else {
                if path_is_dir(full) {
                    stack = push(stack, { "path": full, "ancestors": ancestors })
                } else if path_is_file(full) {
                    found = push(found, full)
                }
```

#### Reachability

A repository contributor adds a matching source file with a backslash in its POSIX filename and a prohibited import, then the operator runs a full scan. Changed-only behavior is different and does not repair full traversal.

- **Attacker:** Contributor controlling scanned source contents or filenames, without trusted configuration authority

Limitations:
- Fence is a best-effort local architecture tool; this finding does not establish application runtime authorization bypass.

#### Severity

**Low** — Constrained local tooling/report integrity impact; no remote execution or credential theft is established.

Additional runtime or deployment evidence could raise or lower this severity.

#### Remediation

Preserve native directory-entry identity or fail closed with an explicit unsupported-path error before normalization; use the same ambiguity policy for changed-only and explain paths.

Tests:
- A literal-backslash source basename must be analyzed accurately or fail closed, never disappear.
- A decoy nested path matching the rewritten name must not substitute for the original source.

<a id="finding-3"></a>

### [3] Repository text controls terminal and Markdown report presentation

| Field | Value |
| --- | --- |
| Severity | low |
| Confidence | high |
| Confidence rationale | Complete static source trace confirms the transformation and affected consumer; no application execution was performed. |
| Category | output-encoding |
| CWE | CWE-116 |
| Affected lines | src/reports.kujo:155-169, src/reports.kujo:365-375, src/cmd_explain.kujo:123-151 |

#### Summary

Source filenames and import strings are concatenated into terminal and Markdown output without neutralizing control characters or markup.

#### Root Cause

Human and Markdown renderers treat parsed repository strings as presentation syntax. JSON serialization protects machine output, but terminal escape sequences and Markdown delimiters remain active in text renderers.

**Human report interpolation** — `src/reports.kujo:155-169`

Untrusted file/import values enter printable output unchanged.

```
func human_violations(viols) {
    let n = len(viols)
    mut o = ""
    mut i = 0
    while i < n {
        let v = viols[i]
        o = o + "[" + to_upper(v["severity"]) + "] " + v["from_zone"] + " -> " + v["to_zone"] + " is not allowed\n"
        o = o + "  File: " + v["file"] + ":" + to_string(dict_get(v, "line", 1)) + "\n"
        if dict_get(v, "from_owner", "") != "" { o = o + "  Owner: " + v["from_owner"] + "\n" }
        o = o + "  Import: " + v["import"] + "\n"
        if v["resolved"] != "" {
            o = o + "  Resolved: " + v["resolved"] + "\n"
        }
        o = o + "  Rule: " + v["rule"] + "\n"
        o = o + "  Suggestion: " + v["suggestion"] + "\n\n"
```

**Markdown interpolation** — `src/reports.kujo:365-375`

A filename or import can terminate the fixed backtick span and introduce report markup.

```
        let v = viols[i]
        if v["severity"] == severity {
            any = true
            o = o + "- **" + v["from_zone"] + " -> " + v["to_zone"] + "** in `" + v["file"] + ":" + to_string(dict_get(v, "line", 1)) + "`\n"
            o = o + "  - Import: `" + v["import"] + "`"
            if v["resolved"] != "" {
                o = o + " (resolves to `" + v["resolved"] + "`)"
            }
            o = o + "\n"
            o = o + "  - Rule: " + v["rule"] + "\n"
            o = o + "  - Fix: " + v["suggestion"] + "\n"
```

**Explain interpolation** — `src/cmd_explain.kujo:123-151`

Explicitly inspected filenames and imported strings are also embedded raw in human explanations.

```
    o = o + "Explain: " + a["file"] + "\n"
    o = o + "=========" + "\n\n"
    o = o + "Zone: " + a["zone"] + "\n"
    if len(a["matched_zones"]) > 1 {
        o = o + "Note: file matched multiple zones: " + join_strings(a["matched_zones"], ", ") + " (first wins)\n"
    }
    o = o + "In scope: " + to_string(a["in_scope"]) + "\n"
    o = o + "Allowed dependencies: " + list_or_none(a["allowed"]) + "\n"
    o = o + "Denied dependencies: " + list_or_none(a["denied"]) + "\n\n"

    let imps = a["imports"]
    let n = len(imps)
    o = o + "Imports (" + to_string(n) + ")\n"
    o = o + "-------\n"
    if n == 0 {
        o = o + "(none detected)\n"
        return o
    }
    mut i = 0
    while i < n {
        let r = imps[i]
        o = o + "[" + to_upper(r["decision"]) + "] line " + to_string(r["line"]) + ": " + r["import"]
        if r["resolved"] != "" {
            o = o + " -> " + r["resolved"] + " (" + r["to_zone"] + ")"
        } else {
            o = o + " (" + r["status"] + ")"
        }
        if r["ignored"] { o = o + " (ignored: " + r["ignore_reason"] + "; expires " + r["ignore_expires"] + ")" }
        o = o + "\n"
```

#### Validation

Attacker-controlled basename/import -\> violation fields -\> human_violations/md_severity_section or explain_human -\> printed/saved report; no presentation encoding is applied.

Validation method: static source trace

**Human report interpolation** — `src/reports.kujo:155-169`

Untrusted file/import values enter printable output unchanged.

```
func human_violations(viols) {
    let n = len(viols)
    mut o = ""
    mut i = 0
    while i < n {
        let v = viols[i]
        o = o + "[" + to_upper(v["severity"]) + "] " + v["from_zone"] + " -> " + v["to_zone"] + " is not allowed\n"
        o = o + "  File: " + v["file"] + ":" + to_string(dict_get(v, "line", 1)) + "\n"
        if dict_get(v, "from_owner", "") != "" { o = o + "  Owner: " + v["from_owner"] + "\n" }
        o = o + "  Import: " + v["import"] + "\n"
        if v["resolved"] != "" {
            o = o + "  Resolved: " + v["resolved"] + "\n"
        }
        o = o + "  Rule: " + v["rule"] + "\n"
        o = o + "  Suggestion: " + v["suggestion"] + "\n\n"
```

**Markdown interpolation** — `src/reports.kujo:365-375`

A filename or import can terminate the fixed backtick span and introduce report markup.

```
        let v = viols[i]
        if v["severity"] == severity {
            any = true
            o = o + "- **" + v["from_zone"] + " -> " + v["to_zone"] + "** in `" + v["file"] + ":" + to_string(dict_get(v, "line", 1)) + "`\n"
            o = o + "  - Import: `" + v["import"] + "`"
            if v["resolved"] != "" {
                o = o + " (resolves to `" + v["resolved"] + "`)"
            }
            o = o + "\n"
            o = o + "  - Rule: " + v["rule"] + "\n"
            o = o + "  - Fix: " + v["suggestion"] + "\n"
```

**Explain interpolation** — `src/cmd_explain.kujo:123-151`

Explicitly inspected filenames and imported strings are also embedded raw in human explanations.

```
    o = o + "Explain: " + a["file"] + "\n"
    o = o + "=========" + "\n\n"
    o = o + "Zone: " + a["zone"] + "\n"
    if len(a["matched_zones"]) > 1 {
        o = o + "Note: file matched multiple zones: " + join_strings(a["matched_zones"], ", ") + " (first wins)\n"
    }
    o = o + "In scope: " + to_string(a["in_scope"]) + "\n"
    o = o + "Allowed dependencies: " + list_or_none(a["allowed"]) + "\n"
    o = o + "Denied dependencies: " + list_or_none(a["denied"]) + "\n\n"

    let imps = a["imports"]
    let n = len(imps)
    o = o + "Imports (" + to_string(n) + ")\n"
    o = o + "-------\n"
    if n == 0 {
        o = o + "(none detected)\n"
        return o
    }
    mut i = 0
    while i < n {
        let r = imps[i]
        o = o + "[" + to_upper(r["decision"]) + "] line " + to_string(r["line"]) + ": " + r["import"]
        if r["resolved"] != "" {
            o = o + " -> " + r["resolved"] + " (" + r["to_zone"] + ")"
        } else {
            o = o + " (" + r["status"] + ")"
        }
        if r["ignored"] { o = o + " (ignored: " + r["ignore_reason"] + "; expires " + r["ignore_expires"] + ")" }
        o = o + "\n"
```

Limitations:
- Pre-remediation source preserved in source-snapshot; parent is independently implementing and testing fixes. No runtime reproduction in this audit.

#### Dataflow

Attacker-controlled basename/import -\> violation fields -\> human_violations/md_severity_section or explain_human -\> printed/saved report; no presentation encoding is applied.

**Human report interpolation** — `src/reports.kujo:155-169`

Untrusted file/import values enter printable output unchanged.

```
func human_violations(viols) {
    let n = len(viols)
    mut o = ""
    mut i = 0
    while i < n {
        let v = viols[i]
        o = o + "[" + to_upper(v["severity"]) + "] " + v["from_zone"] + " -> " + v["to_zone"] + " is not allowed\n"
        o = o + "  File: " + v["file"] + ":" + to_string(dict_get(v, "line", 1)) + "\n"
        if dict_get(v, "from_owner", "") != "" { o = o + "  Owner: " + v["from_owner"] + "\n" }
        o = o + "  Import: " + v["import"] + "\n"
        if v["resolved"] != "" {
            o = o + "  Resolved: " + v["resolved"] + "\n"
        }
        o = o + "  Rule: " + v["rule"] + "\n"
        o = o + "  Suggestion: " + v["suggestion"] + "\n\n"
```

**Markdown interpolation** — `src/reports.kujo:365-375`

A filename or import can terminate the fixed backtick span and introduce report markup.

```
        let v = viols[i]
        if v["severity"] == severity {
            any = true
            o = o + "- **" + v["from_zone"] + " -> " + v["to_zone"] + "** in `" + v["file"] + ":" + to_string(dict_get(v, "line", 1)) + "`\n"
            o = o + "  - Import: `" + v["import"] + "`"
            if v["resolved"] != "" {
                o = o + " (resolves to `" + v["resolved"] + "`)"
            }
            o = o + "\n"
            o = o + "  - Rule: " + v["rule"] + "\n"
            o = o + "  - Fix: " + v["suggestion"] + "\n"
```

**Explain interpolation** — `src/cmd_explain.kujo:123-151`

Explicitly inspected filenames and imported strings are also embedded raw in human explanations.

```
    o = o + "Explain: " + a["file"] + "\n"
    o = o + "=========" + "\n\n"
    o = o + "Zone: " + a["zone"] + "\n"
    if len(a["matched_zones"]) > 1 {
        o = o + "Note: file matched multiple zones: " + join_strings(a["matched_zones"], ", ") + " (first wins)\n"
    }
    o = o + "In scope: " + to_string(a["in_scope"]) + "\n"
    o = o + "Allowed dependencies: " + list_or_none(a["allowed"]) + "\n"
    o = o + "Denied dependencies: " + list_or_none(a["denied"]) + "\n\n"

    let imps = a["imports"]
    let n = len(imps)
    o = o + "Imports (" + to_string(n) + ")\n"
    o = o + "-------\n"
    if n == 0 {
        o = o + "(none detected)\n"
        return o
    }
    mut i = 0
    while i < n {
        let r = imps[i]
        o = o + "[" + to_upper(r["decision"]) + "] line " + to_string(r["line"]) + ": " + r["import"]
        if r["resolved"] != "" {
            o = o + " -> " + r["resolved"] + " (" + r["to_zone"] + ")"
        } else {
            o = o + " (" + r["status"] + ")"
        }
        if r["ignored"] { o = o + " (ignored: " + r["ignore_reason"] + "; expires " + r["ignore_expires"] + ")" }
        o = o + "\n"
```

#### Reachability

A contributor creates a violating filename containing terminal ESC controls or Markdown delimiters; the operator views a human report in a terminal or renders the Markdown report. The contributor can alter visible evidence or insert deceptive links/sections; no code execution is claimed.

- **Attacker:** Contributor controlling scanned source contents or filenames, without trusted configuration authority

Limitations:
- Fence is a best-effort local architecture tool; this finding does not establish application runtime authorization bypass.

#### Severity

**Low** — Constrained local tooling/report integrity impact; no remote execution or credential theft is established.

Additional runtime or deployment evidence could raise or lower this severity.

#### Remediation

Escape control characters visibly for terminal output and encode Markdown metacharacters in all data-derived report fields. Preserve raw JSON/SARIF evidence.

Tests:
- Human output contains no attacker-supplied ESC/control sequences.
- Markdown filenames/imports containing backticks, line breaks, angle brackets and links remain literal evidence.
- JSON and SARIF keep the original raw path and import strings.

## Reviewed Surfaces

| Surface | Risk Area | Outcome | Notes |
| --- | --- | --- | --- |
| Import identity and architecture policy | not recorded | Reported | Alias and direct-slash dot segments preserve lexical identity through src/resolve.kujo:95-99,178-179,283-300; reported policy bypass. Built-in extraction is documented best effort, so undocumented syntax misses were not promoted as vulnerabilities. |
| Filesystem traversal and source selection | not recorded | Reported | src/walk.kujo:60-74 rewrites POSIX backslashes and can omit source; reported. Directory ancestor identity detects cycles. Source-root symlinks are permitted reads; no source-read sandbox is documented. Changed-only NUL path decoding avoids newline ambiguity (src/git.kujo:65-75,95-107). |
| Terminal and Markdown presentation | not recorded | Reported | src/reports.kujo:155-169,365-375 and src/cmd_explain.kujo:123-151 interpolate repository-controlled values; reported. JSON/SARIF serialization preserves data rather than interpreting it. |
| CLI output confinement and temporary files | not recorded | No issue found | src/output.kujo:29-34 calls native write_file_atomic_beneath with no fallback; src/paths.kujo:17-46 rejects unsafe lexical writes. check/graph apply optional roots; baseline/cache/init have fixed filenames. Native directory handles, temporary permissions and platform races are outside this repository and not independently revalidated. |
| Trusted configuration, composition and generated policy | not recorded | No issue found | src/config.kujo:41-87 validates data, depth, cycles and canonical containment. Config is trusted executable policy when adapters enabled. src/cmd_workspace.kujo:18-24,94-101 quotes names and parses generated TOML before no-overwrite publication. Concurrent hostile config replacement is an additional excluded deployment assumption. |
| Git and parser adapter authority | not recorded | No issue found | src/git.kujo:33-75 validates ref before structured argv and rejects truncated lists; src/parser_adapters.kujo:18-42 bounds duration/output and validates response. Trusted adapters are not sandboxed and may use network/environment. Option-like final paths depend on adapter parsing; no concrete supplied adapter accepts dangerous options, so no standalone vulnerability asserted. |
| Cache and baseline authority | not recorded | No issue found | src/cache.kujo:19-61,92-124 validates schema, caps size, matches digest, bypasses adapters and confines cache paths. Cache/baseline are trusted local state; forged valid state is not authenticated. src/baseline.kujo:49-103 validates baseline shape; no secret storage identified. |
| Resource ceilings and parser availability | not recorded | No issue found | src/cmd_check.kujo and src/analyze.kujo enforce configured check limits; extraction/traversal/render allocation precedes certain checks as documented in SECURITY.md. Missing limits in other analysis callers identified by parent functional review; not separately escalated into an unsupported memory-sandbox claim. |
| Release, CI and credential boundaries | not recorded | No issue found | scripts/release_artifacts.kujo:44-46 uses ordinary writes into a trusted publisher-selected output, separate from CLI confinement. No distinct lower-trust output writer established. .github/workflows/release.yml restricts publication to tag workflow with job-issued token; no hardcoded credentials found. Actions/runtime pinned; external protection settings not verified. |
| Tests, benchmarks, examples and fixture configuration | not recorded | No issue found | All runnable repository code and test configuration reviewed statically. Examples are deliberate architecture passes/failures; fixtures contain no application execution surface. Test shell uses isolated scratch locations; production impact of tests requires trusted harness execution. |

## Open Questions And Follow Up

- Native write_file_atomic_beneath behavior and temporary-file permissions cannot be independently established from Fence source; source deliberately fails closed when API is absent.
- Source/config/cache read races require concurrent adversary-controlled filesystem mutation; source read confinement and process isolation are host/operator obligations rather than established guarantees.
- Post-remediation status belongs to parent verification; this sealed discovery report intentionally preserves original findings.
