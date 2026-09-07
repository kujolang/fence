# F12: confined atomic publication

## Scope and provenance

The user explicitly authorized the previously blocked Kujo runtime work.
Fence starts at `78dcff3f21fb4ea3685313296044202ca432fda9`. Runtime inspection
started at `588836eaa8c61bcbd26007cb4960e5371edd60fb`; a concurrent SiteProbe task
advanced its checkout to `33508db47f3bc472e96d20000f7ea83e6057c30e`. Fence work
was transferred to the separate `kujo-fence-f12` worktree based on that commit.
Only the reviewed Fence changes were transferred; the other task's tracked
files were restored and its branch was not switched or reset.

Runtime implementation commits: `0da28592ba237f00fa1769d5daa7d84c82ef3385`
and `240d092cfbfb4f2d126641350373a52420577e41`. The second is essential: it
replaces Windows library operations that reconstruct ambient paths. Fence pins
that corrected commit; the first implementation alone is not sufficient on
Windows. Fence integration commits are `809ac7ad4f5d9a3e821d930c01a84f5a95791501`
and `30201583b46af039549033f00af29bab13bb7a8a`. Final runtime pin:
`97aa13a338b154646d96e5c257e5d17fed17bef9`; final code integration:
`6312e6520a9deaa48a44918a3eb0194b6db413bb`. The final runtime merges
SiteProbe's exception-unwinding correction and refreshes generated inventories.

## Root cause and implementation

The old Fence writer canonicalized an ancestor, then separately created parents
and wrote by pathname. Atomic replacement prevented torn files but could not
bind subsequent operations to the checked directory.

Kujo now exposes `write_file_atomic_beneath(root, relative_path, payload,
overwrite?)`. It is a 3..=4 argument, filesystem-write-gated native API registered
with interpreter, VM native registration, arity dispatch and type checking.
It accepts text/bytes, applies the existing write-byte limit, validates relative
components and retains directory handles throughout the operation.

On Unix, existing cap-std/cap-fs-ext handles provide nofollow traversal,
relative parent/temp creation, rename and no-replace hard-link publication.
On Windows, source review found cap-primitives' rename/link/remove/create-dir
helpers reconstructing paths. A small native Windows module instead uses
NtCreateFile with RootDirectory and OPEN_REPARSE_POINT, followed by
NtSetInformationFile for handle-relative rename and temporary deletion. The
UTF-16 structures are aligned, length-bounded, synchronously borrowed and
annotated at unsafe boundaries. Windows alternate data streams are rejected.
No new package dependency was added.

Fence's `src/output.kujo` now delegates publication to the native operation.
The prior canonical-check/write sequence and obsolete helpers are removed.
Lexical validation and configured output-root policy remain. Harmless `./`
and repeated separators are normalized after rejecting traversal. IO failures
still return exit 5. All callers of the central writer, including reports,
baselines, cache and generated configuration, inherit the new boundary.

## Exact security contract

The root is trusted and opened once. Child paths cannot redirect publication
by replacing an ancestor with a symlink/junction. Existing symlink parents and
stable final symlinks are rejected. Racing final symlinks are never followed.
No-replace publication is atomic, so a competing winner cannot be overwritten.
Temporary content is synced before publication and cleanup failures are visible.
The six reviewed Windows FFI sites are counted exactly in the unsafe-inventory
ratchet, with total executable sites intentionally increased from 67 to 73.

Confinement is to **directory identity**, not continuous ancestry. A directory
moved after opening remains the destination; arbitrary privileged mount changes
or malicious modification of that directory's contents are not sandboxed.
Parent directories created before an error may remain. File sync is not a
promise of crash-durable directory metadata. Unix cleanup failure after a
successful hard-link publication is identified as `cleanup_failed_after_publish`;
callers must inspect before retrying. This is deliberately not an unrestricted
hostile-workspace integrity guarantee.

## Compatibility and release

Existing Kujo `write_file_atomic` semantics are unchanged. The new API is
additive; no config, environment or serialized runtime schema changes.
Fence's source minimum is the exact corrected Kujo commit, not released 1.3.1.
README, getting-started and all three runtime-checkout workflows specify it.
There is no fallback for older runtimes. Symlinked output parents within the
repository were previously accepted and are now rejected deliberately, matching
the security contract. Check JSON, exit codes and output-root configuration
remain unchanged. No release tag is claimed or created.

## Verification and regression ratchets

The local baseline runtime test attempt hit host process exhaustion (error 35).
An all-disabled-feature library build also exposed pre-existing ungated
image/archive tests. Local F12 tests therefore enable runtime-image and
runtime-archive. A pre-existing non-JIT parity-test compilation problem was fixed by the
concurrent runtime task. Integrating that verified test-only change produces
Kujo merge commit `3cab46ee043b0e452950d7de358487b4c4a3bde8`, with production
source identical to the Fence pin. All 110 parity tests now pass locally.
The exception regression also produced identical `99:3` output in both modes.
Hosted verification uses default features.
A shared build was stopped during worktree isolation. Final verification uses
the isolated worktree and committed runtime pin; neither interrupted build is
counted as a pass.

