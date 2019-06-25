#!/bin/bash
#SBATCH -p defq
#SBATCH -n 32
#SBATCH --time=48:00:00
#SBATCH -o output/parallel-sig-out.txt
#SBATCH -e output/parallel-sig-err.txt
#SBATCH --mincpus=32
#SBATCH --mem=32000
# Compute the signatures of raw sequencing data

OUT_DIR='raw-signatures'
mkdir -p $OUT_DIR

module add c3ddb/miniconda/3.7
source activate sourmash

i=0
FILES=$(cd raw && ls *_1.fastq)
for FILE in $FILES; do
    CELL_NO=${FILE//_1.fastq}
    if ! [[ -f raw-signatures/$CELL_NO.json ]]; then
        sourmash compute --track-abundance --merge raw/${CELL_NO}_*.fastq --output "$OUT_DIR/$CELL_NO.json" &
        i=$(( i + 1 ))
    fi
    # Pause until the current jobs finished
    # Modify this line for the number of jobs in parallel
    if ! (( (i + 1) % 32 )); then
        wait
    fi
done

wait
