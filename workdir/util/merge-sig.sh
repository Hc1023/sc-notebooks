#!/bin/bash
# Compare a list of cells
# Arguments:
#   $1  File containing a list of cells
#   $2  Source signature dir
#   $3  Output signature name

# Lines for configuring sourmash
# Modify them accordingly
module add c3ddb/miniconda/3.7
source activate sourmash

CELLS=$(cat $1)
NCELLS=0
SIGS=""

for CELL in $CELLS; do
    SIGS="$SIGS $2/$CELL.json"
    NCELLS=$((NCELLS + 1))
done

if [ $NCELLS -eq 1 ]; then
    cp $SIGS $3
else
    sourmash signature merge $SIGS -k 51 -o $3
fi
