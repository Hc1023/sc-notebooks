#!/bin/bash
# Co-assemble the groups in the first iteration
#   $1  Directory containing a cells lists
#   $2  Source signature directory
#   $3  Target signature directory

read -r -d '' SLURM_TEMPLATE << EOS
#!/bin/bash
#SBATCH -p defq
#SBATCH -n 16
#SBATCH --time=72:00:00
#SBATCH -o output/0-merge-masterout.txt
#SBATCH -e output/0-merge-mastererr.txt
#SBATCH --mincpus=16
#SBATCH --mem=32000

FILES=\$(cd $1 && ls *.tsv)

for FILE in \$FILES; do
    GROUPNAME=\${FILE//.tsv}
    if ! [ -e $3/\$GROUPNAME.json ]; then 
        bash util/merge-sig.sh $1/\$GROUPNAME.tsv $2 $3/\$GROUPNAME.json
    fi
done
EOS

printf "$SLURM_TEMPLATE" | sbatch -J merge-sig
