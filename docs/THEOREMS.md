# Result index

This file lists the numbered results of the paper
"Generalized DBLog: A Verified Contract for Interleaving Copied Rows with a
Change Log" with their names in the Isabelle/HOL development.

The tables below were generated from
[formal/dblog_framework/CROSS_VERIFICATION.md](../formal/dblog_framework/CROSS_VERIFICATION.md),
which is part of the archived artifact. That file also covers the nine
definitions, the three worked examples, the Lean names and the TLC runs. Each
Isabelle name listed here is a declared theorem or lemma in the named theory
file.

The short titles are labels that omit assumptions. They are not formal
statements. For citation or technical comparison, read the result in
`paper/main.tex` and the Isabelle statements themselves, which are
authoritative.

Theory files are in
[formal/dblog_framework/framework_core/](../formal/dblog_framework/framework_core/).
The column "Lean" says whether the independent Lean 4 development in
[formal/dblog_framework/lean/](../formal/dblog_framework/lean/) also proves the
result.

## Theorems

| Result | Title | Isabelle names | Theory | Lean |
|---|---|---|---|---|
| Theorem 1 | Cut theorem | `contract_cut`, `contract_cut_at`, `contract_cut_scope` | `Cut_Theorem.thy` | yes |
| Theorem 2 | Window-discard equivalence | `window_discard_replay` | `Merge_Disciplines.thy` | yes |
| Theorem 3 | Window-discard monotonicity | `window_discard_monotone` | `Merge_Disciplines.thy` | yes |
| Theorem 4 | Range-merge equivalence | `range_merge_replay` | `Range_Merge.thy` | no |
| Theorem 5 | Range-merge monotonicity | `range_merge_monotone` | `Range_Merge.thy` | no |
| Theorem 6 | Classic DBLog satisfies the contract | `classic_imports_upward`, `classic_sink_is_Src` | `Classic_Instance.thy` | no |
| Theorem 7 | Transaction-complete executed-set windows are faithful | `oracle_agreement` | `ReadOnly_Instance.thy` | no |
| Theorem 8 | Degradation | `degraded_cut`, `degraded_trajectory_from_end`, `degraded_replay`, `degraded_emitted_cut`, `trusted_point_is_degenerate_bracket` | `Dump_Splice_Instance.thy` | no |

## Corollaries

| Result | Title | Isabelle names | Theory | Lean |
|---|---|---|---|---|
| Corollary 1 | Shared witness | `shared_witness_trajectory`, `shared_witness_trajectory_at` | `Cut_Theorem.thy` | yes |
| Corollary 2 | Continuation | `continuation` | `Cut_Theorem.thy` | yes |
| Corollary 3 | Mixing | `mixing_union`, `mixing_shared_witness_lift`, `mixing_shared_honesty_lift` | `Cut_Theorem.thy` | yes |
| Corollary 4 | Actual emitted replay at the frontier | `emitted_replay_cut`, `emitted_replay_cut_scope` | `Merge_Disciplines.thy` | no |

## Propositions

| Result | Title | Isabelle names | Theory | Lean |
|---|---|---|---|---|
| Proposition 1 | No shared read point | `wit_torn_contract`, `fix_torn_no_single_witness`, `wit_torn_cut` | `Contract_Witnesses.thy` | yes |
| Proposition 2 | Composition can lose every earlier onset | `wit_sync_composition_sharpness`, `wit_sync_contract`, `fix_sync_no_common_bracket_witness`, `fix_sync_no_strictly_below_frontier_onset`, `fix_sync_no_early_onset`, `fix_sync_trajectory_breaks` | `Contract_Witnesses.thy` | partly |
| Proposition 3 | Withholding is necessary | `fix_no_withholding_wrong`, `wit_rma_lawful_replay`, `wit_rma_lawful_absent` | `Range_Merge.thy` | no |
| Proposition 4 | Placement: read-only | `readonly_cut`, `readonly_window_discard`, `readonly_emitted_cut` | `ReadOnly_Instance.thy` | no |
| Proposition 5 | Placement: parallel chunks | `parallel_cut`, `parallel_replay`, `parallel_emitted_cut`, `parallel_monotone` | `Parallel_Chunks_Instance.thy` | no |
| Proposition 6 | Placement: the trusted point splice | `splice_cut`, `splice_trajectory`, `splice_replay`, `splice_emitted_cut` | `Dump_Splice_Instance.thy` | no |

## Lemmas

| Result | Title | Isabelle names | Theory | Lean |
|---|---|---|---|---|
| Lemma 4.1 | Window invariance | `win_invariant_state`, `win_invariant_state2` | `Contract_Base.thy` | yes |
| Lemma 4.2 | Latest-high trajectory | `latest_high_exists`, `latest_high_trajectory` | `Cut_Theorem.thy` | no |
| Lemma 4.3 | Closed-unit cut | `contract_cut_unit` | `Cut_Theorem.thy` | no |
| Lemma 6.1 | Per-key shape of the discard emission | `titems_emission_master` | `Merge_Disciplines.thy` | yes |
| Lemma 6.2 | The merged buffer is the state at the high edge | `merged_at_hi` | `Range_Merge.thy` | no |
| Lemma 6.3 | Per-key shape of the gated emission | `titems_rm_emission_master` | `Range_Merge.thy` | no |

## The three verification layers

- **Isabelle/HOL** proves the normalized mathematical form of every numbered
  definition and result, including the five placements and degradation.
- **Lean 4** independently proves the contract core, the cut theorem with its
  first three corollaries, window invariance, the window-discard results, and
  the no-shared-read-point witness. It does not cover every placement or the
  range merge.
- **TLA+** model-checks five specifications of the protocols in 25 bounded TLC
  runs. 15 complete with no invariant violation. 10 produce the
  counterexamples they were built to produce. Model checking gives evidence
  rather than a proof.

## What the results do not say

Kernel checking establishes the formal results under their assumptions. It
does not establish that a running connector satisfies complete observation,
correct source coordinates, read validity, representation agreement, or
recovery conditions. Transport, populated-sink repairs, and end-to-end delivery
are outside the verified contract. The paper evaluates protocol designs. It
does not certify a software release. Section 12 of the paper, "Scope and
Limitations", lists the assumptions for each analyzed protocol.

## Citation rule

When citing a result, include:

1. the paper result number and title,
2. the conditions of the contract or of the placement that the result assumes,
3. the verification layer you rely on: Isabelle, Lean, or bounded model checking.

Do not cite the one-line title alone.
