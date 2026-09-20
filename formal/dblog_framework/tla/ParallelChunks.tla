--------------------------- MODULE ParallelChunks ---------------------------
(***************************************************************************)
(* Parallel chunks with buffered range-merge, modeled for the model        *)
(* checker TLC.                                                            *)
(*                                                                         *)
(* This specification is a redundancy layer for the paper "Generalized    *)
(* DBLog: A Verified Contract for Interleaving Database Copies with        *)
(* Change Logs".  The paper proves its results for arbitrary               *)
(* configurations; TLC re-checks the same claims exhaustively on small     *)
(* configurations.  Model checking on small configurations is evidence,    *)
(* never proof.                                                            *)
(*                                                                         *)
(* The protocol modeled here is the parallel-chunks instance of Section    *)
(* 7.5: chunks in flight concurrently, each bracketed by two log-offset    *)
(* reads taken before and after its select (write-free), each chunk's      *)
(* window read back as a ranged backfill and upserted onto the chunk       *)
(* buffer, the merged buffer emitted once at the chunk's close, and a      *)
(* single streaming reader that starts at or before every chunk's high     *)
(* edge and withholds, per unit, everything at or before that unit's       *)
(* high edge: the gated range-merge discipline of Section 6.3, with        *)
(* clause (a) as the cross-phase deduplication rule and clause (b) as      *)
(* the merged verdict.  The chunk select is NOT one atomic read: each      *)
(* key is read at some offset of its own inside the bracket (O2 /          *)
(* A-read).  The named assumptions of the paper's Section 7.5 register     *)
(* are built into the model where a deployment would have to supply        *)
(* them: A-read is the read rule, A-identity is stable final ownership,    *)
(* A-handoff is the streaming reader's start bound, and the emission       *)
(* realizes the gated discipline (A-merge).                                *)
(*                                                                         *)
(* Two config switches select the paper's countermodels:                   *)
(*                                                                         *)
(* WithholdClauseA = FALSE is Proposition 3's window-narrowed variant:     *)
(* the reader absorbs only the window into the buffer and streams every    *)
(* other consumed event, pre-bracket events included.  EXPECTED TO         *)
(* FAIL: a pre-bracket insert of a key deleted inside the window           *)
(* replays to a value the source no longer holds.                          *)
(*                                                                         *)
(* PointBrackets = TRUE makes every unit a point splice: one atomic        *)
(* step records the current offset as both edges and reads the unit's      *)
(* keys exactly there (the LSN-positioned select shape of Section 7.6,     *)
(* as units of one composite plan).  Each unit alone then satisfies        *)
(* Corollary 1's premises at its own coordinate; the composite is in       *)
(* contract, and the assertion EarlyOnsetExists (for distinct point        *)
(* coordinates, some onset below the frontier exists from which the        *)
(* canonical replay tracks true source states) is EXPECTED TO FAIL,        *)
(* exactly as Proposition 2 constructs.                                    *)
(*                                                                         *)
(* Mapping from spec objects to paper objects:                             *)
(*                                                                         *)
(*   log, SrcAt                Section 2.1: events, per-key fold           *)
(*   offsets as coordinates    Section 7.5: scalar log offsets denoting    *)
(*                             prefixes; in-range comparisons agree with   *)
(*                             the denotational order                      *)
(*   ChunkDoms, low, high, R   Definition 3.1: capture plan; A-identity    *)
(*   RecordLow, RecordHigh     Section 7.5: "record current binlog         *)
(*                             position as LOW/HIGH offset"                *)
(*   ReadChunkKey              O2 / A-read: per-key existential honesty    *)
(*   MergedAt                  Definition 6.3: the merged verdict          *)
(*                             (clause (b)); Lemma 6.2's content           *)
(*   CloseUnit                 Definition 6.4's close block at             *)
(*                             Definition 6.2's placement; Section        *)
(*                             7.5's "upsert the read binlog records       *)
(*                             into the buffered chunk records",           *)
(*                             emitted once at the unit's close            *)
(*                             (A-merge); per-key shape of Lemma 6.3.      *)
(*                             Shipped systems emit blocks at chunk        *)
(*                             completion; under the lawful gate the       *)
(*                             two orders are per-key identical            *)
(*   StartStream, s0           A-handoff: the streaming phase starts at    *)
(*                             or before every chunk's high edge, after    *)
(*                             the chunks finish                           *)
(*   StreamStep gate           Definition 6.4, clause (a): an event of     *)
(*                             unit i passes only beyond high_i           *)
(*   FrontierExact             Theorem 1 with Theorem 4 at the frontier    *)
(*                             (Proposition 5's placement content)         *)
(*   ContinuationExact         the frontier-parametric reading, from the   *)
(*                             point where the reader has passed every     *)
(*                             high edge                                   *)
(*   GatedMonotone             Theorem 5 (range-merge monotonicity)        *)
(*   PointSplice               point brackets (Section 3.1's degenerate    *)
(*                             case; Sections 6.4 and 7.6)                 *)
(*   PlanReplayAt              Definition 4.1: replay at a coordinate      *)
(*   EarlyOnsetExists          Proposition 2's exact fixture property,     *)
(*                             EXPECTED TO FAIL in point mode.  The safe   *)
(*                             canonical latest-high trajectory remains   *)
(*   WithholdClauseA = FALSE   Proposition 3's window-narrowed variant,    *)
(*                             EXPECTED TO FAIL against FrontierExact      *)
(***************************************************************************)
EXTENDS Integers, Sequences, FiniteSets

CONSTANTS
  Keys,             \* the capture scope
  Vals,             \* the value domain
  NULL,             \* the absence verdict (a model value)
  MaxEvents,        \* bound on committed data events
  ChunkDoms,        \* the plan's domains: one key set per chunk
  WithholdClauseA,  \* TRUE: clause (a) as defined.  FALSE: Proposition
                    \* 3's window-narrowed variant
  PointBrackets     \* TRUE: every unit is a point splice (Prop 2 mode)

ASSUME NullNotAValue == NULL \notin Vals
ASSUME MaxEventsNat  == MaxEvents \in Nat
ASSUME WithholdBool  == WithholdClauseA \in BOOLEAN
ASSUME PointBool     == PointBrackets \in BOOLEAN
ASSUME ChunkDomsPartition ==
  /\ \A i \in DOMAIN ChunkDoms :
       ChunkDoms[i] \subseteq Keys /\ ChunkDoms[i] # {}
  /\ UNION {ChunkDoms[i] : i \in DOMAIN ChunkDoms} = Keys
  /\ \A i, j \in DOMAIN ChunkDoms :
       i # j => ChunkDoms[i] \cap ChunkDoms[j] = {}

NumChunks == Len(ChunkDoms)
Img == Vals \cup {NULL}

(* A-identity: the logical partition is fixed for the run; a key's unit is a
   constant of the model. *)
UnitOf(k) == CHOOSE i \in 1..NumChunks : k \in ChunkDoms[i]

VARIABLES
  log,       \* the committed history: data events at offset positions
  nData,     \* count of committed data events
  cphase,    \* per chunk: "idle" | "select" | "done"; chunks run
             \* concurrently, in any interleaving
  low, high, \* per chunk: the recorded LOW and HIGH offsets
  R,         \* per chunk: refresh verdicts
  readDone,  \* per chunk: keys already read
  emitted,   \* per chunk: whether its merged block has been emitted
  sphase,    \* "chunks" | "stream": the single streaming reader runs
             \* after the chunks finish
  s0,        \* the reader's consumption start (A-handoff)
  spos,      \* the reader's position
  emission   \* the emitted stream

vars == <<log, nData, cphase, low, high, R, readDone, emitted, sphase,
          s0, spos, emission>>

SrcAt(n) ==
  [k \in Keys |->
     LET ps == {p \in 1..n : log[p].key = k}
     IN IF ps = {} THEN NULL
        ELSE log[CHOOSE p \in ps : \A q \in ps : q <= p].img]

Init ==
  /\ log = <<>>
  /\ nData = 0
  /\ cphase = [i \in 1..NumChunks |-> "idle"]
  /\ low  = [i \in 1..NumChunks |-> 0]
  /\ high = [i \in 1..NumChunks |-> 0]
  /\ R  = [i \in 1..NumChunks |-> [k \in Keys |-> NULL]]
  /\ readDone = [i \in 1..NumChunks |-> {}]
  /\ emitted = [i \in 1..NumChunks |-> FALSE]
  /\ sphase = "chunks"
  /\ s0 = 0
  /\ spos = 0
  /\ emission = <<>>

(* The environment atomically commits one complete single-row
   transaction as a data event at the next offset. No pending or
   uncommitted event exists in the model. Commits interleave freely
   with every capture step, in the chunk phase and in the streaming
   phase alike. *)
Commit(k, v) ==
  /\ nData < MaxEvents
  /\ log' = Append(log, [key |-> k, img |-> v])
  /\ nData' = nData + 1
  /\ UNCHANGED <<cphase, low, high, R, readDone, emitted, sphase, s0,
                 spos, emission>>

(* "Record current binlog position as LOW offset."  Chunks start
   independently; any number may be in flight at once. *)
RecordLow(i) ==
  /\ ~PointBrackets
  /\ sphase = "chunks"
  /\ cphase[i] = "idle"
  /\ low' = [low EXCEPT ![i] = Len(log)]
  /\ cphase' = [cphase EXCEPT ![i] = "select"]
  /\ UNCHANGED <<log, nData, high, R, readDone, emitted, sphase, s0,
                 spos, emission>>

(* One key of the chunk is read at some offset of its own inside the
   bracket so far: O2 / A-read. *)
ReadChunkKey(i, k) ==
  /\ cphase[i] = "select"
  /\ k \in ChunkDoms[i]
  /\ k \notin readDone[i]
  /\ \E c \in low[i]..Len(log) :
       R' = [R EXCEPT ![i][k] = SrcAt(c)[k]]
  /\ readDone' = [readDone EXCEPT ![i] = @ \cup {k}]
  /\ UNCHANGED <<log, nData, cphase, low, high, emitted, sphase, s0,
                 spos, emission>>

(* "Record current binlog position as HIGH offset," after the chunk's
   select. *)
RecordHigh(i) ==
  /\ cphase[i] = "select"
  /\ readDone[i] = ChunkDoms[i]
  /\ high' = [high EXCEPT ![i] = Len(log)]
  /\ cphase' = [cphase EXCEPT ![i] = "done"]
  /\ UNCHANGED <<log, nData, low, R, readDone, emitted, sphase, s0,
                 spos, emission>>

(* Point mode (Proposition 2's construction): one atomic step records
   the current offset as both edges and reads the unit's keys exactly
   there.  The unit's refresh is honest AT its point coordinate, so
   each unit alone satisfies Corollary 1's premises at that
   coordinate. *)
PointSplice(i) ==
  /\ PointBrackets
  /\ sphase = "chunks"
  /\ cphase[i] = "idle"
  /\ LET r == Len(log)
     IN /\ low'  = [low EXCEPT ![i] = r]
        /\ high' = [high EXCEPT ![i] = r]
        /\ R' = [R EXCEPT ![i] =
                   [k \in Keys |->
                      IF k \in ChunkDoms[i] THEN SrcAt(r)[k] ELSE NULL]]
  /\ readDone' = [readDone EXCEPT ![i] = ChunkDoms[i]]
  /\ cphase' = [cphase EXCEPT ![i] = "done"]
  /\ UNCHANGED <<log, nData, emitted, sphase, s0, spos, emission>>

(* Definition 6.3's merged verdict, clause (b): the key's last event
   in the half-open window (low_i, high_i] decides; a key with no
   in-window event keeps its refresh verdict.  The window is read from
   the log by coordinate-addressable access (the ranged backfill). *)
WindowEvts(i, k) ==
  {p \in 1..Len(log) :
     low[i] < p /\ p <= high[i] /\ log[p].key = k}

MergedAt(i, k) ==
  LET ws == WindowEvts(i, k)
  IN IF ws = {} THEN R[i][k]
     ELSE log[CHOOSE p \in ws : \A q \in ws : q <= p].img

RECURSIVE SeqOf(_)
SeqOf(S) ==
  IF S = {} THEN <<>>
  ELSE LET x == CHOOSE y \in S : TRUE IN <<x>> \o SeqOf(S \ {x})

(* The unit's close: one entry per key present at the high edge,
   absence rendered by emitting nothing (Lemma 6.3's per-key shape),
   placed as Definition 6.2 places close blocks: immediately before
   the first consumed event beyond the unit's high edge, or at the
   end of the pass.  Shipped systems emit each merged buffer when its
   chunk finishes, before the streaming phase; under the lawful
   clause-(a) gate the two orders are per-key identical (every
   streamed entry of the unit's keys lies beyond its high edge), so
   the model uses the definition's own placement, which is also the
   discipline Proposition 3's variant is stated against. *)
CloseUnit(i) ==
  /\ sphase = "stream"
  /\ ~emitted[i]
  /\ spos = Len(log) \/ spos + 1 > high[i]
  /\ LET ks == SeqOf({k \in ChunkDoms[i] : MergedAt(i, k) # NULL})
     IN emission' = emission \o
          [j \in 1..Len(ks) |->
             [kind |-> "refresh", key |-> ks[j],
              img |-> MergedAt(i, ks[j]), tag |-> high[i]]]
  /\ emitted' = [emitted EXCEPT ![i] = TRUE]
  /\ UNCHANGED <<log, nData, cphase, low, high, R, readDone, sphase,
                 s0, spos>>

MinHigh == LET m == CHOOSE i \in 1..NumChunks :
                      \A j \in 1..NumChunks : high[i] <= high[j]
           IN high[m]

MaxHigh == LET m == CHOOSE i \in 1..NumChunks :
                      \A j \in 1..NumChunks : high[j] <= high[i]
           IN high[m]

(* A-handoff: the single streaming reader starts at or before every
   chunk's high edge, once the chunks have finished. *)
StartStream ==
  /\ sphase = "chunks"
  /\ \A i \in 1..NumChunks : cphase[i] = "done"
  /\ \E s \in 0..MinHigh :
       s0' = s /\ spos' = s
  /\ sphase' = "stream"
  /\ UNCHANGED <<log, nData, cphase, low, high, R, readDone, emitted,
                 emission>>

(* Clause (a), the withholding gate: an event whose key belongs to
   unit i passes to the stream only beyond unit i's high edge.  The
   window-narrowed variant of Proposition 3 (WithholdClauseA = FALSE)
   absorbs only the window and streams every other consumed event,
   pre-bracket events included. *)
GatePasses(u, p) ==
  IF WithholdClauseA
  THEN p > high[u]
  ELSE ~(low[u] < p /\ p <= high[u])

StreamStep ==
  /\ sphase = "stream"
  /\ spos < Len(log)
  /\ ~\E i \in 1..NumChunks : ~emitted[i] /\ spos + 1 > high[i]
  /\ LET p == spos + 1
         u == UnitOf(log[p].key)
     IN emission' =
          IF GatePasses(u, p)
          THEN Append(emission,
                 [kind |-> "ev", key |-> log[p].key,
                  img |-> log[p].img, tag |-> p])
          ELSE emission
  /\ spos' = spos + 1
  /\ UNCHANGED <<log, nData, cphase, low, high, R, readDone, emitted,
                 sphase, s0>>

Next ==
  \/ \E k \in Keys, v \in Img : Commit(k, v)
  \/ \E i \in 1..NumChunks : RecordLow(i)
  \/ \E i \in 1..NumChunks, k \in Keys : ReadChunkKey(i, k)
  \/ \E i \in 1..NumChunks : RecordHigh(i)
  \/ \E i \in 1..NumChunks : PointSplice(i)
  \/ \E i \in 1..NumChunks : CloseUnit(i)
  \/ StartStream
  \/ StreamStep

Spec == Init /\ [][Next]_vars

----------------------------------------------------------------------------
(* Properties.                                                             *)

ReplayOf(em) ==
  [k \in Keys |->
     LET js == {j \in 1..Len(em) : em[j].key = k}
     IN IF js = {} THEN NULL
        ELSE em[CHOOSE j \in js : \A q \in js : q <= j].img]

Frontier == Len(log)

Done ==
  /\ nData = MaxEvents
  /\ sphase = "stream"
  /\ spos = Len(log)
  /\ \A i \in 1..NumChunks : emitted[i]

TypeOK ==
  /\ nData \in 0..MaxEvents
  /\ \A p \in 1..Len(log) : log[p] \in [key : Keys, img : Img]
  /\ cphase \in [1..NumChunks -> {"idle", "select", "done"}]
  /\ low  \in [1..NumChunks -> 0..Len(log)]
  /\ high \in [1..NumChunks -> 0..Len(log)]
  /\ R \in [1..NumChunks -> [Keys -> Img]]
  /\ \A i \in 1..NumChunks : readDone[i] \subseteq Keys
  /\ emitted \in [1..NumChunks -> BOOLEAN]
  /\ sphase \in {"chunks", "stream"}
  /\ s0 \in 0..Len(log)
  /\ spos \in 0..Len(log)
  /\ \A j \in 1..Len(emission) :
       emission[j] \in [kind : {"ev", "refresh"}, key : Keys,
                        img : Img, tag : 0..Len(log)]

(* Theorem 1 with Theorem 4 at the frontier: the content of
   Proposition 5's placement.  EXPECTED TO FAIL under the
   window-narrowed variant, exactly as Proposition 3 constructs. *)
FrontierExact ==
  Done => \A k \in Keys : ReplayOf(emission)[k] = SrcAt(Frontier)[k]

(* The frontier-parametric reading: once the reader has passed every
   high edge and every close block is out, the replay of the
   emission-so-far equals the source state at the reader's position,
   at every remaining step. *)
ContinuationExact ==
  (sphase = "stream" /\ spos >= MaxHigh
     /\ \A i \in 1..NumChunks : emitted[i]) =>
    \A k \in Keys : ReplayOf(emission)[k] = SrcAt(spos)[k]

(* Theorem 5: per-key tags never decrease along the gated emission. *)
GatedMonotone ==
  \A j1, j2 \in 1..Len(emission) :
    (j1 < j2 /\ emission[j1].key = emission[j2].key)
      => emission[j1].tag <= emission[j2].tag

(* Definition 4.1: the plan-level replay at a coordinate g.  The
   window (low_u, g] is read as den(g) \ den(low_u); when g is at or
   below low_u it is empty and the refresh verdict stands. *)
PlanReplayAt(g) ==
  [k \in Keys |->
     LET u == UnitOf(k)
         ws == {p \in 1..Len(log) :
                  low[u] < p /\ p <= g /\ log[p].key = k}
     IN IF ws = {} THEN R[u][k]
        ELSE log[CHOOSE p \in ws : \A q \in ws : q <= p].img]

(* Proposition 2's target, EXPECTED TO FAIL in point mode: for the
   composite the proposition constructs (point units at DISTINCT
   coordinates, each refresh honest at its own point), some onset
   strictly below the frontier exists from which every intermediate
   replay state is a true source state (Corollary 1's trajectory
   property).  Proposition 2 says no such onset exists: a unit's
   refresh asserts a value the source did not yet hold at coordinates
   between the two splice points.  The plan still has the canonical
   trajectory beginning at its latest high, which is the frontier in
   the paper's fixture.  The assertion is conditioned on
   distinct coordinates because that is the shape the proposition is
   about: a composite whose units all share one coordinate is
   Corollary 1's case, and an onset below a shared frontier witness
   was never claimed by anything. *)
EarlyOnsetExists ==
  (Done /\ \E i, j \in 1..NumChunks : low[i] # low[j]) =>
    \E cstar \in 0..(Frontier - 1) :
      \A g \in cstar..Frontier :
        \A k \in Keys : PlanReplayAt(g)[k] = SrcAt(g)[k]

----------------------------------------------------------------------------
(* Model configurations (selected by the .cfg files). *)

MainKeys == {1, 2, 3}
MainVals == {1, 2}
MainChunkDoms == <<{1}, {2, 3}>>

Prop3Keys == {1}
Prop3Vals == {1, 2}
Prop3ChunkDoms == <<{1}>>

PointKeys == {1, 2}
PointVals == {1, 2}
PointChunkDoms == <<{1}, {2}>>

============================================================================
