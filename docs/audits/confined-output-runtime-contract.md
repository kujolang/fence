# F12: runtime contract required for confined publication

> Current status (2026-09-07): F12 is implemented in Kujo and integrated into Fence.
> Linux/Windows release gates and local macOS verification pass. See the
> [implementation and final verification receipt](confined-output-implementation.md).
> Open F12 statements below are historical.

Fence's supported Kujo runtime exposes path-based `write_file_atomic`; Fence
checks the canonical parent before calling it. A concurrent hostile writer can
replace an ancestor between those operations. Atomic publication prevents torn
files, but does not bind the destination to the checked directory. This is a
source-supported race concern, not a reproduced exploit in this session.

Inspected Kujo's filesystem implementation and standard library documentation.
The newer `read_file_beneath` family anchors reads; private-spool operations hold
file handles but do not provide general handle-relative publication beneath a
caller-selected directory. Neither is an equivalent replacement for Fence output.
Repeating canonical checks, hashing paths, or adding sleeps cannot close F12.

## Proposed Kujo mechanism (not a shipped API)

Add a capability-gated operation such as
`write_file_atomic_beneath(root, relative_path, content, overwrite)`:

- Open and retain the root directory handle once; resolve all destination
  components relative to retained handles without following symlinks/reparse
  points. Reject absolute paths, traversal, empty final names and embedded NUL.
- Create missing directories relative to those handles. Never reconstruct a
  path-based fallback for validation, temporary creation, or final publication.
- Create an exclusive temporary file in the anchored destination directory;
  write all content, then publish relative to that same directory handle.
- Enforce no-replace atomically when overwrite is false. Concurrent winners
  must not be overwritten. Clean up temporary handles/files on every failure.
- Define whether moved-out directory handles remain valid destinations or
  require stronger kernel resolution semantics. Do not promise confinement
  under arbitrary privileged filesystem mutation beyond platform guarantees.
- Gate filesystem writes using Kujo's existing capability checks. Return
  actionable structured errors; unsupported platforms must fail explicitly.
- Implement POSIX and Windows semantics in the native runtime, with tests on
  both platforms. Pin and document the first compatible Kujo release in Fence.

## Required regression evidence

Use synchronization barriers in native tests, not arbitrary sleeps. Swap each
ancestor after traversal but before temporary creation and publication; verify
outside sentinels remain unchanged. Cover existing and missing parents, dangling
symlinks, final-component symlinks, Windows junctions, concurrent no-replace
writers, overwrite, write failure, cleanup, Unicode paths, and capability denial.
A normal path-write fallback must be impossible in restricted operation.

## Fence integration after the runtime contract ships

Replace `write_safe`'s path-check/write sequence with the anchored operation;
retain lexical validation and `output_roots` policy. Route cache and baseline
writes through it. Add process-level regression checks and raise the runtime
minimum deliberately, with release notes. Existing trusted-workspace behavior,
atomic replacement, explicit overwrite, and IO exit 5 must be preserved.

This requires changes in the **kujo** repository. The original task explicitly
limits writes to Fence; no sibling files were modified. F12 remains open pending
cross-repository authorization, native implementation, and platform verification.
