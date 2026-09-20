-------------------------- MODULE ReadOnlyBrackets --------------------------
(***************************************************************************)
(* Read-only capture over executed transaction-identifier sets, modeled    *)
(* for the model checker TLC.                                              *)
(*                                                                         *)
(* This specification is a redundancy layer for the paper "Generalized    *)
(* DBLog: A Verified Contract for Interleaving Database Copies with        *)
(* Change Logs".  The paper proves its results for arbitrary               *)
(* configurations; TLC re-checks the same claims exhaustively on small     *)
(* configurations.  Model checking on small configurations is evidence,    *)
(* never proof.                                                            *)
(*                                                                         *)
(* The protocol modeled here is the write-free instance of Section 7.4:    *)
(* the capture writes nothing.  Each chunk is bracketed by two READS of    *)
(* server state, the executed transaction-identifier sets, taken as low    *)
(* and high watermarks.  An event is inside the window exactly when its    *)
(* transaction identifier lies in the high set and not in the low set:     *)
(* the bracket coordinates are SETS, and the window decision is the        *)
(* membership oracle on their difference, with no scalar anywhere.         *)
(* Deduplication is window-discard, driven by that oracle.                 *)
(*                                                                         *)
(* Two premises of the paper's Section 7.4 register are built into the     *)
(* lawful model, and named: A-linear (one linear commit history;           *)
(* transaction identifiers occupy contiguous position blocks; every        *)
(* sampled executed set reflects a transaction boundary) holds because     *)
(* transactions commit atomically in the lawful model, so every            *)
(* reachable log state IS a boundary; A-read (bracket-local per-key        *)
(* read honesty, O2) is the read rule, as in WatermarkLoop.  The chunk     *)
(* select is NOT one atomic read: each key is read at some boundary of     *)
(* its own inside the bracket.                                             *)
(*                                                                         *)
(* THE A-LINEAR PROBE.  The constant BoundarySampling selects the          *)
(* premise.  TRUE is the lawful model above.  FALSE permits the low        *)
(* sample's analysis denotation to name an interior prefix of an already   *)
(* fully committed transaction block.  The sampled set then aliases the   *)
(* set at the block's real boundary even though the bookkeeping position   *)
(* is earlier.  With UncommittedProbe = FALSE, as in every A-linear run,   *)
(* transactions commit atomically in both coordinate modes and no          *)
(* reachable state exposes an uncommitted event.  Reads remain             *)
(* boundary-honest in both modes (A-read binds in ReadKey), so the probe    *)
(* changes coordinate fidelity and nothing else.  With the malformed       *)
(* denotation, the set-difference oracle mis-classifies later events in     *)
(* the same committed block, so Theorem 7's conclusion fails: this is a    *)
(* model-level demonstration that A-linear is necessary for the            *)
(* faithfulness of the membership oracle.  The frontier replay of the      *)
(* window-discard discipline is NOT broken by the denotation violation     *)
(* alone: a surviving key's boundary-honest verdict is forced to the       *)
(* frontier value by window invariance, and the search confirms it.  The   *)
(* paper names the premise; it constructs no witness for its necessity;    *)
(* this probe supplies the model-level witness, with the break located      *)
(* precisely at the oracle.                                                *)
(*                                                                         *)
(* THE UNCOMMITTED-VISIBILITY PROBE.  The separate constant                *)
(* UncommittedProbe is FALSE in every contract and A-linear run.  When     *)
(* deliberately set TRUE by the dedicated mutation configurations, it     *)
(* permits one transaction block to become visible in two steps.  This     *)
(* explicitly violates the paper's committed-log premise; it is not an     *)
(* allowed DBLog execution.  Keeping this mutation separate lets TLC show  *)
(* how the oracle and replay react if an implementation nevertheless       *)
(* exposes in-progress transaction events, without weakening the lawful    *)
(* model or confusing that violation with coordinate fidelity.             *)
(*                                                                         *)
(* Mapping from spec objects to paper objects:                             *)
(*                                                                         *)
(*   log entries with txn labels  Section 2.1 events; Section 7.4's       *)
(*                                labeled positions                        *)
(*   Labels(n)                    Section 7.4: the executed set G(n) at    *)
(*                                a boundary                               *)
(*   loS, hiS                     Section 7.4: executed-set brackets,      *)
(*                                observed, never written                  *)
(*   InWindow                     Section 7.4: "the event's transaction    *)
(*                                identifier lies in the high set and      *)
(*                                not in the low set"                      *)
(*   OracleFaithful               Theorem 7 (executed-set windows are      *)
(*                                faithful): the set test decides          *)
(*                                exactly the half-open positional         *)
(*                                window (nlo, nhi]                        *)
(*   ChunkDoms, brackets, R       Definition 3.1: capture plan             *)
(*   ReadKey                      O2 / A-read: per-key existential         *)
(*                                honesty at a boundary in the bracket     *)
(*   Survivors, CloseChunk,       Definition 6.2: the window-discard       *)
(*   Consume                      emission, close block placed before      *)
(*                                the first consumed event beyond the      *)
(*                                high edge or at the end of the pass      *)
(*   ReplayOf                     Definition 6.1: stream replay            *)
(*   FrontierExact                Theorem 1 with Theorem 2, at the         *)
(*                                model's frontier (Proposition 4's       *)
(*                                placement content)                       *)
(*   ContinuationExact            Corollary 2 / frontier-parametric form   *)
(*   PerKeyMonotone               Theorem 3, with Theorem 3's tag scheme   *)
(*   SharedInstantExists          Proposition 1 (the torn read),           *)
(*                                EXPECTED TO FAIL, as in WatermarkLoop:   *)
(*                                write-free brackets tear the same way    *)
(*   BoundarySampling = FALSE     the A-linear violation: a sampled set is *)
(*                                assigned an interior-prefix denotation;   *)
(*                                OracleFaithful                           *)
(*                                is then EXPECTED TO FAIL (A-linear       *)
(*                                necessity for the oracle, model          *)
(*                                level), while FrontierExact is           *)
(*                                expected to HOLD (the discipline is      *)
(*                                robust to the denotation violation       *)
(*                                alone)                                   *)
(*   UncommittedProbe = TRUE      deliberate S-LOG violation: one pending  *)
(*                                transaction is exposed in two pieces;    *)
(*                                used only by configs whose names contain *)
(*                                "uncommitted"                            *)
(*                                                                         *)
(* The emission's position tags are analysis bookkeeping for Theorem 3's   *)
(* property, not protocol data; the protocol itself consults only the      *)
(* executed sets.                                                          *)
(***************************************************************************)
EXTENDS Integers, Sequences, FiniteSets

CONSTANTS
  Keys,             \* the capture scope
  Vals,             \* the value domain
  NULL,             \* the absence verdict (a model value)
  MaxEvents,        \* bound on committed data events
  MaxTxnSize,       \* bound on events per transaction (>= 2 exercises
                    \* sets genuinely coarser than positions)
  ChunkDoms,        \* the plan's domains: one key set per chunk
  BoundarySampling, \* TRUE: lawful model (A-linear holds).  FALSE: the
                    \* A-linear probe (a set may be mis-denoted at an
                    \* interior prefix of a committed transaction block)
  UncommittedProbe  \* FALSE: committed-only theory. TRUE: deliberate,
                    \* out-of-contract partial-visibility mutation

ASSUME NullNotAValue == NULL \notin Vals
ASSUME MaxEventsNat  == MaxEvents \in Nat
ASSUME MaxTxnSizePos == MaxTxnSize \in Nat \ {0}
ASSUME BoundarySamplingBool == BoundarySampling \in BOOLEAN
ASSUME UncommittedProbeBool == UncommittedProbe \in BOOLEAN
ASSUME ChunkDomsPartition ==
  /\ \A i \in DOMAIN ChunkDoms :
       ChunkDoms[i] \subseteq Keys /\ ChunkDoms[i] # {}
  /\ UNION {ChunkDoms[i] : i \in DOMAIN ChunkDoms} = Keys
  /\ \A i, j \in DOMAIN ChunkDoms :
       i # j => ChunkDoms[i] \cap ChunkDoms[j] = {}

NumChunks == Len(ChunkDoms)
Img == Vals \cup {NULL}

VARIABLES
  log,       \* visible event history: committed-only unless the explicit
             \* UncommittedProbe mutation is enabled
  open,      \* pending remainder, nonempty only in the explicit
             \* UncommittedProbe mutation
  nData,     \* count of visible data events
  nTxn,      \* allocated transaction labels (all committed except the
             \* one deliberately open transaction in the probe)
  ci,        \* index of the chunk currently in flight
  phase,     \* "idle" | "select" | "closing" for the current chunk
  loS, hiS,  \* the observed executed sets per chunk: the bracket
  nlo, nhi,  \* the log lengths at which the sets were sampled
             \* (analysis bookkeeping for OracleFaithful; the protocol
             \*  never reads them)
  R,         \* refresh verdicts per chunk
  readDone,  \* keys of the current chunk already read
  cpos,      \* the consumer's position in the single pass
  emission   \* the emitted stream

vars == <<log, open, nData, nTxn, ci, phase, loS, hiS, nlo, nhi, R,
          readDone, cpos, emission>>

(* The row-event replay state after the length-n prefix (Section 2.1's
   fold). At Boundary(n), it is also a committed database state. *)
SrcAt(n) ==
  [k \in Keys |->
     LET ps == {p \in 1..n : log[p].key = k}
     IN IF ps = {} THEN NULL
        ELSE log[CHOOSE p \in ps : \A q \in ps : q <= p].img]

(* The executed set at log length n: the labels of all positions at or
   before n. With UncommittedProbe = FALSE, every reachable source state
   is a transaction boundary: transactions commit atomically and log
   contains committed events only. In the A-linear probe, only the
   analysis denotation n can be malformed. *)
Labels(n) == {log[p].txn : p \in 1..n}

(* Section 7.4's boundary: a prefix length that no transaction block
   straddles.  Under label contiguity, an interior length is a boundary
   exactly when the labels change across it.  The full committed length
   is always a boundary. *)
Boundary(n) ==
  \/ n = 0
  \/ n = Len(log) /\ open = <<>>
  \/ 0 < n /\ n < Len(log) /\ log[n].txn # log[n + 1].txn

LoSampled(i) == i < ci \/ (i = ci /\ phase \in {"select", "closing"})
HiSampled(i) == i < ci \/ (i = ci /\ phase = "closing")

Init ==
  /\ log = <<>>
  /\ open = <<>>
  /\ nData = 0
  /\ nTxn = 0
  /\ ci = 1
  /\ phase = "idle"
  /\ loS = [i \in 1..NumChunks |-> {}]
  /\ hiS = [i \in 1..NumChunks |-> {}]
  /\ nlo = [i \in 1..NumChunks |-> 0]
  /\ nhi = [i \in 1..NumChunks |-> 0]
  /\ R  = [i \in 1..NumChunks |-> [k \in Keys |-> NULL]]
  /\ readDone = {}
  /\ cpos = 0
  /\ emission = <<>>

(* The normal environment: the source commits one transaction, a
   contiguous block of one to MaxTxnSize events under one fresh label,
   in a single step. When UncommittedProbe = FALSE, every log entry
   therefore belongs to a completed transaction, and every reachable
   source state is a transaction boundary. *)
CommitTxn ==
  /\ open = <<>>
  /\ \E len \in 1..MaxTxnSize :
       /\ nData + len <= MaxEvents
       /\ \E txn \in [1..len -> Keys \X Img] :
            log' = log \o [j \in 1..len |->
                             [key |-> txn[j][1], img |-> txn[j][2],
                              txn |-> nTxn + 1]]
       /\ nData' = nData + len
  /\ nTxn' = nTxn + 1
  /\ UNCHANGED <<open, ci, phase, loS, hiS, nlo, nhi, R, readDone,
                 cpos, emission>>

(* Deliberate out-of-contract mutation: expose the first part of one
   transaction while retaining its remainder as pending. This action is
   unreachable unless a dedicated config sets UncommittedProbe = TRUE. *)
BeginTxnUncommitted ==
  /\ UncommittedProbe
  /\ open = <<>>
  /\ \E len \in 2..MaxTxnSize :
       /\ nData + len <= MaxEvents
       /\ \E txn \in [1..len -> Keys \X Img], s \in 1..(len - 1) :
            /\ log' = log \o [j \in 1..s |->
                                [key |-> txn[j][1], img |-> txn[j][2],
                                 txn |-> nTxn + 1]]
            /\ open' = [j \in 1..(len - s) |->
                          [key |-> txn[s + j][1], img |-> txn[s + j][2],
                           txn |-> nTxn + 1]]
            /\ nData' = nData + s
  /\ nTxn' = nTxn + 1
  /\ UNCHANGED <<ci, phase, loS, hiS, nlo, nhi, R, readDone, cpos,
                 emission>>

(* Complete the deliberately exposed transaction. *)
FinishTxnUncommitted ==
  /\ UncommittedProbe
  /\ open # <<>>
  /\ log' = log \o open
  /\ open' = <<>>
  /\ nData' = nData + Len(open)
  /\ UNCHANGED <<nTxn, ci, phase, loS, hiS, nlo, nhi, R, readDone,
                 cpos, emission>>

(* The low watermark: a READ of the executed set.  Nothing is written.
   In the lawful model the denotation is the current committed boundary.
   The probe keeps the same fully committed log and the same current
   executed-set value, but permits the analysis denotation to be an
   earlier prefix carrying that same set.  Such a prefix can lie inside
   the final committed block.  This is a coordinate-fidelity mutation,
   not a source state and not access to an in-progress transaction. *)
SampleLow ==
  /\ ci <= NumChunks
  /\ phase = "idle"
  /\ \E n \in (IF BoundarySampling
                 THEN {Len(log)}
                 ELSE {m \in 0..Len(log) : Labels(m) = Labels(Len(log))}) :
       /\ loS' = [loS EXCEPT ![ci] = Labels(Len(log))]
       /\ nlo' = [nlo EXCEPT ![ci] = n]
  /\ phase' = "select"
  /\ readDone' = {}
  /\ UNCHANGED <<log, open, nData, nTxn, ci, hiS, nhi, R, cpos,
                 emission>>

(* One key of the chunk is read at some BOUNDARY between the low
   sample and now: O2 / A-read, per key, existential.  The boundary
   restriction is A-read's content (reads observe committed states,
   so each key's witness sits at a transaction boundary); it binds in
   both coordinate-sampling modes. The deliberate uncommitted probe can
   expose log events early, but this read rule still refuses a dirty-read
   witness and waits for a transaction boundary. *)
ReadKey(k) ==
  /\ phase = "select"
  /\ k \in ChunkDoms[ci]
  /\ k \notin readDone
  /\ \E c \in nlo[ci]..Len(log) :
       Boundary(c) /\ R' = [R EXCEPT ![ci][k] = SrcAt(c)[k]]
  /\ readDone' = readDone \cup {k}
  /\ UNCHANGED <<log, open, nData, nTxn, ci, phase, loS, hiS, nlo, nhi,
                 cpos, emission>>

(* The high watermark: a second READ of the executed set. *)
SampleHigh ==
  /\ phase = "select"
  /\ readDone = ChunkDoms[ci]
  /\ hiS' = [hiS EXCEPT ![ci] = Labels(Len(log))]
  /\ nhi' = [nhi EXCEPT ![ci] = Len(log)]
  /\ phase' = "closing"
  /\ UNCHANGED <<log, open, nData, nTxn, ci, loS, nlo, R, readDone,
                 cpos, emission>>

(* The window test is the protocol's own membership oracle: the
   event's transaction identifier lies in the high set and not in the
   low set.  Positions are never consulted. *)
InWindow(i, p) == log[p].txn \in hiS[i] \ loS[i]

(* Definition 6.2's survivors, decided by the oracle. *)
Survivors(i) ==
  {k \in ChunkDoms[i] :
     R[i][k] # NULL
     /\ ~\E p \in 1..Len(log) : log[p].key = k /\ InWindow(i, p)}

RECURSIVE SeqOf(_)
SeqOf(S) ==
  IF S = {} THEN <<>>
  ELSE LET x == CHOOSE y \in S : TRUE IN <<x>> \o SeqOf(S \ {x})

CloseBlock(i) ==
  LET ks == SeqOf(Survivors(i))
  IN [j \in 1..Len(ks) |->
       [kind |-> "refresh", key |-> ks[j], img |-> R[i][ks[j]],
        tag |-> nhi[i]]]

(* A pending close blocks the pass from stepping beyond the window:
   the close block must be emitted immediately before the first
   consumed event beyond the high edge (Definition 6.2).  The oracle
   decides "beyond": the next event's label is not in the high set. *)
CloseIsPending ==
  /\ phase = "closing"
  /\ cpos < Len(log)
  /\ log[cpos + 1].txn \notin hiS[ci]

(* The single pass: events are emitted at their own places. *)
Consume ==
  /\ cpos < Len(log)
  /\ ~CloseIsPending
  /\ LET p == cpos + 1
     IN emission' = Append(emission,
          [kind |-> "ev", key |-> log[p].key, img |-> log[p].img,
           tag |-> p])
  /\ cpos' = cpos + 1
  /\ UNCHANGED <<log, open, nData, nTxn, ci, phase, loS, hiS, nlo, nhi,
                 R, readDone>>

(* The close: emitted when the pass stands immediately before the
   first event beyond the window, or at the end of the pass (the
   heartbeat case; window-closure detection is liveness, not safety).
   The serial loop then moves to the next chunk. *)
CloseChunk ==
  /\ phase = "closing"
  /\ cpos = Len(log) \/ CloseIsPending
  /\ emission' = emission \o CloseBlock(ci)
  /\ ci' = ci + 1
  /\ phase' = "idle"
  /\ UNCHANGED <<log, open, nData, nTxn, loS, hiS, nlo, nhi, R,
                 readDone, cpos>>

Next ==
  \/ CommitTxn
  \/ BeginTxnUncommitted
  \/ FinishTxnUncommitted
  \/ SampleLow
  \/ \E k \in Keys : ReadKey(k)
  \/ SampleHigh
  \/ Consume
  \/ CloseChunk

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
  /\ ci > NumChunks
  /\ cpos = Len(log)

TypeOK ==
  /\ nData \in 0..MaxEvents
  /\ nTxn \in 0..MaxEvents
  /\ \A p \in 1..Len(log) :
       log[p] \in [key : Keys, img : Img, txn : 1..nTxn]
  /\ \A j \in 1..Len(open) :
       open[j] \in [key : Keys, img : Img, txn : 1..nTxn]
  /\ ci \in 1..(NumChunks + 1)
  /\ phase \in {"idle", "select", "closing"}
  /\ \A i \in 1..NumChunks :
       loS[i] \subseteq 1..nTxn /\ hiS[i] \subseteq 1..nTxn
  /\ nlo \in [1..NumChunks -> 0..Len(log)]
  /\ nhi \in [1..NumChunks -> 0..Len(log)]
  /\ R \in [1..NumChunks -> [Keys -> Img]]
  /\ readDone \subseteq Keys
  /\ cpos \in 0..Len(log)
  /\ \A j \in 1..Len(emission) :
       emission[j] \in [kind : {"ev", "refresh"}, key : Keys,
                        img : Img, tag : 0..Len(log)]

(* The paper's committed-only premise, made executable. It is checked by
   every lawful run, checked-to-fail by the dedicated premise probe, and
   omitted by the later uncommitted diagnostic runs. *)
CommittedOnly == open = <<>>

(* Theorem 7: for every sampled bracket, the protocol's set test
   decides exactly the half-open positional window (nlo, nhi], on
   every position of the current log, however far it has grown since
   the samples were taken.  In the A-linear probe this is EXPECTED TO
   FAIL: a malformed interior denotation makes two positionally
   distinct prefixes carry one executed set, and later events of the
   same already committed transaction block are mis-classified. *)
OracleFaithful ==
  \A i \in 1..NumChunks :
    HiSampled(i) =>
      \A p \in 1..Len(log) :
        InWindow(i, p) <=> (nlo[i] < p /\ p <= nhi[i])

(* Theorem 1 with Theorem 2 at the frontier (the content of
   Proposition 4's placement).  In the A-linear probe this is
   EXPECTED TO HOLD, on a complete search: the discipline is
   robust to the denotation violation alone.  A surviving key's
   boundary-honest verdict is forced to the frontier value by
   window invariance. *)
FrontierExact ==
  Done => \A k \in Keys : ReplayOf(emission)[k] = SrcAt(Frontier)[k]

(* Corollary 2 / the frontier-parametric remark. *)
ContinuationExact ==
  ci > NumChunks =>
    \A k \in Keys : ReplayOf(emission)[k] = SrcAt(cpos)[k]

(* Theorem 3: per-key tags never decrease along the emission. *)
PerKeyMonotone ==
  \A j1, j2 \in 1..Len(emission) :
    (j1 < j2 /\ emission[j1].key = emission[j2].key)
      => emission[j1].tag <= emission[j2].tag

(* Proposition 1's target, EXPECTED TO FAIL when checked (as in
   WatermarkLoop): no single shared read boundary is required by O2,
   and the torn read is reachable under write-free brackets too.
   Candidate witnesses range over boundaries because boundaries are
   this instance's coordinate space. *)
SharedInstantExists ==
  \A i \in 1..NumChunks :
    HiSampled(i) =>
      \E c \in nlo[i]..nhi[i] :
        Boundary(c) /\ \A k \in ChunkDoms[i] : R[i][k] = SrcAt(c)[k]

----------------------------------------------------------------------------
(* Model configurations (selected by the .cfg files). *)

MainKeys == {1, 2, 3}
MainVals == {1, 2}
MainChunkDoms == <<{1}, {2, 3}>>

TornKeys == {1, 2}
TornVals == {1, 2}
TornChunkDoms == <<{1, 2}>>

AlinKeys == {1}
AlinVals == {1, 2}
AlinChunkDoms == <<{1}>>

============================================================================