Native tests force ancestor replacement synchronously after parent acquisition
and before publication, for both first and nested parents. Outside sentinel
files must remain unchanged and the output must appear through the held handle.
The Windows version attempts junction replacement. Where NT returns exact
access-denied because an ancestor contains open handles, it requires successful
output through the original directory and unchanged outside sentinels. Other
mutation errors fail. Where mutation succeeds, it requires output through the
held directory. The first Windows run exposed this documented kernel prevention
in the test harness; the test was corrected without relaxing output assertions.
A second Windows attempt exposed mixed-separator paths passed to cmd mklink;
normalizing the fixture path components fixes that command. Git Bash symlink
fixtures now require an actual symbolic link rather than accepting copy emulation.
Native Windows junction coverage remains mandatory. Two no-replace writers synchronize before
publication and must have exactly one winner with no leftover temporary files.
Additional cases cover Unicode, missing parents, overwrite, lexical rejection,
symlinks/dangling links, failure cleanup, bytes, bad arity/flags and capability
parity under VM and interpreter.

Fence adds CLI cases for external/internal symlink parents, final symlinks,
unchanged outside sentinels, parent creation and harmless separator normalization.
The pinned Linux/Windows platform gate runs native boundary/parity tests before
the full Fence release suite. Runtime's existing three-platform filesystem gate
also includes the new tests. No sleeps or timing thresholds were used to conceal
races; hooks/barriers establish exact test boundaries.

Final platform run [34121357542](https://github.com/kujolang/fence/actions/runs/34121357542)
passed on Linux and Windows at the exact Fence/runtime pins above. Selected
receipts are in [receipts/f12](receipts/f12/). macOS was verified locally.

| Exact command | Result |
|---|---|
| `cargo test --release --locked --manifest-path kujo-runtime/Cargo.toml --lib --test native_api_security_boundaries filesystem` | Hosted Linux: 11 library + 16 integration; Windows: 8 library + 16 integration; all pass |
| `kujo run scripts/verify_release.kujo` | Linux, Windows and local macOS pass; static checks, unit/CLI suites, config/architecture, six examples, artifact generation |
| `kujo run tests/fence_tests.kujo` | macOS 266 passed, 0 failed |
| `sh tests/cli_smoke.sh` | macOS 76 passed, 0 failed (previous baseline 70) |
| `cargo test --no-default-features --features runtime-archive,runtime-image --lib --test native_api_security_boundaries filesystem` | macOS 11 library + 16 integration pass |
| `cargo test --no-default-features --features runtime-archive,runtime-image --test vm_interpreter_parity_surfaces` | macOS 110 pass on merged runtime |
| `cargo test --no-default-features --features runtime-archive,runtime-image --test generated_artifact_freshness_contract --test unsafe_inventory_contract --test readme_contracts` | Freshness 3, unsafe 3, README 1: PASS |
| `cargo fmt --check` | PASS |
| `git diff --check` (both repositories) | PASS |
| `sh -n tests/cli_smoke.sh fence.sh` | PASS |

Local Cargo commands use `CARGO_BUILD_JOBS=1` and Cargo on PATH. Local Fence
commands put the isolated runtime's `target/debug` first on PATH, including
adapter subprocesses. The installed global runtime was not replaced.
An attempted target named `generated_artifact_freshness` was a command typo;
the exact existing `generated_artifact_freshness_contract` target above was
rerun. The full Kujo release gate passed for the concurrent main predecessor
5dcbfcd; this pass qualifies the changed filesystem surface plus parity and
artifact gates, rather than claiming an additional full Kujo release-gate run.

| ID | Priority | Area | Finding | Evidence | Action | Status |
|---|---|---|---|---|---|---|
| F12 | P1 | Filesystem confinement | Separate canonical check and pathname publication allow ancestor substitution | Implementation review and deterministic replacement tests | Held-directory native publication; Fence integration; three-platform verification | Fixed within the explicit directory-identity contract |

## Performance and remaining concerns

This is a security/correctness change. No runtime, memory, token, or latency gain
is claimed. Dependency count is unchanged. Platform assumptions and held-directory
semantics above remain explicit. F12 is closed within the documented contract. No P0/P1 audit work or required
cross-repository implementation remains. Consumers must use the pinned source
runtime (or a future release containing it); publishing that release is outside
this task. Independent timing/memory gains remain unmeasured and are not claimed.
This supersedes F12's previous authorization blocker; earlier reports remain historical.

Primary Windows ABI references:
[FILE_RENAME_INFORMATION](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/ntifs/ns-ntifs-_file_rename_information),
[NtCreateFile](https://learn.microsoft.com/en-us/windows/win32/api/winternl/nf-winternl-ntcreatefile).
