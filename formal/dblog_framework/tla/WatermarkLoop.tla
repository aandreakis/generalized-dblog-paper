--------------------------- MODULE WatermarkLoop ---------------------------
(***************************************************************************)
(* The classic watermarked chunk loop, modeled for the model checker TLC.  *)
(*                                                                         *)
(* This specification is a redundancy layer for the paper "Generalized    *)
(* DBLog: A Verified Contract for Interleaving Database Copies with        *)
(* Change Logs".  The paper proves its results for arbitrary               *)
(* configurations; TLC re-checks the same claims exhaustively on small     *)
(* configurations, and re-discovers the paper's countermodels when a       *)
(* premise is deliberately dropped.  Model checking on small               *)
(* configurations is evidence, never proof.                                *)
(*                                                                         *)
(* The protocol modeled here is the original algorithm of the 2020 DBLog   *)
(* paper, as placed in Section 7.3 of the framework paper.  The capture    *)
(* reads the scope in chunks, one chunk at a time.  Each chunk select is   *)
(* bracketed by two watermark writes.  The watermark writes are updates    *)
(* to a dedicated table outside the capture scope, so they appear in the   *)
(* log as events of their own, and the log positions of the two watermark  *)
(* events are the chunk's bracket.  Deduplication is window-discard: a     *)
(* chunk row survives to the close of its window only if no log event      *)
(* touched its key inside the window.                                      *)
(*                                                                         *)
(* The chunk select is NOT modeled as one atomic read.  Each key of the    *)
(* chunk is read at some position of its own inside the bracket, so the    *)
(* refresh can be torn across the bracket exactly as a cursor-driven scan  *)
(* can.  This is obligation O2 of the paper (Section 3.3): per-key,        *)
(* existential honesty, with no single read instant required anywhere.     *)
(*                                                                         *)
(* Mapping from spec objects to paper objects:                             *)
(*                                                                         *)
(*   log, DataEntry, SrcAt      Section 2.1: events, per-key fold sigma    *)
(*   positions as coordinates   Definition 2.1: prefix denotations (the    *)
(*                              coordinate space is prefix lengths)        *)
(*   WindowEvents               Definition 2.2: half-open window (lo, hi]  *)
(*   ChunkDoms, lo, hi, R       Definition 3.1: capture plan               *)
(*                              (D_i, lo_i, hi_i, R_i)                     *)
(*   WriteLow, WriteHigh        Section 7.3: watermark writes as log       *)
(*                              events; preconditions W1-W5 presumed       *)
(*   ReadKey                    O2 (Section 3.3): per-key existential      *)
(*                              honesty inside the bracket                 *)
(*   Survivors, CloseBlock,     Definition 6.2: the window-discard         *)
(*   Consume                    emission (close block immediately before   *)
(*                              the first consumed event beyond hi_i)      *)
(*   ReplayOf                   Definition 6.1: stream replay (empty       *)
(*                              start; absence by omission)                *)
(*   FrontierExact              Theorem 1 (cut theorem) with Theorem 2     *)
(*                              (window-discard equivalence), at the       *)
(*                              model's frontier                           *)
(*   ContinuationExact          Corollary 2 / the frontier-parametric      *)
(*                              remark after Theorem 1                     *)
(*   PerKeyMonotone             Theorem 3 (window-discard monotonicity),   *)
(*                              with Theorem 3's tag scheme                *)
(*   SharedInstantExists        Proposition 1 (the torn read).  This       *)
(*                              assertion is EXPECTED TO FAIL: it claims   *)
(*                              a single in-bracket read instant exists    *)
(*                              for every chunk, which O2 deliberately     *)
(*                              does not require.  TLC's counterexample    *)
(*                              is the torn read of Proposition 1, and     *)
(*                              FrontierExact holds on the same model.     *)
(*                                                                         *)
(* Premises the model builds in, named after the paper's registers: the    *)
(* watermark events appear in the same log as the data (W3, W5 of          *)
(* Section 7.3); the log is a linear commit-order event sequence with      *)
(* full row images (S-LOG, S-IMG); consumption is a single pass from a     *)
(* start at or before every bracket (the window-discard bound of S-OBS).   *)
(***************************************************************************)
EXTENDS Integers, Sequences, FiniteSets

CONSTANTS
  Keys,       \* the capture scope: a finite set of keys
  Vals,       \* the value domain
  NULL,       \* the absence verdict (a model value); img NULL is a delete
  MaxEvents,  \* bound on committed data events (the model's finiteness)
  ChunkDoms   \* the plan's domains: a sequence of key sets, one per chunk

ASSUME NullNotAValue == NULL \notin Vals
ASSUME MaxEventsNat  == MaxEvents \in Nat
ASSUME ChunkDomsPartition ==
  /\ \A i \in DOMAIN ChunkDoms :
       ChunkDoms[i] \subseteq Keys /\ ChunkDoms[i] # {}
  /\ UNION {ChunkDoms[i] : i \in DOMAIN ChunkDoms} = Keys
  /\ \A i, j \in DOMAIN ChunkDoms :
       i # j => ChunkDoms[i] \cap ChunkDoms[j] = {}

NumChunks == Len(ChunkDoms)
Img == Vals \cup {NULL}

VARIABLES
  log,       \* the committed history: data events and watermark events
  nData,     \* count of committed data events
  ci,        \* index of the chunk currently in flight (NumChunks+1 = done)
  phase,     \* "idle" | "select" | "closing" for the current chunk
  lo, hi,    \* bracket edges per chunk: positions of the watermark events
  R,         \* refresh verdicts per chunk (Definition 3.1's R_i)
  readDone,  \* keys of the current chunk already read
  cpos,      \* the consumer's position in the single pass over the log
  emission   \* the emitted stream (Definition 6.2)

vars == <<log, nData, ci, phase, lo, hi, R, readDone, cpos, emission>>

DataEntry(k, v) == [type |-> "data", key |-> k, img |-> v]
WmEntry == [type |-> "wm"]
IsData(p) == log[p].type = "data"

(* The source state after the length-n prefix: the per-key fold of
   Section 2.1.  A key's value is the image of its last event at or
   before position n, or NULL if it has none. *)
SrcAt(n) ==
  [k \in Keys |->
     LET ps == {p \in 1..n : IsData(p) /\ log[p].key = k}
     IN IF ps = {} THEN NULL
        ELSE log[CHOOSE p \in ps : \A q \in ps : q <= p].img]

Init ==
  /\ log = <<>>
  /\ nData = 0
  /\ ci = 1
  /\ phase = "idle"
  /\ lo = [i \in 1..NumChunks |-> 0]
  /\ hi = [i \in 1..NumChunks |-> 0]
  /\ R  = [i \in 1..NumChunks |-> [k \in Keys |-> NULL]]
  /\ readDone = {}
  /\ cpos = 0
  /\ emission = <<>>

(* The environment atomically commits one complete single-row
   transaction. An image of NULL is a delete. No pending or uncommitted
   event exists in the model. Commits interleave freely with every
   capture step. *)
Commit(k, v) ==
  /\ nData < MaxEvents
  /\ log' = Append(log, DataEntry(k, v))
  /\ nData' = nData + 1
  /\ UNCHANGED <<ci, phase, lo, hi, R, readDone, cpos, emission>>

(* The low watermark write commits atomically. The update appears in the
   log as an event, and its position is the bracket's low edge. *)
WriteLow ==
  /\ ci <= NumChunks
  /\ phase = "idle"
  /\ log' = Append(log, WmEntry)
  /\ lo' = [lo EXCEPT ![ci] = Len(log) + 1]
  /\ phase' = "select"
  /\ readDone' = {}
  /\ UNCHANGED <<nData, ci, hi, R, cpos, emission>>

(* One key of the chunk is read.  The verdict is the source state of
   that key at SOME position between the low watermark and now: this is
   O2's per-key existential honesty.  Different keys of one chunk may
   be honest at different positions, and no step requires a shared
   read instant. *)
ReadKey(k) ==
  /\ phase = "select"
  /\ k \in ChunkDoms[ci]
  /\ k \notin readDone
  /\ \E c \in lo[ci]..Len(log) :
       R' = [R EXCEPT ![ci][k] = SrcAt(c)[k]]
  /\ readDone' = readDone \cup {k}
  /\ UNCHANGED <<log, nData, ci, phase, lo, hi, cpos, emission>>

(* The high watermark write commits atomically after every key of the
   chunk was read. Its position is the bracket's high edge. *)
WriteHigh ==
  /\ phase = "select"
  /\ readDone = ChunkDoms[ci]
  /\ log' = Append(log, WmEntry)
  /\ hi' = [hi EXCEPT ![ci] = Len(log) + 1]
  /\ phase' = "closing"
  /\ UNCHANGED <<nData, ci, lo, R, readDone, cpos, emission>>

(* The serial loop: the next chunk starts only after the consumer has
   passed the current chunk's high watermark, so its close block is
   already emitted. *)
FinishChunk ==
  /\ phase = "closing"
  /\ cpos >= hi[ci]
  /\ ci' = ci + 1
  /\ phase' = "idle"
  /\ UNCHANGED <<log, nData, lo, hi, R, readDone, cpos, emission>>

(* The half-open window (lo_i, hi_i] of Definition 2.2, as data-event
   positions: strictly after the low watermark event, at or before the
   high watermark event. *)
WindowEvents(i, k) ==
  {p \in 1..Len(log) :
     lo[i] < p /\ p <= hi[i] /\ IsData(p) /\ log[p].key = k}

(* Definition 6.2's survivors: keys read as present with no event in
   the window. *)
Survivors(i) ==
  {k \in ChunkDoms[i] : R[i][k] # NULL /\ WindowEvents(i, k) = {}}

RECURSIVE SeqOf(_)
SeqOf(S) ==
  IF S = {} THEN <<>>
  ELSE LET x == CHOOSE y \in S : TRUE IN <<x>> \o SeqOf(S \ {x})

(* The close block: one refresh entry per survivor, tagged with the
   high edge per Theorem 3's tag scheme.  Distinct chunks never share
   a survivor key, so the order inside a block is immaterial. *)
CloseBlock(i) ==
  LET ks == SeqOf(Survivors(i))
  IN [j \in 1..Len(ks) |->
       [kind |-> "refresh", key |-> ks[j], img |-> R[i][ks[j]],
        tag |-> hi[i]]]

(* The single pass of Definition 6.2.  Data events are emitted at their
   own places, tagged with their positions.  Consuming a chunk's high
   watermark emits that chunk's close block, which places the block
   immediately before the first consumed event beyond the high edge.
   Watermark events themselves are outside the scope and are never
   emitted. *)
Consume ==
  /\ cpos < Len(log)
  /\ LET p == cpos + 1
         e == log[p]
     IN emission' =
          IF e.type = "data"
          THEN Append(emission,
                 [kind |-> "ev", key |-> e.key, img |-> e.img, tag |-> p])
          ELSE IF \E i \in 1..NumChunks : hi[i] = p
               THEN emission \o CloseBlock(CHOOSE i \in 1..NumChunks : hi[i] = p)
               ELSE emission
  /\ cpos' = cpos + 1
  /\ UNCHANGED <<log, nData, ci, phase, lo, hi, R, readDone>>

Next ==
  \/ \E k \in Keys, v \in Img : Commit(k, v)
  \/ WriteLow
  \/ \E k \in Keys : ReadKey(k)
  \/ WriteHigh
  \/ FinishChunk
  \/ Consume

Spec == Init /\ [][Next]_vars

----------------------------------------------------------------------------
(* Properties.                                                             *)

(* Definition 6.1's stream replay: a key's last entry decides its value;
   a key with no entry replays to absent. *)
ReplayOf(em) ==
  [k \in Keys |->
     LET js == {j \in 1..Len(em) : em[j].key = k}
     IN IF js = {} THEN NULL
        ELSE em[CHOOSE j \in js : \A q \in js : q <= j].img]

Frontier == Len(log)

Done ==
  /\ nData = MaxEvents
  /\ ci > NumChunks
  /\ cpos = Len(log)

TypeOK ==
  /\ nData \in 0..MaxEvents
  /\ \A p \in 1..Len(log) :
       log[p] \in [type : {"data"}, key : Keys, img : Img]
                  \cup [type : {"wm"}]
  /\ ci \in 1..(NumChunks + 1)
  /\ phase \in {"idle", "select", "closing"}
  /\ lo \in [1..NumChunks -> 0..Len(log)]
  /\ hi \in [1..NumChunks -> 0..Len(log)]
  /\ R \in [1..NumChunks -> [Keys -> Img]]
  /\ readDone \subseteq Keys
  /\ cpos \in 0..Len(log)
  /\ \A j \in 1..Len(emission) :
       emission[j] \in [kind : {"ev", "refresh"}, key : Keys,
                        img : Img, tag : 1..Len(log)]

(* Theorem 1 with Theorem 2: at the frontier, with every chunk closed
   and the pass complete, the replay of the emitted stream equals the
   source state, on every key of the scope. *)
FrontierExact ==
  Done => \A k \in Keys : ReplayOf(emission)[k] = SrcAt(Frontier)[k]

(* Corollary 2 / the frontier-parametric remark: once every chunk is
   closed, the replay of the emission-so-far equals the source state at
   the consumer's position, at every step of the remaining pass. *)
ContinuationExact ==
  ci > NumChunks =>
    \A k \in Keys : ReplayOf(emission)[k] = SrcAt(cpos)[k]

(* Theorem 3: along the emitted stream, each key's tags never decrease. *)
PerKeyMonotone ==
  \A j1, j2 \in 1..Len(emission) :
    (j1 < j2 /\ emission[j1].key = emission[j2].key)
      => emission[j1].tag <= emission[j2].tag

(* Proposition 1's target, EXPECTED TO FAIL when checked: the claim
   that every completed chunk has one in-bracket coordinate at which
   every key of the chunk is honest at once.  O2 requires less, and the
   counterexample TLC reports is the torn read: one key read before an
   event committed, another key read after a later event, with no
   single position accounting for both.  FrontierExact holds on the
   same model, which is Proposition 1's parts (2) and (3). *)
SharedInstantExists ==
  \A i \in 1..NumChunks :
    hi[i] > 0 =>
      \E c \in lo[i]..hi[i] :
        \A k \in ChunkDoms[i] : R[i][k] = SrcAt(c)[k]

----------------------------------------------------------------------------
(* Model configurations (selected by the .cfg files). *)

MainKeys == {1, 2, 3}
MainVals == {1, 2}
MainChunkDoms == <<{1}, {2, 3}>>

TornKeys == {1, 2}
TornVals == {1, 2}
TornChunkDoms == <<{1, 2}>>

============================================================================
