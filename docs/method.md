# Method details

## Method overview

Our method recovers genomes from large-scale single-cell sequencing data of gut microbiome samples. All the data, dependent computational tools and source code for our method are publicly available.

We proposed a new data analysis pipeline and applied it to 21,914 single-cells’ sequencing data, with a total of 89 high-quality (> 90% completeness, < 5% contamination) genome assemblies recovered, among which 41 known species and 9 unknown species were found. Our method requires little prior knowledge of the community to work, and features the potential ability to detailed studies of the microbial communities at the cell level.

> Note: The numbers mentioned above need update accordingly.

The very fundamental idea of our computational pipeline is to co-assemble the sequencing data of the cells that are likely to be the same species, and thus genomes of the species are supposed to be recovered. The co-assembly is necessary, since each single-cell sequencing file reveals limited completeness of the cell’s information. Empirically, a high-quality genome assembly requires sequencing data of at least 20 cells from the same species.

Our method can be roughly divided into three stages. a) Iterative comparing and aggregating, which tries to gather the cells of the same species to the same group. Each iteration is done by sequence comparisons of cells or groups of cells, with the help of Sourmash, an implementation of the MinHash similarity comparing algorithm. The cell or cell groups with similarities to an extent will be gathered using cluster analysis techniques. And later co-assembled to get draft genome assemblies for quality check. b) Splitting the contaminated cell groups and merging the groups representing identical species, which could fix the false positives and the false negatives respectively introduced in former stage. c) Final co-assembly and clean up, which finalize the whole process returning the genomes we recovered from the input sequencing data.

## The genomes were recovered from sequencing data of 20k single cells

Our data, acquired by NextSeq and NovaSeq technology, concerns both paired-end and single-end reads. The naming convention follows a very simple rule,

```
<CELL NAME>_<1|2|S>.fastq
```

where the paired-end reads end with `1.fastq` or `2.fastq`, and the file for single-end reads end with `S.fastq`. 

Though the paired-end information preserves, we treat the data single-end-wisely. The files will be merged together when we compute the mash distances and assemble the reads. By doing this, the assembly outperforms the result of paired-end-wise assembly slightly.

Currently we have sequencing data of 21,914 single cells from multiple samples of the same donor, and thus there are 21,914 × 3 = 65,742​ `.fastq` files in directory `raw`.

## Dependencies

The computation is performed on a cluster running a [Slurm workload manager](https://slurm.schedmd.com/documentation.html). A few of the scripts depend on the `sbatch` command for submitting jobs to Slurm.

Some tools we are using require [Conda](https://docs.conda.io/en/latest/) for package management. Below is a list of the Conda environments we are using and how to configure them.

| Environment name | Configurations                                               |
| ---------------- | ------------------------------------------------------------ |
| checkm           | python=2.7, [CheckM 1.0.13](https://github.com/Ecogenomics/CheckM/wiki) |
| sklearn          | python=3.7, [scikit-learn 0.20.3](https://scikit-learn.org/stable/) |
| sourmash         | python=3.7, [Sourmash 2.0.0](<https://sourmash.readthedocs.io/en/latest/>) |

Some environments are managed with `module` on the cluster, including Miniconda, SPAdes assembler and Bowtie2.

You need to look into the scripts and modify the corresponding lines accordingly to make it work for your case.

## Iterative comparing and aggregating

### Computing signatures

The sequence comparing tool, Sourmash, is based on MinHash algorithm, which is originally used for comparing the similarity of two sets. The feature vectors extracted from the sequences, i.e. signatures, are then used for computing the similarity of query sequences. The computation of signatures and evaluation of the similarities of the signatures are faster than alignment-based comparison by orders of magnitude. 

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



