# Artifact provenance

The generalized development in `dblog_framework/framework_core/` builds against the classic `DBLog_Virtual_Cuts` session in `formal/`, which in turn depends on shared source-history and replay definitions in `dual_write_layer0/`.

The cited upstream artifact is Andreas Andreakis, *Isabelle/HOL formal development for "A Theoretical Study of DBLog"*, version 2.1, [DOI 10.5281/zenodo.21732790](https://doi.org/10.5281/zenodo.21732790). The earlier [version 1.0 record](https://zenodo.org/records/20389697) has a distinct version DOI; its version series has concept DOI `10.5281/zenodo.20389696`. This generalized artifact is a separate work, not a new version of that classic artifact.

The version 2.1 archive was fetched anew on 7 September 2026 and its bytes checked against the MD5 in Zenodo's file metadata. Zenodo's version list and latest-version endpoint confirmed version 2.1 as the latest published classic artifact on that date. The unmodified downloaded archive is included under `upstream/`.

Of its 38 theory files, 19 are byte-identical to the corresponding current dependency files. The other 19 contain the following accounted-for changes:

1. Imports of shared source-history, coordinate, scope, and replay theories acquire the `Dual_Write_Layer0` session qualifier. The four shared theory bodies are byte-identical to their published versions.
2. The definition of `core_virtual_cut_state` moves from `Virtual_Cut_Core.thy` to the shared `Virtual_Cut_State.thy` and is named `virtual_cut_state`.
3. The identical duplicate `virtual_cut_state` definition is removed from `Virtual_Cut.thy`; references use the shared constant. The old compatibility equality between the two identical predicates becomes reflexivity, and one redundant simplification reference is removed.
4. Documentation describes the shared-session arrangement.

The three predicate bodies (the two published definitions and the consolidated definition) are identical after naming normalization. After removing comments/documentation, normalizing session qualifications and predicate names, and accounting explicitly for the relocated definition and redundant equality, every remaining code token agrees. No unmatched change to a theorem assumption or conclusion was found. The published `DBLog_Run.thy`, `DBLog_Run_Substrate.thy`, and `Continuation.thy` are byte-identical. This is a source comparison, complemented by the fresh complete session build; it is not a claim that the archives themselves are byte-identical.

The original-to-current hash comparison, classified differences, and complete textual diffs are included under `upstream/`. All current prover and model inputs were copied byte-for-byte into fresh verification directories. `verification/verified-inputs.json` binds the source files shipped in this archive to those fresh checks; `SHA256SUMS` checks the whole extracted package.

No theorem source was changed during the 7 September 2026 release check. The paper's former assertion that the imported development was unaltered was corrected to describe the existing refactoring accurately.
