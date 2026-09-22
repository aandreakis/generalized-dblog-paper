# Generalized DBLog

### A Verified Contract for Interleaving Copied Rows with a Change Log

[![Paper (arXiv)](https://img.shields.io/badge/paper-arXiv%3A2609.08160-b31b1b)](https://arxiv.org/abs/2609.08160)
[![Artifact 1.0 DOI](https://img.shields.io/badge/artifact-10.5281%2Fzenodo.22643866-1682D4)](https://doi.org/10.5281/zenodo.22643866)

Sources for the paper **"Generalized DBLog: A Verified Contract for Interleaving
Copied Rows with a Change Log"** (Andreas Andreakis, 2026) and the formal
verification artifacts that accompany it.

A change-data-capture pipeline often has to copy existing rows while it
keeps reading the database's log of committed changes. Changes must not fall
through a gap, and older copied state must not overwrite a newer logged update
or bring back a deleted row. DBLog, developed at Netflix, addressed this problem
by reading tables in chunks and interleaving those reads with the live log.
Debezium and Flink CDC have since adapted this design. Earlier work proved that
replaying the original algorithm's output reconstructs the source's rows. This
paper asks when the same result holds for variants of that design. It states
the conditions that the source and the capture implementation must satisfy. It
proves that, once copying and reconciliation are complete, the result holds
across all selected tables and key ranges, even when their rows were read at
different times. A single database snapshot is not required for the copy.

The results are per key and hold under explicit source and capture assumptions.
The paper evaluates protocol designs. It does not certify a software release,
and no running connector is verified. Transport, populated-sink repairs, and
end-to-end delivery are outside the verified contract.

The complete theory is machine-checked in Isabelle/HOL. Its core is
independently verified in Lean 4. Five TLA+ specifications of the protocols are
examined by bounded model checking. Model checking gives evidence. It is not a
proof.

**Links:** [paper on arXiv](https://arxiv.org/abs/2609.08160) ·
[archived artifact (Zenodo)](https://doi.org/10.5281/zenodo.22643866) ·
[result index](docs/THEOREMS.md) ·
[provenance](docs/PROVENANCE.md) ·
[AGENTS.md](AGENTS.md) for AI tools

## Repository map

| Path | What it is |
|---|---|
| [paper/](paper/) | Exact arXiv v3 manuscript files, the six figures, and arXiv's stamped PDF. |
| [formal/](formal/) | The complete verification artifact, **byte-identical to Zenodo version 1.0**. Do not edit. |
| [formal/README.md](formal/README.md) | The artifact's own README: contents, requirements, reproduction, scope. |
| [formal/dblog_framework/CROSS_VERIFICATION.md](formal/dblog_framework/CROSS_VERIFICATION.md) | Authoritative map from every numbered object of the paper to Isabelle, Lean and TLC. |
| [docs/THEOREMS.md](docs/THEOREMS.md) | Short index of the paper's numbered results with their Isabelle names. |
| [docs/PROVENANCE.md](docs/PROVENANCE.md) | Paper and artifact version history, DOIs, hashes. |
| [AGENTS.md](AGENTS.md) | Guide for AI assistants and automated readers. |

## The paper

- **arXiv v3:** [abstract](https://arxiv.org/abs/2609.08160v3) ·
  [PDF](https://arxiv.org/pdf/2609.08160v3). 39 pages, 6 figures,
  cs.DB + cs.DC + cs.LO, CC BY 4.0.
- **In this repository:** [generalized-dblog.pdf](paper/generalized-dblog.pdf), arXiv's own stamped v3 PDF.
- **Build from source.** The bundle carries `main.bbl`, so BibTeX is not
  required for this exact rebuild:

~~~bash
cd paper
pdflatex main
pdflatex main
pdflatex main
~~~

## The proofs

The artifact has three layers with different scopes.

| Layer | Location | Scope |
|---|---|---|
| Isabelle/HOL | [formal/dblog_framework/framework_core/](formal/dblog_framework/framework_core/) | The full development: the normalized mathematical form of every numbered definition and result of the paper, including the five placements and degradation. |
| Lean 4 | [formal/dblog_framework/lean/](formal/dblog_framework/lean/) | An independent proof of the contract core and the window-discard results. It does not cover every placement or the range merge. |
| TLA+ | [formal/dblog_framework/tla/](formal/dblog_framework/tla/) | Five models and 25 TLC configurations. 15 complete with no invariant violation. 10 produce the counterexamples they were built to produce. |

Requirements: Isabelle2025-2, Lean 4.32.2, Python 3, Java 21, and TLC 2.19. The
exact TLC binary and its hash are named in [formal/README.md](formal/README.md).
Run the checks from the artifact directory:

~~~bash
cd formal
python3 reproduce.py checksums
python3 reproduce.py isabelle
python3 reproduce.py lean
python3 reproduce.py tlc --jar /absolute/path/to/tla2tools.jar
~~~

To check the Isabelle proofs without LaTeX, use
`python3 reproduce.py isabelle --no-document`. A counterexample reported in a
mutation run is the expected result of that run. The three PDFs in
[formal/proof_documents/](formal/proof_documents/) can be read without
installing Isabelle.

To check this tree against the archived deposit, run from the repository root:

~~~bash
curl -sL -o artifact.zip https://zenodo.org/records/22643866/files/Generalized_DBLog_artifact-1.0.zip
unzip -q artifact.zip
diff -r Generalized_DBLog_artifact-1.0 formal
~~~

No output from `diff` means the trees are identical. Zenodo remains the archival
identifier. This repository is a mirror.

## Versions and DOIs

| | Paper | Verification artifact |
|---|---|---|
| Current | [arXiv:2609.08160v3](https://arxiv.org/abs/2609.08160v3), 21 Sep 2026 | `1.0`, [10.5281/zenodo.22643866](https://doi.org/10.5281/zenodo.22643866), 7 Sep 2026 |
| Previous | [v2](https://arxiv.org/abs/2609.08160v2), 14 Sep 2026, and [v1](https://arxiv.org/abs/2609.08160v1), 8 Sep 2026 | none |
| Always latest | [arXiv:2609.08160](https://arxiv.org/abs/2609.08160) | [10.5281/zenodo.22643865](https://doi.org/10.5281/zenodo.22643865) (concept DOI) |

The arXiv paper cites the Zenodo version DOI `10.5281/zenodo.22643866`, and this
repository's `formal/` tree is byte-identical to that deposit. Full hashes and
the relationship between the public records:
[docs/PROVENANCE.md](docs/PROVENANCE.md).

## Citing

The paper:

~~~bibtex
@misc{andreakis2026generalized_dblog,
  author        = {Andreas Andreakis},
  title         = {Generalized {DBLog}: A Verified Contract for Interleaving
                   Copied Rows with a Change Log},
  year          = {2026},
  eprint        = {2609.08160},
  archivePrefix = {arXiv},
  primaryClass  = {cs.DB},
  doi           = {10.48550/arXiv.2609.08160}
}
~~~

The verification artifact:

~~~bibtex
@misc{andreakis2026generalized_dblog_formal,
  author    = {Andreas Andreakis},
  title     = {Formal development for "Generalized {DBLog}: A Verified Contract
               for Interleaving Copied Rows with a Change Log"},
  year      = {2026},
  publisher = {Zenodo},
  version   = {1.0},
  doi       = {10.5281/zenodo.22643866},
  note      = {Software, BSD 3-Clause License.}
}
~~~

GitHub's **Cite this repository** button reads [CITATION.cff](CITATION.cff).

## Background

- **A Theoretical Study of DBLog: Certified Virtual Cuts for a
  Snapshot-Equivalent Replay of Live Databases**, Andreakis, 2026.
  [arXiv:2605.31475](https://arxiv.org/abs/2605.31475) ·
  [repository](https://github.com/aandreakis/dblog-theory-virtual-cuts-paper).
  This is the earlier proof for the original algorithm. The present artifact
  builds on its formal development.
- **DBLog: A Watermark Based Change-Data-Capture Framework**, Andreakis &
  Papapanagiotou, 2020. [arXiv:2010.12597](https://arxiv.org/abs/2010.12597).
  This is the original paper on the mechanism.
- **DBLog: A Generic Change-Data-Capture Framework**, Netflix Tech Blog, 2019.
  [Post](https://netflixtechblog.com/dblog-a-generic-change-data-capture-framework-69351fb9099b).

## Licence

- **Paper text and figures** (`paper/main.tex`, `paper/main.bbl`,
  `paper/figures/` and reader documentation): Creative Commons Attribution 4.0
  International, matching the arXiv posting. See
  [LICENSES/CC-BY-4.0.txt](LICENSES/CC-BY-4.0.txt). `paper/acmart.cls` is the
  ACM class file bundled with the arXiv submission. It keeps its own terms,
  stated in its header.
- **Verification artifact** (`formal/`): BSD 3-Clause. See [LICENSE](LICENSE),
  copied from the archived artifact. Upstream materials inside the artifact
  retain their own licence notices.

## Author

**Andreas Andreakis**, independent researcher ·
[ORCID 0009-0003-9025-9402](https://orcid.org/0009-0003-9025-9402)
