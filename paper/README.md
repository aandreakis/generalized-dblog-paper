# Paper source

This directory mirrors the public arXiv v3 paper payload for:

> Generalized DBLog: A Verified Contract for Interleaving Copied Rows with a Change Log  
> Andreas Andreakis  
> arXiv:2609.08160v3

## Contents

- <code>main.tex</code> - manuscript source
- <code>main.bbl</code> - frozen bibliography generated for the public build
- <code>acmart.cls</code> - class bundled with the arXiv submission
- <code>figures/</code> - six vector-PDF figures
- <code>generalized-dblog.pdf</code> - arXiv's stamped 39-page v3 PDF

ArXiv's generated <code>00README.json</code> transport metadata is not
mirrored. Every paper payload member was compared file by file with the
public source export.

## Build

~~~bash
pdflatex main
pdflatex main
pdflatex main
~~~

The source bundle carries <code>main.bbl</code>, so BibTeX is not required
for the exact public rebuild.

## Public record

- [Abstract](https://arxiv.org/abs/2609.08160v3)
- [PDF](https://arxiv.org/pdf/2609.08160v3)
- [Source](https://arxiv.org/e-print/2609.08160v3)
- [DOI](https://doi.org/10.48550/arXiv.2609.08160)

The paper text and figures are licensed CC BY 4.0, matching the arXiv
posting. <code>acmart.cls</code> is the ACM class file. It keeps its own
terms, stated in its header.
