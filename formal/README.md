# Generalized DBLog formal verification artifact, version 1.0

This artifact accompanies Andreas Andreakis, *Generalized DBLog: A Verified Contract for Interleaving Copied Rows with a Change Log* (2026).

The paper gives conditions under which a copy of database state, reconciled with a committed change log, replays to source state at a chosen frontier. Its results are per key. A transactional-snapshot interpretation additionally requires transaction closure. Production protocol placements are conditional on their stated source and implementation assumptions.

## Contents

| Directory or file | Purpose |
| --- | --- |
| `dblog_framework/framework_core/` | Complete Isabelle/HOL development: 9 theories, including the cut theorem, merge disciplines, protocol placements, and degradation |
| `dual_write_layer0/` | Shared source-history and replay definitions needed by the Isabelle sessions |
| `formal/` | Imported classic DBLog development, with the documented session refactoring |
| `dblog_framework/lean/` | Independent Lean 4 proof of the contract core and window-discard results |
| `dblog_framework/tla/` | Five TLA+ models and 25 TLC configurations, including expected counterexamples |
| `dblog_framework/CROSS_VERIFICATION.md` | Paper-to-formalization correspondence and verification scope |
| `verification/` | Fresh build logs, TLC outcomes, and verified source hashes |
| `proof_documents/` | Typeset Isabelle proof documents for the generalized theory and both dependency sessions |
| `upstream/` | Unmodified published classic artifact and source comparison evidence |
| `ARTIFACT_PROVENANCE.md` | Exact relationship to the published classic artifact |
| `reproduce.py`, `tlc-runs.json` | Portable check runner and expected TLC outcomes |
| `SHA256SUMS` | SHA-256 checksums for every other file in the archive |

Isabelle checks the full normalized theorem development. Lean checks the core and window-discard results, not every protocol placement or range-merge. TLC supplies bounded searches, not a general proof: 15 configurations complete with no invariant violation and 10 deliberately produce the specified counterexamples. The largest complete search has 73,690,264 distinct states.

## Requirements and reproduction

Install Isabelle2025-2, Lean 4.32.2 (the project pins `leanprover/lean4:v4.32.2`), Python 3, Java 21, and TLC 2.19. Isabelle's document generation also needs a working LaTeX installation; proof checking alone does not. Lean uses its core library with no external package dependencies.

The exact TLC binary is the `tla2tools.jar` asset of the [official v1.7.4 release](https://github.com/tlaplus/tlaplus/releases/download/v1.7.4/tla2tools.jar). Its SHA-256 is `936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88`. It is not bundled. A newer jar is not the binary used for these verification records.

From this extracted directory, with `isabelle`, `lake`, and `java` on PATH:

```sh
python3 reproduce.py checksums
python3 reproduce.py isabelle
python3 reproduce.py lean
python3 reproduce.py tlc --jar /absolute/path/to/tla2tools.jar
```

The runner copies build inputs into fresh temporary directories and prints their paths. Isabelle uses a fresh user directory with `quick_and_dirty=false`; both the classic and generalized sessions are explicit targets. Lean starts without compiled project objects. TLC checks expected negative results as well as successful searches. A reported counterexample in a mutation run is the expected result, not a failed artifact check.

To check the Isabelle proofs without LaTeX or PDF generation:

```sh
python3 reproduce.py isabelle --no-document
```

This keeps the same proof checks and source files while disabling document output. It passes both `-o document=false` and `-o document_variants=` because the session ROOT files explicitly enable PDFs. The option also works with `all`. The three PDFs in `proof_documents/` can be read without installing Isabelle. Their hashes and generating build are recorded in `verification/proof-documents.json` and `verification/isabelle-build.json`.

For a quick positive and negative TLC check:

```sh
python3 reproduce.py tlc --jar /absolute/path/to/tla2tools.jar --run S1-B --run S1-C
```

The full TLC battery uses tens of millions of states in its larger searches. Use a workstation with sufficient memory and allow the searches to finish. Each model disables deadlock checking because its bounded final state is intentional.

## Provenance and scope

`ARTIFACT_PROVENANCE.md` documents the classic dependency. The archived version 2.1 and this dependency have the same mathematical definitions and results after a shared-session refactoring and predicate consolidation; they are not byte-identical. The archive includes the original upstream tarball so this relationship can be independently checked.

Kernel checking establishes the formal results under their assumptions. It does not establish that a running connector satisfies complete observation, correct source coordinates, read validity, representation agreement, or recovery conditions. Transport, populated-sink repairs, and end-to-end delivery are outside the verified contract. The accompanying paper explains those boundaries.

## AI assistance

The author used Claude Fable 5, ChatGPT 5.5 and 5.6 Sol, and GPT 6 Astra to assist with the theory, the Isabelle/HOL and Lean formalizations, the TLA+ models, and drafting the paper's prose. The author edited all of the prose and takes responsibility for the paper's content and conclusions.

## License

BSD 3-Clause; see `LICENSE` and the retained component licenses and copyright notices. The software archive does not include or assign a license to the separately submitted paper. Upstream materials retain their own license notices.
