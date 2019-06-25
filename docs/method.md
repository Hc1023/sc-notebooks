# Method details

## Method overview

Our method recovers genomes from large-scale single-cell sequencing data of gut microbiome samples. All the data, dependent computational tools and source code for our method are publicly available.

We proposed a new data analysis pipeline and applied it to 21,914 single-cells’ sequencing data, with a total of 89 high-quality (> 90% completeness, < 5% contamination) genome assemblies recovered, among which 41 known species and 9 unknown species were found. Our method requires little prior knowledge of the community to work, and features the potential ability to detailed studies of the microbial communities at the cell level.

> The numbers mentioned above need update accordingly.

The very fundamental idea of our computational pipeline is to co-assemble the sequencing data of the cells that are likely to be the same species, and thus genomes of the species are supposed to be recovered. The co-assembly is necessary, since each single-cell sequencing file reveals limited completeness of the cell’s information. Empirically, a high-quality genome assembly requires sequencing data of at least 20 cells from the same species.

Our method can be roughly divided into three stages. a) Iterative comparing and aggregating, which tries to gather the cells of the same species to the same group. Each iteration is done by sequence comparisons of cells or groups of cells, with the help of Sourmash, an implementation of the MinHash similarity comparing algorithm. The cell or cell groups with similarities to an extent will be gathered using cluster analysis techniques. And later co-assembled to get draft genome assemblies for quality check. b) Splitting the mixed cell groups and merging the groups representing identical species, which could fix the false positives and the false negatives respectively introduced in former stage. c) Final co-assembly and clean up, which finalize the whole process returning the genomes we recovered from the input sequencing data.

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

A mock community consisting of 2,985 cells is used as baseline data for the methods’ justification and assessment. The mock community is made up of 4 species: *Bacillus subtilis*, *Escherichia coli*, *Klebsiella pneumoniae*, and *Staphylococcus aureus*. The data is acquired by Illumina NextSeq, resulting both single-end and paired-end reads.

## Computational dependencies

The computational tools we used in our pipeline are all publicly accessible. The common tasks in the analysis includes alignment, assembly, sequence comparison, clustering and quality assessment. The table lists the computational dependencies of our method, together with their sources and functions.

> Numbering the table

| Environment name | Function                           | Citation               | URL                                                   |
| ---------------- | ---------------------------------- | ---------------------- | ----------------------------------------------------- |
| Bowtie2 v2.2.6   | Alignment tool                     | Langmead et al., 2012  | http://bowtie-bio.sourceforge.net/bowtie2/index.shtml |
| CheckM v1.0.13   | Genome assembly quality check      | Parks et al., 2015     | https://github.com/Ecogenomics/CheckM                 |
| FastANI v1.1     | Alignment-free sequence comparison | Jain et al., 2018      | https://github.com/ParBliSS/FastANI                   |
| SciPy v1.2.1     | Data science library               | Jones et al,. 2001     | https://www.scipy.org/                                |
| Sourmash v2.0.0  | Alignment-free sequence comparison | Brown et al,. 2016     | https://github.com/dib-lab/sourmash                   |
| SPAdes v3.13.0   | Assembler                          | Bankevich et al,. 2012 | https://github.com/ablab/spades                       |

## Iterative comparing and aggregating

The very first iterative stage gather the cells that are potentially from the same species. Sourmash signatures of reads or contigs are helpful features for evaluating similarities of sequences. The cells are gathered in a bottom-up manner using the hierarchical clustering technique, with the comparing subjects being combinations of the prior results in the last iteration. This comparing and clustering is repeated, i.e. iterated.

**A pre-division is performed to the dataset before the cells’ pairwise comparison**, because comparing 22k cells pairwisely with Sourmash is infeasible with the limited RAM resources. A pairwise comparison of cells, as well as the later hierarchical clustering, takes *O*(*n*<sup>2</sup>) complexity, spatial and temporal. To allow the first few pairwise comparisons to happen, we divided the 22k cells into 6 divisions by lexicographical order of their identifiers (that is also by random, the cell identifiers are concatenations of sample identifiers and the cells’ bar codes). Each of the divisions has at most 4,000 cells, and the cells’ pairwise comparisons starts within each division.

**Computing signatures extracts features for comparison.** The sequence comparing tool, Sourmash, is an implementation of the adapted MinHash algorithm, which is a *k*-mer based method used for comparing the similarity of two sets. The feature vectors extracted from the sequences, i.e. signatures, are later used for computing the similarities of the query sequences. The computation of signatures and evaluation of the similarities of the signatures are faster than alignment-based comparison by orders of magnitude. In our analysis, we are using the default *k*-mer length (`-k 21,31,51`), resolution (`--scaled 1000`) and number of hashes (`-n 1000`). The abundance information is saved (`--track-abundance`). Hashes for 51-mers are used for later comparisons. 

**Each comparison gives a distance matrix, which is used for clustering.** The entries of the matrix are Jaccard index values representing the similarity of two query sequences. With the distance matrix, the similar cells (the first iteration) or cell groups (the else) can be gathered with the hierarchical clustering technique. The hierarchical clustering algorithm returns a dendrogram of the input subjects, and clusters can be formed by splitting the dendrogram under certain criterion and flatten the subtrees to sublists of the subjects. 

