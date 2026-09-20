# Result index

This file lists the numbered results of the paper
"Generalized DBLog: A Verified Contract for Interleaving Copied Rows with a
Change Log" with their names in the Isabelle/HOL development.

The tables below were generated from
[formal/dblog_framework/CROSS_VERIFICATION.md](../formal/dblog_framework/CROSS_VERIFICATION.md),
which is part of the archived artifact. That file is authoritative. It also
covers the nine definitions, the three worked examples, the Lean names and the
TLC runs. Each Isabelle name listed here was checked to be a declared theorem
or lemma in the named theory file.

The short titles are labels. They are not formal statements. For citation or
technical comparison, read the result in <code>paper/main.tex</code> and the
Isabelle statement with its assumptions. The Isabelle source is authoritative.

Theory files are in
[formal/dblog_framework/framework_core/](../formal/dblog_framework/framework_core/).
The column "Lean" says whether the independent Lean 4 development in
[formal/dblog_framework/lean/](../formal/dblog_framework/lean/) also proves the
result.

## Theorems

| Result | Title | Isabelle names | Theory | Lean |
|---|---|---|---|---|
| Theorem 1 | Cut theorem | <code>contract_cut</code>, <code>contract_cut_at</code>, <code>contract_cut_scope</code> | <code>Cut_Theorem.thy</code> | yes |
| Theorem 2 | Window-discard equivalence | <code>window_discard_replay</code> | <code>Merge_Disciplines.thy</code> | yes |
| Theorem 3 | Window-discard monotonicity | <code>window_discard_monotone</code> | <code>Merge_Disciplines.thy</code> | yes |
| Theorem 4 | Range-merge equivalence | <code>range_merge_replay</code> | <code>Range_Merge.thy</code> | no |
| Theorem 5 | Range-merge monotonicity | <code>range_merge_monotone</code> | <code>Range_Merge.thy</code> | no |
| Theorem 6 | Classic DBLog satisfies the contract | <code>classic_imports_upward</code>, <code>classic_sink_is_Src</code> | <code>Classic_Instance.thy</code> | no |
| Theorem 7 | Transaction-complete executed-set windows are faithful | <code>oracle_agreement</code> | <code>ReadOnly_Instance.thy</code> | no |
| Theorem 8 | Degradation | <code>degraded_cut</code>, <code>degraded_trajectory_from_end</code>, <code>degraded_replay</code>, <code>degraded_emitted_cut</code>, <code>trusted_point_is_degenerate_bracket</code> | <code>Dump_Splice_Instance.thy</code> | no |

## Corollaries

| Result | Title | Isabelle names | Theory | Lean |
|---|---|---|---|---|
| Corollary 1 | Shared witness | <code>shared_witness_trajectory</code>, <code>shared_witness_trajectory_at</code> | <code>Cut_Theorem.thy</code> | yes |
| Corollary 2 | Continuation | <code>continuation</code> | <code>Cut_Theorem.thy</code> | yes |
| Corollary 3 | Mixing | <code>mixing_union</code>, <code>mixing_shared_witness_lift</code>, <code>mixing_shared_honesty_lift</code> | <code>Cut_Theorem.thy</code> | yes |
| Corollary 4 | Actual emitted replay at the frontier | <code>emitted_replay_cut</code>, <code>emitted_replay_cut_scope</code> | <code>Merge_Disciplines.thy</code> | no |

## Propositions

| Result | Title | Isabelle names | Theory | Lean |
|---|---|---|---|---|
| Proposition 1 | No shared read point | <code>wit_torn_contract</code>, <code>fix_torn_no_single_witness</code>, <code>wit_torn_cut</code> | <code>Contract_Witnesses.thy</code> | yes |
| Proposition 2 | Composition can lose every earlier onset | <code>wit_sync_composition_sharpness</code>, <code>wit_sync_contract</code>, <code>fix_sync_no_common_bracket_witness</code>, <code>fix_sync_no_strictly_below_frontier_onset</code>, <code>fix_sync_no_early_onset</code>, <code>fix_sync_trajectory_breaks</code> | <code>Contract_Witnesses.thy</code> | partly |
| Proposition 3 | Withholding is necessary | <code>fix_no_withholding_wrong</code>, <code>wit_rma_lawful_replay</code>, <code>wit_rma_lawful_absent</code> | <code>Range_Merge.thy</code> | no |
| Proposition 4 | Placement: read-only | <code>readonly_cut</code>, <code>readonly_window_discard</code>, <code>readonly_emitted_cut</code> | <code>ReadOnly_Instance.thy</code> | no |
| Proposition 5 | Placement: parallel chunks | <code>parallel_cut</code>, <code>parallel_replay</code>, <code>parallel_emitted_cut</code>, <code>parallel_monotone</code> | <code>Parallel_Chunks_Instance.thy</code> | no |
| Proposition 6 | Placement: the trusted point splice | <code>splice_cut</code>, <code>splice_trajectory</code>, <code>splice_replay</code>, <code>splice_emitted_cut</code> | <code>Dump_Splice_Instance.thy</code> | no |

## Lemmas

| Result | Title | Isabelle names | Theory | Lean |
|---|---|---|---|---|
| Lemma 4.1 | Window invariance | <code>win_invariant_state</code>, <code>win_invariant_state2</code> | <code>Contract_Base.thy</code> | yes |
| Lemma 4.2 | Latest-high trajectory | <code>latest_high_exists</code>, <code>latest_high_trajectory</code> | <code>Cut_Theorem.thy</code> | no |
| Lemma 4.3 | Closed-unit cut | <code>contract_cut_unit</code> | <code>Cut_Theorem.thy</code> | no |
| Lemma 6.1 | Per-key shape of the discard emission | <code>titems_emission_master</code> | <code>Merge_Disciplines.thy</code> | yes |
| Lemma 6.2 | The merged buffer is the state at the high edge | <code>merged_at_hi</code> | <code>Range_Merge.thy</code> | no |
| Lemma 6.3 | Per-key shape of the gated emission | <code>titems_rm_emission_master</code> | <code>Range_Merge.thy</code> | no |

## The three verification layers

- **Isabelle/HOL** proves the normalized mathematical form of every numbered
  definition and result, including the five placements and degradation.
- **Lean 4** independently proves the contract core, the cut theorem with its
  first three corollaries, window invariance, the window-discard results, and
  the no-shared-read-point witness. It does not cover every placement or the
  range merge.
- **TLA+** model-checks five specifications of the protocols in 25 bounded TLC
  runs. 15 complete with no invariant violation. 10 produce the
  counterexamples they were built to produce. Model checking gives evidence.
  It is not a proof.

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
