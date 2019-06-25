#!/bin/bash
# Computing signatures for fasta files in the iteration
#   $1  Iterated directory

# Sourmash environment configuration
# Modify the lines when needed
module add c3ddb/miniconda/3.7
source activate sourmash

IN_DIR="$1/contigs"
OUT_DIR="$1/signatures"
mkdir -p ${OUT_DIR}

read -r -d '' SLURM_TEMPLATE << EOS
#!/bin/bash
#SBATCH -p defq
#SBATCH -n 32
#SBATCH --time=72:00:00
#SBATCH -o output/signatures-masterout.txt
#SBATCH -e output/signatures-mastererr.txt
#SBATCH --mincpus=32
#SBATCH --mem=64000

FILES=\$(cd ${IN_DIR} && ls *.fasta)

i=0
for FILE in \$FILES; do
    GROUP_NO=\${FILE//.fasta}
    if ! [[ -f ${OUT_DIR}/\$GROUP_NO.json ]]; then
        sourmash compute --track-abundance "${IN_DIR}/\${GROUP_NO}.fasta" --output "${OUT_DIR}/\${GROUP_NO}.json" &
        i=\$(( i + 1 ))
    fi
    # Pause until the current jobs finished
    if ! (( (i + 1) %% 32 )); then
        wait
    fi
done
wait
EOS

printf "$SLURM_TEMPLATE" | sbatch -J signatures
