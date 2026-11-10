# Paper source

This directory holds the source files of the public arXiv v4 bundle for:

> Generalized DBLog: A Verified Contract for Interleaving Copied Rows with a Change Log  
> Andreas Andreakis  
> arXiv:2609.08160v4

## Contents

- `main.tex`: manuscript source
- `main.bbl`: bibliography as generated for the public build
- `acmart.cls`: class bundled with the arXiv submission
- `figures/`: six vector-PDF figures
- `generalized-dblog.pdf`: arXiv's stamped 40-page v4 PDF

The `00README.json` file that arXiv generates is not copied here.
Every source file matches the public arXiv v4 bundle byte for byte.

## Build

~~~bash
pdflatex main
pdflatex main
pdflatex main
~~~

The source bundle carries `main.bbl`, so BibTeX is not required
for the exact public rebuild.

## Public record

- [Abstract](https://arxiv.org/abs/2609.08160v4)
- [PDF](https://arxiv.org/pdf/2609.08160v4)
- [Source](https://arxiv.org/e-print/2609.08160v4)
- [DOI](https://doi.org/10.48550/arXiv.2609.08160)

The paper text and figures are licensed CC BY 4.0, matching the arXiv
posting. `acmart.cls` is the ACM class file. It keeps its own
terms, stated in its header.