**5% similarity under Jaccard index is used for determining clusters.** The choice of this cutoff value can be justified by the mock data, as few of the pairwise distances of cells from different species have a similarity of more than 5%, when comparing to the cells from the same species, as shown in the figure. The hierarchical clustering is using complete linkage method (`method='complete'`) and splitting by the 0.95 distance criterion (`0.95, criterion='distance'`). The distance is the dissimilarity, i.e. 1 - Jaccard index). This would ensure that the maximum distances within each cell cluster resulted are no more than 0.95. In other words, the cells in each cluster are at least 5% similar by their Jaccard index given by Sourmash.

> Supplementary figure needed
>
> Data source: https://github.com/celestialphineas/sc-notebooks/tree/master/data/mock-mash
>
> `dist.csv.gz` is the distance matrix of the cells’ raw reads in `.csv` format. `species.tsv` is a list of the cell id’s and their corresponding species. Note that when plotting the histogram for pairwise distances of the cells, the self-comparisons need crossing out. See below for a reference of an implementation,
>
> https://github.com/celestialphineas/sc-notebooks/blob/master/mock-mash.pdf

**The clustered cells were co-assembled for quality check and further comparing.** Co-assembly of multiple cells improves the information of corresponding species. The co-assembled contigs are used for signature computing, comparison and clustering in the next iteration. Though the paired-end information preserves, we treat the data single-end-wisely. The files will be merged together when assembly, resulting the assembly outperforms the result of paired-end-wise assembly slightly. We use SPAdes as the assembler with the single-cell mode (`–-sc`) on to reduce the impact of MDA, and the `--careful` option to run MismatchCorrector for post processing. Quality properties of the assemblies, especially completeness and contamination, are evaluated with CheckM.

> Is it legit to call a cell group and its co-assembly a “bin”?

**The above steps are iterated until 10% of the genome assemblies have > 20% contamination.** The major motivation of the iterations is to reduce false negatives (clustering cells being the same species to the same group as far as possible). However, the clustering steps of the iterations are also involving false positives (cell groups containing more than one species). Empirically, a cell group whose co-assembly has > 20% contamination contains cells from more than one species. To allow the stage to stop, and for sake of reasonable portions of false errors, we keep the ratio for > 20% contaminated assemblies below 10%. For our instance, the process is iterated for 3 times before termination.

> Update the number of iterations if needed

## Correcting errors of the iteration result

Splitting the mixed cell groups and merging the groups representing identical species would correct the false positive and false negative errors respectively. 

**To split the mixed cell groups (i.e. false positives in former clustering), an abundance-based clustering is applied.** The heavily contaminated assemblies (> 20% contamination) correspond to cell groups containing cells of multiple species. We extract the contigs with lengths > 1kbp in the assemblies, and use the average sequencing depths (i.e. abundances) of the contigs as a feature to cluster the cells potentially from the same species together.

Assume that the co-assembly of the cell group *g*, which consists of *n* cells, has *m* contigs with lengths > 1kbp. Let <i>d<sub>ij</sub></i> denote the average sequencing depth of contig *j* in cell *i*. Then for each cell *i* in group *g*, <i><b>d</b><sub>i</sub></i> = (<i>d</i><sub><i>i</i>1</sub>, <i>d</i><sub><i>i</i>2</sub>, …, <i>d<sub>im</sub></i>)<sup>T</sup> is a column vector describing the contig abundances into the cell's sequencing.

Each of the mixed cell groups, has a matrix describing the abundances across contigs in cells.

<i><b>D</b></i> = (<i><b>d</b></i><sub>1</sub> <i><b>d</b></i><sub>2</sub> ⋯ <i><b>d</b><sub>n</sub></i>) = (<i>d<sub>ij</sub></i>)<i><sub>m×n</sub></i>

The normalization to produce the feature vectors of the cells is a combination of both the row normalization and the column normalization. The row normalization reduces the impact of contigs' contribution disparity to different cells. And the column normalization reduces the bias in the dissimilarity estimation of the cells, i.e. distances of the cells' contig abundance vectors. The normalization and distance computation are with respect to the 2-norm.

A hierarchical clustering is performed to the distance matrix of the normalized data, using complete linkage method with a 1.4 cutoff value for splitting the dendrogram, which is chosen by looking into our previous results split using human effort with the help of elbow method and plotting the distance matrix.

> The justification of this 1.4 cutoff value refer to the following link:
>
> https://github.com/celestialphineas/sc-notebooks/blob/master/splitting-groups.pdf

**The cell groups supposed to be the same species are merged using ANI comparison.** FastANI is a tool for fast evaluating average nucleotide identity (ANI) of draft genome assemblies, and has good correlation to the sequences’ real ANI for draft genomes with > 80% completeness. The common practice of 95% ANI as the species boundary is used for merging cell groups.

## Finalization and clean-up

The resulting cell groups given by the correcting stage are used for the final assembly. After a … clean-up …, and we…

> Details for Wenshan’s clean-up method

