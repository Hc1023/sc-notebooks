#!/bin/bash
# Assemble a list of cells
#   $1  File containing a list of cells
#   $2  Output basename
#   $3  Output directory

# Modify this environment configuration line accordingly
module add c3ddb/SPAdes/3.13.0

CELLS=$(cat "$1")
BASENAME=$2
OUT_DIR=$3
TO_MERGE=""

echo $CELLS

for CELL in $CELLS; do
    TO_MERGE="$TO_MERGE raw/${CELL}_*.fastq"
done

echo $TO_MERGE

cat $TO_MERGE > ${OUT_DIR}/${BASENAME}.fastq

spades.py --careful --sc -s ${OUT_DIR}/${BASENAME}.fastq -o ${OUT_DIR}/${BASENAME} &&
mv ${OUT_DIR}/${BASENAME}/contigs.fasta ${OUT_DIR}/${BASENAME}.fasta &&
rm ${OUT_DIR}/${BASENAME}.fastq &&
rm -r ${OUT_DIR}/${BASENAME}
