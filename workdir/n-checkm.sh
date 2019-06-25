#!/bin/bash
# Running CheckM for 
#   $1  Iterated directory

# CheckM environment configuration
# Modify the lines when needed
module add c3ddb/miniconda/3.7
source activate checkm

IN_DIR="$1/contigs"
OUT_DIR="$1/checkm"
N_FILES=$(ls $IN_DIR | grep .fasta | wc -l)
CHECKM_LIMIT=1000
mkdir -p ${OUT_DIR}

read -r -d '' SLURM_TEMPLATE << EOS
#!/bin/bash
#SBATCH -p defq
#SBATCH -n 32
#SBATCH --time=72:00:00
#SBATCH -o output/checkm-out.txt
#SBATCH -e output/checkm-err.txt
#SBATCH --mincpus=32
#SBATCH --mem=80000

if (( $N_FILES <= $CHECKM_LIMIT )); then
    checkm lineage_wf -t 32 -x fasta $IN_DIR $OUT_DIR
else
    i=0
    FILES=\$(cd $IN_DIR && ls *.fasta)
    for FILE in \$FILES; do
        DIR_NO=\$((i/$CHECKM_LIMIT))
        mkdir $OUT_DIR/temp-\$DIR_NO
        ln $IN_DIR/\$FILE $OUT_DIR/temp-\$DIR_NO
        i=\$((i+1))
    done
    for TEMP_DIR in $OUT_DIR/temp-*; do
        TEMP_NO=\${TEMP_DIR//"$OUT_DIR/temp-"}
        checkm lineage_wf -t 32 -x fasta \$TEMP_DIR $OUT_DIR/\$TEMP_NO
    done &&
    rm -r $OUT_DIR/temp-*
fi
EOS

printf "$SLURM_TEMPLATE" | sbatch -J checkm
