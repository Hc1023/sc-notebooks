# Genome recovery from single-cell sequencing data

High-quality genome recovery is an important task in genomics applied to microbiomes. Such a task applied to metagenomics sequencing data, aka binning, is already widely practiced, while genome recovery from single-cell sequencing data remains under-developed.

We here introduce an effective computational pipeline for recovering genomes from single-cell sequencing data in large scale, with detailed descriptions to the scripts we are using. The document serves as a readme/recipe to reproduce our method.

The very fundamental idea of our pipeline is to co-assemble the cells that are likely to be the same species, and thus genomes of the species are supposed to be recovered. Each single-cell sequencing file reveals limited completeness of the cell’s information. Empirically, a high-quality genome assembly requires sequencing data of at least 20 cells of the same species.

Our method can be roughly divided into three stages. a) Iterative comparing and aggregating, which tries to gather the cells of the same species to the same group. Each iteration is done by sequence comparisons of cells or groups of cells, with the help of Sourmash, an implementation of the MinHash similarity comparing algorithm. The cell or cell groups with similarities to an extent will be gathered using cluster analysis techniques. And later co-assembled to get draft genome assemblies for quality check. b) Splitting the contaminated cell groups and merging the groups representing identical species, which could fix the false positives and the false negatives respectively introduced in former stage. c) Final co-assembly and clean up, which finalize the whole process returning the genomes we recovered from the input sequencing data.

> Data and intermediate files are located at `/scratch/users/yehang/nsc-full`. The description below uses relative paths to this directory.

## Data specification

All the raw sequencing data is located in `raw`. Our data, acquired by NextSeq and NovaSeq technology, concerns both paired-end and single-end reads. The naming convention follows a very simple rule,

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



### Pre-division

The motivation of the pre-division is to make mash comparison feasible for large number of cells. 

```
$ bash dividing.sh
```

The command line above will generate lists of cell numbers and write the files to the directory `divisions`. The default division size is 4000. This can be modified in the script,

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
You'll have to compute the Mash signatures for every raw cell sequencing data.

```

```