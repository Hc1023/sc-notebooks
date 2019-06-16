# Genome recovery from single-cell sequencing data

> Data and intermediate files are located at `/scratch/users/yehang/nsc-full`. The description below uses relative paths to this directory.

Recovering high-quality genomes is an important task in genomics applied to microbial communities. Such a task applied to metagenomics sequencing data, aka binning, is already widely practiced, while genome recovery from single-cell sequencing data remains under-developed.

We here introduce an effective computational pipeline for recovering genomes from single-cell sequencing data in large scale, with detailed descriptions to the scripts we are using. The document serves as a readme/recipe to reproduce our method.

The very fundamental idea of our pipeline is to co-assemble the cells that are likely to be the same species, and thus genomes of the species are supposed to be recovered. Each single-cell sequencing file reveals limited completeness of the cell’s information. Empirically, a high-quality genome assembly requires sequencing data of at least 20 cells of the same species.

Our method can be roughly divided into three stages. a) Iterative comparing and aggregating, which tries to gather the cells of the same species to the same group. Each iteration is done by sequence comparisons of cells or groups of cells, with the help of Sourmash, an implementation of the MinHash similarity comparing algorithm. The cell or cell groups with similarities to an extent will be gathered using cluster analysis techniques. And later co-assembled to get draft genome assemblies for quality check. b) Splitting the contaminated groups and merging the groups representing identical species, which could fix the false positives and the false negatives introduced in former stage respectively. c) Final co-assembly and clean up, which finalize the whole process and returns the genomes we recovered from the input sequencing data.

## Data specification



## Dependencies




## Iterative comparing and aggregating

### Pre-division

The motivation of the pre-division is to make mash comparison feasible for large number of cells

```
$ bash dividing.sh
```

### Computing Mash signatures

Mash signatures can be used as a feature for fast comparison between sequencing data files. 
You'll have to compute the Mash signatures for every raw cell sequencing data.

```

```