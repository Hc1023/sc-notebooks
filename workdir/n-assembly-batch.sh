#!/bin/bash
# Co-assemble the groups in the first iteration
#   $1  Iteration directory
#   $2  Prefix of the file names

read -r -d '' SLURM_TEMPLATE << EOS
#!/bin/bash
#SBATCH -p defq
#SBATCH -n 8
#SBATCH --time=72:00:00
#SBATCH -o output/assembly-$1-$2-masterout.txt
#SBATCH -e output/assembly-$1-$2-mastererr.txt
#SBATCH --mincpus=8
#SBATCH --mem=16000

bash util/assembly.sh $1/cell-groups/GROUPNAME.tsv GROUPNAME $1/contigs
EOS

FILES=$(cd $1/cell-groups && ls *.tsv | grep ^"$2")

for FILE in $FILES; do
    GROUPNAME=${FILE//.tsv}
    if ! [ -e $1/contigs/$GROUPNAME.fasta ]; then 
        printf "${SLURM_TEMPLATE//GROUPNAME/$GROUPNAME}" | sbatch -J assembly-$1
    fi
done
