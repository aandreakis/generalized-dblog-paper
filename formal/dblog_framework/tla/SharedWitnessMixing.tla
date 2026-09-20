------------------------ MODULE SharedWitnessMixing ------------------------
(***************************************************************************)
(* Mixing and the shared witness, checked at the contract level.           *)
(*                                                                         *)
(* This specification extends the redundancy layer of the paper            *)
(* "Generalized DBLog: A Verified Contract for Interleaving Database       *)
(* Copies with Change Logs".  The sibling specifications check the         *)
(* through the emission disciplines; this one checks the contract-level    *)
(* objects directly: the canonical replay of Definition 4.1, the union of  *)
(* two plans over disjoint scopes (Corollary 3 with Theorem 1), and the    *)
(* shared-witness trajectory (Corollary 1).  Model checking on small       *)
(* configurations is evidence, never proof.                                *)
(*                                                                         *)
(* The plan is the heterogeneous composite of the paper's mixing figure,   *)
(* reduced to its contract content: provenance never enters the plan, so   *)
(* what remains of heterogeneity is bracket shape and witness placement.   *)
(* Unit 1 covers one part of the scope behind a span bracket, its reads    *)
(* honest at one witness inside the span.  Unit 2 covers the rest behind   *)
(* a point bracket at its own witness.  Nothing is written; brackets are   *)
(* observed positions.                                                     *)
(*                                                                         *)
(* Witness modes, selected by the configuration:                           *)
(*                                                                         *)
(*   "shared"    Unit 2's point is unit 1's witness: one coordinate is a   *)
(*               shared read witness for the whole composite plan.         *)
(*               Corollary 1 then lifts the composite to the full          *)
(*               trajectory property, checked as an invariant.             *)
(*   "distinct"  Each unit is honest at its own witness.  The composite    *)
(*               still satisfies the contract and its cut holds            *)
(*               (Corollary 3 with Theorem 1, checked green), but the      *)
(*               trajectory claim from the earliest witness FAILS.  This   *)
(*               is a stronger earlier-onset probe in Proposition 2's      *)
(*               shape; S3-E checks the proposition's exact claim.  The    *)
(*               canonical latest-high trajectory is checked separately.  *)
(*                                                                         *)
(* Mapping from spec objects to paper objects:                             *)
(*                                                                         *)
(*   log, SrcAt                Section 2.1: events, per-key fold sigma     *)
(*   positions as coordinates  Definition 2.1: prefix denotations          *)
(*   Dom1/lo1/hi1/R1,          Definition 3.1: two units over disjoint     *)
(*   Dom2/w2/R2                domains; unit 2's bracket is the point      *)
(*                             (w2, w2]                                    *)
(*   ReadUnit1, ReadUnit2      O2 honesty, here at one instant per unit    *)
(*   CanonicalSinkAt           Definition 4.1: the canonical replay at a   *)
(*                             coordinate, per key through its owning      *)
(*                             unit                                        *)
(*   UnionCut                  Corollary 3 with Theorem 1: the combined    *)
(*                             plan's replay equals the source state at    *)
(*                             the frontier on the union of the scopes     *)
(*   SharedTrajectory          Corollary 1: with the shared witness, the   *)
(*                             canonical replay is a true source history   *)
(*                             from the witness onward                     *)
(*   LatestHighTrajectory      Lemma 4.2 on a nonempty plan: the canonical *)
(*                             replay is a true source history from the    *)
(*                             maximal unit high edge onward               *)
(*   DistinctOnsetTrajectory   stronger earlier-onset probe, EXPECTED TO   *)
(*                             FAIL in "distinct" mode: trajectory from    *)
(*                             the earliest witness; exact claim is S3-E   *)
(*                                                                         *)
(* Premises built in: S-LOG and S-IMG as in the sibling specs.  The        *)
(* shared-mode read of unit 2 at a past coordinate models a shared         *)
(* engine snapshot: the read view is the state at the shared witness,     *)
(* which the paper lists as one of the three mechanisms producing a        *)
(* shared witness.                                                         *)
(***************************************************************************)
EXTENDS Integers, Sequences, FiniteSets

CONSTANTS
  Keys,        \* the combined scope
  Vals,        \* the value domain
  NULL,        \* the absence verdict; img NULL is a delete
  MaxEvents,   \* bound on committed data events
  Dom1,        \* unit 1's domain
  Dom2,        \* unit 2's domain
  WitnessMode  \* "shared" | "distinct"

ASSUME NullNotAValue == NULL \notin Vals
ASSUME MaxEventsNat  == MaxEvents \in Nat
ASSUME DomsPartition ==
  /\ Dom1 \subseteq Keys /\ Dom2 \subseteq Keys
  /\ Dom1 \cup Dom2 = Keys
  /\ Dom1 \cap Dom2 = {}
  /\ Dom1 # {} /\ Dom2 # {}
ASSUME ModeOK == WitnessMode \in {"shared", "distinct"}

Img == Vals \cup {NULL}

VARIABLES
  log,      \* the committed history: data events
  nData,    \* count of committed data events
  r1done,   \* unit 1 read
  r2done,   \* unit 2 read
  lo1, hi1, \* unit 1's span bracket (observed positions)
  w1,       \* unit 1's witness, inside its bracket
  w2,       \* unit 2's witness; its bracket is the point (w2, w2]
  R1, R2    \* the refresh verdicts

vars == <<log, nData, r1done, r2done, lo1, hi1, w1, w2, R1, R2>>

DataEntry(k, v) == [key |-> k, img |-> v]

SrcAt(n) ==
  [k \in Keys |->
     LET ps == {p \in 1..n : log[p].key = k}
     IN IF ps = {} THEN NULL
        ELSE log[CHOOSE p \in ps : \A q \in ps : q <= p].img]

Init ==
  /\ log = <<>>
  /\ nData = 0
  /\ r1done = FALSE
  /\ r2done = FALSE
  /\ lo1 = 0 /\ hi1 = 0 /\ w1 = 0 /\ w2 = 0
  /\ R1 = [k \in Dom1 |-> NULL]
  /\ R2 = [k \in Dom2 |-> NULL]

(* One complete single-row transaction commits atomically. The model has
   no pending or uncommitted event state. *)
Commit(k, v) ==
  /\ nData < MaxEvents
  /\ log' = Append(log, DataEntry(k, v))
  /\ nData' = nData + 1
  /\ UNCHANGED <<r1done, r2done, lo1, hi1, w1, w2, R1, R2>>

(* Unit 1 reads its domain at one witness inside an observed span
   bracket.  The bracket edges and the witness are chosen
   nondeterministically over the committed history, so TLC searches
   every placement. *)
ReadUnit1 ==
  /\ ~r1done
  /\ \E l \in 0..Len(log) : \E w \in l..Len(log) : \E h \in w..Len(log) :
       /\ lo1' = l /\ w1' = w /\ hi1' = h
       /\ R1' = [k \in Dom1 |-> SrcAt(w)[k]]
  /\ r1done' = TRUE
  /\ UNCHANGED <<log, nData, r2done, w2, R2>>

(* Unit 2 reads its domain behind a point bracket at its witness.  In
   "shared" mode the witness IS unit 1's witness and the read view is
   the state there (a shared engine snapshot); in "distinct" mode the
   witness is its own, chosen over the committed history. *)
ReadUnit2 ==
  /\ ~r2done
  /\ CASE WitnessMode = "shared" ->
            /\ r1done
            /\ w2' = w1
            /\ R2' = [k \in Dom2 |-> SrcAt(w1)[k]]
       [] WitnessMode = "distinct" ->
            \E w \in 0..Len(log) :
              /\ w2' = w
              /\ R2' = [k \in Dom2 |-> SrcAt(w)[k]]
  /\ r2done' = TRUE
  /\ UNCHANGED <<log, nData, r1done, lo1, hi1, w1, R1>>

Next ==
  \/ \E k \in Keys, v \in Img : Commit(k, v)
  \/ ReadUnit1
  \/ ReadUnit2

Spec == Init /\ [][Next]_vars

----------------------------------------------------------------------------
(* Properties. *)

Frontier == Len(log)

Done == nData = MaxEvents /\ r1done /\ r2done

(* Definition 4.1 through the owning unit: the last event for the key
   after its unit's low edge wins; absent any, the unit's refresh
   verdict stands.  Unit 2's low edge is its point w2. *)
LoOf(k) == IF k \in Dom1 THEN lo1 ELSE w2
ROf(k)  == IF k \in Dom1 THEN R1[k] ELSE R2[k]

CanonicalSinkAt(g) ==
  [k \in Keys |->
     LET ps == {p \in 1..g : LoOf(k) < p /\ log[p].key = k}
     IN IF ps = {} THEN ROf(k)
        ELSE log[CHOOSE p \in ps : \A q \in ps : q <= p].img]

TypeOK ==
  /\ nData \in 0..MaxEvents
  /\ \A p \in 1..Len(log) : log[p] \in [key : Keys, img : Img]
  /\ lo1 \in 0..Len(log) /\ w1 \in 0..Len(log) /\ hi1 \in 0..Len(log)
  /\ w2 \in 0..Len(log)
  /\ (r1done => (lo1 <= w1 /\ w1 <= hi1))

(* Corollary 3 with Theorem 1: once both units are read, the combined
   plan's canonical replay at the frontier equals the source state on
   every key of the union.  EXPECTED TO HOLD in both modes: distinct
   witnesses keep the composite in contract. *)
UnionCut ==
  Done => \A k \in Keys :
    CanonicalSinkAt(Frontier)[k] = SrcAt(Frontier)[k]

(* Corollary 1, checked positively in "shared" mode: from the shared
   witness onward, the canonical replay is a true source history at
   EVERY coordinate, not only at the frontier. *)
SharedTrajectory ==
  (r1done /\ r2done) =>
    \A g \in w1..Frontier :
      \A k \in Keys : CanonicalSinkAt(g)[k] = SrcAt(g)[k]

(* Lemma 4.2's safe canonical trajectory for this nonempty two-unit
   plan.  Distinct witnesses do not remove it.  Unit 1's high edge is
   hi1 and unit 2's point bracket has high edge w2. *)
MaxHi == IF hi1 <= w2 THEN w2 ELSE hi1

LatestHighTrajectory ==
  (r1done /\ r2done) =>
    \A g \in MaxHi..Frontier :
      \A k \in Keys : CanonicalSinkAt(g)[k] = SrcAt(g)[k]

(* A stronger earlier-onset target, EXPECTED TO FAIL in "distinct"
   mode: the trajectory claim from the earliest witness.  TLC's
   counterexample is the tablesync shape: the later unit's verdict,
   honest at its own witness, is not source history at coordinates
   below it.  The exact existential strict-below-frontier property is
   checked by EarlyOnsetExists in ParallelChunks.tla. *)
MinW == IF w1 <= w2 THEN w1 ELSE w2

DistinctOnsetTrajectory ==
  (r1done /\ r2done) =>
    \A g \in MinW..Frontier :
      \A k \in Keys : CanonicalSinkAt(g)[k] = SrcAt(g)[k]

----------------------------------------------------------------------------
(* Model configurations (selected by the .cfg files). *)

MainKeys == {1, 2, 3}
MainVals == {1, 2}
MainDom1 == {1, 2}
MainDom2 == {3}

============================================================================
