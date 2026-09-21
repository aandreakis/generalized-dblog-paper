# AGENTS.md

## Purpose

This repository contains the verification artifact and manuscript sources for the paper
"Generalized DBLog: A Verified Contract for Interleaving Copied Rows with a
Change Log." It combines:

- the exact arXiv v2 paper source and stamped PDF,
- the complete formal verification artifact archived as version 1.0
  (Isabelle/HOL, Lean 4, TLA+),
- a short result index and provenance notes.

Human readers should start at <code>README.md</code>, which is short and points
at the sources and their identifiers. This file is the most detailed guide in
the repository. Use it before answering questions about the results or modifying
derived documentation.

This repository is not a software project. There is no application to run and no
feature work. Your likely task is to read, explain, cite, or check.

**Links.** Paper: [arXiv:2609.08160](https://arxiv.org/abs/2609.08160)
([v2 abstract](https://arxiv.org/abs/2609.08160v2) ·
[v2 PDF](https://arxiv.org/pdf/2609.08160v2) ·
[in-repo PDF](paper/generalized-dblog.pdf) ·
[sources](paper/)). Verification artifact: [formal/](formal/) · archived at Zenodo
[10.5281/zenodo.22643866](https://doi.org/10.5281/zenodo.22643866) (version 1.0)
· [10.5281/zenodo.22643865](https://doi.org/10.5281/zenodo.22643865) (concept
DOI). Indexes and derived reading:
[formal/dblog_framework/CROSS_VERIFICATION.md](formal/dblog_framework/CROSS_VERIFICATION.md) ·
[formal/README.md](formal/README.md) ·
[docs/THEOREMS.md](docs/THEOREMS.md) ·
[docs/PROVENANCE.md](docs/PROVENANCE.md). Earlier work:
[theory paper for the original algorithm](https://arxiv.org/abs/2605.31475) ·
[2020 DBLog paper](https://arxiv.org/abs/2010.12597). Author: Andreas Andreakis,
[ORCID 0009-0003-9025-9402](https://orcid.org/0009-0003-9025-9402).

## Source precedence

When sources differ, use this order:

1. **Isabelle theorem statements and definitions** under
   <code>formal/dblog_framework/framework_core/</code> and its two dependency
   sessions are authoritative for what is proved. The artifact names the
   Isabelle development as the source of truth for the Lean and TLA+ layers.
2. **formal/dblog_framework/CROSS_VERIFICATION.md** is the authoritative map
   from the paper's numbered objects to Isabelle names, Lean names and TLC runs.
3. **paper/main.tex** is authoritative for the paper's exposition, the theorem
   statements as published, the scope discussion, and the proofs in the paper's
   own notation.
4. **README.md** and <code>docs/</code> are derived aids for readers.

The kernel checks the theorem statements under their stated assumptions. It
does not check whether a real deployment satisfies those assumptions.

## Frozen and editable areas

| Path | Role | Edit policy |
|---|---|---|
| <code>formal/</code> | Exact Zenodo 1.0 artifact bytes | Do not edit. Publish a new artifact version instead. |
| <code>paper/</code> | Exact arXiv v2 source and PDF | Do not edit in place. Refresh only from a new public arXiv version. |
| <code>README.md</code>, <code>docs/</code>, this file | Derived guidance | May be clarified if every claim remains traceable to the frozen sources. |
| <code>CITATION.cff</code> | Repository citation metadata | Update only when the public paper or artifact record changes. |

## What the paper studies

A change-data-capture pipeline copies existing rows while it keeps reading the
database's log of committed changes. The paper calls the merge of the copy with
the active log the copy-to-log handoff problem. DBLog reads tables in chunks,
interleaves those reads with the live log, and lets the log win when a copied
row is stale. The paper states conditions on the source and on the capture
implementation. Under those conditions it proves that replaying the emitted
events reconstructs the source's rows once copying and reconciliation are
complete. The paper establishes this for:

- classic watermarking,
- Debezium's signal-table and read-only modes,
- Flink CDC's parallel chunks,
- reads and dumps tied to exact log positions,
- engine-consistent backups whose log position lies within known bounds.

## Paper terms and mechanization names

The paper and the mechanization use different names for a few objects. The
artifact's cross-verification table gives this map:

| Paper | Mechanization |
|---|---|
| bracket-local validity (obligation O2) | <code>honest</code> |
| read result, merged result | <code>verdict</code> |
| shared state witness | the <code>shared_witness_trajectory</code> family |

Mechanization lemma names keep their established identifiers, for example
<code>mixing_shared_honesty_lift</code>.

## Paper result map

The eight theorems and their Isabelle names. Corollaries, propositions and
lemmas are listed in <code>docs/THEOREMS.md</code>. Definitions, examples and
the TLC runs are listed in
<code>formal/dblog_framework/CROSS_VERIFICATION.md</code>.

| Paper | Title | Isabelle names | Theory in <code>formal/dblog_framework/framework_core/</code> |
|---|---|---|---|
| Theorem 1 | Cut theorem | <code>contract_cut</code>, <code>contract_cut_at</code>, <code>contract_cut_scope</code> | <code>Cut_Theorem.thy</code> |
| Theorem 2 | Window-discard equivalence | <code>window_discard_replay</code> | <code>Merge_Disciplines.thy</code> |
| Theorem 3 | Window-discard monotonicity | <code>window_discard_monotone</code> | <code>Merge_Disciplines.thy</code> |
| Theorem 4 | Range-merge equivalence | <code>range_merge_replay</code> | <code>Range_Merge.thy</code> |
| Theorem 5 | Range-merge monotonicity | <code>range_merge_monotone</code> | <code>Range_Merge.thy</code> |
| Theorem 6 | Classic DBLog satisfies the contract | <code>classic_imports_upward</code>, <code>classic_sink_is_Src</code> | <code>Classic_Instance.thy</code> |
| Theorem 7 | Transaction-complete executed-set windows are faithful | <code>oracle_agreement</code> | <code>ReadOnly_Instance.thy</code> |
| Theorem 8 | Degradation | <code>degraded_cut</code>, <code>degraded_trajectory_from_end</code>, <code>degraded_replay</code>, <code>degraded_emitted_cut</code>, <code>trusted_point_is_degenerate_bracket</code> | <code>Dump_Splice_Instance.thy</code> |

## Misreadings to avoid

| Misreading | Correction |
|---|---|
| "The paper verifies Debezium or Flink CDC." | The paper evaluates protocol designs. It does not certify a software release. A connector obtains the guarantees when its runtime execution fulfills the modeled rules under the stated preconditions. |
| "The copy needs a consistent database snapshot." | A single database snapshot is not required for the copy. The result holds even when rows were read at different times. |
| "The results describe a transactional snapshot." | The results are per key. A transactional-snapshot interpretation additionally requires transaction closure. |
| "The theorems cover delivery to the sink." | Transport, duplicate delivery, and exactly-once application are outside the framework. |
| "The theorems cover repairing a populated sink." | The formal theorems assume an empty initial state. Populated-sink repairs are outside the current framework. |
| "Checkpoint, restart and failover are proved." | Checkpoint, restart, rescaling, and failover protocols are not proved. A resumed run obtains the guarantee only when its recovered plan and output again satisfy the same source and emission conditions. |
| "Schema changes are covered." | Schema and DDL evolution are excluded by the stable logical identity space. |
| "Model checking proves the protocols." | TLC supplies bounded searches. They are evidence and do not replace the proofs. 10 of the 25 runs produce counterexamples on purpose. |
| "Lean proves the same theorems as Isabelle." | Lean checks the contract core and the window-discard results. The placements, the range merge and degradation are proved in Isabelle only. |

## Artifact facts

- Zenodo version DOI: <code>10.5281/zenodo.22643866</code>
- Zenodo concept DOI: <code>10.5281/zenodo.22643865</code>
- Version: <code>1.0</code>
- Publication date: <code>2026-09-07</code>
- Archive: <code>Generalized_DBLog_artifact-1.0.zip</code>
- Archive SHA-256:
  <code>5009f27f51863ad5065dc3225f99eae0b43d3f1791cc4a1c62370838b0ffe8a5</code>
- 167 files: 48 Isabelle theory files in three sessions, 6 Lean files, 5 TLA+
  specifications with 25 TLC configurations, 3 typeset proof documents,
  verification records, and the unmodified upstream archive of the classic
  DBLog development.
- Checked with Isabelle2025-2, Lean 4.32.2, and TLC 2.19.
- No <code>axiomatization</code>, no <code>consts</code>, no proof oracles, and
  no unfinished proof in the Isabelle sources.
- One conservative source-coordinate <code>typedef</code>, in
  <code>formal/dual_write_layer0/Source_History.thy</code>.

## Verification commands

### Paper source

~~~bash
cd paper
pdflatex main
pdflatex main
pdflatex main
pdfinfo generalized-dblog.pdf
~~~

Expected public PDF: 38 pages, letter size, six figures.

### Verification artifact

~~~bash
cd formal
python3 reproduce.py checksums
python3 reproduce.py isabelle
python3 reproduce.py lean
python3 reproduce.py tlc --jar /absolute/path/to/tla2tools.jar
~~~

The Isabelle, Lean and TLC checks take time and need the tools named in
<code>formal/README.md</code>. Do not run them unless the user asked for a
build. Read the sources and the records under
<code>formal/verification/</code> instead.

### Deposit fidelity

Run from the repository root:

~~~bash
curl -sL -o artifact.zip https://zenodo.org/records/22643866/files/Generalized_DBLog_artifact-1.0.zip
unzip -q artifact.zip
diff -r Generalized_DBLog_artifact-1.0 formal
~~~

No output from <code>diff</code> means byte identity.

## Short summary

A short accurate summary is:

> The paper states a contract for change-data-capture pipelines that copy
> existing rows while they read the database's change log. If the source and
> the capture implementation satisfy the stated conditions, replaying the
> emitted events reconstructs the source's rows once copying and
> reconciliation are complete, without a single database snapshot. The paper
> places classic watermarking, Debezium's signal-table and read-only modes,
> Flink CDC's parallel chunks, and dump-based variants under this contract.
> The theory is machine-checked in Isabelle/HOL, its core is independently
> verified in Lean 4, and the protocols are examined by bounded model checking
> in TLA+.

Do not shorten this to "Debezium is verified" or "DBLog guarantees exactly-once
delivery."
