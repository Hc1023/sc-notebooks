#!/bin/bash
# Comparing 
#   $1  Source iteration directory
#   $2  Target iteration directory

# Sourmash environment configuration
# Modify the lines when needed
module add c3ddb/miniconda/3.7
source activate sourmash

IN_DIR="$1/signatures"
OUT_DIR="$2/dist"
COMPARE_LIMIT=4000
mkdir -p ${OUT_DIR}

echo 'Creating temp cell indices...'

i=0
# A list of the input signatures and sorted by random
IN_SIGS=$(cd $IN_DIR && ls *.json | sort -R)
# Devide the source groups
for SIG_FILE in $IN_SIGS; do
    SIG_NO=${SIG_FILE//.json}
    if ! ((i%COMPARE_LIMIT)); then
        printf "" > $OUT_DIR/temp-$((i/COMPARE_LIMIT)).tsv
    fi
    echo $SIG_NO >> $OUT_DIR/temp-$((i/COMPARE_LIMIT)).tsv
    i=$((i+1))
done

read -r -d '' SLURM_TEMPLATE << EOS
#!/bin/bash
#SBATCH -p defq
#SBATCH -n 16
#SBATCH --time=48:00:00
#SBATCH -o output/compare-DIV_NO-out.txt
#SBATCH -e output/compare-DIV_NO-err.txt
#SBATCH --mincpus=16
#SBATCH --mem=80000

bash util/compare.sh $OUT_DIR/temp-DIV_NO.tsv $IN_DIR $OUT_DIR/DIV_NO &&
rm $OUT_DIR/temp-DIV_NO.tsv
EOS

FILES=$(cd $OUT_DIR && ls temp-*.tsv)
for FILE in $FILES; do
    DIV_NO=${FILE//.tsv}
    DIV_NO=${DIV_NO//temp-}
    printf "${SLURM_TEMPLATE//DIV_NO/$DIV_NO}" | sbatch -J compare-$DIV_NO
done
