# Troubleshooting

### "No fence.toml found"

Fence needs a config. Run `kujo run fence.kujo -- init` and edit the generated
`fence.toml` to match your directories.

### `check` scans 0 files

- Confirm `source_roots` points at real directories.
- Confirm `[scan].include` patterns match your file extensions. Empty `include`
  means "include everything" under the roots.
- Remember glob support is pragmatic: `src/**/*.ts` works; brace/bracket
  patterns (`{}`, `[]`) do not.

### A file maps to the wrong zone (or `unknown`)

Run `kujo run fence.kujo -- explain <path>`. It shows the matched zone, whether
multiple zones matched (first wins), and each import's decision. Adjust the
zone `paths` globs. If `validate` warns about **overlapping paths**, two zones
are competing for the same files.

### An import I expected to flag shows as `external`

Fence could not resolve it to a file in the repo, so it treated it as a
third-party package. Check:
- relative paths resolve from the importing file's directory;
- aliases are declared under `[aliases]`;
- the target file extension is one Fence tries (`.ts/.tsx/.js/.jsx/.py/.rs/.php/.go/.kujo`).

To forbid a genuine third-party package, add it to `[external].deny`.

### `--changed-only` fails

- The directory must be a Git repository.
- `--base` must be a valid ref matching `^[A-Za-z0-9._/~^-]+$` (anything else is
  rejected to prevent shell injection).
- In CI, ensure full history is fetched (`fetch-depth: 0`) so the base ref exists.

### `--output` is refused

The path escaped the working directory. Output must be repo-relative: no
absolute paths, no `~`, no `..`, no drive letters, and no symlinked parent that
points outside the tree.

### `kujo check src/<file>.kujo` reports an error after I edited a module

Common Kujo VM gotchas:
- **Duplicate declaration:** you reused a `let` name across `if` branches in the
  same function — rename to unique locals.
- **More than one `for` per function:** convert to `while` loops.
- **Undefined variable on import:** use `from src.x import name`; qualified
  `src.x.f()` is unsupported, and exported functions need `export func`.

See [architecture.md](architecture.md) for the full list of VM constraints.

### Tests fail after a change

Run `kujo run tests/fence_tests.kujo` (not `kujo test-run`). The failing line
prints the label plus got/want. Add assertions for new behavior in the same
file.
