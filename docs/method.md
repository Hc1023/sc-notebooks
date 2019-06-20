# Method details

## Method overview

Our method recovers genomes from large-scale single-cell sequencing data of gut microbiome samples. All the data, dependent computational tools and source code for our method are publicly available.

We proposed a new data analysis pipeline and applied it to 21,914 single-cells’ sequencing data, with a total of 89 high-quality (> 90% completeness, < 5% contamination) genome assemblies recovered, among which 41 known species and 9 unknown species were found. Our method requires little prior knowledge of the community to work, and features the potential ability to detailed studies of the microbial communities at the cell level.

> The numbers mentioned above need update accordingly.

The very fundamental idea of our computational pipeline is to co-assemble the sequencing data of the cells that are likely to be the same species, and thus genomes of the species are supposed to be recovered. The co-assembly is necessary, since each single-cell sequencing file reveals limited completeness of the cell’s information. Empirically, a high-quality genome assembly requires sequencing data of at least 20 cells from the same species.

Our method can be roughly divided into three stages. a) Iterative comparing and aggregating, which tries to gather the cells of the same species to the same group. Each iteration is done by sequence comparisons of cells or groups of cells, with the help of Sourmash, an implementation of the MinHash similarity comparing algorithm. The cell or cell groups with similarities to an extent will be gathered using cluster analysis techniques. And later co-assembled to get draft genome assemblies for quality check. b) Splitting the contaminated cell groups and merging the groups representing identical species, which could fix the false positives and the false negatives respectively introduced in former stage. c) Final co-assembly and clean up, which finalize the whole process returning the genomes we recovered from the input sequencing data.

## Sequencing data of 22k single cells was used for recovering genomes

The single-cell sequencing data comes from 15 stool samples of the same donor, adding up to 21,914 cells in all. 10 of the samples were sequenced with Illumina NovaSeq and NextSeq systems. The other 5 were sequenced with Illumina NextSeq only. All cells have both single-end and paired-end read sequencing data.

> Numbering the table

| ID   | Sample contnet | Cell number | Sequence platform |
| ---- | -------------- | ----------- | ----------------- |
| 5    | Stool 44-150   | 2167        | NovaSeq & NextSeq |
| 7    | Stool 44-150   | 2426        | NovaSeq & NextSeq |
| 8    | Stool 44-111   | 2332        | NovaSeq & NextSeq |
| 9    | Stool 44-111   | 2319        | NovaSeq & NextSeq |
| 10   | Stool 44-171   | 1606        | NovaSeq & NextSeq |
| 11   | Stool 44-172   | 1242        | NovaSeq & NextSeq |
| 12   | Stool 44-172   | 2276        | NovaSeq & NextSeq |
| 14   | Stool 44-14    | 2109        | NovaSeq & NextSeq |
| 15   | Stool 44-150   | 1125        | NovaSeq & NextSeq |
| 27   | Stool 44-150   | 1301        | NovaSeq & NextSeq |
| 31   | Stool 44-52    | 209         | NextSeq           |
| 32   | Stool 44-52    | 462         | NextSeq           |
| 33   | Stool 44-224   | 1056        | NextSeq           |
| 34   | Stool 44-52    | 464         | NextSeq           |
| 35   | Stool 44-224   | 820         | NextSeq           |

A mock community consisting of 2,985 cells is used as baseline data for the methods’ justification and assessment. The mock community is made up of 4 species: *Bacillus subtilis*, *Escherichia coli*, Klebsiella pneumoniae, and *Staphylococcus aureus*. The data is acquired by Illumina NextSeq, resulting both single-end and paired-end reads.

## Computational dependencies

The computational tools we used in our pipeline are all publicly accessible. The common tasks in the analysis includes alignment, assembly, sequence comparison, clustering and quality assessment. The table lists the computational dependencies of our method, together with their sources and functions.

> Numbering the table

| Environment name     | Function                           | Citation               | URL                                                   |
| -------------------- | ---------------------------------- | ---------------------- | ----------------------------------------------------- |
| Bowtie2 v2.2.6       | Alignment tool                     | Langmead et al., 2012  | http://bowtie-bio.sourceforge.net/bowtie2/index.shtml |
| CheckM v1.0.13       | Genome assembly quality check      | Parks et al., 2015     | https://github.com/Ecogenomics/CheckM                 |
| FastANI v1.1         | Alignment-free sequence comparison | Jain et al., 2018      | https://github.com/ParBliSS/FastANI                   |
| scikit-learn v0.20.3 | Machine learning toolkit           | Pedregosa et al,. 2011 | https://scikit-learn.org                              |
| Sourmash v2.0.0      | Alignment-free sequence comparison | Brown et al,. 2016     | https://github.com/dib-lab/sourmash                   |
| SPAdes v3.13.0       | Assembler                          | Bankevich et al,. 2012 | https://github.com/ablab/spades                       |

## Iterative comparing and aggregating

The very first iterative stage gather the cells that are potentially from the same species. Sourmash signatures of reads or contigs are helpful features for evaluating similarities of sequences. The cells are gathered in a bottom-up manner using hierarchical clustering technique, with the comparing subjects being combinations of the prior results in the last iteration. This comparing and clustering is repeated, i.e. iterated.

A pre-division is performed to the dataset before the cells’ pairwise comparison, because comparing 22k cells pairwisely with Sourmash is infeasible with the limited RAM resources. A pairwise comparison of cells, as well as the later hierarchical clustering, takes *O*(*n*<sup>2</sup>) complexity, spatial and temporal. To allow the first few pairwise comparison to happen, we divided the 22k cells into 6 divisions by lexicographical order of their identifiers (that is also by random, the cell identifiers are concatenations of sample identifiers and the cells’ bar codes). Each of the divisions has at most 4,000 cells, and the cells’ pairwise comparisons starts within each division.

**Computing signatures extracts features for comparison.** The sequence comparing tool, Sourmash, is an implementation of the adapted MinHash algorithm, which is a *k*-mer based method used for comparing the similarity of two sets. The feature vectors extracted from the sequences, i.e. signatures, are later used for computing the similarities of the query sequences. The computation of signatures and evaluation of the similarities of the signatures are faster than alignment-based comparison by orders of magnitude. 

### Pre-division

The motivation of the pre-division is to make mash comparison feasible for large number of cells. Sourmash’s mash distance comparison requires intensive RAM usage, making 20k signatures impossible to compare all at once. Intentionally 

```
$ bash dividing.sh
```

The command line above will generate lists of cell numbers and write the files containing lists of cells to the directory `divisions`. The default division size is 4000. This can be modified in the script,

```
DIVISION_SIZE=4000
```

Output files of the script have the extension `.tsv`. Within each file, every single line is the name for the cell’s sequencing data. An example is given below,

```
1000000
1000010
1000013
1000020
...
```

### Computing Mash signatures

Mash signatures can be used as a feature for fast comparison between sequencing data files.

You'll have to compute the Mash signatures for every raw cell sequencing data. The 

```
$ sbatch raw-sig-parallel.slurm
```

> Note: The following lines in this file need modification to adapt to your own environment configuration.
>
> ```shell
> module add c3ddb/miniconda/3.7
> source activate sourmash
> ```



