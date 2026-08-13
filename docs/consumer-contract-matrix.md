# Consumer contract matrix

Verified August 12, 2026 against the local Kujo ecosystem checkouts and the
versioned fixtures in `tests/contracts/`.

| Consumer | Result | Evidence / boundary |
| --- | --- | --- |
| Scout | Compatible | A quick scan ingested both fixture files as data artifacts: 2 files, 0 findings, valid scan manifest. Scout produces SARIF but does not consume Fence findings. |
| Eval | Pass | `tests/consumer_contract_eval.json` ran 3/3 JSON assertions against exact staged copies of JSON v1 and SARIF 2.1.0. |
| PackWrite | Blocked upstream | PackWrite has no Fence report input. Its launcher also resolves the target repository's `src.cli` before PackWrite's own `src.cli` when run inside Fence, so even dry-run context collection cannot start. No Fence contract incompatibility was observed because ingestion never began. |
| ShipCheck | Compatible | `scan --dir ../fence --format json` consumed the repository without parsing or conflicting with the fixtures. After adding `kennel.toml`, its error-level release metadata and entry-point checks pass; Fence reports remain out of scope for ShipCheck. |

Eval reproduction (the suite deliberately uses an Eval-local staging directory
because Eval rejects parent-traversal paths):

```bash
mkdir -p ../eval/.fence-contract-tmp
cp tests/contracts/*.json ../eval/.fence-contract-tmp/
(cd ../eval && kujo run main.kujo run ../fence/tests/consumer_contract_eval.json --json)
```

The PackWrite module-resolution collision is tracked as an upstream ecosystem
finding; Fence does not weaken module resolution or copy provider code to work
around it.
