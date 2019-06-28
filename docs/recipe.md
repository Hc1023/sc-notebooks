# Script usage manual

> Data and intermediate files are located at `/scratch/users/yehang/nsc-full`. The description below uses relative paths to this directory.

## Data specification

All the raw sequencing data is located in `raw`. Our data, acquired by NextSeq and NovaSeq technology, concerns both paired-end and single-end reads. The naming convention follows a very simple rule,

```
<CELL NAME>_<1|2|S>.fastq
```

where the paired-end reads end with `1.fastq` or `2.fastq`, and the file for single-end reads end with `S.fastq`. 

Though the paired-end information preserves, we treat the data single-end-wisely. The files will be merged together when we compute the mash distances and assemble the reads. By doing this, the assembly outperforms the result of paired-end-wise assembly slightly.

Currently we have sequencing data of 21,914 single cells from multiple samples of the same donor, and thus there are 21,914 × 3 = 65,742​ `.fastq` files in directory `raw`.

> Note: The `CELL NAME` should not contain underscores, spaces and hyphens!

## Hierarchy of the working directory

The input sequencing data of the single cells is located in the directory `raw`. The `.sh` and `.slurm` scripts stored directly inside the working directory are major scripts for submitting computational jobs. Scripts with filenames starting with `1` handles the first round of signature computation, pre-division and dendrogram splitting. Scripts with filenames starting with `n` are used for tasks in later iterations. And filenames starting with `c` do correction jobs for the cell groups. The `util` directory contains utility scripts for some common tasks. The directory `output` is used for . New directories are created when needed.

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

### 1-1. Signature computing of all cells

The sequence comparing tool, Sourmash, is based on MinHash algorithm, which is originally used for comparing the similarity of two sets. The feature vectors extracted from the sequences, i.e. signatures, are then used for computing the similarities of the query sequences. 

The following line submits a job for computing the signatures for all cells in the directory `raw`. The signatures will then be written to the `raw-signatures` directory in the working directory with the `.json` file extensions.

```
$ sbatch 1-raw-sig.slurm
```

To make the script work for your case, you may need to modify the lines for the environment configuration. This also applies to scripts in the following steps.

```shell
module add c3ddb/miniconda/3.7
source activate sourmash
```

The job requires 32 CPUs available on the cluster, and runs 32 `sourmash compute` jobs in parallel. You can modify the script to change the number of minimum CPUs, number of nodes and the number of jobs in parallel.

The Sourmash command line for signature computing is,

```
sourmash compute --track-abundance --merge raw/${CELL_NO}_*.fastq --output "$OUT_DIR/$CELL_NO.json"
```

The `--track-abundance` option would preserve the abundance information of the *k*-mers. And the `--merge` option would take the paired-end and single-end sequencing files as a whole. The default *k*-mer sizes of Sourmash are 21, 31 and 51.

### 1-2. Pre-division

The motivation of the pre-division is to make mash comparison feasible for large number of cells. Sourmash’s mash distance comparison requires intensive RAM usage, making 20k signatures impossible to compare all at once. Our pre-division simply divides the cells by lexicographical order with a maximum division size of 4,000. 

