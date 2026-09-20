---------------------------- MODULE DumpSplice ----------------------------
(***************************************************************************)
(* The native-dump splice and its degradation, modeled for TLC.            *)
(*                                                                         *)
(* This specification extends the redundancy layer of the paper            *)
(* "Generalized DBLog: A Verified Contract for Interleaving Database       *)
(* Copies with Change Logs" to the fifth instance family: a dump taken     *)
(* coordinate, spliced into the log behind a bracket.  The paper proves    *)
(* the splice placement and the degradation theorem for arbitrary          *)
(* configurations; TLC re-checks the same claims exhaustively on small     *)
(* configurations.  Model checking on small configurations is evidence,    *)
(* never proof.                                                            *)
(*                                                                         *)
(* The protocol: the source is dumped atomically at its true coordinate    *)
(* d, so the dump rows are the source state at d.  A tool asserts a        *)
(* recovery coordinate for the dump.  The plan carries one unit over the   *)
(* dumped scope whose bracket depends on how far the assertion is          *)
(* trusted, and the emission is the window-discard pass over the whole     *)
(* log with the dump rows as the unit's refresh.                           *)
(*                                                                         *)
(* Bracket modes, selected by the configuration:                           *)
(*                                                                         *)
(*   "trusted"     The asserted point is the true d and is trusted: a      *)
(*                 point bracket (d, d].  This is the splice placement     *)
(*                 (Proposition 6's shape): the cut holds and the replay   *)
(*                 is a true source history from d onward.                 *)
(*   "degraded"    The assertion is NOT trusted (its named assumption is   *)
(*                 dropped).  The bracket widens to a span [bstart,        *)
(*                 brecover] that provably contains d: backup started at   *)
(*                 or before d, recovery completed at or after d.  This    *)
(*                 is Theorem 8: the widened plan still satisfies the      *)
(*                 contract, because the dump rows are honest AT d and d   *)
(*                 lies inside the widened bracket, so the cut still       *)
(*                 holds.  A safe canonical trajectory also holds from     *)
(*                 brecover, the high edge.  The stronger claim beginning  *)
(*                 at bstart is not made, and the probe run refutes it.     *)
(*   "wrongpoint"  The mutation: a wrong asserted point is trusted with    *)
(*                 a degenerate point bracket.  The contract's honesty     *)
(*                 obligation fails, and TLC finds the wrong replay.       *)
(*                                                                         *)
(* Mapping from spec objects to paper objects:                             *)
(*                                                                         *)
(*   log, DataEntry, SrcAt     Section 2.1: events, per-key fold sigma     *)
(*   positions as coordinates  Definition 2.1: prefix denotations          *)
(*   blo, bhi, R               Definition 3.1: the one dump unit           *)
(*   TakeDump                  the dump read, honest at the true d; in     *)
(*                             "trusted" mode the point bracket is O4's    *)
(*                             asserted coordinate taken as true           *)
(*   Survivors, CloseBlock,    Definition 6.2: the window-discard          *)
(*   Consume                   emission over the consumed log              *)
(*   ReplayOf                  Definition 6.1: stream replay               *)
(*   CanonicalSinkAt           Definition 4.1: the canonical replay at a   *)
(*                             coordinate (sink_at), used for the          *)
(*                             trajectory facets                           *)
(*   FrontierExact             Theorem 1 with Theorem 2 at the frontier    *)
(*   SpliceTrajectory          Corollary 1 at the instance: from the       *)
(*                             true dump coordinate onward the canonical   *)
(*                             replay is a true source history             *)
(*   HighEdgeTrajectory        Lemma 4.2 / Theorem 8: in degraded mode the *)
(*                             canonical replay is a true source history   *)
(*                             from the known high edge onward             *)
(*   WidenedTrajectory         the probe target for "degraded" mode,       *)
(*                             EXPECTED TO FAIL there: the trajectory      *)
(*                             claim from the low edge of the widened      *)
(*                             bracket.  It is stronger than the safe      *)
(*                             high-edge result                            *)
(*                                                                         *)
(* Premises built in: S-LOG and S-IMG as in the sibling specs; the dump    *)
(* is atomic at d (native dumps are consistent reads); consumption is a    *)
(* single pass over the whole log (s0 at position 0).  Per-key             *)
(* monotonicity is not re-checked here: it is discipline-generic and       *)
(* checked in the sibling specs.                                           *)
(* TLC stores the latent true coordinate dpos and can evaluate equations   *)
(* that mention it.  It does not model whether an operational capture      *)
(* knows or can exhibit dpos as evidence.                                  *)
(***************************************************************************)
EXTENDS Integers, Sequences, FiniteSets

CONSTANTS
  Keys,        \* the dumped scope
  Vals,        \* the value domain
  NULL,        \* the absence verdict; img NULL is a delete
  MaxEvents,   \* bound on committed data events
  BracketMode  \* "trusted" | "degraded" | "wrongpoint"

ASSUME NullNotAValue == NULL \notin Vals
ASSUME MaxEventsNat  == MaxEvents \in Nat
ASSUME ModeOK ==
  BracketMode \in {"trusted", "degraded", "wrongpoint"}

Img == Vals \cup {NULL}

VARIABLES
  log,       \* the committed history: data events only (no watermarks)
  nData,     \* count of committed data events
  dtaken,    \* whether the dump has been taken
  dpos,      \* the TRUE dump coordinate d
  R,         \* the dump rows: the unit's refresh
  blo, bhi,  \* the unit's bracket edges, set per BracketMode
  closed,    \* whether the unit's close block has been emitted
  cpos,      \* the consumer's position in the single pass
  emission   \* the emitted stream

vars == <<log, nData, dtaken, dpos, R, blo, bhi, closed, cpos, emission>>

DataEntry(k, v) == [key |-> k, img |-> v]

SrcAt(n) ==
  [k \in Keys |->
     LET ps == {p \in 1..n : log[p].key = k}
     IN IF ps = {} THEN NULL
        ELSE log[CHOOSE p \in ps : \A q \in ps : q <= p].img]

Init ==
  /\ log = <<>>
  /\ nData = 0
  /\ dtaken = FALSE
  /\ dpos = 0
  /\ R = [k \in Keys |-> NULL]
  /\ blo = 0
  /\ bhi = 0
  /\ closed = FALSE
  /\ cpos = 0
  /\ emission = <<>>

(* One complete single-row transaction commits atomically. The model has
   no pending or uncommitted event state. *)
Commit(k, v) ==
  /\ nData < MaxEvents
  /\ log' = Append(log, DataEntry(k, v))
  /\ nData' = nData + 1
  /\ UNCHANGED <<dtaken, dpos, R, blo, bhi, closed, cpos, emission>>

(* The dump: an atomic read of the whole scope at the true coordinate
   d.  In "trusted" and "wrongpoint" modes the dump is taken at the
   current log end.  In "degraded" mode the restore completes now, at
   the current log end, and the backup's content dates from a true
   view d chosen nondeterministically at or before it, so events
   between d and the recovery edge are in the window and newer than
   the dump rows; the bracket is every span satisfying the
   uncertainty bound: backup start at or before d, recovery point the
   current end, at or after d.  TLC searches every such span.
   "trusted" places the point bracket at d itself.  "wrongpoint"
   trusts a nondeterministically chosen WRONG point with a degenerate
   bracket.  The dump happens before the consumer starts, as a
   restore does. *)
TakeDump ==
  /\ ~dtaken
  /\ cpos = 0
  /\ dtaken' = TRUE
  /\ CASE BracketMode = "trusted" ->
            (dpos' = Len(log) /\ R' = SrcAt(Len(log))
              /\ blo' = Len(log) /\ bhi' = Len(log))
       [] BracketMode = "degraded" ->
            (\E v \in 0..Len(log) : \E s \in 0..v :
              dpos' = v /\ R' = SrcAt(v)
              /\ blo' = s /\ bhi' = Len(log))
       [] BracketMode = "wrongpoint" ->
            (\E a \in 0..MaxEvents :
              a # Len(log) /\ dpos' = Len(log) /\ R' = SrcAt(Len(log))
              /\ blo' = a /\ bhi' = a)
  /\ UNCHANGED <<log, nData, closed, cpos, emission>>

(* Definition 6.2 over the one unit: survivors are keys read as
   present with no event inside the bracket's window. *)
WindowEvents(k) ==
  {p \in 1..Len(log) : blo < p /\ p <= bhi /\ log[p].key = k}

Survivors ==
  {k \in Keys : R[k] # NULL /\ WindowEvents(k) = {}}

RECURSIVE SeqOf(_)
SeqOf(S) ==
  IF S = {} THEN <<>>
  ELSE LET x == CHOOSE y \in S : TRUE IN <<x>> \o SeqOf(S \ {x})

CloseBlock ==
  LET ks == SeqOf(Survivors)
  IN [j \in 1..Len(ks) |->
       [key |-> ks[j], img |-> R[ks[j]]]]

(* The single pass.  The unit closes immediately before the first
   consumed event beyond bhi, or at the end of the pass; with a point
   bracket at d this splices the dump exactly at d.  The consumer runs
   only after the dump is taken, as a restore-then-follow does.  A
   bracket asserted beyond the eventual history never closes, and the
   run never reaches Done: an honest dead end, not a verdict. *)
Consume ==
  /\ dtaken
  /\ cpos < Len(log)
  /\ LET p == cpos + 1
         atc == bhi = cpos /\ ~closed
         pre == IF atc THEN CloseBlock ELSE <<>>
     IN /\ emission' = emission \o pre \o
             <<[key |-> log[p].key, img |-> log[p].img]>>
        /\ closed' = (closed \/ bhi = cpos)
  /\ cpos' = cpos + 1
  /\ UNCHANGED <<log, nData, dtaken, dpos, R, blo, bhi>>

CloseAtEnd ==
  /\ dtaken
  /\ ~closed
  /\ cpos = Len(log)
  /\ bhi = cpos
  /\ closed' = TRUE
  /\ emission' = emission \o CloseBlock
  /\ UNCHANGED <<log, nData, dtaken, dpos, R, blo, bhi, cpos>>

Next ==
  \/ \E k \in Keys, v \in Img : Commit(k, v)
  \/ TakeDump
  \/ Consume
  \/ CloseAtEnd

Spec == Init /\ [][Next]_vars

----------------------------------------------------------------------------
(* Properties. *)

ReplayOf(em) ==
  [k \in Keys |->
     LET js == {j \in 1..Len(em) : em[j].key = k}
     IN IF js = {} THEN NULL
        ELSE em[CHOOSE j \in js : \A q \in js : q <= j].img]

Frontier == Len(log)

Done ==
  /\ nData = MaxEvents
  /\ dtaken
  /\ cpos = Len(log)
  /\ closed

(* Definition 4.1 at this plan: the canonical replay at position g.
   The last event for the key after the bracket's low edge wins;
   absent any, the dump verdict stands. *)
CanonicalSinkAt(g) ==
  [k \in Keys |->
     LET ps == {p \in 1..g : blo < p /\ log[p].key = k}
     IN IF ps = {} THEN R[k]
        ELSE log[CHOOSE p \in ps : \A q \in ps : q <= p].img]

TypeOK ==
  /\ nData \in 0..MaxEvents
  /\ \A p \in 1..Len(log) : log[p] \in [key : Keys, img : Img]
  /\ dpos \in 0..Len(log)
  /\ closed \in BOOLEAN
  /\ cpos \in 0..Len(log)
  /\ \A j \in 1..Len(emission) : emission[j] \in [key : Keys, img : Img]

(* Theorem 1 with Theorem 2 at the frontier. In "trusted" and
   "degraded" modes this is EXPECTED TO HOLD; in "wrongpoint" mode it
   is the mutation target and TLC finds the wrong replay. *)
FrontierExact ==
  Done => \A k \in Keys : ReplayOf(emission)[k] = SrcAt(Frontier)[k]

(* Corollary 1 at the instance (the splice placement): from the true
   dump coordinate onward, the canonical replay is a true source
   history.  Checked in "trusted" mode, where the bracket sits at d. *)
SpliceTrajectory ==
  dtaken => \A g \in dpos..Frontier :
    \A k \in Keys : CanonicalSinkAt(g)[k] = SrcAt(g)[k]

(* The safe canonical trajectory retained in degraded mode begins at the
   recorded high edge, not at the low edge of the uncertainty span. *)
HighEdgeTrajectory ==
  dtaken => \A g \in bhi..Frontier :
    \A k \in Keys : CanonicalSinkAt(g)[k] = SrcAt(g)[k]

(* The probe target for "degraded" mode, EXPECTED TO FAIL there: the
   same trajectory claim made from inside the widened bracket.  The
   dump's verdicts are honest at d, not at earlier coordinates of the
   span, so an intermediate replay below d can already show the dump's
   newer values.  This refutes the low-edge start only.  The
   HighEdgeTrajectory property remains. *)
WidenedTrajectory ==
  dtaken => \A g \in blo..Frontier :
    \A k \in Keys : CanonicalSinkAt(g)[k] = SrcAt(g)[k]

----------------------------------------------------------------------------
(* Model configurations (selected by the .cfg files). *)

MainKeys == {1, 2}
MainVals == {1, 2}

============================================================================
