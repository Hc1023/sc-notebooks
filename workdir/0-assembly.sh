#!/bin/bash
# Co-assemble the groups in the first iteration
#   $1  Prefix of the file names
mkdir -p it1/contigs

read -r -d '' SLURM_TEMPLATE << EOS
#!/bin/bash
#SBATCH -p defq
#SBATCH -n 16
#SBATCH --time=72:00:00
#SBATCH -o output/assembly-1-$1-masterout.txt
#SBATCH -e output/assembly-1-$1-mastererr.txt
#SBATCH --mincpus=16
#SBATCH --mem=32000

FILES=\$(cd it1/cell-groups && ls *.tsv | grep ^"$1")

for FILE in \$FILES; do
    GROUPNAME=\${FILE//.tsv}
    if ! [ -e it1/contigs/\$GROUPNAME.fasta ]; then 
        bash util/assembly.sh it1/cell-groups/\$GROUPNAME.tsv \$GROUPNAME it1/contigs
    fi
done
EOS

printf "$SLURM_TEMPLATE" | sbatch -J assembly-$1
