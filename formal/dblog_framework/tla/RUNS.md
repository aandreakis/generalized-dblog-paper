# Fresh TLC run record, 7 September 2026

All runs use the five specifications and configurations in this directory. The full outcome records and logs are in `../../verification/`. Expected violations are deliberate negative checks.

| Run | Configuration | Expected result | Distinct states |
| --- | --- | --- | --- |
| S1-A | `WatermarkLoop.cfg` | PASS | 12,844,167 |
| S1-B | `WatermarkLoop_torn_green.cfg` | PASS | 4,785 |
| S1-C | `WatermarkLoop_torn.cfg` | VIOLATED: SharedInstantExists | 1,988 |
| S2-A | `ReadOnlyBrackets.cfg` | PASS | 25,606,379 |
| S2-B | `ReadOnlyBrackets_torn_green.cfg` | PASS | 3,297 |
| S2-C | `ReadOnlyBrackets_torn.cfg` | VIOLATED: SharedInstantExists | 1,816 |
| S2-D0 | `ReadOnlyBrackets_alinear_green.cfg` | PASS | 898 |
| S2-D1 | `ReadOnlyBrackets_alinear_oracle.cfg` | VIOLATED: OracleFaithful | 247 |
| S2-D2 | `ReadOnlyBrackets_alinear_replay.cfg` | PASS | 988 |
| S2-D3 | `ReadOnlyBrackets_alinear_replay_wide.cfg` | PASS | 33,205,754 |
| S2-E1 | `ReadOnlyBrackets_uncommitted_premise.cfg` | VIOLATED: CommittedOnly | 14 |
| S2-E2 | `ReadOnlyBrackets_uncommitted_oracle.cfg` | VIOLATED: OracleFaithful | 550 |
| S2-E3 | `ReadOnlyBrackets_uncommitted_replay.cfg` | PASS | 1,159 |
| S3-A | `ParallelChunks.cfg` | PASS | 73,690,264 |
| S3-B | `ParallelChunks_prop3_green.cfg` | PASS | 829 |
| S3-C | `ParallelChunks_noclausea.cfg` | VIOLATED: FrontierExact | 768 |
| S3-D | `ParallelChunks_pointsplice_green.cfg` | PASS | 3,314 |
| S3-E | `ParallelChunks_pointsplice.cfg` | VIOLATED: EarlyOnsetExists | 2,496 |
| S4-A | `DumpSplice.cfg` | PASS | 5,049 |
| S4-B | `DumpSplice_degraded.cfg` | PASS | 23,373 |
| S4-C | `DumpSplice_wrongpoint.cfg` | VIOLATED: FrontierExact | 796 |
| S4-D | `DumpSplice_degraded_probe.cfg` | VIOLATED: WidenedTrajectory | 34 |
| S5-A | `SharedWitnessMixing.cfg` | PASS | 31,674 |
| S5-B | `SharedWitnessMixing_distinct.cfg` | PASS | 80,248 |
| S5-C | `SharedWitnessMixing_probe.cfg` | VIOLATED: DistinctOnsetTrajectory | 645 |
