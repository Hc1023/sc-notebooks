#!/bin/bash
# The first round splitting the distance matrices
IN_DIR='it1/dist'
OUT_DIR='it1/groups'
CELL_GROUP_DIR='it1/cell-groups'
mkdir -p $OUT_DIR
ln -fs $OUT_DIR $CELL_GROUP_DIR

# Environment configuration
module add c3ddb/miniconda/3.7
source activate sklearn

read -r -d '' SLURM_TEMPLATE << EOS
#!/bin/bash
#SBATCH -p defq
#SBATCH -n 4
#SBATCH --time=48:00:00
#SBATCH -o output/split-MAT_NO-out.txt
#SBATCH -e output/split-MAT_NO-err.txt
#SBATCH --mincpus=4
#SBATCH --mem=4000

python util/split.py $IN_DIR/MAT_NO.npy $IN_DIR/MAT_NO.npy.labels.txt '(?<=raw/).+(?=_1\.fastq)' $OUT_DIR/MAT_NO-
EOS

FILES=$(cd $IN_DIR && ls *.npy)
for FILE in $FILES; do
    MAT_NO=${FILE//.npy}
    printf "${SLURM_TEMPLATE//MAT_NO/$MAT_NO}" | sbatch -J split
done
