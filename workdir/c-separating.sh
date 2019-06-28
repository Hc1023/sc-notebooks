#!/bin/bash
# Separating the contaminated assemblies
#   $1  Base name
#   $2  Output directory
# Please ensure that $1.fasta is the assembly file
# and $1.tsv contains a list of the corresponding cells

# Environment configuration
module add c3ddb/bowtie2/2.2.6
module add c3ddb/samtools/1.6
module add c3ddb/miniconda/3.7
source activate sklearn

IN_FILE=$1
FILEBASE=$(echo "$1" | sed "s/.*\///")
OUT_DIR=$2
RAW_DIR=raw
mkdir -p $OUT_DIR
mkdir -p $OUT_DIR/indices


read -r -d '' SLURM_TEMPLATE << EOS
#!/bin/bash
#SBATCH -p defq
#SBATCH -n 16
#SBATCH --time=48:00:00
#SBATCH -o output/separating-$FILEBASE-out.txt
#SBATCH -e output/separating-$FILEBASE-err.txt
#SBATCH --mincpus=16
#SBATCH --mem=16000

# Indexing
bash util/extract1k.sh "$IN_FILE.fasta" "$OUT_DIR/indices/$FILEBASE.1k"
bowtie2-build "$OUT_DIR/indices/$FILEBASE.1k" "$OUT_DIR/indices/$FILEBASE"

# Aligning
CELLS=\$(cat "$IN_FILE.tsv")
for CELL_NO in \$CELLS; do
    bowtie2 -x $OUT_DIR/indices/$FILEBASE -U raw/\${CELL_NO}_1.fastq,raw/\${CELL_NO}_2.fastq,raw/\${CELL_NO}_S.fastq -S $OUT_DIR/align/\${CELL_NO}.sam &&
    samtools sort $OUT_DIR/align/\${CELL_NO}.sam > $OUT_DIR/align/\${CELL_NO}_$FILEBASE.bam && rm $OUT_DIR/align/\${CELL_NO}.sam
done

# Computing depths
for CELL_NO in \$CELLS; do
    samtools depth $OUT_DIR/align/\${CELL_NO}_$FILEBASE.bam | python util/depth-tsv.py > $OUT_DIR/depths/\${CELL_NO}_$FILEBASE.tsv
done

# Hierarchical clustering
python util/depth-clustering.py $OUT_DIR/depths/*_$FILEBASE.tsv $OUT_DIR
EOS

printf "$SLURM_TEMPLATE" | sbatch -J separating-$BASENAME
