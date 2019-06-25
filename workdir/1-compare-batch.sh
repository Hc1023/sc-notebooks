#!/bin/bash
# The first round comparison of raw reads
SIG_DIR='raw-signatures'
OUT_DIR='it1/dist'
mkdir -p OUT_DIR

# Sourmash environment configuration
# Modify the lines when needed
module add c3ddb/miniconda/3.7
source activate sourmash

read -r -d '' SLURM_TEMPLATE << EOS
#!/bin/bash
#SBATCH -p defq
#SBATCH -n 16
#SBATCH --time=48:00:00
#SBATCH -o output/compare-DIV_NO-out.txt
#SBATCH -e output/compare-DIV_NO-err.txt
#SBATCH --mincpus=16
#SBATCH --mem=80000

bash util/compare.sh divisions/DIV_NO.tsv $SIG_DIR $OUT_DIR/DIV_NO
EOS

FILES=$(cd divisions && ls *.tsv)
for FILE in $FILES; do
    DIV_NO=${FILE//.tsv}
    printf "${SLURM_TEMPLATE//DIV_NO/$DIV_NO}" | sbatch -J compare-$DIV_NO
done
