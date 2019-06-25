#!/bin/bash
# Co-assemble the groups in later iterations
#   $1  Iteration directory
#   $2  Prefix of the file names
mkdir -p $1/contigs

read -r -d '' SLURM_TEMPLATE << EOS
#!/bin/bash
#SBATCH -p defq
#SBATCH -n 16
#SBATCH --time=72:00:00
#SBATCH -o output/assembly-$1-$2-masterout.txt
#SBATCH -e output/assembly-$1-$2-mastererr.txt
#SBATCH --mincpus=16
#SBATCH --mem=80000

FILES=\$(cd $1/cell-groups && ls *.tsv | grep ^"$2")

for FILE in \$FILES; do
    GROUPNAME=\${FILE//.tsv}
    if ! [ -e $1/contigs/\$GROUPNAME.fasta ]; then 
        bash util/assembly.sh $1/cell-groups/\$GROUPNAME.tsv \$GROUPNAME $1/contigs
    fi
done
EOS

printf "$SLURM_TEMPLATE" | sbatch -J assembly-$2
