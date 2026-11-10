# Provenance

This repository joins two public records without changing their contents:
the arXiv paper and the Zenodo verification artifact.

## Paper record

**Title:** Generalized DBLog: A Verified Contract for Interleaving Copied Rows with a Change Log  
**Author:** Andreas Andreakis  
**arXiv:** [2609.08160](https://arxiv.org/abs/2609.08160)  
**arXiv DOI:** [10.48550/arXiv.2609.08160](https://doi.org/10.48550/arXiv.2609.08160)  
**Current version:** v4, 5 October 2026  
**Subjects:** cs.DB, cs.DC, cs.LO  
**License:** CC BY 4.0  
**Extent:** 40 pages, 6 figures

### Version history

| Version | Date | Public record |
|---|---|---|
| v1 | 8 Sep 2026 | [arXiv:2609.08160v1](https://arxiv.org/abs/2609.08160v1) |
| v2 | 14 Sep 2026 | [arXiv:2609.08160v2](https://arxiv.org/abs/2609.08160v2) |
| v3 | 21 Sep 2026 | [arXiv:2609.08160v3](https://arxiv.org/abs/2609.08160v3) |
| v4 | 5 Oct 2026 | [arXiv:2609.08160v4](https://arxiv.org/abs/2609.08160v4) |

Version v1 carries the title *Generalized DBLog: A Verified Contract for
Interleaving Database Rows with a Change Log*. Versions v2, v3 and v4 carry
the current title. Version v3 extends the analysis to Debezium's PostgreSQL
read-only mode. Version v4 adds a sixth watermark precondition, visibility
order, which a PostgreSQL primary does not guarantee. It states the further
conditions under which the watermark-based and read-only results hold there.
No numbered result of the paper changes in v3 or v4, and the verification
artifact stays at version 1.0.

### Paper files in this repository

The following files under `paper/` come from the public arXiv v4
source bundle:

- `main.tex`
- `main.bbl`
- `acmart.cls`
- six vector PDFs under `figures/`

The public bundle also contains `00README.json`, a file that arXiv
generates. It is not part of the paper and is not copied here.

The repository PDF `paper/generalized-dblog.pdf` is arXiv's v4
build, including its margin stamp.

**Public PDF SHA-256:**
`3210f8922afb86d501b7cc83d005cf62101ad91ca79ec4a6dc5f8d5c561fae76`

The source files were compared with the public arXiv v4 bundle on
10 November 2026. Every file matched byte for byte.

## Verification-artifact record

**Record title:** Formal development for "Generalized DBLog: A Verified
Contract for Interleaving Copied Rows with a Change Log"  
**Version:** 1.0  
**Publication date:** 7 September 2026  
**Version DOI:** [10.5281/zenodo.22643866](https://doi.org/10.5281/zenodo.22643866)  
**Concept DOI:** [10.5281/zenodo.22643865](https://doi.org/10.5281/zenodo.22643865)  
**License:** BSD 3-Clause  
**Archive:** `Generalized_DBLog_artifact-1.0.zip`

**Archive SHA-256:**
`5009f27f51863ad5065dc3225f99eae0b43d3f1791cc4a1c62370838b0ffe8a5`

**Zenodo MD5:**
`203fdafcf63d0975dedd0dced4941df9`

The extracted archive contains 167 files. They include 48 Isabelle theory
files in three sessions, 6 Lean files, 5 TLA+ specifications with 25 TLC
configurations, 3 typeset proof documents, verification records, and the
unmodified upstream archive of the classic DBLog development. The extracted
tree is copied unchanged as `formal/`.

The MD5 of the local archive was compared with the checksum that the Zenodo
record publishes for its file on 20 September 2026. They matched, and
`formal/` was unpacked directly from that archive. The archive's own
`SHA256SUMS` file verifies all 166 other files of the tree.

The record's title, description and file were updated in place after the first
publication, to follow the paper's v2 title. The version number and the DOIs
did not change. The hashes on this page are those of the file that the record
published on 20 September 2026.

## Relationship between the records

The arXiv paper cites the artifact's version DOI
`10.5281/zenodo.22643866`. The Zenodo record declares itself
`isSupplementTo` arXiv:2609.08160 and `isDerivedFrom` the
formal development of the earlier DBLog theory paper,
`10.5281/zenodo.21732790`. The file
`formal/ARTIFACT_PROVENANCE.md` documents that dependency.

This GitHub repository brings the paper and the artifact together in one
place. It is not a separate archival record:

- Use arXiv for the paper of record.
- Use the Zenodo version DOI when you need the exact artifact bytes.
- Use the Zenodo concept DOI when a citation should follow future artifact
  versions.
- Use GitHub for browsing and issue discussion.

## Files written for this repository

The following files were written for this repository and are not part of
either archived record:

- `README.md`
- `AGENTS.md`
- `docs/`
- `paper/README.md`
- `CITATION.cff`
