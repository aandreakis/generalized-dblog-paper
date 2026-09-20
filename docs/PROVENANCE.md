# Provenance

This repository joins two public records without changing their contents:
the arXiv paper and the Zenodo verification artifact.

## Paper record

**Title:** Generalized DBLog: A Verified Contract for Interleaving Copied Rows with a Change Log  
**Author:** Andreas Andreakis  
**arXiv:** [2609.08160](https://arxiv.org/abs/2609.08160)  
**arXiv DOI:** [10.48550/arXiv.2609.08160](https://doi.org/10.48550/arXiv.2609.08160)  
**Current version:** v2, 14 September 2026  
**Subjects:** cs.DB, cs.DC, cs.LO  
**License:** CC BY 4.0  
**Extent:** 38 pages, 6 figures

### Version history

| Version | Date | Public record |
|---|---|---|
| v1 | 8 Sep 2026 | [arXiv:2609.08160v1](https://arxiv.org/abs/2609.08160v1) |
| v2 | 14 Sep 2026 | [arXiv:2609.08160v2](https://arxiv.org/abs/2609.08160v2) |

Version v1 carries the title *Generalized DBLog: A Verified Contract for
Interleaving Database Rows with a Change Log*. Version v2 carries the current
title.

### Repository payload

The following files under <code>paper/</code> are the payload members of
the public v2 source:

- <code>main.tex</code>
- <code>main.bbl</code>
- <code>acmart.cls</code>
- six vector PDFs under <code>figures/</code>

The public source export also supplies an arXiv-generated
<code>00README.json</code>. It is transport metadata and is not part of the
paper payload mirrored here.

The repository PDF <code>paper/generalized-dblog.pdf</code> is arXiv's v2
build, including its margin stamp.

**Public PDF SHA-256:**
<code>03ca12662940bd747e573f16f2f315ae6c01f322f993414f10cec038a7ec861c</code>

The source payload was compared file by file with the public arXiv v2
export on 20 September 2026. Every payload file was identical.

## Verification-artifact record

**Record title:** Formal development for "Generalized DBLog: A Verified
Contract for Interleaving Copied Rows with a Change Log"  
**Version:** 1.0  
**Publication date:** 7 September 2026  
**Version DOI:** [10.5281/zenodo.22643866](https://doi.org/10.5281/zenodo.22643866)  
**Concept DOI:** [10.5281/zenodo.22643865](https://doi.org/10.5281/zenodo.22643865)  
**License:** BSD 3-Clause  
**Archive:** <code>Generalized_DBLog_artifact-1.0.zip</code>

**Archive SHA-256:**
<code>5009f27f51863ad5065dc3225f99eae0b43d3f1791cc4a1c62370838b0ffe8a5</code>

**Zenodo MD5:**
<code>203fdafcf63d0975dedd0dced4941df9</code>

The extracted archive contains 167 files. They include 48 Isabelle theory
files in three sessions, 6 Lean files, 5 TLA+ specifications with 25 TLC
configurations, 3 typeset proof documents, verification records, and the
unmodified upstream archive of the classic DBLog development. The extracted
tree is mirrored verbatim as <code>formal/</code>.

The MD5 of the local archive was compared with the checksum that the Zenodo
record publishes for its file on 20 September 2026. They matched, and the
<code>formal/</code> tree was populated from those bytes. The archive's own
<code>SHA256SUMS</code> file verifies all 166 other files of the tree.

The record's title, description and file were updated in place after the first
publication, to follow the paper's v2 title. The version number and the DOIs
did not change. The hashes on this page are those of the file that the record
published on 20 September 2026.

## Relationship between the records

The arXiv paper cites the artifact's version DOI
<code>10.5281/zenodo.22643866</code>. The Zenodo record declares itself
<code>isSupplementTo</code> arXiv:2609.08160 and <code>isDerivedFrom</code> the
formal development of the earlier DBLog theory paper,
<code>10.5281/zenodo.21732790</code>. The file
<code>formal/ARTIFACT_PROVENANCE.md</code> documents that dependency.

This GitHub repository is not a third archival authority. It is an
information hub that makes the two records easier to inspect together:

- Use arXiv for the paper of record.
- Use the Zenodo version DOI when you need the exact artifact bytes.
- Use the Zenodo concept DOI when a citation should follow future artifact
  versions.
- Use GitHub for browsing and issue discussion.

## Derived files

The following files are derived and are not part of either archived
payload:

- <code>README.md</code>
- <code>AGENTS.md</code>
- <code>docs/</code>
- <code>paper/README.md</code>
- <code>CITATION.cff</code>