```
$ bash 1-dividing.sh
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

### 1-3. Comparing signatures

We then make pairwise comparisons of the signatures.

```
$ bash 1-compare-batch.sh
```

This script will submit several Sourmash comparison jobs to Slurm, each one requires 16 CPUs and 80 GB RAM.

The distance matrices computed will be written to the directory `it1/dist`. The files written to the directory includes (the i’s below are division numbers), `i.npy` which is a NumPy array dump containing the distance matrix, `i.npy.labels.txt` which is a list of filenames for the compared sequences, and `i.csv` containing the matrix in CSV format. 

### 1-4. Splitting dendrogram

The distance matrices are then used for hierarchical clustering. The clustering requires certain criterion for splitting the dendrogram and flatten the subtrees to lists as the clusters. 

```
$ bash 1-split-batch.sh
```

The script submits Slurm jobs to split all the distance matrices resulting by the former step. The script depends on the utility Python script `util/split.py` to work. The jobs will write the groups as lists to individual TSV files located in `it1/groups` and create a soft link `it1/cell-groups` referring to `it1/groups` for compatibility with later steps.

Looking into `util/split.py`, you will notice that the clustering is computed with the following line of Python code,

```python
assignments = fcluster(linkage(square_form, method = 'complete'), 0.95, criterion = 'distance')
```

This means that we are using the complete linkage method with 0.95 distance criterion for splitting the dendrogram to clusters. This ensures that the similarities within each cluster will be at least 5% by Sourmash’s Jaccard index.

### n-1. Co-assemble the single cells in each cluster

The cell groups are co-assembled and the contigs are used for later steps. The script requires two parameters, the first of which is the directory name for the current iteration, and the second is the group name prefix. The script will submit a job to co-assemble the cell groups with the specified group names prefix serially.

```
$ bash n-assembly.sh <ITERATED DIR> <GROUP PREFIX>
```

Below is an example for submitting co-assembly jobs for the first iteration. 64 Slurm jobs will be submitted, each of them requires 80 GB RAM and 16 CPUs.

```
$ bash n-assembly.sh it1 0-1
Submitted batch job xxxxxxx
$ bash n-assembly.sh it1 0-2
Submitted batch job xxxxxxx
...
$ bash n-assembly.sh it1 0-9
Submitted batch job xxxxxxx
$ bash n-assembly.sh it1 1-1
Submitted batch job xxxxxxx
...
$ bash n-assembly.sh it1 5-9
Submitted batch job xxxxxxx
```

There is also a script submit the co-assembly jobs in batches. Be careful when submitting jobs using this script.

```
$ bash n-assembly-batch.sh it1 0-1
```

The command above will submit huge amount of Slurm jobs in parallel, each of which handles only one co-assembly of a cell group with the filename prefix `0-1`.

The sequencing data of the cells within each group are then concatenated together and co-assembled single-end-wisely. The utility shell script for the assembly is `util/assembly.sh` using the command line

```shell
spades.py --careful --sc -s ${OUT_DIR}/${BASENAME}.fastq -o ${OUT_DIR}/${BASENAME}
```

The `--sc` (single-cell) option reduces the impact of MDA, and the `--careful` option turns on the MismatchCorrector for post processing.

### n-2. Quality assessment with CheckM

CheckM is used for quality assessment of the assemblies, especially the completeness and the contamination of the draft genome assemblies. This step does require the following steps to halt. 

The assemblies are also divided for running CheckM, the default devision size is 1,000, and this can be modified in the script `n-checkm.sh`.

```
$ bash n-checkm.sh <ITERATED DIR>
```

### n-3. Computing signatures of the assemblies

The signatures of the assemblies are computed for later comparison. The reason for using independent scripts for the three steps n-3 to n-5 in further iteration is for ease of the directory hierarchy.

```
$ bash n-contig-sig.sh <ITERATED DIR>
```

### n-4. Comparison of the assembly signatures

The comparison of the signatures from the assemblies makes no differences from the comparison of the signatures from raw sequencing data.

The comparison bootstrap script requires two arguments. The first argument specify the source iteration directory, for which the signatures are already computed. The second argument specify the target directory for storing the comparison result, in which the next iteration will start.

```
$ bash n-compare-batch.sh <SOURCE DIR> <TARGET DIR>
```

An example is (starting the second iteration),

```
$ bash n-compare-batch.sh it1 it2
```

### n-5. Splitting the comparison result

The script for splitting dendrograms in the iteration steps is different from the splitting script for the first round, and will output the clustering results to two directories, `groups` containing lists of cell groups in the former iteration, and `cell-groups` containing lists of corresponding cells.

```
$ bash n-split-batch.sh <SOURCE DIR> <TARGET DIR>
```

### Iterating

The steps above are repeated until CheckM (n-3) reports that more than 10% of the assemblies have more than 20% contamination. The resulting cell groups and the corresponding assemblies are later used for error correction and cleaning-up.

## Correcting errors of the iteration result

After running CheckM to evaluate the completeness and contamination of the assemblies. The cell groups whose co-assemblies have > 20% contamination are chosen for separating to reduce the false positive errors. Then, the cells in the groups are co-assembled again. The cell groups with > 95% ANI will be merged to reduce the false negative errors.

### Separating mixed cell groups

```
$ bash c-separating.sh <BASE NAME> <OUTPUT DIR>
```

Please ensure that the assembly is located at `<BASE NAME>.fasta` and the corresponding list of cells is at `<BASE NAME>.tsv`. Separated cell groups will be written to `<OUTPUT DIR>` as TSV cell lists.

