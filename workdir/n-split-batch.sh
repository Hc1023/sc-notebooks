#!/bin/bash
# The first round splitting the distance matrices
#   $1  Source iteration directory
#   $2  Target iteration directory

IN_DIR="$2/dist"
OUT_DIR="$2/groups"
CELL_GROUP_DIR="$2/cell-groups"
mkdir -p $OUT_DIR
mkdir -p $CELL_GROUP_DIR

# Environment configuration
module add c3ddb/miniconda/3.7
source activate sklearn

read -r -d '' SLURM_TEMPLATE_1 << EOS
#!/bin/bash
#SBATCH -p defq
#SBATCH -n 4
#SBATCH --time=48:00:00
#SBATCH -o output/split-MAT_NO-out.txt
#SBATCH -e output/split-MAT_NO-err.txt
#SBATCH --mincpus=4
#SBATCH --mem=4000

python util/split.py $IN_DIR/MAT_NO.npy $IN_DIR/MAT_NO.npy.labels.txt '(?<=$1/contigs/).+(?=\.fasta)' $OUT_DIR/MAT_NO-

# Generate cell groups
OUTS=\$(cd $OUT_DIR && ls MAT_NO-*.tsv)
for OUT in \$OUTS; do
    CELL_GROUPS=\$(cat $OUT_DIR/\$OUT)
    FILES=""
    for GROUP in \$CELL_GROUPS; do
        FILES="$1/cell-groups/\$GROUP.tsv \$FILES"
    done
    cat \$FILES > $CELL_GROUP_DIR/\$OUT
done
EOS

# No prefix
read -r -d '' SLURM_TEMPLATE_2 << EOS
#!/bin/bash
#SBATCH -p defq
#SBATCH -n 4
#SBATCH --time=48:00:00
#SBATCH -o output/split-MAT_NO-out.txt
#SBATCH -e output/split-MAT_NO-err.txt
#SBATCH --mincpus=4
#SBATCH --mem=4000

python util/split.py $IN_DIR/MAT_NO.npy $IN_DIR/MAT_NO.npy.labels.txt '(?<=$1/contigs/).+(?=\.fasta)' $OUT_DIR/

# Generate cell groups
OUTS=\$(cd $OUT_DIR && ls *.tsv)
for OUT in \$OUTS; do
    CELL_GROUPS=\$(cat $OUT_DIR/\$OUT)
    FILES=""
    for GROUP in \$CELL_GROUPS; do
        FILES="$1/cell-groups/\$GROUP.tsv \$FILES"
    done
    cat \$FILES > $CELL_GROUP_DIR/\$OUT
done
EOS

FILES=$(cd $IN_DIR && ls *.npy)
N_FILES=$(ls $IN_DIR/*.npy | wc -l)

for FILE in $FILES; do
    MAT_NO=${FILE//.npy}
    if (( $N_FILES <= 1 )); then
        printf "${SLURM_TEMPLATE_2//MAT_NO/$MAT_NO}" | sbatch -J split
    else
        printf "${SLURM_TEMPLATE_1//MAT_NO/$MAT_NO}" | sbatch -J split
    fi
done
