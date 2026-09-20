# Cross-verification table

This table maps every numbered object of the paper "Generalized
DBLog: A Verified Contract for Interleaving Copied Rows with a Change Log" to its mechanization and its model-checking
evidence. The paper prints 36 numbered objects: 9 definitions, 6
lemmas, 8 theorems, 4 corollaries, 6 propositions, and 3 worked
examples. The object list and the printed numbers below are read
from the paper build's own label record, not transcribed by hand;
theorems, corollaries, and propositions carry global numbers, while
definitions, lemmas, and examples are numbered per section.
(Terminology note, 2026-09-03: Obligation O2 is designated as
"bracket-local validity" in the paper text, formerly "bracket-local
honesty"; the DBLog import condition is named "read validity",
formerly "read honesty". Mechanization lemma names and ledger keys
retain their established identifiers, e.g. `mixing_shared_honesty_lift`.
Vocabulary map, paper to mechanization: "bracket-local validity" (O2)
= `honest`; "read result" / "merged result" = `verdict`; "shared state
witness" = the `shared_witness_trajectory` family.)

The verification artifacts and their scopes:

1. The paper states and proves all of its numbered objects in its
   own notation and is self-contained.
2. The Isabelle/HOL development in `framework_core/` mechanizes
   every definition, lemma, theorem, corollary, and proposition of
   the paper, including the instance studies and the degradation
   theory; it is the source of truth for the other layers.
3. The Lean 4 port in `lean/` re-proves the contract core in a
   second, independent proof kernel: the base model, the contract,
   the cut theorem with its three original corollaries, the torn-read witness,
   a partial tablesync fixture, the amortized shared bracket, and the
   window-discard discipline. Lemma 4.2, the complete Proposition 2
   sharpness bundle, the range-merge discipline, the instance studies,
   and the degradation theory remain Isabelle-only.
4. The TLA+ layer in `tla/` model-checks five specifications of the
   shipped protocols on small finite configurations. Model checking
   is evidence, never proof: green runs are complete searches at
   the stated bounds, and the mutation and probe runs re-discover
   the paper's countermodels.

Reading the table: Isabelle names resolve in `framework_core/`
theory files, Lean names in `lean/DBLogContract/`, and run
identifiers in `tla/RUNS.md`, which lists run outcomes and state
counts. In the release archive, `../verification/verified-inputs.json`
contains the verified source hashes, and the per-run logs in
`../verification/` contain the full TLC output, including counterexample
traces. "Isabelle only" in the Lean
column marks objects outside the port's chartered scope. In the TLC
column, claim-class objects cite the invariants and runs that check
them or state "not model-checked"; definitions are modeled rather
than checked, so their cells name the specifications whose header
maps carry them. The specification key: S1 `WatermarkLoop`, S2
`ReadOnlyBrackets`, S3 `ParallelChunks`, S4 `DumpSplice`, S5
`SharedWitnessMixing`.

| Object | Title | Isabelle (`framework_core/`) | Lean (`lean/`) | TLC (`tla/`) |
| --- | --- | --- | --- | --- |
| Definition 2.1 | Coordinate space | locale `coordinate_space` (Contract_Base) | structure `CoordinateSpace` | named in the S1, S4, S5 maps; S2 and S3 model the set-valued and offset readings |
| Definition 2.2 | Window | `win` (Contract_Base) | `CoordinateSpace.win` | named in the S1 map; S2's executed-set window is the subject of Theorem 7's row |
| Definition 3.1 | Capture plan | record `cunit`, locale `capture_plan` (Cut_Theorem) | structure `CUnit` | named in all five spec maps |
| Definition 3.2 | Source-side contract | locale `capture_contract` (Cut_Theorem) | structure `CaptureContract` | O2 is the read rule of all five specs; S5 checks the contract-level objects directly |
| Definition 4.1 | Canonical replay at a coordinate | `sink_at` (Cut_Theorem) | `sink_at` | named in the S3, S4, S5 maps |
| Definition 6.1 | Stream replay | `stream_replay` (Merge_Disciplines) | `stream_replay` | named in the S1, S2, S4 maps |
| Definition 6.2 | Survivors and window-discard emission | `survivors`, `emission` (Merge_Disciplines) | `survivors`, `emission` | named in the S1, S2, S4 maps; close-block placement reused in S3 |
| Definition 6.3 | Merged result | `merged` (Range_Merge) | Isabelle only | named in the S3 map |
| Definition 6.4 | Gated range-merge emission | `rm_emission` (Range_Merge) | Isabelle only | named in the S3 map |
| Lemma 4.1 | Window invariance | `win_invariant_state`, `win_invariant_state2` (Contract_Base) | `CoordinateSpace.win_invariant_state` | not model-checked (proof step inside the checked theorems) |
| Lemma 4.2 | Latest-high trajectory | `latest_high_exists`, `latest_high_trajectory` (Cut_Theorem). Totality is documented by `cle_total` (Contract_Base), while the proof selects `Max` over the natural-number denotations | Isabelle only | `LatestHighTrajectory` green in S5-B and `HighEdgeTrajectory` green in S4-B on bounded models. The general result is derived in Isabelle from the frontier-parametric cut theorem |
| Lemma 4.3 | Closed-unit cut | `contract_cut_unit` (Cut_Theorem): `contract_cut_at` with its high-edge bound weakened to the key's own unit | Isabelle only | not model-checked (a per-key instantiation of the cut theorem's workhorse) |
| Lemma 6.1 | Per-key shape of the discard emission | `titems_emission_master` (Merge_Disciplines) | `CaptureContract.titems_emission_master` | not model-checked (proof step toward Theorem 2) |
| Lemma 6.2 | The merged buffer is the state at the high edge | `merged_at_hi` (Range_Merge) | Isabelle only | content modeled in S3 (`MergedAt`); no dedicated invariant |
| Lemma 6.3 | Per-key shape of the gated emission | `titems_rm_emission_master` (Range_Merge) | Isabelle only | content modeled in S3 (close-block shape); no dedicated invariant |
| Theorem 1 | Cut theorem | `contract_cut`, workhorse `contract_cut_at`, scope form `contract_cut_scope` (Cut_Theorem) | `CaptureContract.contract_cut` (`_at`, `_scope`) | `FrontierExact` green in S1-A, S1-B, S2-A, S2-B, S2-D(0), S2-D(ii), S2-D(iii), S3-A, S3-B, S3-D, S4-A, S4-B; as `UnionCut` with Corollary 3 green in S5-A, S5-B; deliberately violated in S3-C and S4-C |
| Theorem 2 | Window-discard equivalence | `window_discard_replay` (Merge_Disciplines) | `CaptureContract.window_discard_replay` | inside `FrontierExact` of S1, S2, S4 (their emissions are the discard discipline) |
| Theorem 3 | Window-discard monotonicity | `window_discard_monotone` (Merge_Disciplines) | `CaptureContract.window_discard_monotone` | `PerKeyMonotone` green in S1-A, S1-B, S2-A, S2-B, S2-D(0) |
| Theorem 4 | Range-merge equivalence | `range_merge_replay` (Range_Merge) | Isabelle only | inside `FrontierExact` of S3 (green S3-A, S3-B, S3-D; violated in S3-C) |
| Theorem 5 | Range-merge monotonicity | `range_merge_monotone` (Range_Merge) | Isabelle only | `GatedMonotone` green in S3-A, S3-B, S3-D |
| Theorem 6 | Classic DBLog satisfies the contract | `classic_imports_upward` (part 1), `classic_sink_is_Src` (part 2) (Classic_Instance). This bridge is plan-level; no physical-output theorem is claimed without an additional real-upper-marker condition | Isabelle only | not model-checked; S1 models the classic protocol itself, not the import statement |
| Theorem 7 | Transaction-complete executed-set windows are faithful | `oracle_agreement` (ReadOnly_Instance) | Isabelle only | `OracleFaithful` green in S2-A, S2-B, S2-D(0); violated in S2-D(i), showing the boundary premise necessary |
| Theorem 8 | Degradation | `degraded_cut` and `degraded_trajectory_from_end` (part 1), `degraded_replay` and direct source equality `degraded_emitted_cut` (part 2), `trusted_point_is_degenerate_bracket` (part 3) (Dump_Splice_Instance). The restored scope is one engine-consistent state at one latent coordinate inside the bound | Isabelle only | S4-B green (`FrontierExact` and the safe canonical `HighEdgeTrajectory`); S4-C violated (wrong point trusted); S4-D violates the stronger `WidenedTrajectory` probe from the low bound. TLC does not model operational exhibition of the latent view |
| Corollary 1 | Shared witness | `shared_witness_trajectory`, engine `shared_witness_trajectory_at` (Cut_Theorem) | `CaptureContract.shared_witness_trajectory` | `SharedTrajectory` green in S5-A; `SpliceTrajectory` green in S4-A |
| Corollary 2 | Continuation | `continuation` (Cut_Theorem) | `CaptureContract.continuation` | `ContinuationExact` green in S1-A, S1-B, S2-A, S2-B, S2-D(0), S3-A, S3-B, S3-D |
| Corollary 3 | Mixing | `mixing_union`, lifts `mixing_shared_witness_lift`, `mixing_shared_honesty_lift` (Cut_Theorem) | `mixing_union` and both lifts | `UnionCut` green in S5-A, S5-B |
| Corollary 4 | Actual emitted replay at the frontier | `emitted_replay_cut` and scope form `emitted_replay_cut_scope` (Merge_Disciplines) | not in the current Lean port | Checked inside the final-replay invariants of S1, S2, S3, and S4. TLC checks concrete emitted constructions rather than the generic composition lemma |
| Proposition 1 | No shared read point | `wit_torn_contract`, `fix_torn_no_single_witness`, `wit_torn_cut` (Contract_Witnesses) | the same three names | `SharedInstantExists` violated as predicted in S1-C and S2-C; the trace is the torn read |
| Proposition 2 | Composition can lose every earlier onset | `wit_sync_composition_sharpness`, bundling `wit_sync_contract`, both one-member shared-witness results, `fix_sync_no_common_bracket_witness`, the exact strict-below-frontier statement `fix_sync_no_strictly_below_frontier_onset`, its equivalent fixture-specific helper `fix_sync_no_early_onset`, and `fix_sync_trajectory_breaks` (Contract_Witnesses) | partial fixture: `wit_sync_contract`, `fix_sync_no_early_onset`, `fix_sync_trajectory_breaks`, and the second-member result `wit_sync_memberB_T3` | `EarlyOnsetExists` violated in S3-E and `DistinctOnsetTrajectory` violated in S5-C. Both traces refute an onset earlier than the latest high, while the bounded green checks retain the canonical latest-high trajectory |
| Proposition 3 | Withholding is necessary | `fix_no_withholding_wrong`, `wit_rma_lawful_replay`, `wit_rma_lawful_absent` (Range_Merge) | Isabelle only | `FrontierExact` violated in S3-C under the window-narrowed clause (a); the lawful gate passes S3-B on the same fixture |
| Proposition 4 | Placement: read-only | `readonly_cut`, `readonly_window_discard`, `readonly_emitted_cut` (ReadOnly_Instance). This is the generic executed-set placement used directly by the conditional MySQL bridge. The MariaDB validated-quiet-point bridge is a separate point-plan use of the generic cut | Isabelle only | its executed-set placement content is S2's `FrontierExact`, green in S2-A and S2-B |
| Proposition 5 | Placement: parallel chunks | plan-level `parallel_cut` in `parallel_chunks_plan`; emission-level `parallel_replay`, `parallel_emitted_cut`, and `parallel_monotone` in the extending `parallel_chunks` locale (Parallel_Chunks_Instance). The plan locale does not assume handoff | Isabelle only | its placement content is S3's `FrontierExact`, green in S3-A, S3-B, S3-D |
| Proposition 6 | Placement: the trusted point splice | `splice_cut`, `splice_trajectory`, modeled `splice_replay`, and direct source equality `splice_emitted_cut` (Dump_Splice_Instance) | Isabelle only | S4-A green (`FrontierExact` and `SpliceTrajectory` at the trusted point) |
| Example 4.1 | Window replay | no dedicated object; a worked instance of Theorem 1's two replay cases | none | not model-checked |
| Example 5.1 | Composition across levels | no dedicated object; its constituent facts are the rows for Lemma 4.2, Corollaries 1 and 3, Proposition 2, and the witness lift | none | not model-checked |
| Example 7.1 | The degradation bracket at work | the `wit_degraded` witness family (Dump_Splice_Instance), which evaluates the example's replay | Isabelle only | not model-checked |

Three objects justify a remark. Theorem 6 relates the 2020
algorithm's original formalization to this paper's contract, so its
statement quantifies over runs of the published model; a finite
protocol model cannot check the import itself, and S1 instead
checks the protocol the theorem is about. The two shape lemmas 6.2
and 6.3 are proof steps whose content the S3 specification builds
in rather than asserts. The three examples are worked instances of
proved results and carry no claim of their own; Example 7.1's
arithmetic is nevertheless replayed by the mechanization's
degraded-bracket witness.


Build outcomes, input hashes, and full TLC logs are supplied in `../verification/`; `tla/RUNS.md` lists the fresh run outcomes.
